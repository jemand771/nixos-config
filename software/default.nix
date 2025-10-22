{ ... }:
{
  imports = [
    ./nix
    ./wsl

    ./basics.nix
    ./locale.nix
    ./shell-utils.nix
    ./office-utils.nix
    ./dev-infra.nix
    ./dev-python.nix
    ./gaming.nix
    ./auto-upgrade.nix
    ./ssh-access.nix
  ];
}
