{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nixpkgs-unstable,
    agenix,
    home-manager,
    plasma-manager,
    nix-vscode-extensions,
    ...
  }: let nixosSystem = { modules ? [], homeModules ? [], system ? "x86_64-linux", stateVersion }: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs; };
    modules = [
      {
        # make unstable packages available as pkgs.unstable
        nixpkgs.overlays = [
          (_: prev: ({
            unstable = import inputs.nixpkgs-unstable { config.allowUnfree = true; inherit (prev.stdenv.hostPlatform) system; };
          }))
          nix-vscode-extensions.overlays.default
        ];
      }
      ./meta-options.nix
      ./home/options.nix
      home-manager.nixosModules.home-manager
      ({ config, ...}:
      {
        options.jemand771.home-manager.enable = nixpkgs.lib.mkEnableOption "home-manager";
        config.home-manager = nixpkgs.lib.mkIf config.jemand771.home-manager.enable {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = [
            plasma-manager.homeManagerModules.plasma-manager
          ];
          users.willy.imports = [
            ./home/common.nix
            ./home/desktop-lag-fix.nix
            ./home/plasma.nix
            ./home/thunderbird.nix
            { home = { inherit stateVersion; }; }
          ] ++ homeModules;
        };
      })
      ./nix-tools.nix
      ./software/basics.nix
      ./software/locale.nix
      ./software/shell-utils.nix
      ./software/office-utils.nix
      ./software/dev-infra.nix
      ./software/gaming.nix
      ./software/auto-upgrade.nix
      ./sync.nix
      { system = { inherit stateVersion; }; }
    ] ++ modules;
  };
  in {
    nixosConfigurations.nixbox = nixosSystem {
      modules = [
        {
          jemand771.meta.personal-system = true;
        }
        agenix.nixosModules.default
        { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        ./secrets-nixos.nix
        ./backups.nix
        ./hosts/nixbox.nix
        ./hardware/nixbox.nix
        ./hardware/nvidia.nix
        ./hardware/nic.nix
        ./hardware/keyboard.nix
        ./hardware/fans.nix
        ./hardware/mouse.nix
        ./mounts.nix
      ];
      stateVersion = "23.11";
    };
    nixosConfigurations.nixtique = nixosSystem {
      modules = [
        {
          jemand771.meta.personal-system = true;
        }
        # agenix.nixosModules.default
        # { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        # ./secrets-nixos.nix
        ./hosts/nixtique.nix
        ./hardware/nixtique.nix
        ./hardware/mouse.nix
        {
          jemand771.plasma.enable = true;
        }
      ];
      stateVersion = "24.05";
    };
    nixosConfigurations.nixbox2 = nixosSystem {
      modules = [
        {
          jemand771.meta.personal-system = true;
        }
        # agenix.nixosModules.default
        # { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        # ./secrets-nixos.nix
        ./hosts/nixbox2.nix
        ./hardware/nixbox2.nix
        ./hardware/mouse.nix
      ];
      stateVersion = "24.05";
    };
    nixosConfigurations.apt-cache = nixosSystem {
      modules = [
        ./software/apt-cache.nix
        {
          jemand771.auto-upgrade.enable = true;
        }
      ];
      stateVersion = "23.11";
    };
    nixosConfigurations.syncthing-arbiter = nixosSystem {
      modules = [
        # TODO this is probably bad, how to modulesPath ?
        ("${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix")
        {
          jemand771.syncthing.enable = true;
          jemand771.auto-upgrade.enable = true;
        }
      ];
      stateVersion = "24.05";
    };
  };
}
