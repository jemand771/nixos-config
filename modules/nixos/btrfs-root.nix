{
  lib,
  config,
  ...
}:
{
  options.jemand771.btrfs-root.enable = lib.mkEnableOption "btrfs root on jemand771.btrfs-root.disk";
  options.jemand771.btrfs-root.disk = lib.mkOption {
    type = lib.types.str;
    description = "path to the disk device";
    example = "/dev/disk/by-id/abc";
  };
  config = lib.mkIf config.jemand771.btrfs-root.enable {
    disko.devices.disk.main = {
      type = "disk";
      device = config.jemand771.btrfs-root.disk;
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              subvolumes =
                lib.genAttrs
                  [
                    "/root"
                    "/nix"
                    "/persist"
                  ]
                  (name: {
                    mountpoint = if name == "/root" then "/" else name;
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  });
            };
          };
        };
      };
    };

    boot.loader.systemd-boot.enable = true;
  };
}
