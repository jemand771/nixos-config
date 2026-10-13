{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.wsl.enable = lib.mkEnableOption "WSL stuffs";
  options.jemand771.wsl.desktop.enable =
    lib.mkEnableOption "plasma desktop via xrdp";
  config = lib.mkIf config.jemand771.wsl.enable {
    wsl = {
      enable = true;
      defaultUser = "willy";
      interop.includePath = false;
      wslConf.automount.options = "metadata,umask=022,fmask=111,uid=1000,gid=100";
      usbip.enable = true;
    };

    # vscode antinag
    environment.variables.DONT_PROMPT_WSL_INSTALL = "1";

    services = lib.mkIf config.jemand771.wsl.desktop.enable {
      desktopManager.plasma6.enable = true;
      xrdp = {
        enable = true;
        # windows' rdp server listens on 3389 already
        port = 3390;
        # GDK_BACKEND: force using the x11 desktop, otherwise some windows launch via wslg
        # PULSE_LATENCY_MSEC: bigger audio buffer to fix stuttering/crackling
        defaultWindowManager = "GDK_BACKEND=x11 PULSE_LATENCY_MSEC=150 startplasma-x11";
      };
    };
    # audio goes to wslg's pulse server -> install audio controls even when no server is enabled
    environment.systemPackages = lib.mkIf config.jemand771.wsl.desktop.enable [
      pkgs.kdePackages.plasma-pa
    ];
  };
}
