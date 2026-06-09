# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  microvm,
  pkgs,
  ...
}:

{
  deployment.tags = [ "personal" ];
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

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "willy";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    solaar
    # TODO broken
    # streamdeck-ui
    nvtopPackages.nvidia
    nfs-utils
    wineWow64Packages.full
    winetricks
    protontricks
    qpwgraph
    gpu-screen-recorder-gtk
    jetbrains-toolbox
    firefox
    # TODO broken
    # (google-cloud-sdk.withExtraComponents (
    #   with pkgs.google-cloud-sdk.components;
    #   [
    #     gke-gcloud-auth-plugin
    #   ]
    # ))
    (blender.override {
      cudaSupport = true;
    })
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
  virtualisation.waydroid.enable = true;
  services.openssh.enable = true;

  zramSwap.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  imports = [
    ../secrets-nixos.nix
    ../backups.nix
    ../mounts.nix
    ../playground/minecraft.nix
    microvm.nixosModules.host
    ../playground/vms.nix
  ];
  home-manager.users.willy.imports = [
    {
      jemand771.desktopLagFix.enable = true;
      jemand771.ssh = {
        enable = true;
        hostsets = {
          cloudlab.enable = true;
          d39s.enable = true;
          homelab.enable = true;
        };
      };
      jemand771.ai.enable = true;
    }
  ];
  jemand771.printer.enable = true;
  jemand771.meta.personal-system = true;
  jemand771.fancontrol = {
    enable = true;
    enableNixboxProfile = true;
  };
  # manual hardware settings
  hardware.ckb-next.enable = true;
  hardware.logitech.wireless.enable = true;
  boot.kernelParams = [
    "pcie_port_pm=off"
    "pcie_aspm.policy=performance"
  ];
  jemand771.nvidiagpu.enable = true;

  system.stateVersion = "23.11";
}
