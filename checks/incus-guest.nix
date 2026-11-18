{
  pkgs,
  self,
  disko,
  preservation,
  ...
}:
pkgs.testers.runNixOSTest {
  name = "incus-guest";
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        disko.nixosModules.disko
        preservation.nixosModules.default
        self.nixosModules.btrfs-root
        self.nixosModules.zfs-rpool
        self.nixosModules.preservation
        self.nixosModules.incus-image
        self.nixosModules._incus-guest
      ];
      # "we have incus at home"
      virtualisation = {
        directBoot.enable = false;
        mountHostNixStore = false;
        useEFIBoot = true;
        useDefaultFilesystems = false;
        fileSystems = lib.mkForce { };
        diskImage = null;
        qemu.options = [
          "-device virtio-scsi-pci,id=scsi0"
          "-drive file=\"$NIX_DISK_IMAGE\",if=none,id=root,format=qcow2,cache=writeback,werror=report"
          "-device scsi-hd,drive=root,bus=scsi0.0,serial=incus_root,bootindex=1"
        ];
      };
      system.switch.enable = true;
      virtualisation.incus.agent.enable = false;
    };
  testScript =
    { nodes, ... }:
    /* python */ ''
      import os
      import subprocess
      import tempfile

      disk = tempfile.NamedTemporaryFile()
      subprocess.run([
        "${nodes.machine.virtualisation.qemu.package}/bin/qemu-img",
        "create",
        "-f", "qcow2",
        "-F", "qcow2",
        "-b", "${nodes.machine.system.build.incusImage}/disk.qcow2",
        disk.name,
        "8G",
      ], check=True)
      os.environ["NIX_DISK_IMAGE"] = disk.name

      def boot():
          machine.wait_for_unit("multi-user.target")
          machine.succeed("systemctl is-system-running --wait")
          machine.succeed("journalctl -b -u rollback.service -o cat | grep 'Finished Rotate btrfs root subvolume'")
          # contains old_roots
          machine.succeed("mkdir -p /mnt && mount /dev/disk/by-partlabel/disk-main-root /mnt")

      def reboot():
          machine.shutdown()
          boot()

      boot()

      with subtest("partition and filesystem grown to disk size"):
          size = int(machine.succeed("findmnt -bno SIZE /").strip())
          assert size > 7 * 1024**3, f"root fs only {size} bytes"

      with subtest("/run/current-system registered"):
          machine.succeed("nix-store --verify-path /run/current-system")

      with subtest("btrfs reset/persistance works"):
          machine.succeed("touch /foo /persist/bar")
          reboot()
          machine.fail("test -e /foo")
          machine.succeed(
              "test -e /persist/bar",
              "ls /mnt/old_roots/*/foo",
          )

      with subtest("expired roots are deleted"):
          expired = machine.succeed("ls /mnt/old_roots | head -n1").strip()
          machine.succeed(
              f"btrfs subvolume list -o '/mnt/old_roots/{expired}' | grep .",
              f"touch -d '-31 days' '/mnt/old_roots/{expired}'",
          )
          reboot()
          machine.succeed(
              f"! test -e '/mnt/old_roots/{expired}'",
              "ls /mnt/old_roots/*/foo",
          )
    '';
}
