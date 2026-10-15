{
  lib,
  config,
  ...
}:
{
  options.jemand771.wsl.enable = lib.mkEnableOption "WSL stuffs";
  options.jemand771.wsl.desktop.enable = lib.mkEnableOption "plasma desktop via xrdp";
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
        # KWIN_X11_REFRESH_RATE: "monitors" report 50Hz, force 60Hz instead
        defaultWindowManager = "GDK_BACKEND=x11 KWIN_X11_REFRESH_RATE=60000 startplasma-x11";
        # 30-ish -> 60-ish fps
        extraConfDirCommands = ''
          substituteInPlace $out/xrdp.ini \
            --replace-fail "rfx_frame_interval=32" "rfx_frame_interval=16"
        '';
        audio.enable = true;
      };
      # no builtin pipewire support :(
      pulseaudio = {
        enable = true;
        # wslg manages $XDG_RUNTIME_DIR/pulse/pid
        daemon.config.use-pid-file = "no";
      };
    };
    # overwrite wslg's socket
    systemd.user.sockets.pulseaudio.after = lib.mkIf config.jemand771.wsl.desktop.enable [
      "wslg-session.service"
    ];
  };
}
