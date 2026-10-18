{
  imports = [ ../modules/nixos/_incus-guest.nix ];
  networking.hostName = "cina";
  deployment.tags = [ "cloudlab" ];

  jemand771.ingress = {
    enable = true;
    ip = "10.6.0.21";
    peer = "10.6.0.22";
    vip = "46.225.196.58";
    primary = true;
    uplink = {
      subnet = "46.225.196.56/29";
      gateway = "46.225.196.57";
    };
  };

  system.stateVersion = "26.05";
}
