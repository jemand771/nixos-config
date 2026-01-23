{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
    # they tell you not to overwrite the nixpkgs input so I won't
    proxmox-nixos.url = "github:SaumonNet/proxmox-nixos";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs':
    let
      inputs = (import ./patches.nix) inputs';
      inherit (inputs)
        self
        nixpkgs
        home-manager
        plasma-manager
        nix-vscode-extensions
        nixpkgs-unstable-small
        flake-utils
        colmena
        disko
        proxmox-nixos
        ;
    in
    {
      nixosConfigurations = self.colmenaHive.nodes;
      colmenaHive =
        let
          defaultModules = [
            {
              nixpkgs.overlays = [
                # make unstable-small packages available as pkgs.unstable-small
                (_: prev: ({
                  unstable-small = import nixpkgs-unstable-small {
                    config.allowUnfree = true;
                    inherit (prev.stdenv.hostPlatform) system;
                  };
                }))
                nix-vscode-extensions.overlays.default
                (
                  final: prev:
                  if builtins.hasAttr prev.stdenv.hostPlatform.system proxmox-nixos.overlays then
                    proxmox-nixos.overlays.${prev.stdenv.hostPlatform.system} final prev
                  else
                    { }
                )
              ];
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
                  sharedModules = [
                    plasma-manager.homeModules.plasma-manager
                  ];
                  users.willy.imports = [
                    ./home/common.nix
                    ./home/desktop-lag-fix.nix
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
          ];
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        colmena.lib.makeHive (
          {
            meta = {
              nixpkgs = pkgs;
              specialArgs = inputs;
              allowApplyAll = false;
            };
          }
          // (pkgs.lib.mapAttrs' (n: _: {
            name = inputs'.nixpkgs.lib.removeSuffix ".nix" n;
            value.imports = defaultModules ++ [
              ./hosts/${n}
            ];
          }) (builtins.readDir ./hosts))
        );
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = (import nixpkgs { inherit system; });
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          nativeBuildInputs = with pkgs; [
            colmena.packages.${system}.colmena
            deadnix
            nixfmt
            nixfmt-tree
          ];
        };
        formatter = pkgs.nixfmt-tree;
      }
    );
}
