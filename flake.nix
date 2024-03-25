{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, agenix, home-manager, ... }: {

    nixosConfigurations.nixbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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
            users.willy = import ./home.nix;
          };
        }
        ./backups.nix
        ./configuration.nix
        ./hardware/nvidia.nix
        ./hardware/nic.nix
        ./hardware/keyboard.nix
        ./nix-tools.nix
        ./mounts.nix
      ];
    };
  };
}
