{
  lib,
  config,
  ...
}:
{
  config = {
    users.users.willy = {
      isNormalUser = true;
      description = "willy";
      extraGroups = [
        "wheel"
        "dialout"
      ]
      ++ lib.optional config.networking.networkmanager.enable "networkmanager"
      ++ lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd"
      ++ lib.optional config.services.minecraft-servers.enable "minecraft";
    };
    security.sudo.wheelNeedsPassword = false;
  };
}
