{
  lib,
  config,
  pkgs,
  ...
}:
let
  desktop = config.jemand771.wsl.desktop;
  # windows' rdp server listens on 3389 already
  rdpPort = 3390;
  krdpserver = pkgs.writeShellScript "krdpserver" ''
    set -eu
    dir=''${XDG_DATA_HOME:-$HOME/.local/share}/krdp
    if [ ! -s "$dir/cert.pem" ]; then
      mkdir -p "$dir"
      ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -subj /CN=${config.networking.hostName} -keyout "$dir/key.pem" -out "$dir/cert.pem"
    fi
    exec ${pkgs.kdePackages.krdp}/bin/krdpserver --plasma --port ${toString rdpPort} \
      --certificate "$dir/cert.pem" --certificate-key "$dir/key.pem" \
      --username ${config.wsl.defaultUser} --password "$(< "$CREDENTIALS_DIRECTORY/password")"
  '';
in
{
  options.jemand771.wsl.enable = lib.mkEnableOption "WSL stuffs";
  options.jemand771.wsl.desktop.enable =
    lib.mkEnableOption "headless plasma wayland session served by krdp";
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

    environment.systemPackages = lib.mkIf desktop.enable [
      (pkgs.writeShellApplication {
        name = "wsl-desktop-wait";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.iproute2
        ];
        text = ''
          for _ in $(seq 240); do
            if ss -Htln 'sport = :${toString rdpPort}' | grep -q .; then
              ip -4 -br addr show dev eth0 | tr -s ' ' | cut -d ' ' -f 3 | cut -d / -f 1
              exit 0
            fi
            sleep 0.5
          done
          echo "nothing listening on port ${toString rdpPort}" >&2
          exit 1
        '';
      })
    ];

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
      (lib.mkIf desktop.enable {
        desktopManager.plasma6.enable = true;
        pipewire = {
          pulse.enable = true;
          alsa.enable = true;
          wireplumber.extraConfig.log-suspend."context.properties"."log.level" = "2,s-node:4,si-audio-adapter:4";
        };
      })
    ];

    ### warning: SLOP AHEAD ###

    nixpkgs.overlays = lib.mkIf desktop.enable [
      (_: prev: {
        kdePackages = prev.kdePackages.overrideScope (
          _: kprev: {
            # wsl has no udmabuf: let kwin allocate its virtual outputs' buffers through gbm instead,
            # but keep screencasts on memfd since those gbm buffers can't be shared with clients
            kwin = kprev.kwin.overrideAttrs (old: {
              patches = old.patches or [ ] ++ [
                ../../patches/kwin-faux-without-udmabuf.patch
                # memfd screencasts (all of them on wsl) re-rendered and read back whole outputs every frame
                ../../patches/kwin-screencast-partial-readback.patch
              ];
            });
            # upstream krdp serves a single monitor per connection
            krdp = kprev.krdp.overrideAttrs (old: {
              version = "6.7.5-niposch";
              buildInputs = old.buildInputs ++ [ pkgs.pipewire ];
              src = pkgs.fetchFromGitHub {
                owner = "niposch";
                repo = "krdp";
                rev = "0b54f7197f88460085f1d7151c281807c20a9923";
                hash = "sha256-rAO10g9Z6FSexD4HRN08ssOS/VfeNKhtgc1moe9jSnU=";
              };
              # nla: backport of upstream's sam database, mstsc insists on it
              # kwin-virtual-backend: kwin --virtual outputs (Virtual-N) count as physical
              # mstsc-multimon: announce the monitor union up front, anchor monitor defs on the primary
              # progressive: no winpr thread pool (wakes every worker per tile), no dma-buf (not importable on wsl)
              # audio: krdp MR !239 (rdpsnd output + audin microphone via pipewire), wslg's pulse server crackles and dies
              #   minus the microphone's suspend-on-idle: teams pauses its capture for ~2ms when joining, the instant
              #   suspend likely raced the renegotiation and occasionally left the source's ports without a format
              # mouse-xbuttons: back/forward were dropped by the plasma input path (upstream 6.8 too)
              # raster-copy: memfd frames went through 4 full-frame copies/swaps on the main thread, now one copy of the damage,
              #   made before kpipewire returns the buffer to kwin (queued, it raced kwin's next render: tearing, stale rects)
              patches = old.patches ++ [
                ../../patches/krdp-niposch-nla.patch
                ../../patches/krdp-niposch-kwin-virtual-backend.patch
                ../../patches/krdp-niposch-mstsc-multimon.patch
                ../../patches/krdp-niposch-progressive.patch
                ../../patches/krdp-niposch-audio.patch
                ../../patches/krdp-niposch-mouse-xbuttons.patch
                ../../patches/krdp-niposch-raster-copy.patch
              ];
            });
          }
        );
      })
    ];

    environment.etc."xdg/krdpserverrc" = lib.mkIf desktop.enable {
      text = lib.generators.toINI { } {
        General = {
          MonitorMode = "virtual";
          VirtualMonitorLayout = "client";
          VirtualMonitorPolicy = "replace";
          # rgb tiles: no yuv conversion or x264 blockiness, bandwidth doesn't matter on localhost
          Codec = "progressive";
          # its backlog detection reacts to local encode/decode time, not the network
          AdaptiveQuality = false;
        };
      };
    };

    # mesa's d3d12 driver instead of llvmpipe, kwin alone burned ~5 cores compositing in software
    wsl.useWindowsDriver = lib.mkIf desktop.enable true;
    # the driver dlopens libd3d12/libdxcore, but nothing points it at /run/opengl-driver/lib
    # (LD_LIBRARY_PATH would be ignored by the capability-wrapped kwin_wayland anyway)
    hardware.graphics.package = lib.mkIf desktop.enable (
      pkgs.mesa.overrideAttrs (old: {
        # d3d12's deferred frees re-enter the slab manager's mutex, hanging kwin on glReadPixels
        patches = old.patches or [ ] ++ [ ../../patches/mesa-pb-slab-unlock-provider.patch ];
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.addDriverRunpath ];
        postFixup = (old.postFixup or "") + ''
          addDriverRunpath $out/lib/libgallium-*.so
        '';
      })
    );

    # even the virtual backend wants the drm node for gl compositing, which screencasting requires
    users.users.${config.wsl.defaultUser}.extraGroups = lib.mkIf desktop.enable [
      "video"
      "render"
    ];
    # wslg mounts this read-only, which keeps xwayland from creating its socket
    systemd.services.wslg-x11-socket-dir = lib.mkIf desktop.enable {
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathIsMountPoint = "/tmp/.X11-unix";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.util-linux}/bin/mount -o remount,bind,rw /tmp/.X11-unix"
          "${pkgs.coreutils}/bin/chmod 1777 /tmp/.X11-unix"
        ];
      };
    };
    systemd.services.plasma-wayland = lib.mkIf desktop.enable {
      description = "headless plasma wayland session";
      wantedBy = [ "multi-user.target" ];
      wants = [ "wslg-x11-socket-dir.service" ];
      after = [
        "systemd-user-sessions.service"
        "wslg-x11-socket-dir.service"
      ];
      # kwin on wayland doesn't know about services.xserver.xkb
      environment = {
        XKB_DEFAULT_LAYOUT = config.services.xserver.xkb.layout;
        XKB_DEFAULT_VARIANT = config.services.xserver.xkb.variant;
        # only kwin gets the gpu (see below): d3d12 ignores the colour of qt quick's distance field text,
        # and glx would otherwise pick zink on top of it
        LIBGL_ALWAYS_SOFTWARE = "1";
        # llvmpipe repaints qt quick windows every frame (e.g. spectacle) software doesn't
        QT_QUICK_BACKEND = "software";
        # mesa's vulkan device select layer crashes on wsl's faux drm device (no pci info)
        NODEVICE_SELECT = "1";
      };
      serviceConfig = {
        User = config.wsl.defaultUser;
        # logind session plus the usual pam environment, no tty or password involved
        PAMName = "login";
        WorkingDirectory = "~";
        ExecStart = "${pkgs.kdePackages.plasma-workspace}/bin/startplasma-wayland";
        Restart = "always";
        RestartSec = 2;
      };
    };
    systemd.user.services = lib.mkMerge [
      {
        # pipewire-pulse supersedes everything wslg could ever symlink here (pid, socket, ...)
        wslg-session.enable = !desktop.enable;
      }
      (lib.mkIf desktop.enable {
        pipewire.environment.PIPEWIRE_DEBUG = "2,pw.link:3,pw.node:3";
        plasma-kwin_wayland = {
          overrideStrategy = "asDropin";
          # the wrapper looks up kwin_wayland via the session's PATH, don't shadow it
          path = lib.mkForce [ ];
          environment = {
            LIBGL_ALWAYS_SOFTWARE = "0";
            GALLIUM_DRIVER = "d3d12";
            # mesa only knows wsl's faux drm device as a software egl device, so kwin assumes
            # llvmpipe and turns all animations off although d3d12 renders on the gpu
            KWIN_EFFECTS_FORCE_ANIMATIONS = "1";
            # mesa's d3d12 ignores the colour of qt quick's distance field text (tabbox, osds come out white/yellow)
            QML_DISABLE_DISTANCEFIELD = "1";
            QT_QUICK_BACKEND = "";
          };
          # placeholder output, krdp replaces it with one virtual output per client monitor
          serviceConfig.ExecStart = [
            ""
            "${pkgs.kdePackages.kwin}/bin/kwin_wayland_wrapper --xwayland --virtual --width 1920 --height 1080"
          ];
        };
        # otherwise it starts with wslg's WAYLAND_DISPLAY/DISPLAY and its extractor crash-loops
        kde-baloo = {
          overrideStrategy = "asDropin";
          path = lib.mkForce [ ];
          after = [ "plasma-kwin_wayland.service" ];
        };
        "app-org.kde.krdpserver" = {
          description = "krdp server";
          wantedBy = [ "plasma-workspace.target" ];
          after = [ "plasma-core.target" ];
          path = [ pkgs.kdePackages.libkscreen ];
          serviceConfig = {
            ExecStart = krdpserver;
            LoadCredential = "password:%h/.config/krdp/password";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      })
    ];
  };
}
