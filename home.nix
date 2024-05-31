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

  # TODO htop's own config menu can still overwrite (delete and recreate) this file - how to prevent this?
  programs.htop.enable = true;
  programs.htop.settings = {
    hide_userland_threads = 1;
  };

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;
}
