{
  config,
  lib,
  modulesPath,
  ...
}:
let
  inherit (config.disko.devices.disk.main.content) partitions;
in
{
  imports = [ "${modulesPath}/virtualisation/incus-virtual-machine.nix" ];

  # lxc-instance-common.nix
  system.installer.channel.enable = false;

  jemand771.btrfs-root = {
    enable = true;
    disk = lib.mkDefault "/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus_root";
  };
  jemand771.preservation.enable = true;
  disko.imageBuilder.imageFormat = "qcow2";
  disko.devices.disk.main.imageSize = lib.mkDefault "4G";

  # incus-virtual-machine.nix has different plans for what a "vm disk" should look like
  fileSystems."/" = {
    device = lib.mkForce partitions.root.device;
    fsType = lib.mkForce "btrfs";
    autoResize = lib.mkForce false;
    options = [ "x-systemd.growfs" ];
  };
  fileSystems."/boot" = {
    device = lib.mkForce partitions.ESP.device;
    fsType = lib.mkForce "vfat";
  };
  boot.growPartition = lib.mkForce false;

  boot.initrd.systemd.repart = {
    enable = true;
    device = config.jemand771.btrfs-root.disk;
  };
  systemd.repart.partitions = {
    "10-esp" = {
      Type = "esp";
      Weight = 0;
    };
    "20-root".Type = "linux-generic";
  };
}
