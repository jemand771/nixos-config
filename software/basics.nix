{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.jemand771.basics.enable = lib.mkEnableOption "basics";
  config.environment.systemPackages =
    with pkgs;
    lib.mkIf config.jemand771.basics.enable [
      google-chrome
      (discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
    ];
  config.programs = lib.mkIf config.jemand771.basics.enable {
    git = {
      enable = true;
      lfs.enable = true;
    };
  };
}
