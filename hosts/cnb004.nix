{
  config,
  lib,
  pkgs,
  ...
}:
{
  # TODO this would like to be somewhere else
  networking.hostName = "cnb004";
  deployment.tags = [ "intenta" ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      features.containerd-snapshotter = true;
      # wsl nat / company vpn fuckery
      mtu = 1400;
      default-network-opts.bridge."com.docker.network.driver.mtu" = "1400";
    };
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  virtualisation.podman.enable = true;
  boot.binfmt = {
    emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    preferStaticEmulators = true;
  };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  security.pki.certificateFiles = [
    ../certs/intenta-root01.crt
    ../certs/intenta-sub01.crt
  ];
  jemand771.wsl.nat = {
    address = "172.25.185.3/20";
    gateway = "172.25.176.1";
  };
  # TODO review and work around or file upstream (slop)
  nixpkgs.overlays = [
    (_: prev: {
      kdePackages = prev.kdePackages.overrideScope (
        _: kprev: {
          plasma-nm = kprev.plasma-nm.overrideAttrs (old: {
            patches = old.patches or [ ] ++ [
              ../patches/plasma-nm-openconnect-resolve.patch
              ../patches/plasma-nm-keep-in-memory-profiles.patch
            ];
          });
        }
      );
    })
  ];
  networking.networkmanager = {
    enable = true;
    plugins = [
      pkgs.networkmanager-openconnect
      pkgs.networkmanager-strongswan
    ];
    ensureProfiles.environmentFiles = [ config.age.secrets.caltrain-vpn-password.path ];
    ensureProfiles.profiles.caltrain = {
      connection = {
        id = "Caltrain";
        uuid = "4bec0839-9404-4d7c-a00f-56ed1d81f491";
        type = "vpn";
        autoconnect = false;
      };
      vpn = {
        service-type = "org.freedesktop.NetworkManager.openconnect";
        protocol = "gp";
        gateway = "sjcc-vpn.caltrain-ot.com/gateway";
        cookie-flags = 2;
        gwcert-flags = 2;
        gateway-flags = 2;
      };
      # prefills plasma-nm's login form
      vpn-secrets = {
        "form:_login:user" = "hillew";
        "form:_login:passwd" = "$CALTRAIN_VPN_PASSWORD";
        save_passwords = "yes";
        autoconnect = "yes";
      };
      ipv4 = {
        method = "auto";
        # default is all traffic, yucky
        never-default = true;
        ignore-auto-routes = true;
        route1 = "10.213.0.0/16";
        route2 = "10.220.220.113/32";
        route3 = "10.220.220.114/32";
      };
      ipv6.method = "disabled";
    };
    ensureProfiles.profiles.intenta = {
      connection = {
        id = "Intenta";
        uuid = "b444bc6b-50bd-46bd-b50b-972f451b6fc6";
        type = "vpn";
        autoconnect = false;
        permissions = "user:willy;";
      };
      vpn = {
        service-type = "org.freedesktop.NetworkManager.strongswan";
        address = "vpn.intop01.de";
        certificate = "${../certs/intenta-watchguard-ike.crt}";
        # cert has no vpn.intop01.de san
        remote-identity = "O=WatchGuard, OU=Fireware, CN=ike2muvpn Server";
        method = "eap";
        user = "willy.hille";
        password-flags = 1;
        virtual = "yes";
        proposal = "yes";
        ike = "aes256-sha256-modp2048";
        esp = "aes256-sha1";
        # once again 0.0.0.0/0 is stinky, but we can just ask the server for what we want
        remote-ts = lib.concatStringsSep ";" [
          "10.150.0.0/16"
          "10.153.0.0/16"
          "10.154.0.0/16"
          "217.160.252.63/32"
        ];
      };
      ipv4 = {
        method = "auto";
        dns-search = "~intop01.de;";
      };
      ipv6.method = "disabled";
    };
  };
  # charon-nm refuses to start without
  environment.etc."strongswan.conf".text = "";
  fileSystems =
    lib.mapAttrs'
      (
        letter: share:
        lib.nameValuePair "/mnt/${letter}" {
          device = "//sfs002.intop01.de/${share}";
          fsType = "cifs";
          noCheck = true;
          options = [
            "credentials=${config.age.secrets.intop01-smb-credentials.path}"
            "uid=1000"
            "gid=100"
            "file_mode=0644"
            "dir_mode=0755"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
          ];
        }
      )
      {
        h = "homes/wihi";
        n = "main";
        t = "temp";
        w = "data2";
        y = "data-transient";
      };
  # TODO svp2 schroot config, or ignore and abandon? (build locally and just reference hardcoded path to avoid delays from IFD?)
  # TODO warning, dangerous and ugly, see https://github.com/NixOS/nixpkgs/issues/30723
  nix.settings.extra-sandbox-paths = [ "/docker-auth.json" ];
  environment.systemPackages = with pkgs; [
    bomgar-acc
    ktimetracker
    outlook-web
    password-depot
    play
    skcopy
  ];
  system.extraDependencies = [ pkgs.bomgar-acc.installer ];
  programs.firefox = {
    enable = true;
    policies.EnableTrackingProtection.Category = "strict";
    policies.PasswordManagerEnabled = false;
    policies.Preferences."browser.sessionstore.max_resumed_crashes" = -1;
    policies.FirefoxHome = {
      Stories = false;
      SponsoredStories = false;
      SponsoredTopSites = false;
      Locked = true;
    };
    policies.FirefoxSuggest = {
      SponsoredSuggestions = false;
      Locked = true;
    };
    policies.ExtensionSettings =
      lib.mapAttrs
        (_: slug: {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
        })
        {
          "uBlock0@raymondhill.net" = "ublock-origin";
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = "bitwarden-password-manager";
          "firefox@tampermonkey.net" = "tampermonkey";
        };
  };

  # no openssh here, so specify whatever it would do manually
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  jemand771.wsl.enable = true;
  jemand771.wsl.desktop.enable = true;
  jemand771.dev-python.enable = true;
  jemand771.dev-infra.enable = true;
  jemand771.shell-utils.enable = true;
  jemand771.office-utils.enable = true;
  jemand771.home-manager.enable = true;
  home-manager.users.willy.imports = [
    {
      jemand771.ssh = {
        enable = true;
        hostsets = {
          cloudlab.enable = true;
          d39s.enable = true;
          homelab.enable = true;
          intenta.enable = true;
        };
      };
      jemand771.ai.enable = true;
      jemand771.kubeconfig.enable = true;
      jemand771.plasma = {
        enable = true;
        panelScreens = [
          0
          1
          2
        ];
        taskbarLaunchers = [
          "applications:org.kde.dolphin.desktop"
          "applications:firefox.desktop"
          "applications:org.kde.konsole.desktop"
          "applications:teams-for-linux.desktop"
          "applications:outlook-web.desktop"
        ];
      };
      programs.plasma.overrideConfig = true;
      programs.plasma.resetFilesExclude = [
        # TODO report upstream: deleting baloofilerc causes baloo to reindex everything :-)
        "baloofilerc"
        # contains runtime state (hand-created wallet name)
        "kwalletrc"
      ];
      programs.plasma.kscreenlocker.autoLock = false;
    }
  ];
  deployment.targetHost = null;
  system.stateVersion = "23.11";
}
