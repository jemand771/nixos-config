{
  lib,
  config,
  ...
}:
{
  options.jemand771.defaults.enable = lib.mkEnableOption "sane defaults" // {
    default = true;
  };
  config = lib.mkIf config.jemand771.defaults.enable {
    # forces using usernames from local ssh config
    deployment.targetUser = null;
    jemand771 = {
      ckb-next-autostart.enable = true;
      nix-config.enable = true;
    };
  };
}
