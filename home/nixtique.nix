{ config, pkgs, ... }:
{
  programs.plasma = {
    enable = true;
    # TODO enable after natural scrolling is supported as a native config option
    # https://github.com/nix-community/plasma-manager/pull/123
    # overrideConfig = true;
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
    };
  };
  home.stateVersion = "24.05";
}
