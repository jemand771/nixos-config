{
  pkgs,
  self,
  preservation,
  ...
}:
let
  mkNode =
    localIp:
    { config, ... }:
    {
      imports = [
        self.nixosModules.incus
        preservation.nixosModules.default
      ];
      networking.firewall.trustedInterfaces = [ "eth1" ];
      environment.systemPackages = [
        config.virtualisation.incus.clientPackage
      ];
      jemand771.incus = {
        enable = true;
        inherit localIp;
        # just to see if memberConfig applies
        memberConfig."scheduler.instance" = "manual";
        projects = {
          default = { };
          example = { };
        };
      };
      virtualisation.incus.preseed = {
        # just to see if preseed applies
        networks = [
          {
            name = "default";
            type = "macvlan";
            config.parent = "eth1";
          }
          {
            name = "testbr";
            type = "bridge";
            config."ipv4.address" = "192.168.53.1/24";
          }
        ];
        storage_pools = [
          {
            name = "default";
            driver = "dir";
          }
        ];
      };
    };
in
pkgs.testers.runNixOSTest {
  name = "incus";
  nodes = {
    node1 = mkNode "192.168.1.1";
    node2 = mkNode "192.168.1.2";
  };
  testScript = /* python */ ''
    start_all()
    node1.wait_for_unit("incus.service")
    node2.wait_for_unit("incus.service")

    with subtest("bootstrap cluster"):
        node1.succeed("systemctl start --wait incus-bootstrap.service")
        node1.wait_until_succeeds("incus cluster list --format csv")
        node2.sleep(4)

    with subtest("join cluster"):
        token = node1.succeed("incus cluster add node2 | tail -n1").strip()
        node2.succeed(f"echo '{token}' > /run/incus-join-token")
        node2.succeed("systemctl start --wait incus-join.service")

    with subtest("list members"):
        node1.wait_until_succeeds(
            "test \"$(incus cluster list --format csv | grep -c ONLINE)\" = 2"
        )
        node1.succeed("incus cluster list --format csv | grep -q '^node1,'")
        node1.succeed("incus cluster list --format csv | grep -q '^node2,'")

    with subtest("check preseed"):
        # created standalone earlier, retry in per-member preseed
        # TODO this should really be a 2-stage test (bootstrap with blank preseed, then configure)
        node1.succeed("incus network delete testbr")
        # eventual consistency(tm)
        for node in machines:
            node.succeed("systemctl restart incus-preseed-member.service")
        for node in machines:
            node.succeed("systemctl restart incus-preseed.service")
        node1.succeed("incus network show default")
        node1.succeed("incus network show testbr | grep 'status: Created'")
        node1.succeed("test \"$(incus network get testbr ipv4.address)\" = 192.168.53.1/24")
        for node in machines:
            node.succeed("ip -br addr show testbr | grep 192.168.53.1/24")
        node1.succeed("incus storage show default")
        node1.succeed("incus profile show default --project example | grep 'network: default'")
        node1.succeed("test \"$(incus project get example restricted.networks.access)\" = default")
        for node in "node1", "node2":
            node1.succeed(f"test \"$(incus cluster get {node} scheduler.instance)\" = manual")
  '';
}
