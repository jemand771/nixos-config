{ config, lib, ... }:
{
  options.jemand771.meta.personal-system = lib.mkEnableOption "personal system";
  config = lib.mkIf config.jemand771.meta.personal-system {
    jemand771 = {
      basics.enable = true;
      dev-infra.enable = true;
      dev-python.enable = true;
      gaming.enable = true;
      home-manager.enable = true;
      office-utils.enable = true;
      shell-utils.enable = true;
      syncthing.enable = true;
      nasmounts.enable = true;
    };
    deployment.targetHost = null;
  };
}
