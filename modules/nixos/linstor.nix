{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.linstor = {
    enable = lib.mkEnableOption "linstor";
    controller.enable = lib.mkEnableOption "linstor controller (+drbd-reactor)";
    controllers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "linstor controllers for client connection";
      example = [
        "linstor://192.168.9.10"
        "linstor://192.168.9.11"
      ];
    };
    localIp = lib.mkOption {
      type = lib.types.str;
      description = "LINSTOR local IP address";
      example = "192.168.9.10";
    };
    storagePools = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [
                "lvm"
                "lvmthin"
                "zfs"
                "zfsthin"
                "file"
                "filethin"
              ];
              example = "zfs";
              description = "storage pool provider";
            };
            backing = lib.mkOption {
              type = lib.types.str;
              description = "storage pool provider argument";
              example = "rpool/linstor";
            };
          };
        }
      );
      default = { };
      description = "node-local storage pools (name -> config)";
      example = {
        incus_zfs = {
          type = "zfs";
          backing = "rpool/linstor";
        };
      };
    };
    dbStoragePool = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "storage pool for linstor_db (key of jemand771.linstor.storagePools)";
    };
  };
  config = lib.mkIf config.jemand771.linstor.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = builtins.length config.jemand771.linstor.controllers > 0;
            message = "need at least one linstor controller";
          }
          {
            assertion =
              (config.jemand771.linstor.dbStoragePool != null) == config.jemand771.linstor.controller.enable;
            message = "jemand771.linstor.dbStoragePool must be set if and only if jemand771.linstor.controller.enable is true";
          }
        ];

        preservation.preserveAt."/persist" = {
          directories = [
            # TODO needed?
            # "/var/lib/linstor"
            # "/var/lib/linstor.d"
          ];
        };

        environment.systemPackages = [ pkgs.linstor-client ];
        environment.etc."linstor/linstor-client.conf".text = ''
          [global]
          controllers = ${lib.concatStringsSep "," config.jemand771.linstor.controllers}
        '';

        # trick incus into using our linstor binaries (well, "trick", just debianmoding)
        systemd.tmpfiles.settings.incus-linstor-shim = {
          "/usr/share/linstor-server/bin/Satellite"."L+".argument =
            lib.getExe' pkgs.linstor-server "linstor-satellite";
          "/usr/share/linstor-server/bin/Controller"."L+".argument =
            lib.getExe' pkgs.linstor-server "linstor-controller";
        };

        services.drbd = {
          enable = true;
          config = ''
            include "/var/lib/linstor.d/*.res";
            global {
              usage-count no;
              udev-always-use-vnr;
            }
          '';
        };
        # we just want the system config goodies, not the actual service (it runs `drbdadm up all`, ugh)
        systemd.suppressedSystemUnits = [ "drbd.service" ];
        # force drbd 9 (in-tree is v8)
        boot.extraModulePackages = [ config.boot.kernelPackages.drbd ];

        systemd.services.linstor-satellite = {
          description = "LINSTOR satellite";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            # journal already has everything, but file logging can't be turned off.
            # dump logs somewhere they don't bother us (the default would be /logs)
            ExecStart = "${lib.getExe' pkgs.linstor-server "linstor-satellite"} --logs /run/linstor-satellite";
            RuntimeDirectory = "linstor-satellite";
            Restart = "on-failure";
            StateDirectory = "linstor.d";
          };
        };
      }

      {
        # on any one (!) node:
        # systemctl start linstor-controller
        # then on each node (including the one running the controller):
        #   systemctl start --wait linstor-register
        # after that, continue bootstrap+join dance
        systemd.services.linstor-register = {
          description = "register LINSTOR node";
          enableStrictShellChecks = true;
          after = [
            "linstor-satellite.service"
            "network-online.target"
          ];
          requires = [ "linstor-satellite.service" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "60s";
          };
          script =
            let
              linstor = lib.getExe' pkgs.linstor-client "linstor";
              node = config.networking.hostName;
              poolCmds = lib.concatStrings (
                lib.mapAttrsToList (
                  name: pool: "${linstor} storage-pool create ${pool.type} ${node} ${name} ${pool.backing}\n"
                ) config.jemand771.linstor.storagePools
              );
            in
            ''
              set -x

              until ${linstor} node list; do sleep 1; done

              ${linstor} node create ${node} ${config.jemand771.linstor.localIp}
              ${poolCmds}
            '';
        };
      }

      (lib.mkIf config.jemand771.linstor.controller.enable {
        # created manually instead of via StateDirectory for the initial bootstrapping dance
        # (so the controller doesn't depend on something in there that doesn't exist yet)
        systemd.tmpfiles.settings.linstor."/var/lib/linstor".d = {
          mode = "0700";
          user = "root";
          group = "root";
        };

        systemd.services.linstor-controller = {
          description = "LINSTOR controller";
          # not wantedBy anything because drbd-reactor starts and stops it
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            # journal already has everything, but file logging can't be turned off.
            # dump logs somewhere they don't bother us (the default would be /logs)
            ExecStart = "${lib.getExe' pkgs.linstor-server "linstor-controller"} --logs /run/linstor-controller";
            RuntimeDirectory = "linstor-controller";
            Restart = "on-failure";
          };
        };

        # mounted by promoter before starting the controller
        systemd.mounts = [
          {
            what = "/dev/drbd/by-res/linstor_db/0";
            where = "/var/lib/linstor";
            type = "ext4";
            options = "noauto";
          }
        ];

        # see https://github.com/LINBIT/drbd-utils/blob/master/scripts/drbd-service-shim.sh.in
        systemd.tmpfiles.settings.drbd-reactor = {
          "/lib/drbd/scripts".d = {
            mode = "0755";
            user = "root";
            group = "root";
          };
          "/lib/drbd/scripts/drbd-service-shim.sh"."L+".argument = "${lib.getExe (
            pkgs.writeShellApplication {
              name = "drbd-service-shim.sh";
              text = ''
                cmd="$1"
                res="$2"
                case "$cmd" in
                  primary)
                    exec ${pkgs.drbd}/bin/drbdadm primary "$res"
                    ;;
                  secondary)
                    exec ${pkgs.drbd}/bin/drbdadm secondary "$res"
                    ;;
                  secondary-secondary-force)
                    ${pkgs.drbd}/bin/drbdadm secondary "$res" || ${pkgs.drbd}/bin/drbdadm secondary --force "$res"
                    ;;
                  *)
                    echo "drbd-service-shim.sh: unknown verb: $cmd" >&2
                    exit 1
                    ;;
                esac
              '';
            }
          )}";
        };

        # only run drbd-reactor when a node has either bootstrapped or joined a HA setup.
        # linstor_db is local-only until then
        preservation.preserveAt."/persist".directories = [ "/var/lib/linstor-ha-marker" ];
        systemd.paths.drbd-reactor = {
          description = "Start drbd-reactor once this node is a commissioned HA controller";
          wantedBy = [ "multi-user.target" ];
          pathConfig.PathExists = "/var/lib/linstor-ha-marker/enabled";
        };
        systemd.services.drbd-reactor = {
          description = "DRBD reactor";
          # started by drbd-reactor.path (either transiently at boot or via bootstrap/join oneshots)
          after = [
            "network-online.target"
            "systemd-modules-load.service"
          ];
          path = [ pkgs.drbd ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "notify";
            ExecStart = lib.getExe pkgs.drbd-reactor;
            Restart = "on-failure";
          };
        };

        environment.systemPackages = [
          # for drbd-reactorctl
          pkgs.drbd-reactor
        ];

        # yoink and unyoink resources
        systemd.services."drbd-promote@" = {
          description = "Promote DRBD resource %I";
          after = [
            "drbd.service"
            "systemd-modules-load.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            ExecStart = "${pkgs.drbd}/bin/drbdadm primary %i";
            ExecStop = "${pkgs.drbd}/bin/drbdadm secondary %i";
          };
        };

        # drbd-reactor says: Unit drbd-services@blabla.target not found
        systemd.targets."drbd-services@" = {
          description = "DRBD services target for resource %I";
          unitConfig = {
            PartOf = "drbd-promote@%i.service";
            Requires = "drbd-promote@%i.service";
            After = "drbd-promote@%i.service";
          };
        };

        # drbd-reactorctl doesn't care about this config, the canonical location is /etc/drbd-reactor.d
        environment.etc."drbd-reactor.toml".text = ''
          snippets = "/etc/drbd-reactor.d"
        '';

        # enable the HA data mount and controller on the primary node
        environment.etc."drbd-reactor.d/linstor.toml".text = ''
          [[promoter]]
          [promoter.resources.linstor_db]
          start = [
            "var-lib-linstor.mount",
            "linstor-controller.service",
          ]
        '';

        # first register every node (set localIp + storagePools per host,
        # then on each node once a controller is up):
        # systemctl start --wait linstor-register
        # that forms the cluster, but linstor's db isn't distributed. to fix that:
        # systemctl start --wait linstor-bootstrap
        # also see https://linbit.com/drbd-user-guide/linstor-guide-1_0-en/#s-linstor_ha
        # on later node additions, remember to adjust the linstor_db replica count so each controller gets one:
        # linstor resource-group modify linstor_db --place-count 3 --diskless-on-remaining false
        systemd.services.linstor-bootstrap = {
          description = "Bootstrap LINSTOR";
          enableStrictShellChecks = true;
          after = [
            "linstor-satellite.service"
            "network-online.target"
          ];
          requires = [ "linstor-satellite.service" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "60s";
          };
          script =
            let
              linstor = lib.getExe' pkgs.linstor-client "linstor";
              drbdadm = lib.getExe' pkgs.drbd "drbdadm";
              mkfs = lib.getExe' pkgs.e2fsprogs "mkfs.ext4";
              mount = lib.getExe' pkgs.util-linux "mount";
              umount = lib.getExe' pkgs.util-linux "umount";
              blkid = lib.getExe' pkgs.util-linux "blkid";
            in
            ''
              set -x

              if [ -e /var/lib/linstor-ha-marker/enabled ]; then
                echo /var/lib/linstor-ha-marker/enabled exists
                exit 1
              fi
              if ${linstor} resource list -r linstor_db | grep linstor_db; then
                echo linstor_db already exists
                exit 1
              fi

              systemctl start linstor-controller.service
              until ${linstor} node list; do sleep 1; done

              ${linstor} resource-group create linstor_db \
                --place-count 2 \
                --storage-pool ${config.jemand771.linstor.dbStoragePool} \
                --diskless-on-remaining true
              ${linstor} resource-group drbd-options \
                --auto-promote=no \
                --quorum=majority \
                --on-suspended-primary-outdated=force-secondary \
                --on-no-quorum=io-error \
                --on-no-data-accessible=io-error \
                linstor_db
              ${linstor} volume-group create linstor_db
              ${linstor} resource-group spawn-resources linstor_db linstor_db 1G

              # by-res symlink created by udev
              until [ -b "/dev/drbd/by-res/linstor_db/0" ]; do sleep 1; done

              until ${drbdadm} primary linstor_db; do sleep 1; done
              systemctl stop linstor-controller.service

              if ${blkid} -t TYPE=ext4 /dev/drbd/by-res/linstor_db/0; then
                echo /dev/drbd/by-res/linstor_db/0 already ext4
              else
                ${mkfs} -L linstor_db /dev/drbd/by-res/linstor_db/0
                mnt="$(mktemp -d)"
                ${mount} /dev/drbd/by-res/linstor_db/0 "$mnt"
                cp -a /var/lib/linstor/. "$mnt"/
                ${umount} "$mnt"
                rmdir "$mnt"
              fi
              ${drbdadm} secondary linstor_db

              mkdir -p /var/lib/linstor-ha-marker
              touch /var/lib/linstor-ha-marker/enabled
            '';
        };

        # systemctl start --wait linstor-join
        systemd.services.linstor-join = {
          description = "Join LINSTOR";
          enableStrictShellChecks = true;
          after = [
            "linstor-satellite.service"
            "network-online.target"
          ];
          requires = [ "linstor-satellite.service" ];
          wants = [ "network-online.target" ];
          serviceConfig.Type = "oneshot";
          script =
            let
              linstor = lib.getExe' pkgs.linstor-client "linstor";
              drbdadm = lib.getExe' pkgs.drbd "drbdadm";
            in
            ''
              set -x

              if [ -e /var/lib/linstor-ha-marker/enabled ]; then
                echo /var/lib/linstor-ha-marker/enabled exists
                exit 1
              fi
              if ! ${linstor} resource list -r linstor_db | grep linstor_db; then
                echo linstor_db does not exist, is the cluster bootstrapped?
                exit 1
              fi
              if ! ${drbdadm} status linstor_db | grep -E '[[:space:]]disk:' | grep -vi diskless; then
                echo local linstor_db replica is diskless
                exit 1
              fi

              mkdir -p /var/lib/linstor-ha-marker
              touch /var/lib/linstor-ha-marker/enabled
            '';
        };
      })
    ]
  );
}
