{
  config,
  lib,
  nixpkgs,
  options,
  pkgs,
  ...
}:

{
  options.jemand771.nix-config.enable = lib.mkEnableOption "Standard nix config" // { default = true; };
  config = lib.mkIf config.jemand771.nix-config.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
      fallback = true;
    };
    nixpkgs.config.allowUnfree = true;
    nix.package = pkgs.lixPackageSets.latest.lix;

    # sudo rm -rf /root/.nix-defexpr/channels /nix/var/nix/profiles/per-user/root/channels /root/.nix-defexpr/channels /home/willy/.nix-defexpr/channels
    nix.channel.enable = false;
    nixpkgs.flake.source = nixpkgs;

    nix.gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    environment.systemPackages = with pkgs; [
      nix-output-monitor
    ];

    # thanks, marie
    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        if [[ -e /run/current-system ]]; then
          echo "--- diff to current-system"
          ${pkgs.nvd}/bin/nvd --nix-bin-dir=${config.nix.package}/bin diff /run/current-system "$systemConfig"
          echo "---"
        fi
      '';
    };
  };
}
