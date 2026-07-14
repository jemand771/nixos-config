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
  };
  config = lib.mkIf config.jemand771.linstor.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = builtins.length config.jemand771.linstor.controllers > 0;
            message = "need at least one linstor controller";
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
            ExecStart = lib.getExe' pkgs.linstor-server "linstor-satellite";
            Restart = "on-failure";
            StateDirectory = "linstor.d";
          };
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
            ExecStart = "${lib.getExe' pkgs.linstor-server "linstor-controller"}";
            Restart = "on-failure";
          };
        };

        # see https://github.com/LINBIT/drbd-utils/blob/master/scripts/drbd-service-shim.sh.in
        systemd.tmpfiles.settings.drbd-reactor = {
          "/lib/drbd/scripts".d = {
            mode = "0755";
            user = "root";
            group = "root";
          };
          "/lib/drbd/scripts/drbd-service-shim.sh"."L+".argument =
            "${pkgs.writeShellScript "drbd-service-shim.sh" ''
              set -e
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
            ''}";
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
      })
    ]
  );
}
