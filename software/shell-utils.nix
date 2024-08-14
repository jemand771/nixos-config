{ config, lib, pkgs, ... }:

{
    options.jemand771.shell-utils.enable = lib.mkEnableOption "shell utils";
    config.environment.systemPackages = with pkgs; lib.mkIf config.jemand771.shell-utils.enable [
        curl
        bc
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
