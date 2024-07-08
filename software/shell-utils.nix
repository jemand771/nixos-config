{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        curl
        dig
        ffmpeg
        jq
        nano
        ncdu
        nmap
        pv
        yt-dlp
    ];
}