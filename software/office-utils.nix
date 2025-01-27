{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.jemand771.office-utils.enable = lib.mkEnableOption "office utils";
  config = lib.mkIf config.jemand771.office-utils.enable {
    environment.systemPackages = with pkgs; [
      kcalc
      libreoffice-qt
      pinta
      spotify
      spotify-tray
      texliveFull
      unstable.vesktop
      vlc
    ];
    fonts.packages = with pkgs; [
      comic-neue
    ];
  };
}
