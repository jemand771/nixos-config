{ config, lib, pkgs, ... }:

{
    options.jemand771.office-utils.enable = lib.mkEnableOption "office utils";
    config.environment.systemPackages = with pkgs; lib.mkIf config.jemand771.office-utils.enable [
        kcalc
        libreoffice-qt
        pinta
        spotify
        spotify-tray
        texliveFull
        unstable.vesktop
        vlc
    ];
}