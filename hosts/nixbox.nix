# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixbox"; # Define your hostname.

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.willy = {
    isNormalUser = true;
    description = "willy";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "dialout"
    ];
    packages = with pkgs; [
      gpu-screen-recorder-gtk
      lutris
      jetbrains-toolbox
      firefox
      (google-cloud-sdk.withExtraComponents (
        with pkgs.google-cloud-sdk.components;
        [
          gke-gcloud-auth-plugin
        ]
      ))
      (blender.override {
        cudaSupport = true;
      })
      gh
      insomnia
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "willy" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "willy";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    solaar
    # TODO broken
    # streamdeck-ui
    config.boot.kernelPackages.xone
    qt6.qtwebsockets
    libsForQt5.qt5.qtwebsockets
    libsForQt5.qt5.qtwebchannel
    libsForQt5.qt5.qtwebchannel
    nvtopPackages.nvidia
    nfs-utils
    wineWowPackages.full
    wineWow64Packages.full
    winetricks
    protontricks
    qpwgraph
  ];
  hardware.xone.enable = true;
  programs.kdeconnect.enable = true;
  # TODO broken / moved to non-option package
  # programs.k3b.enable = true;
  programs.partition-manager.enable = true;
  programs.ausweisapp = {
    enable = true;
    openFirewall = true;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  virtualisation.docker = {
    enable = true;
    daemon.settings.features.containerd-snapshotter = true;
  };
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];
  boot.binfmt.preferStaticEmulators = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  services.openssh.enable = true;

  zramSwap.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };
}
