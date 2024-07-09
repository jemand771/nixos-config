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
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, agenix, home-manager, plasma-manager, ... }: {

    nixosConfigurations.nixbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        agenix.nixosModules.default
        { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        ./secrets-nixos.nix
        home-manager.nixosModules.home-manager
        {
          # make unstable packages available as pkgs.unstable
          nixpkgs.overlays = [
            (_: prev: ({
              unstable = import inputs.nixpkgs-unstable { config.allowUnfree = true; inherit (prev.stdenv.hostPlatform) system; };
            }))
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.willy.imports = [
              ./home/common.nix
              ./home/nixbox.nix
            ];
          };
        }
        ./backups.nix
        ./hosts/nixbox.nix
        ./hardware/nixbox.nix
        ./hardware/nvidia.nix
        ./hardware/nic.nix
        ./hardware/keyboard.nix
        ./hardware/fans.nix
        ./nix-tools.nix
        ./mounts.nix
        ./software/basics.nix
        ./software/locale.nix
        ./software/shell-utils.nix
        ./software/office-utils.nix
      ];
    };
    nixosConfigurations.nixtique = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # agenix.nixosModules.default
        # { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        # ./secrets-nixos.nix
        home-manager.nixosModules.home-manager
        {
          # make unstable packages available as pkgs.unstable
          nixpkgs.overlays = [
            (_: prev: ({
              unstable = import inputs.nixpkgs-unstable { config.allowUnfree = true; inherit (prev.stdenv.hostPlatform) system; };
            }))
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [
              plasma-manager.homeManagerModules.plasma-manager
            ];
            users.willy.imports = [
              ./home/common.nix
              ./home/nixtique.nix
            ];
          };
        }
        ./hosts/nixtique.nix
        ./hardware/nixtique.nix
        ./nix-tools.nix
        ./software/basics.nix
        ./software/locale.nix
        ./software/shell-utils.nix
        ./software/office-utils.nix
      ];
    };
    nixosConfigurations.nixbox2 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # agenix.nixosModules.default
        # { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        # ./secrets-nixos.nix
        home-manager.nixosModules.home-manager
        {
          # make unstable packages available as pkgs.unstable
          nixpkgs.overlays = [
            (_: prev: ({
              unstable = import inputs.nixpkgs-unstable { config.allowUnfree = true; inherit (prev.stdenv.hostPlatform) system; };
            }))
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.willy.imports = [
              ./home/common.nix
              ./home/nixbox2.nix
            ];
          };
        }
        ./hosts/nixbox2.nix
        ./hardware/nixbox2.nix
        ./nix-tools.nix
        ./software/basics.nix
        ./software/locale.nix
        # ./software/shell-utils.nix
        # ./software/office-utils.nix
      ];
    };
  };
}
