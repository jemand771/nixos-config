{ ... }:
{
  networking.hostName = "treble";
  networking.hostId = "ed937e54";

  jemand771.unbeatable = {
    enable = true;
    ip = "10.5.1.11";
  };

  networking.interfaces.enp0s31f6.ipv6.addresses = [
    {
      address = "2a01:4f8:10a:2bcd::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp0s31f6";
  };

  jemand771.zfs-rpool.disks = [
    "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18301DC6962D"
    "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_171416BD471F"
    "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18301DC6961F"
    "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_18291D998032"
  ];

  system.stateVersion = "26.05";
}
