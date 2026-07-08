{
  pkgs,
  self,
  preservation,
  ...
}:
let
  ip1 = "192.168.1.1";
  ip2 = "192.168.1.2";
  peers = [
    ip1
    ip2
  ];
  mkNode = localIp: {
    imports = [
      self.nixosModules.ovn
      preservation.nixosModules.default
    ];
    # normally unbeatable does trustedInterfaces = [ "br-underlay" ] as part of the hetzner networking setup,
    # we'll just use the boring local test vm network here
    networking.firewall.trustedInterfaces = [ "eth1" ];
    jemand771.ovn = {
      enable = true;
      inherit localIp peers;
      chassis.enable = true;
    };
    # pretend we have cloudlab-ext. there's no actual uplink here
    systemd.services.dummy-cloudlab-ext = {
      description = "dummy uplink interface expected by the ovn chassis setup";
      before = [ "ovn-ovs-setup.service" ];
      requiredBy = [ "ovn-ovs-setup.service" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = "ip link show cloudlab-ext || ip link add cloudlab-ext type dummy";
    };
  };
in
pkgs.testers.runNixOSTest {
  name = "ovn-bootstrap-join";
  nodes = {
    node1 = mkNode ip1;
    node2 = mkNode ip2;
  };
  testScript =
    let
      ovs-appctl = pkgs.lib.getExe' pkgs.openvswitch "ovs-appctl";
      ping = pkgs.lib.getExe pkgs.unixtools.ping;
    in
    ''
      start_all()

      def restart_ovsdb(node):
          # units hit the restart limit before we can form the cluster, manually reset
          node.succeed("systemctl reset-failed ovn-nb-ovsdb.service ovn-sb-ovsdb.service")
          node.succeed("systemctl restart ovn-nb-ovsdb.service ovn-sb-ovsdb.service")

      with subtest("bootstrap cluster"):
          node1.succeed("systemctl start --wait ovn-bootstrap.service")
          restart_ovsdb(node1)
          node1.wait_until_succeeds("${ovs-appctl} -t /run/ovn/ovnnb_db.ctl cluster/status OVN_Northbound")
          node1.wait_until_succeeds("${ovs-appctl} -t /run/ovn/ovnsb_db.ctl cluster/status OVN_Southbound")

      with subtest("join cluster"):
          node2.succeed("systemctl start --wait ovn-join@${ip1}.service")
          restart_ovsdb(node2)

      with subtest("north+south db report both members"):
          for ctl, db in [
              ("/run/ovn/ovnnb_db.ctl", "OVN_Northbound"),
              ("/run/ovn/ovnsb_db.ctl", "OVN_Southbound"),
          ]:
              node1.wait_until_succeeds(
                  f"test \"$(${ovs-appctl} -t {ctl} cluster/status {db} | grep -c 'at tcp:')\" = 2"
              )

      with subtest("start northd and ovn-controller"):
          for node in node1, node2:
              node.succeed("systemctl reset-failed ovn-northd.service ovn-controller.service")
              node.succeed("systemctl restart ovn-northd.service ovn-controller.service")
              node.wait_for_unit("ovn-northd.service")
              node.wait_for_unit("ovn-controller.service")

      with subtest("ping test"):
          # virtual router magic
          def bind(node, port, mac, ip):
              node.succeed(f"ip netns add {port}")
              node.succeed(
                  f"ovs-vsctl add-port br-int {port} -- "
                  f"set interface {port} type=internal external_ids:iface-id={port}"
              )
              node.succeed(f"ip link set {port} netns {port}")
              node.succeed(f"ip -n {port} link set {port} address {mac}")
              node.succeed(f"ip -n {port} addr add {ip}/24 dev {port}")
              node.succeed(f"ip -n {port} link set {port} up")

          node1.succeed("ovn-nbctl ls-add ls0")
          node1.succeed("ovn-nbctl lsp-add ls0 lp1")
          node1.succeed("ovn-nbctl lsp-set-addresses lp1 '02:00:00:00:00:01 10.0.0.1'")
          bind(node1, "lp1", "02:00:00:00:00:01", "10.0.0.1")
          node1.succeed("ovn-nbctl lsp-add ls0 lp2")
          node1.succeed("ovn-nbctl lsp-set-addresses lp2 '02:00:00:00:00:02 10.0.0.2'")
          bind(node2, "lp2", "02:00:00:00:00:02", "10.0.0.2")

          node1.wait_until_succeeds("ip netns exec lp1 ${ping} -c1 -W1 10.0.0.2")
          node2.succeed("ip netns exec lp2 ${ping} -c1 -W1 10.0.0.1")
    '';
}
