{
  lib,
  config,
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
    preservation.preserveAt."/persist".directories = [ "/var/lib/incus" ];
    virtualisation.incus = {
      enable = true;
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

    systemd.services.incus-preseed-member = {
      description = "Incus preseed for member specific config";
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
        lib.concatMapStringsSep "\n" (net: ''
          ${incus} network create ${net.name} --type ${net.type} --target ${config.networking.hostName} parent=${net.config.parent} || true
          ${incus} network create ${net.name} --type ${net.type} || true
        '') (lib.filter (net: net.config ? parent) config.virtualisation.incus.preseed.networks);
    };
  };
}
