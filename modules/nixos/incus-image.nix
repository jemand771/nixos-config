{
  config,
  lib,
  pkgs,
  ...
}:
let
  disks = lib.attrValues config.disko.devices.disk;
  disk =
    lib.throwIfNot (lib.length disks == 1) "system.build.incusImage can only handle single-disk machines"
      (
        lib.throwIfNot (config.disko.imageBuilder.imageFormat == "qcow2")
          "system.build.incusImage requires disko.imageBuilder.imageFormat = \"qcow2\""
          "${config.system.build.diskoImages}/${(lib.head disks).imageName}.qcow2"
      );
in
{
  # nix build .#nixosConfigurations.foobar.config.system.build.incusImage
  # incus image import result/metadata.tar.xz result/disk.qcow2 --alias foobar
  config.system.build.incusImage =
    lib.throwIfNot (config.system.build ? metadata)
      "system.build.incusImage requires lxc image metadata (lxc-image-metadata.nix)"
      (
        pkgs.linkFarm "incus-image-${config.networking.hostName}" {
          "disk.qcow2" = disk;
          "metadata.tar.xz" = "${config.system.build.metadata}/tarball/${config.image.baseName}.tar.xz";
        }
      );
}
