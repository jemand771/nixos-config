{
  description = "Willy's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.darwin.follows = "";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-unstable = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";
    nixpkgs-patch-vencord = {
      url = "https://github.com/NixOS/nixpkgs/pull/422168.diff";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      agenix,
      home-manager,
      home-manager-unstable,
      plasma-manager,
      nix-vscode-extensions,
      nix-minecraft,
      nix-vanillatweaks,
      flake-utils,
      colmena,
      microvm,
      disko,
      nixpkgs-patcher,
      ...
    }:
    let
      nixosSystem =
        {
          modules ? [ ],
          homeModules ? [ ],
          system ? "x86_64-linux",
          stateVersion,
          nixpkgs ? inputs.nixpkgs,
          home-manager ? inputs.home-manager
        }:
        nixpkgs-patcher.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          nixpkgsPatcher.inputs = inputs;
          nixpkgsPatcher.nixpkgs = nixpkgs;
          modules = [
            {
              nixpkgs.overlays = [
                # make unstable packages available as pkgs.unstable
                (_: prev: ({
                  unstable = import inputs.nixpkgs-unstable {
                    config.allowUnfree = true;
                    inherit (prev.stdenv.hostPlatform) system;
                  };
                  unstable-small = import inputs.nixpkgs-unstable-small {
                    config.allowUnfree = true;
                    inherit (prev.stdenv.hostPlatform) system;
                  };
                }))
                nix-vscode-extensions.overlays.default
              ];
            }
            ./meta-options.nix
            ./home/options.nix
            home-manager.nixosModules.home-manager
            (
              { config, ... }:
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
              }
            )
            ./nix-tools.nix
            ./software/basics.nix
            ./software/locale.nix
            ./software/shell-utils.nix
            ./software/office-utils.nix
            ./software/dev-infra.nix
            ./software/dev-python.nix
            ./software/gaming.nix
            ./software/auto-upgrade.nix
            ./sync.nix
            ./software/ssh-access.nix
            disko.nixosModules.disko
            { system = { inherit stateVersion; }; }
          ] ++ modules;
          # https://github.com/zhaofengli/colmena/issues/60#issuecomment-1047199551
          extraModules = [ colmena.nixosModules.deploymentOptions ];
        };
    in
    {
      nixosConfigurations.nixbox = nixosSystem {
        nixpkgs = nixpkgs-unstable;
        home-manager = home-manager-unstable;
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
          ./hardware/printer.nix
          ./mounts.nix
          ./playground/minecraft.nix
          microvm.nixosModules.host
          ./playground/vms.nix
        ];
        homeModules = [
          ./hardware/keyboard-user.nix
          {
            jemand771.desktopLagFix.enable = true;
          }
        ];
        stateVersion = "23.11";
      };
      nixosConfigurations.nixbook = nixosSystem {
        nixpkgs = nixpkgs-unstable;
        home-manager = home-manager-unstable;
        modules = [
          {
            jemand771.meta.personal-system = true;
          }
          ./hosts/nixbook.nix
          ./hardware/nixbook.nix
          ./hardware/mouse.nix
          ./hardware/printer.nix
        ];
        stateVersion = "24.05";
      };
      nixosConfigurations.nixtique = nixosSystem {
        nixpkgs = nixpkgs-unstable;
        home-manager = home-manager-unstable;
        modules = [
          {
            jemand771.meta.personal-system = true;
          }
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
        nixpkgs = nixpkgs-unstable;
        home-manager = home-manager-unstable;
        modules = [
          {
            jemand771.meta.personal-system = true;
          }
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
            deployment.tags = [ "homelab" ];
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
            deployment.tags = [ "homelab" ];
            users.users.willy.isNormalUser = true;
            jemand771.syncthing.enable = true;
            jemand771.auto-upgrade.enable = true;
          }
        ];
        stateVersion = "24.05";
      };
      nixosConfigurations.nix-cache = nixosSystem {
        modules = [
          # TODO this is probably bad, how to modulesPath ?
          ("${inputs.nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix")
          ./software/nix-cache.nix
          {
            deployment.tags = [ "homelab" ];
            jemand771.auto-upgrade.enable = true;
          }
        ];
        stateVersion = "24.05";
      };
      nixosConfigurations.proxmoxTest1 = import ./playground/proxmox.nix { inherit inputs; pkgs = import nixpkgs { system = "x86_64-linux"; }; id = 1; };
      nixosConfigurations.proxmoxTest2 = import ./playground/proxmox.nix { inherit inputs; pkgs = import nixpkgs { system = "x86_64-linux"; }; id = 2; };
      nixosConfigurations.proxmoxTest3 = import ./playground/proxmox.nix { inherit inputs; pkgs = import nixpkgs { system = "x86_64-linux"; }; id = 3; };
      colmenaHive = colmena.lib.makeHive (
        {
          meta = {
            # TODO how to make this work on whatever system you're running this from?
            nixpkgs = (import nixpkgs { system = "x86_64-linux"; });
            nodeNixpkgs = builtins.mapAttrs (name: value: value.pkgs) self.nixosConfigurations;
            nodeSpecialArgs = builtins.mapAttrs (
              name: value: value._module.specialArgs
            ) self.nixosConfigurations;
            allowApplyAll = false;
          };
        }
        // builtins.mapAttrs (name: value: {
          imports = value._module.args.modules;
        }) self.nixosConfigurations
      );
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            colmena.packages.${system}.colmena
          ];
        };
        formatter = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
      }
    );
}
