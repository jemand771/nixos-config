{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
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
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vanillatweaks = {
      url = "github:jemand771/nix-vanillatweaks";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    preservation.url = "github:nix-community/preservation";
    # they tell you not to overwrite the nixpkgs input so I won't
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
  };

  outputs =
    inputs':
    let
      inherit (inputs'.nixpkgs) lib;
      inputs = (import ./patches.nix) inputs';
      inherit (inputs)
        self
        nixpkgs
        home-manager
        plasma-manager
        nix-vscode-extensions
        flake-utils
        colmena
        disko
        agenix
        nixos-wsl
        nix-minecraft
        preservation
        proxmox-nixos
        ;
      overlaysFor =
        system:
        [
          colmena.overlays.default
          nix-minecraft.overlay
          nix-vscode-extensions.overlays.default
        ]
        ++ lib.optional (builtins.hasAttr system proxmox-nixos.overlays) proxmox-nixos.overlays.${system}
        ++ [ self.overlays.default ];
    in
    {
      lib =
        let
          call = n: import (./lib + "/${n}") { inherit lib; };
        in
        call "mapDir.nix" ./lib call;
      nixosModules = self.lib.mapDir ./modules/nixos (n: ./modules/nixos/${n});
      homeModules = self.lib.mapDir ./modules/home-manager (n: ./modules/home-manager/${n});
      overlays.default = final: _prev: self.lib.mapDir ./pkgs (n: final.callPackage ./pkgs/${n} { });
      nixosConfigurations = self.colmenaHive.nodes;
      colmenaHive =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
          defaultModules = [
            self.nixosModules.default
            nixos-wsl.nixosModules.default
            {
              nixpkgs.overlays = overlaysFor pkgs.stdenv.hostPlatform.system;
            }
            ./meta-options.nix
            ./home/options.nix
            home-manager.nixosModules.home-manager
            (
              { config, lib, ... }:
              {
                options.jemand771.home-manager.enable = lib.mkEnableOption "home-manager";
                config.home-manager = lib.mkIf config.jemand771.home-manager.enable {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  extraSpecialArgs = inputs;
                  sharedModules = [
                    plasma-manager.homeModules.plasma-manager
                  ];
                  users.willy.imports = [
                    self.homeModules.default
                    ./home/ai.nix
                    ./home/common.nix
                    ./home/plasma.nix
                    ./home/thunderbird.nix
                    ./home/ssh
                    (
                      { osConfig, ... }:
                      {
                        home = { inherit (osConfig.system) stateVersion; };
                      }
                    )
                  ];
                };
              }
            )
            ./software
            ./sync.nix
            disko.nixosModules.disko
            agenix.nixosModules.default
            nix-minecraft.nixosModules.minecraft-servers
            preservation.nixosModules.default
          ];
        in
        colmena.lib.makeHive (
          {
            meta = {
              nixpkgs = pkgs;
              specialArgs = inputs;
              allowApplyAll = false;
            };
          }
          // self.lib.mapDir ./hosts (n: {
            imports =
              defaultModules
              ++ [ ./hosts/${n} ]
              ++ pkgs.lib.optional (builtins.pathExists ./hardware/${n}) ./hardware/${n};
          })
        );
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (
          import nixpkgs {
            inherit system;
            overlays = overlaysFor system;
          }
        );
      in
      {
        packages = self.lib.mapDir ./pkgs (n: pkgs.callPackage ./pkgs/${n} { });
        checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
          self.lib.mapDir ./checks (n: import ./checks/${n} (inputs // { inherit pkgs self; }))
        );
        devShells.default = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            agenix.packages.${system}.default
            pkgs.colmena
            deadnix
            nix-diff
            nix-update
            nixfmt
            nixfmt-tree
            nixos-anywhere
          ];
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
