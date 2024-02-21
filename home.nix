{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
  ];

  programs.git = {
    enable = true;
    userName = "Willy";
    userEmail = "jemand771@gmx.net";
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
