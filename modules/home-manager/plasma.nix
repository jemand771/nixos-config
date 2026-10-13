{ config, lib, ... }:
{
  options.jemand771.plasma.enable = lib.mkEnableOption "plasma-manager";
  config.programs.plasma = lib.mkIf config.jemand771.plasma.enable {
    enable = true;
    # TODO enable after natural scrolling is supported as a native config option
    # https://github.com/nix-community/plasma-manager/pull/123
    # overrideConfig = true;
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
    };
  };
}
