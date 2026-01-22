{ inputs, ... }:
{
  imports = [ inputs.microvm.nixosModules.host ];

  systemd.network.enable = true;
  networking.useDHCP = false;

  # inspired by https://astro.github.io/microvm.nix/simple-network.html
  systemd.network.networks."10-lan" = {
    matchConfig.Name = [
      "eno1"
      "vm-*"
    ];
    networkConfig = {
      Bridge = "br0";
    };
    linkConfig.RequiredForOnline = "enslaved";
  };

  systemd.network.netdevs."br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."10-lan-bridge" = {
    matchConfig.Name = "br0";
    networkConfig = {
      DHCP = "yes";
    };
    linkConfig.RequiredForOnline = "routable";
  };
}
