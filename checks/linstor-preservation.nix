{
  pkgs,
  self,
  preservation,
  ...
}:
let
  mkNode =
    controller: num:
    { lib, ... }:
    {
      imports = [
        self.nixosModules.linstor
        preservation.nixosModules.default
      ];
      networking.firewall.trustedInterfaces = [ "eth1" ];
      virtualisation.memorySize = if controller then 2048 else 1024;
      # vdb: /persist (all)
      # vdc: LVM (controllers)
      virtualisation.emptyDiskImages = [ 512 ] ++ lib.optional controller 2048;
      environment.systemPackages = [ pkgs.lvm2 ];
      services.lvm.enable = true;

      # preservation in vm test magic
      boot.initrd.systemd.enable = true;
      virtualisation.fileSystems."/" = lib.mkVMOverride {
        fsType = "tmpfs";
        options = [ "mode=0755" ];
      };
      virtualisation.fileSystems."/persist" = {
        device = "/dev/vdb";
        fsType = "ext4";
        neededForBoot = true;
        autoFormat = true;
      };
      virtualisation.fileSystems."/nix/store".neededForBoot = true;

      preservation.enable = true;
      jemand771.linstor = {
        enable = true;
        controller.enable = controller;
        localIp = "192.168.1.${toString num}";
        dbStoragePool = if controller then "incus_lvm" else null;
        storagePools = lib.optionalAttrs controller {
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
  name = "linstor-preservation";
  nodes = {
    node1 = mkNode true 1;
    node2 = mkNode true 2;
    node3 = mkNode false 3;
  };
  testScript = /* python */ ''
    controllers = node1, node2

    def current_primary():
        promoted = [
            node for node in controllers
            if node.execute("drbdadm role linstor_db | grep Primary")[0] == 0
        ]
        assert len(promoted) <= 1, f"split brain: {promoted}"
        return promoted[0] if promoted else None

    def wait_for_primary():
        retry(lambda _: current_primary() is not None)
        owner = current_primary()
        standby, = [node for node in controllers if node is not owner]
        return owner, standby

    for node in machines_qemu:
        node.start(allow_reboot=True)
    for node in machines:
        node.wait_for_unit("linstor-satellite.service")
        node.wait_until_succeeds("test -d /sys/module/drbd")

    with subtest("root really is a self resetting tmpfs"):
        for node in machines:
            node.succeed("findmnt --kernel --type tmpfs /")

    with subtest("set up HA cluster"):
        for node in controllers:
            node.succeed("pvcreate /dev/vdc")
            node.succeed("vgcreate vg_linstor /dev/vdc")
        node1.succeed("systemctl start linstor-controller.service")
        node1.wait_until_succeeds("linstor node list")
        for node in machines:
            node.succeed("systemctl start --wait linstor-register.service")
        node1.wait_until_succeeds(
            'test "$(linstor node list | grep -c Online)" = 3'
        )
        node1.succeed("systemctl start --wait linstor-bootstrap.service")
        node1.wait_for_unit("drbd-reactor.service")
        node1.wait_until_succeeds("systemctl is-active linstor-controller.service")
        node3.wait_until_succeeds("linstor resource list -r linstor_db | grep linstor_db")
        node2.succeed("systemctl start --wait linstor-join.service")
        node2.wait_for_unit("drbd-reactor.service")

    with subtest("power cycle all nodes, observe recovery"):
        for node in machines:
            node.shutdown()
        for node in machines_qemu:
            node.start(allow_reboot=True)
        for node in machines:
            node.wait_for_unit("linstor-satellite.service")
        for node in controllers:
            node.wait_for_unit("drbd-reactor.service")
        owner, standby = wait_for_primary()
        owner.wait_until_succeeds("systemctl is-active linstor-controller.service")
        owner.succeed("findmnt -n -o SOURCE /var/lib/linstor | grep '^/dev/drbd'")
        standby.fail("findmnt /var/lib/linstor")
        standby.fail("systemctl is-active linstor-controller.service")
        standby.succeed("drbdadm role linstor_db | grep Secondary")
        for node in controllers:
            node.wait_until_succeeds("drbdadm dstate linstor_db | grep '^UpToDate'")
        node3.wait_until_succeeds("drbdadm dstate linstor_db | grep '^Diskless'")
        for node in machines:
            node.wait_until_succeeds("linstor resource list -r linstor_db | grep linstor_db")

    with subtest("primary crash failover"):
        owner, standby = wait_for_primary()
        owner.crash()
        standby.wait_until_succeeds("findmnt -n -o SOURCE /var/lib/linstor | grep '^/dev/drbd'")
        standby.wait_until_succeeds("systemctl is-active linstor-controller.service")
        standby.succeed("drbdadm role linstor_db | grep Primary")
        node3.wait_until_succeeds("linstor resource list -r linstor_db | grep linstor_db")
  '';
}
