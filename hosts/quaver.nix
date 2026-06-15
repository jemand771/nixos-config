{ ... }:
{
  networking.hostName = "quaver";
  networking.hostId = "34c778f0";

  jemand771.unbeatable = {
    enable = true;
    # dhcp managed
    ip = "10.5.0.2";
  };

  networking.interfaces.enp1s0.ipv6.addresses = [
    {
      address = "2a01:4f8:c015:e3e7::1";
      prefixLength = 64;
    }
  ];
  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "enp1s0";
  };

  jemand771.zfs-rpool.disks = [
    "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_119079264"
  ];

  system.stateVersion = "26.05";
}
