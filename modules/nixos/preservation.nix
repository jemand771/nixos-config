{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.preservation.enable {
    boot.initrd.systemd.enable = true;
    fileSystems."/persist".neededForBoot = true;
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    boot.initrd.systemd.services.rollback = lib.mkIf config.jemand771.zfs-rpool.enable {
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
    };
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
        {
          file = "/etc/ssh/ssh_host_ed25519_key";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_ed25519_key.pub";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key";
          how = "symlink";
          configureParent = true;
        }
        {
          file = "/etc/ssh/ssh_host_rsa_key.pub";
          how = "symlink";
          configureParent = true;
        }
      ];
    };
  };
}
