{
  config,
  lib,
  ...
}:
{
  options.jemand771.desktopLagFix.enable = lib.mkEnableOption "desktop lag fix";
  config.home.file."${config.xdg.configHome}/plasma-workspace/env/kwin.sh" =
    lib.mkIf config.jemand771.desktopLagFix.enable
      {
        text = ''
          #/usr/bin/env sh
          export __GL_YIELD="usleep"
        '';
        executable = true;
      };
}
