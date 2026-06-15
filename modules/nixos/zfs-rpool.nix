{
  lib,
  config,
  ...
}:
{
  options.jemand771.zfs-rpool.enable = lib.mkEnableOption "ZFS root pool on jemand771.zfs-rpool.disks";
  options.jemand771.zfs-rpool.disks = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = "paths to disk devices for use in the pool";
    default = [ ];
    example = [
      "/dev/disk/by-id/abc"
      "/dev/disk/by-id/def"
    ];
  };
  options.jemand771.zfs-rpool.extraDatasets = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "whether to create incus-local and incus-linstor datasets (zfs_fs, canmount=off, mountpoint=none)";
    default = { };
    example = {
      home = {
        type = "zfs_fs";
        mountpoint = "/home";
        options.mountpoint = "legacy";
      };
    };
  };
  config = lib.mkIf config.jemand771.zfs-rpool.enable {
    disko.devices.disk = builtins.listToAttrs (
      lib.imap (id: device: {
        name = "disk${toString id}";
        value = {
          type = "disk";
          inherit device;
          content = {
            type = "gpt";
            partitions = {
              bios = {
                size = "1M";
                type = "EF02";
                priority = 1;
              };
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "rpool";
                };
              };
            };
          };
        };
      }) config.jemand771.zfs-rpool.disks
    );

    disko.devices.zpool.rpool = {
      type = "zpool";
      mode = if builtins.length config.jemand771.zfs-rpool.disks > 1 then "raidz1" else "";
      options = {
        ashift = "12";
        autotrim = "on";
        compatibility = "grub2";
      };
      rootFsOptions = {
        compression = "lz4";
        atime = "off";
        acltype = "posixacl";
        xattr = "sa";
        canmount = "off";
        mountpoint = "none";
      };
      datasets = {
        root = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
          postCreateHook = "zfs snapshot rpool/root@blank";
        };
        boot = {
          type = "zfs_fs";
          mountpoint = "/boot";
          options.mountpoint = "legacy";
        };
        nix = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options.mountpoint = "legacy";
        };
        persist = {
          type = "zfs_fs";
          mountpoint = "/persist";
          options.mountpoint = "legacy";
        };
      }
      // config.jemand771.zfs-rpool.extraDatasets;
    };

    boot.loader.grub.enable = true;
    boot.supportedFilesystems = [ "zfs" ];
    # after-update 26.11 becomes the default, remove
    boot.zfs.forceImportRoot = false;
  };
}
