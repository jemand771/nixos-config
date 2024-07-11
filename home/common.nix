{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Willy";
    userEmail = "jemand771@gmx.net";
  };

  # TODO htop's own config menu can still overwrite (delete and recreate) this file - how to prevent this?
  programs.htop.enable = true;
  programs.htop.settings = {
    hide_userland_threads = 1;
  };

  programs.vscode.enable = true;
  programs.vscode.userSettings = {
    "files.simpleDialog.enable" = true;
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableSmartCommit" = true;
  };
  programs.vscode.extensions = with pkgs.vscode-extensions; [
    ms-python.python
    bbenoist.nix
    # TODO gamunu.opentofu
  ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "opentofu";
      publisher = "gamunu";
      version = "0.2.1";
      sha256 = "sha256-OizdHTSGuwBRuD/qPXjmna6kZWfRp9EimhcFk3ICN9I=";
    }
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        identityFile = "~/.ssh/id_github";
      };

      # TODO make these generic-ish per key/host group
      "d39s-sx" = {
        hostname = "88.99.58.198";
        user = "root";
        identityFile = "~/.ssh/id_d39s";
      };
      "d39s-sxvm" = {
        hostname = "88.99.58.196";
        user = "root";
        identityFile = "~/.ssh/id_d39s";
      };
      "d39s-sxlh" = {
        hostname = "10.0.2.4";
        user = "root";
        identityFile = "~/.ssh/id_d39s";
        proxyJump = "d39s-sx";
      };
      "d39s-spg" = {
        hostname = "168.119.251.136";
        user = "root";
        identityFile = "~/.ssh/id_d39s";
      };
    };
  };

  programs.home-manager.enable = true;
}
