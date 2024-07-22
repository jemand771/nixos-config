{ config, lib, ... }:
{
  options.jemand771.meta.personal-system = lib.mkEnableOption "personal system";
  config = lib.mkIf config.jemand771.meta.personal-system {
    jemand771.home-manager.enable = true;
  };
}
