{ config, lib, pkgs, ... }:
{
  options.jemand771.gaming.enable = lib.mkEnableOption "gaming";
  config = lib.mkIf config.jemand771.gaming.enable {
    environment.systemPackages = with pkgs; [
      heroic
      tetrio-desktop
      prismlauncher
    ];

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}