{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
  ];

  programs.git = {
    enable = true;
    userName = "Willy";
    userEmail = "jemand771@gmx.net";
  };

  home.file."${config.xdg.configHome}/plasma-workspace/env/kwin.sh" = {
    text = ''
      #/usr/bin/env sh
      export __GL_YIELD="usleep"
    '';
    executable = true;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
