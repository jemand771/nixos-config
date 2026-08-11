{
  pkgs,
  self,
  preservation,
  ...
}:
let
  controllerIPs = [
    "192.168.1.1"
    "192.168.1.2"
  ];
  mkNode =
    controller: num:
    {
      lib,
      config,
      ...
    }:
    {
      imports = [
        self.nixosModules.incus
        self.nixosModules.linstor
        preservation.nixosModules.default
      ];
      networking.firewall.trustedInterfaces = [ "eth1" ];
      environment.systemPackages = [
        config.virtualisation.incus.clientPackage
        pkgs.lvm2
      ];
      virtualisation = {
        cores = 2;
        memorySize = if controller then 3072 else 2048;
        emptyDiskImages = lib.optional controller 2048;
        incus.preseed = {
          # no cluster networks in this test
          networks = [ ];
          config."storage.linstor.controller_connection" = lib.concatMapStringsSep "," (
            ip: "http://${ip}:3370"
          ) controllerIPs;
          storage_pools = [
            {
              name = "default";
              driver = "linstor";
              config = {
                "linstor.resource_group.place_count" = "2";
                "linstor.resource_group.storage_pool" = "incus_lvm";
              };
            }
          ];
        };
      };
      jemand771 = {
        incus = {
          enable = true;
          localIp = "192.168.1.${toString num}";
        };
        linstor = {
          enable = true;
          controller.enable = controller;
          localIp = "192.168.1.${toString num}";
          controllers = map (ip: "linstor://${ip}") controllerIPs;
          # easier than zfs for the bare minimum check
          dbStoragePool = if controller then "incus_lvm" else null;
          storagePools = lib.optionalAttrs controller {
            incus_lvm = {
              type = "lvm";
              backing = "vg_linstor";
            };
          };
        };
      };
    };
in
pkgs.testers.runNixOSTest {
  name = "incus-linstor";
  nodes = {
    node1 = mkNode true 1;
    node2 = mkNode true 2;
    node3 = mkNode false 3;
  };
  testScript = /* python */ ''
    import json

    controllers = node1, node2
    start_all()

    with subtest("linstor cluster"):
        for node in machines:
            node.wait_for_unit("linstor-satellite.service")
        for node in controllers:
            node.succeed("pvcreate /dev/vdb")
            node.succeed("vgcreate vg_linstor /dev/vdb")
        node1.succeed("systemctl start linstor-controller.service")
        node1.wait_until_succeeds("linstor node list")
        for node in machines:
            node.succeed("systemctl start --wait linstor-register.service")
        node1.succeed("systemctl start --wait linstor-bootstrap.service")
        node2.wait_until_succeeds("drbdadm dstate linstor_db | grep '^UpToDate'")
        node2.wait_until_succeeds("linstor node list")
        node2.succeed("systemctl start --wait linstor-join.service")

    with subtest("incus cluster"):
        node1.succeed("systemctl start --wait incus-bootstrap.service")
        node1.wait_until_succeeds("incus cluster list")
        for node, name in (node2, "node2"), (node3, "node3"):
            token = node1.succeed(f"incus cluster add {name} | tail -n1").strip()
            node.succeed(f"echo '{token}' > /run/incus-join-token")
            node.succeed("systemctl start --wait incus-join.service")

    with subtest("create linstor-backed pool"):
        # preseed(-member) ran at startup and failed
        for node in machines:
            node.succeed("systemctl restart incus-preseed-member.service")
        node1.succeed("systemctl restart incus-preseed.service")

        pool = json.loads(node1.succeed("incus query /1.0/storage-pools/default"))
        assert pool["status"] == "Created", pool["status"]
        assert sorted(pool["locations"]) == ["node1", "node2", "node3"], pool["locations"]
        assert pool["config"]["linstor.resource_group.storage_pool"] == "incus_lvm", pool["config"]
        node1.succeed("linstor resource-group list | grep incus_lvm")

    with subtest("volumes land on both diskful nodes"):
        node1.succeed("incus storage volume create default vol --type block size=128MiB")
        res = node1.succeed(
            "linstor resource-definition list | grep -o 'incus-volume-[0-9a-f]*'"
        ).strip()
        for node in controllers:
            node.wait_until_succeeds(f"drbdadm dstate {res} | grep '^UpToDate'")
  '';
}
