{ config, pkgs, ... }:
{
  home.file."${config.xdg.configHome}/plasma-workspace/env/kwin.sh" = {
    text = ''
      #/usr/bin/env sh
      export __GL_YIELD="usleep"
    '';
    executable = true;
  };

  home.stateVersion = "23.11";
}
