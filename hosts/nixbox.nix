# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixbox"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    packages = with pkgs; [
      heroic
      gpu-screen-recorder-gtk
      tetrio-desktop
      prismlauncher
      jre8
      lutris
      jetbrains-toolbox
      firefox
      (google-cloud-sdk.withExtraComponents( with pkgs.google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ]))
      obs-studio
      (blender.override {
        cudaSupport = true;
      })
      gh
      insomnia
    ];
  };

  security.sudo.extraRules = [
    {
      users = ["willy"];
      commands = [{
        command = "ALL";
        options = ["NOPASSWD"];
      }];
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
    logitech-udev-rules
    # TODO broken
    # streamdeck-ui
    config.boot.kernelPackages.xone
    python311
    qt6.qtwebsockets
    libsForQt5.qt5.qtwebsockets
    libsForQt5.qt5.qtwebchannel
    libsForQt5.qt5.qtwebchannel
    python311Packages.websockets
    nvtopPackages.nvidia
    nfs-utils
    wineWowPackages.full
    wineWow64Packages.full
    winetricks
    protontricks
    nodejs_20
  ];
  hardware.xone.enable = true;
  programs.kdeconnect.enable = true;
  programs.k3b.enable = true;
  programs.partition-manager.enable = true;
  programs.ausweisapp = {
    enable = true;
    openFirewall = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

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

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  services.openssh.enable = true;
}
