{ config, lib, ... }:
{
  options.jemand771.auto-upgrade.enable = lib.mkEnableOption "system.autoUpgrade";
  config.system.autoUpgrade = lib.mkIf config.jemand771.auto-upgrade.enable {
    enable = true;
    flake = "github:jemand771/nixos-config";
    allowReboot = true;
    rebootWindow = {
      lower = "04:00";
      upper = "06:00";
    };
  };
}
