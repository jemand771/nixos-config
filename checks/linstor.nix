{
  pkgs,
  self,
  preservation,
  ...
}:
let
  mkNode =
    controller: num:
    { ... }:
    {
      imports = [
        self.nixosModules.linstor
        preservation.nixosModules.default
      ];
      networking.firewall.trustedInterfaces = [ "eth1" ];
      virtualisation.emptyDiskImages = pkgs.lib.optional controller 2048;
      jemand771.linstor = {
        enable = true;
        controller.enable = controller;
        localIp = "192.168.1.${toString num}";
        # easier than zfs for the bare minimum check
        dbStoragePool = if controller then "incus_lvm" else null;
        storagePools = pkgs.lib.optionalAttrs controller {
          incus_lvm = {
            type = "lvm";
            backing = "vg_linstor";
          };
        };
        controllers = [
          "linstor://192.168.1.1"
          "linstor://192.168.1.2"
        ];
      };
    };
in
pkgs.testers.runNixOSTest {
  name = "linstor";
  nodes = {
    node1 = mkNode true 1;
    node2 = mkNode true 2;
    node3 = mkNode false 3;
  };
  testScript = /* python */ ''
    controllers = node1, node2
    start_all()

    with subtest("Wait for DRBD"):
        for node in machines:
            node.wait_for_unit("linstor-satellite.service")
            node.wait_until_succeeds("test -d /sys/module/drbd")

    with subtest("drbd-reactor not running anywhere"):
        for node in controllers:
            node.wait_for_unit("drbd-reactor.path")
            node.fail("systemctl is-active drbd-reactor.service")

    with subtest("LVM storage backend on the controller nodes"):
        for node in controllers:
            node.succeed("pvcreate /dev/vdb")
            node.succeed("vgcreate vg_linstor /dev/vdb")

    with subtest("register all nodes"):
        node1.succeed("systemctl start linstor-controller.service")
        node1.wait_until_succeeds("linstor node list")
        for node in machines:
            node.succeed("systemctl start --wait linstor-register.service")
        node1.wait_until_succeeds('test "$(linstor node list | grep -c Online)" = 3')

    with subtest("bootstrap HA linstor_db"):
        node1.succeed("systemctl start --wait linstor-bootstrap.service")

    with subtest("linstor_db is replicated to all nodes"):
        node1.wait_for_unit("drbd-reactor.service")
        node1.wait_until_succeeds("findmnt -n -o SOURCE /var/lib/linstor | grep '^/dev/drbd'")
        node1.wait_until_succeeds("systemctl is-active linstor-controller.service")
        node3.wait_until_succeeds("linstor resource list -r linstor_db | grep linstor_db")
        for node in controllers:
            node.wait_until_succeeds("drbdadm dstate linstor_db | grep '^UpToDate'")
        node3.wait_until_succeeds("drbdadm dstate linstor_db | grep '^Diskless'")

    with subtest("join second HA controller"):
        node2.succeed("systemctl start --wait linstor-join.service")
        node2.wait_for_unit("drbd-reactor.service")
        node1.succeed("findmnt -n -o SOURCE /var/lib/linstor | grep '^/dev/drbd'")
        node1.succeed("systemctl is-active linstor-controller.service")
        node2.fail("findmnt /var/lib/linstor")
        node2.fail("systemctl is-active linstor-controller.service")
        node2.succeed("drbdadm role linstor_db | grep Secondary")

    with subtest("no bogus linstor logs dir"):
        for node in machines:
            node.fail("test -e /logs")
            node.succeed("test -d /run/linstor-satellite")

    with subtest("evict and rejoin node2"):
        node2.succeed("rm -f /var/lib/linstor-ha-marker/enabled")
        node2.succeed("systemctl stop drbd-reactor.service")
        node2.fail("systemctl is-active drbd-reactor.service")
        node1.succeed("linstor resource delete node2 linstor_db")
        node1.wait_until_succeeds("! linstor resource list -r linstor_db | grep node2")
        node1.succeed("linstor resource list -r linstor_db | grep node1")

        node1.succeed("linstor resource create node2 linstor_db --storage-pool incus_lvm")
        node2.wait_until_succeeds("drbdadm dstate linstor_db | grep '^UpToDate'")
        node2.succeed("systemctl start --wait linstor-join.service")
        node2.wait_for_unit("drbd-reactor.service")
        node2.succeed("test -e /var/lib/linstor-ha-marker/enabled")
        node1.succeed("systemctl is-active linstor-controller.service")
        node2.fail("systemctl is-active linstor-controller.service")
  '';
}
