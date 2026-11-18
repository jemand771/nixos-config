{
  lib,
  config,
  utils,
  ...
}:
{
  options.jemand771.preservation.enable = lib.mkEnableOption "opinionated preservation";
  config = lib.mkIf config.jemand771.preservation.enable {
    preservation.enable = true;
    fileSystems."/persist".neededForBoot = true;
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    boot.initrd.systemd.services.rollback = lib.mkMerge [
      (lib.mkIf config.jemand771.zfs-rpool.enable {
        description = "Roll back ZFS root dataset";
        wantedBy = [ "initrd.target" ];
        after = [ "zfs-import-rpool.service" ];
        requires = [ "zfs-import-rpool.service" ];
        before = [ "sysroot.mount" ];
        unitConfig.DefaultDependencies = "no";
        serviceConfig.Type = "oneshot";
        script = ''
          zfs rollback -r rpool/root@blank
        '';
      })
      (lib.mkIf config.jemand771.btrfs-root.enable (
        let
          device = config.fileSystems."/".device;
          deviceUnit = "${utils.escapeSystemdPath device}.device";
        in
        {
          # https://github.com/nix-community/impermanence#btrfs-subvolumes
          description = "Rotate btrfs root subvolume";
          wantedBy = [ "initrd.target" ];
          after = [
            deviceUnit
            "local-fs-pre.target"
          ]
          ++ lib.optional config.boot.initrd.systemd.repart.enable "systemd-repart.service";
          requires = [ deviceUnit ];
          before = [ "sysroot.mount" ];
          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          script = ''
            mkdir /btrfs_tmp
            mount -t btrfs ${device} /btrfs_tmp
            trap 'umount /btrfs_tmp' EXIT
            mkdir -p /btrfs_tmp/old_roots
            if [[ -e /btrfs_tmp/root ]]; then
                timestamp=$(date --date="@$(stat -c %W /btrfs_tmp/root)" "+%Y-%m-%d_%H:%M:%S")
                mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
                # bump last modification time to now (prevent insta cleanup after 30d+ uptime)
                touch "/btrfs_tmp/old_roots/$timestamp"
            fi
            btrfs subvolume create /btrfs_tmp/root
            find /btrfs_tmp/old_roots/ -mindepth 1 -maxdepth 1 -mtime +30 \
                -exec btrfs subvolume delete --recursive {} +
          '';
        }
      ))
    ];
    preservation.preserveAt."/persist" = {
      directories = [
        "/var/log"
        {
          directory = "/var/lib/nixos";
          inInitrd = true;
        }
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/timers"
      ];
      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
        }
        {
          file = "/var/lib/systemd/random-seed";
          how = "symlink";
          inInitrd = true;
          configureParent = true;
        }
      ]
      ++ lib.concatMap (
        key:
        map
          (file: {
            inherit file;
            how = "symlink";
            configureParent = true;
          })
          [
            key.path
            "${key.path}.pub"
          ]
      ) config.services.openssh.hostKeys;
    };
  };
}
