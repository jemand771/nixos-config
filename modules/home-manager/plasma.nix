{ config, lib, ... }:
{
  options.jemand771.plasma = {
    enable = lib.mkEnableOption "plasma-manager";
    panelScreens = lib.mkOption {
      type = with lib.types; either (enum [ "all" ]) (listOf ints.unsigned);
      default = "all";
      example = [
        0
        1
      ];
    };
    taskbarLaunchers = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      description = "launcher URLs to pin to the taskbar";
      default = null;
      example = [
        "applications:org.kde.dolphin.desktop"
        "preferred://browser"
      ];
    };
  };
  config.programs.plasma = lib.mkIf config.jemand771.plasma.enable {
    enable = true;
    # TODO enable after natural scrolling is supported as a native config option
    # https://github.com/nix-community/plasma-manager/pull/123
    # overrideConfig = true;
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
    };
    panels = [
      {
        screen = config.jemand771.plasma.panelScreens;
        floating = true;
        height = 44;
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          {
            iconTasks.launchers = config.jemand771.plasma.taskbarLaunchers;
          }
          "org.kde.plasma.marginsseparator"
          "org.kde.plasma.systemtray"
          {
            digitalClock.time.showSeconds = "always";
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];
  };
}
