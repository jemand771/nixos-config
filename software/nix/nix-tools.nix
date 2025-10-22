{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.lixPackageSets.latest.lix;

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
}
