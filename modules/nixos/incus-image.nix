{
  config,
  lib,
  pkgs,
  ...
}:
{
  # nix build .#nixosConfigurations.foobar.config.system.build.incusImage
  # incus image import result/metadata.tar.xz result/disk.qcow2 --alias foobar
  # TODO should this just fall out of upstream (incus-virtual-machine.nix) by default?
  config.system.build.incusImage =
    lib.throwIfNot (config.system.build ? qemuImage)
      "system.build.incusImage requires virtualisation/incus-virtual-machine.nix"
      (
        pkgs.linkFarm "incus-image-${config.networking.hostName}" {
          "disk.qcow2" = "${config.system.build.qemuImage}/nixos.qcow2";
          "metadata.tar.xz" = "${config.system.build.metadata}/${config.image.filePath}";
        }
      );
}
