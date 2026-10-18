{
  imports = [ ../modules/nixos/_incus-guest.nix ];
  networking.hostName = "cinb";
  deployment.tags = [ "cloudlab" ];

  jemand771.ingress = {
    enable = true;
    ip = "10.6.0.22";
    peer = "10.6.0.21";
    vip = "46.225.196.58";
    uplink = {
      subnet = "46.225.196.56/29";
      gateway = "46.225.196.57";
    };
  };

  system.stateVersion = "26.05";
}
