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
    preservation.preserveAt."/persist" = {
      directories = [
        "/var/lib/incus"
      ];
    };
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        projects = builtins.map ({ name, value }: {
          inherit name;
          config = {
            "features.networks" = "false";
            "features.profiles" = "true";
            "features.images" = "true";
            "features.storage.volumes" = "true";
            "features.storage.buckets" = "true";
            "restricted" = "true";
          }
          // value;
        }) (lib.attrsToList (config.jemand771.incus.projects));
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
              network = "guests";
              name = "eth0";
            };
          };
        }) (lib.attrNames config.jemand771.incus.projects);
      };
    };

    # systemctl start --wait incus-bootstrap
    systemd.services.incus-bootstrap = {
      description = "Bootstrap Incus cluster";
      after = [ "incus.service" ];
      requires = [ "incus.service" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        ''
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
      serviceConfig.Type = "oneshot";
      script =
        let
          incus = lib.getExe' config.virtualisation.incus.clientPackage "incus";
        in
        ''
          ${incus} admin init --preseed <<EOF
          cluster:
            enabled: true
            server_address: ${config.jemand771.incus.localIp}
            cluster_token: "$(cat /run/incus-join-token)"
          EOF
          rm -f /run/incus-join-token
        '';
    };
  };
}
