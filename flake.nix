{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
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

  outputs = inputs@{ self, nixpkgs, agenix, home-manager, ... }: {

    nixosConfigurations.nixbox = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        agenix.nixosModules.default
        { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        ./secrets-nixos.nix
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.willy = import ./home.nix;
          };
        }
        ./backups.nix
        ./configuration.nix
        ./nvidia.nix
        ./unstable.nix
        ./nix-tools.nix
        ./mounts.nix
      ];
    };
  };
}
