{ config, lib, pkgs, ... }:

{
  options.jemand771.basics.enable = lib.mkEnableOption "basics";
  config.environment.systemPackages = with pkgs; lib.mkIf config.jemand771.basics.enable [
    git
    google-chrome
    unstable.vesktop
  ];
}
