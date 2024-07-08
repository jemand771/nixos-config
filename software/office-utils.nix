{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        kcalc
        libreoffice-qt
        pinta
        spotify
        spotify-tray
        texliveFull
        thunderbird
        unstable.vesktop
        vlc
    ];
}