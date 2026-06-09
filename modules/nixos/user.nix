{
  lib,
  config,
  ...
}:
let
  taggedKeys = {
    # TODO add keys from nixbox and nixbook
    homelab = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmO89BBLPz+ABHBTrNgF+pTwEhBpE8eWHnHLMsjIDjd willy@cnb004"
    ];
    cloudlab = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSdCzlCvVT7U0FihSL2qEpJAyk0uk3V8HrXe9da+xBR willy@cnb004"
    ];
    personal = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMDm0uifArKw4G8u3Hj8h+dgJhmrCovJLuUWUxLabDw willy@cnb004"
    ];
  };
  keysFor = tags: builtins.concatMap (tag: taggedKeys.${tag} or [ ]) tags;
in
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
      openssh.authorizedKeys.keys = keysFor config.deployment.tags;
    };
    security.sudo.wheelNeedsPassword = false;
    programs.ssh.startAgent = true;
  };
}
