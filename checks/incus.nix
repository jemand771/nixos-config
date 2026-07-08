{
  pkgs,
  self,
  preservation,
  ...
}:
let
  mkNode =
    localIp:
    { config, pkgs, ... }:
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
      };
      # no cluster networks in this test
      virtualisation.incus.preseed.networks = [ ];
    };
in
pkgs.testers.runNixOSTest {
  name = "incus";
  nodes = {
    node1 = mkNode "192.168.1.1";
    node2 = mkNode "192.168.1.2";
  };
  testScript = ''
    start_all()
    node1.wait_for_unit("incus.service")
    node2.wait_for_unit("incus.service")

    with subtest("bootstrap cluster"):
        node1.succeed("systemctl start --wait incus-bootstrap.service")
        node1.wait_until_succeeds("incus cluster list --format csv")

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
  '';
}
