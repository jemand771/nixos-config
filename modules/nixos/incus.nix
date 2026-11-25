{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.incus.enable = lib.mkEnableOption "Incus (assumes preservation + rpool)";
  options.jemand771.incus.localIp = lib.mkOption {
    type = lib.types.str;
    description = "cluster.https_address";
    default = "";
    example = "192.168.9.10";
  };
  options.jemand771.incus.memberConfig = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    description = "incus member config";
    default = { };
    example = {
      "scheduler.instance" = "manual";
    };
  };
  options.jemand771.incus.trustedCertificates = lib.mkOption {
    type = lib.types.attrsOf lib.types.path;
    description = "client certificates to add to the trust store";
    default = { };
    example = {
      willy = ../../certs/incus-client-willy.crt;
    };
  };
  options.jemand771.incus.projects = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    description = "extra project configuratoin";
    default = { };
    example = {
      myproject = {
        "limits.containers" = "1";
        "limits.instances" = "5";
      };
    };
  };
  config = lib.mkIf config.jemand771.incus.enable {
    preservation.preserveAt."/persist".directories = [ "/var/lib/incus" ];
    networking.nftables.enable = true;
    virtualisation.incus = {
      enable = true;
      package = pkgs.incus-lts.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/lxc/incus/commit/6528817f2db68f8ebb1dda45ee6825ede9050ef7.patch";
            hash = "sha256-Eu/quAT7p6EEMVVwGCIoxeNgug9zJLl5Ynt3mSvGsGw=";
          })
        ];
      });
      ui.enable = true;
      preseed = {
        projects = builtins.map ({ name, value }: {
          inherit name;
          config = {
            # true = isolate, false = use default project.
            # we want common networking, but the default project expects `true` everywhere
            "features.networks" = lib.boolToString (name == "default");
            "features.profiles" = "true";
            "features.images" = "true";
            "features.storage.volumes" = "true";
            "features.storage.buckets" = "true";
            "restricted" = "true";
            "restricted.networks.access" = lib.optionalString (name != "default") "default";
          }
          // value;
        }) (lib.attrsToList config.jemand771.incus.projects);
        profiles = builtins.map (project: {
          name = "default";
          inherit project;
          config = {
            "migration.stateful" = "true";
          };
          devices = {
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
            eth0 = {
              type = "nic";
              network = "default";
              name = "eth0";
            };
          };
        }) (lib.attrNames config.jemand771.incus.projects);
      };
    };

    # systemctl start --wait incus-bootstrap
    systemd.services.incus-bootstrap = {
      description = "Bootstrap Incus cluster";
      enableStrictShellChecks = true;
      after = [ "incus.service" ];
      requires = [ "incus.service" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        ''
          set -x

          ${incus} admin init --preseed <<EOF
          config:
            core.https_address: ${config.jemand771.incus.localIp}
          cluster:
            server_name: ${config.networking.hostName}
            enabled: true
          EOF
        '';
    };

    # incus cluster add <new node name>
    # install -m600 /dev/stdin /run/incus-join-token (paste, ctrl+D)
    # systemctl start --wait incus-join
    systemd.services.incus-join = {
      description = "Join Incus cluster";
      enableStrictShellChecks = true;
      serviceConfig.Type = "oneshot";
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        ''
          set -x

          ${incus} admin init --preseed <<EOF
          cluster:
            enabled: true
            server_address: ${config.jemand771.incus.localIp}
            cluster_token: "$(cat /run/incus-join-token)"
          EOF
          rm -f /run/incus-join-token
        '';
    };

    # preseed can do certs, but not idempotently
    # TODO remove unmanaged trust?
    systemd.services.incus-trust = lib.mkIf (config.jemand771.incus.trustedCertificates != { }) {
      description = "Incus client certificate trust store";
      enableStrictShellChecks = true;
      wantedBy = [ "incus.service" ];
      after = [ "incus.service" ];
      bindsTo = [ "incus.service" ];
      partOf = [ "incus.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: cert: "${incus} config trust add-certificate --name ${name} ${cert} || true"
          ) config.jemand771.incus.trustedCertificates
        );
    };

    # after bootstrap: rerun preseed once, rerun preseed-member on all nodes, rerun preseed once
    # (or just reboot everything a bunch of times)
    systemd.services.incus-preseed-member = {
      description = "Incus preseed for member specific config";
      enableStrictShellChecks = true;
      wantedBy = [ "incus.service" ];
      after = [ "incus.service" ];
      bindsTo = [ "incus.service" ];
      partOf = [ "incus.service" ];
      before = [ "incus-preseed.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        # eventual consistency(tm)
        # create locally (for this node), then try to register cluster wide (only works when all nodes have completed the local part)
        # incus-preseed handles updates after that but _can't_ cover the initial creation (neither local nor clustered)
        lib.concatMapStringsSep "\n"
          (net: ''
            ${incus} network create ${net.name} --type ${net.type} --target ${config.networking.hostName} ${
              lib.optionalString (net.config ? parent) "parent=${net.config.parent}"
            } || true
            ${incus} network create ${net.name} --type ${net.type} || true
          '')
          (
            lib.filter (
              net: net.config ? parent || net.type == "bridge"
            ) config.virtualisation.incus.preseed.networks
          )
        + lib.concatMapStringsSep "\n" (pool: ''
          ${incus} storage create ${pool.name} ${pool.driver} --target ${config.networking.hostName} || true
          ${incus} storage create ${pool.name} ${pool.driver} || true
        '') (config.virtualisation.incus.preseed.storage_pools or [ ])
        + lib.optionalString (config.jemand771.incus.memberConfig != { }) ''
          ${incus} cluster set ${config.networking.hostName} ${
            lib.escapeShellArgs (
              lib.mapAttrsToList (key: value: "${key}=${value}") config.jemand771.incus.memberConfig
            )
          } || true
        '';
    };

    systemd.services.incus-unevacuate =
      let
        marker = "/var/lib/incus/evacuated-by-shutdown";
        incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        jq = lib.getExe pkgs.jq;
        status = "${incus} query /1.0/cluster/members/${config.networking.hostName} | ${jq} -r .status";
      in
      lib.mkIf (config.virtualisation.incus.preseed.config."core.shutdown_action" or null == "evacuate") {
        description = "Unevacuate incus member after reboot";
        enableStrictShellChecks = true;
        wantedBy = [ "multi-user.target" ];
        after = [
          "incus.service"
          "incus-startup.service"
        ];
        restartIfChanged = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          Restart = "on-failure";
          RestartSec = "30s";
        };
        # neither incus nor incus-startup.service handle evacuation status, figure out whether this was
        #   a) a shutdown-triggered auto-evacuation (see core.shutdown_action)
        #   b) just a coincidental reboot while evacuated earlier (manually)
        script = ''
          [ -e ${marker} ] || exit 0
          if [ "$(${status})" = Evacuated ]; then
            ${incus} cluster restore ${config.networking.hostName} --force
          fi
          rm ${marker}
        '';
        # incus-startup.service -> incusd shutdown -> evacuate
        preStop = ''
          if [ "$(${status})" != Evacuated ]; then
            touch ${marker}
          fi
        '';
      };
  };
}
