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
      kdePackages.kcalc
      libreoffice-qt
      pinta
      spotify
      spotify-tray
      texliveFull
      vlc
    ];
    fonts.packages = with pkgs; [
      comic-neue
    ];
  };
}
