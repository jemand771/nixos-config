{ pkgs, inputs, id, ... }:
let
  system = "x86_64-linux";
  ip = "10.7.7.20${builtins.toString id}";
in
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    (inputs.nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
    inputs.proxmox-nixos.nixosModules.proxmox-ve
    {
      boot.loader.grub.enable = true;
      boot.loader.grub.device = "/dev/vda";
      boot.loader.grub.useOSProber = true;
      networking.hostName = "proxmox-test-${builtins.toString id}";
      networking.hostId = if id == 1 then "b6f8760a" else if id == 2 then "9d8521db" else if id == 3 then "34a9b41a" else "";
      networking.useDHCP = false;
      fileSystems."/" = {
        device = if id == 1 then "/dev/disk/by-uuid/b96b5b53-f1f6-4ea8-a84c-ab3dd14a4146"
            else if id == 2 then "/dev/disk/by-uuid/5d40556b-5ee1-4704-ba1d-129035d5c9b8"
            else if id == 3 then "/dev/disk/by-uuid/77f64ef6-2568-4032-bff5-3ffa7ab4facd"
            else "";
        fsType = "ext4";
      };

      boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];
      nixpkgs.hostPlatform = "x86_64-linux";

      services.getty.autologinUser = "root";
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "24.05"; # Did you read the comment?
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjygB98U3+QUD24oga93Lej5ZCtSah9KI/DneSQgVjL willy@nixbox"
      ];
      nix = {
        settings.experimental-features = [ "nix-command" "flakes" ];
        registry.nixpkgs.flake = inputs.nixpkgs;
        nixPath = [
          "nixpkgs=${inputs.nixpkgs}"
        ];
      };
      users.users.root.password = "root";
      systemd.network.enable = true;
      systemd.network.networks."10-lan" = {
        matchConfig.Type = "ether";
        networkConfig.Bridge = "vmbr0";
      };
      systemd.network.netdevs."vmbr0".netdevConfig = {
        Name = "vmbr0";
        Kind = "bridge";
      };
      systemd.network.networks."10-lan-bridge" = {
        matchConfig.Name = "vmbr0";
        networkConfig = {
          Gateway = "10.7.7.250";
          DNS = ["10.7.7.250"];
          DHCP = "no";
          Address = ["${ip}/24"];
          VXLAN = "vxlan1";
        };
      };
      services.proxmox-ve.ipAddress = ip;
      deployment.targetHost = ip;
      deployment.tags = [ "proxmox-test" ];
      # cluster join from the ui doesn't work either way, but this at least makes the bridge show up on the networking page
      # https://github.com/SaumonNet/proxmox-nixos/pull/65
      environment.etc."network/interfaces" = {
        mode = "0644";
        text = ''
          auto vmbr0
          iface vmbr0 inet static
            bridge_ports none
          auto vmbr1
          iface vmbr1 inet static
            bridge_ports none
        '';
      };
      services.proxmox-ve.enable = true;
      nixpkgs.overlays = [
        inputs.proxmox-nixos.overlays.${system}
      ];
      boot.supportedFilesystems = [ "zfs" ];
      systemd.network.netdevs."vxlan1" = {
        netdevConfig = {
          Kind = "vxlan";
          Name = "vxlan1";
        };
        vxlanConfig = {
          VNI = 1;
          Group = "239.1.1.1"; # what is this?
          Local = ip;
          DestinationPort = 4789;
          # Independent = true;
        };
      };
      systemd.network.networks."20-vxlan1" = {
        matchConfig.Name = "vxlan1";
        networkConfig = {
          # Address = "10.23.0.${builtins.toString id}/24";
          Bridge = "vmbr1";
        };
      };
      networking.firewall.allowedTCPPorts = [ 4789 ];
      systemd.network.netdevs."vmbr1".netdevConfig = {
        Name = "vmbr1";
        Kind = "bridge";
      };
      systemd.network.networks."10-vxlan-bridge" = {
        matchConfig.Name = "vmbr1";
        networkConfig = {
          Address = "10.23.0.${builtins.toString id}/24";
         };
      };
    }
    {
      time.timeZone = "Europe/Berlin";
      i18n.defaultLocale = "en_US.UTF-8";
      i18n.extraLocaleSettings = {
        LC_ADDRESS = "de_DE.UTF-8";
        LC_IDENTIFICATION = "de_DE.UTF-8";
        LC_MEASUREMENT = "de_DE.UTF-8";
        LC_MONETARY = "de_DE.UTF-8";
        LC_NAME = "de_DE.UTF-8";
        LC_NUMERIC = "de_DE.UTF-8";
        LC_PAPER = "de_DE.UTF-8";
        LC_TELEPHONE = "de_DE.UTF-8";
        LC_TIME = "de_DE.UTF-8";
      };
      console.keyMap = "de-latin1-nodeadkeys";
    }
  ];
  extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];
}
# create cluster:
# pvecm create test-cluster
# pvesh create /cluster/config/join --hostname 10.7.7.201 --password root --fingerprint bla
