{ ... }:
{
  networking.hostName = "clef";
  networking.hostId = "aadb8f55";

  jemand771.unbeatable = {
    enable = true;
    ip = "10.5.1.12";
  };

  networking.interfaces.enp0s31f6.ipv6.addresses = [
    {
      address = "2a01:4f8:10a:12d3::/64";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp0s31f6";
  };

  jemand771.zfs-rpool.disks = [
    "/dev/disk/by-id/ata-Micron_5100_MTFDDAK480TBY_17451A0125B9"
    "/dev/disk/by-id/ata-Micron_5200_MTFDDAK480TDC_17501A66D345"
    "/dev/disk/by-id/ata-SAMSUNG_MZ7LM480HCHP-00003_S1YJNXAG801996"
    "/dev/disk/by-id/ata-SAMSUNG_MZ7WD480HAGM-00003_S16MNEADA07696"
  ];

  system.stateVersion = "26.05";
}
