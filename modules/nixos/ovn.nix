{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.ovn = {
    enable = lib.mkEnableOption "OVN central (north, south, northd)";
    localIp = lib.mkOption {
      type = lib.types.str;
      description = "OVN local IP address (for northd)";
      default = "";
      example = "192.168.9.10";
    };
    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "OVN central peers (IP:port)";
      default = [ ];
      example = [
        "192.168.9.10"
        "192.168.9.11"
      ];
    };
    chassis.enable = lib.mkEnableOption "chassis (allows hosting guests on this node)";
  };
  config = lib.mkIf config.jemand771.ovn.enable {
    assertions = [
      {
        assertion = builtins.elem config.jemand771.ovn.localIp config.jemand771.ovn.peers;
        message = "OVN local IP must be in peers list";
      }
    ];

    preservation.preserveAt."/persist" = {
      directories = [
        "/var/lib/ovn"
      ];
    };

    # debian calls all these "ovn central" (single entrypoint with "magic inside")
    systemd.services.ovn-nb-ovsdb = {
      description = "OVN Northbound OVSDB";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RuntimeDirectory = "ovn";
        RuntimeDirectoryPreserve = "yes";
        StateDirectory = "ovn";
      };
      script = ''
        exec ${lib.getExe' pkgs.openvswitch "ovsdb-server"} \
          --unixctl=/run/ovn/ovnnb_db.ctl \
          --remote=punix:/run/ovn/ovnnb_db.sock \
          --remote=ptcp:6641:${config.jemand771.ovn.localIp} \
          /var/lib/ovn/ovnnb_db.db
      '';
    };
    systemd.services.ovn-sb-ovsdb = {
      description = "OVN Southbound OVSDB";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Restart = "on-failure";
        RuntimeDirectory = "ovn";
        RuntimeDirectoryPreserve = "yes";
        StateDirectory = "ovn";
      };
      script = ''
        exec ${lib.getExe' pkgs.openvswitch "ovsdb-server"} \
          --unixctl=/run/ovn/ovnsb_db.ctl \
          --remote=punix:/run/ovn/ovnsb_db.sock \
          --remote=ptcp:6642:${config.jemand771.ovn.localIp} \
          /var/lib/ovn/ovnsb_db.db
      '';
    };
    systemd.services.ovn-northd = {
      description = "OVN northd";
      wantedBy = [ "multi-user.target" ];
      after = [
        "ovn-nb-ovsdb.service"
        "ovn-sb-ovsdb.service"
      ];
      requires = [
        "ovn-nb-ovsdb.service"
        "ovn-sb-ovsdb.service"
      ];
      serviceConfig = {
        Restart = "on-failure";
        RuntimeDirectory = "ovn";
        RuntimeDirectoryPreserve = "yes";
        StateDirectory = "ovn";
      };
      script = ''
        exec ${lib.getExe' pkgs.ovn "ovn-northd"} \
          --ovnnb-db=${lib.concatMapStringsSep "," (host: "tcp:${host}:6641") config.jemand771.ovn.peers} \
          --ovnsb-db=${lib.concatMapStringsSep "," (host: "tcp:${host}:6642") config.jemand771.ovn.peers}
      '';
    };

    # systemctl start --wait ovn-bootstrap
    systemd.services.ovn-bootstrap = {
      description = "Bootstrap OVN cluster";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "ovn";
      };
      script = ''
        if [ -e /var/lib/ovn/ovnnb_db.db ] || [ -e /var/lib/ovn/ovnsb_db.db ]; then
          echo "OVN db already exists, refusing to re-create" >&2
          exit 1
        fi
        ${lib.getExe' pkgs.openvswitch "ovsdb-tool"} create-cluster \
          /var/lib/ovn/ovnnb_db.db \
          ${pkgs.ovn}/share/ovn/ovn-nb.ovsschema \
          tcp:${config.jemand771.ovn.localIp}:6643
        ${lib.getExe' pkgs.openvswitch "ovsdb-tool"} create-cluster \
          /var/lib/ovn/ovnsb_db.db \
          ${pkgs.ovn}/share/ovn/ovn-sb.ovsschema \
          tcp:${config.jemand771.ovn.localIp}:6644
      '';
    };
    # systemctl start --wait ovn-join@<existing-member-ip>
    systemd.services."ovn-join@" = {
      description = "Join OVN cluster";
      scriptArgs = "%i";
      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "ovn";
      };
      script = ''
        remote="$1"
        if [ -e /var/lib/ovn/ovnnb_db.db ] || [ -e /var/lib/ovn/ovnsb_db.db ]; then
          echo "OVN db already exists, refusing to join" >&2
          exit 1
        fi
        ${lib.getExe' pkgs.openvswitch "ovsdb-tool"} join-cluster \
          /var/lib/ovn/ovnnb_db.db OVN_Northbound \
          tcp:${config.jemand771.ovn.localIp}:6643 \
          "tcp:$remote:6643"
        ${lib.getExe' pkgs.openvswitch "ovsdb-tool"} join-cluster \
          /var/lib/ovn/ovnsb_db.db OVN_Southbound \
          tcp:${config.jemand771.ovn.localIp}:6644 \
          "tcp:$remote:6644"
      '';
    };

    # ovn <-> ovs interop
    virtualisation.vswitch.enable = true;
  };
}
