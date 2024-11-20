{ config, pkgs, inputs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

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

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs}"
  ];

  environment.systemPackages = with pkgs; [
    nix-output-monitor
    attic-client
  ];

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
}
