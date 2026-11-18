{
  lib,
  config,
  ...
}:
let
  keySets = {
    homelab = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOSvXx0+WsuMzZ1y80J8sCFzNqhCB9ZTqeo/Fr4onBi1 willy@nixbox"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII2VFksHIb2Ir7kGNTgX2JpUvRkFG3X9dLoEHFNIFftd willy@nixbook"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOmO89BBLPz+ABHBTrNgF+pTwEhBpE8eWHnHLMsjIDjd willy@cnb004"
    ];
    cloudlab = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOllm4ogq76kDi1n9JiBTlzcgnvHolhtE8PzucClpSL1 willy@nixbox"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMId/sf4FjtKbze69zDePSBM0aD/P3sjQHKbmKHzI7zL willy@nixbook"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILSdCzlCvVT7U0FihSL2qEpJAyk0uk3V8HrXe9da+xBR willy@cnb004"
    ];
    personal = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILVyvZOFj+JRfcUQBpQIoxt1Xae15KGgjpAXM1hsyr+S willy@nixbox"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFZVVmaDjG4JQ/koUQZXPMNjAKoCpsTwR08IKVTQZmEx willy@nixbook"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMDm0uifArKw4G8u3Hj8h+dgJhmrCovJLuUWUxLabDw willy@cnb004"
    ];
  };
in
{
  options.jemand771.user = {
    enable = lib.mkEnableOption "willy user (+ssh +sudo)";
    sshKeyset = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (builtins.attrNames keySets));
      default = null;
      description = "ssh keyset allowed to login as willy";
    };
  };
  config = lib.mkIf config.jemand771.user.enable {
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
      ++ lib.optional config.virtualisation.incus.enable "incus-admin"
      ++ lib.optional config.services.minecraft-servers.enable "minecraft";
      openssh.authorizedKeys.keys =
        let
          keyset = config.jemand771.user.sshKeyset;
        in
        lib.mkIf (keyset != null) keySets.${keyset};
    };
    security.sudo.wheelNeedsPassword = false;
    programs.ssh.startAgent = true;
  };
}
