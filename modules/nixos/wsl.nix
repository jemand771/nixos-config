{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.wsl.enable = lib.mkEnableOption "WSL stuffs";
  options.jemand771.wsl.desktop.enable = lib.mkEnableOption "plasma desktop via xrdp";
  options.jemand771.wsl.nat = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          address = lib.mkOption {
            type = lib.types.str;
            example = "172.25.185.3/20";
          };
          gateway = lib.mkOption {
            type = lib.types.str;
            example = "172.25.176.1";
          };
        };
      }
    );
    default = null;
    description = "eth0 config (managed by wsl itself, just import the current values)";
  };
  config = lib.mkIf config.jemand771.wsl.enable {
    wsl = {
      enable = true;
      defaultUser = "willy";
      interop.includePath = false;
      wslConf.automount.options = "metadata,umask=022,fmask=111,uid=1000,gid=100";
      usbip.enable = true;
    };

    # vscode antinag
    environment.sessionVariables.DONT_PROMPT_WSL_INSTALL = "1";

    # eth0 configured by windows, dns via resolved so vpns can add split dns
    wsl.wslConf.network.generateResolvConf = lib.mkIf config.networking.networkmanager.enable false;
    networking.nameservers = lib.mkIf config.networking.networkmanager.enable [ "10.255.255.254" ];
    networking.networkmanager = lib.mkIf config.networking.networkmanager.enable {
      dns = "systemd-resolved";
      settings.main.no-auto-default = "*";
      unmanaged = [
        "interface-name:docker*"
        "interface-name:br-*"
        "interface-name:veth*"
        "interface-name:virbr*"
        "interface-name:vnet*"
        "interface-name:podman*"
      ];
    };
    systemd.services.NetworkManager-wait-online.enable = lib.mkIf config.networking.networkmanager.enable false;
    networking.wireless.enable = lib.mkIf config.networking.networkmanager.enable (lib.mkForce false);
    # pretend to own eth0 so it's usable as a vpn base
    environment.etc."NetworkManager/system-connections/wsl-eth0.nmconnection" =
      lib.mkIf (config.networking.networkmanager.enable && config.jemand771.wsl.nat != null)
        {
          mode = "0600";
          text = lib.generators.toINI { } {
            connection = {
              id = "wsl-eth0";
              uuid = "81920d52-a4f5-4818-ba4a-19c702405eaa";
              type = "ethernet";
              interface-name = "eth0";
              autoconnect = false;
            };
            ipv4 = {
              method = "manual";
              address1 = config.jemand771.wsl.nat.address;
              gateway = config.jemand771.wsl.nat.gateway;
            };
            ipv6.method = "link-local";
          };
        };

    services = lib.mkMerge [
      (lib.mkIf config.networking.networkmanager.enable { resolved.enable = true; })
      (lib.mkIf config.jemand771.wsl.desktop.enable {
        desktopManager.plasma6.enable = true;
        xrdp = {
          enable = true;
          # windows' rdp server listens on 3389 already
          port = 3390;
          # GDK_BACKEND: force using the x11 desktop, otherwise some windows launch via wslg
          # KWIN_X11_REFRESH_RATE: "monitors" report 50Hz, force 60Hz instead
          defaultWindowManager = "GDK_BACKEND=x11 KWIN_X11_REFRESH_RATE=60000 startplasma-x11";
          extraConfDirCommands = ''
            # 30-ish -> 60-ish fps
            substituteInPlace $out/xrdp.ini \
              --replace-fail "rfx_frame_interval=32" "rfx_frame_interval=16"
            # force the layout I picked over what windows' rdp client requests
            cat ${
              pkgs.writeText "xrdp_keyboard_pc.ini" (
                lib.generators.toINI { } {
                  rdp_keyboard_pc = {
                    keyboard_type = 4;
                    variant = config.services.xserver.xkb.variant;
                    rdp_layouts = "default_rdp_layouts";
                    layouts_map = "default_layouts_map";
                  };
                }
              )
            } >> $out/xrdp_keyboard.ini
          '';
          audio.enable = true;
        };
        # no builtin pipewire support :(
        pulseaudio.enable = true;
      })
    ];
    # pulse server above supersedes everything wslg could ever symlink here (pid, socket, ...)
    systemd.user.services.wslg-session.enable = !config.jemand771.wsl.desktop.enable;
  };
}
