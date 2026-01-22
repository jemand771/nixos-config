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
        agenix
        home-manager
        plasma-manager
        nix-vscode-extensions
        nixpkgs-unstable-small
        flake-utils
        colmena
        microvm
        disko
        ;
    in
    {
      # TODO migrate these to colmena aswell
      # nixosConfigurations.proxmoxTest1 = import ./playground/proxmox.nix {
      #   inherit inputs;
      #   pkgs = import nixpkgs { system = "x86_64-linux"; };
      #   id = 1;
      # };
      # nixosConfigurations.proxmoxTest2 = import ./playground/proxmox.nix {
      #   inherit inputs;
      #   pkgs = import nixpkgs { system = "x86_64-linux"; };
      #   id = 2;
      # };
      # nixosConfigurations.proxmoxTest3 = import ./playground/proxmox.nix {
      #   inherit inputs;
      #   pkgs = import nixpkgs { system = "x86_64-linux"; };
      #   id = 3;
      # };
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
        in
        colmena.lib.makeHive {
          meta = {
            nixpkgs = import nixpkgs { system = "x86_64-linux"; };
            specialArgs = {
              inherit inputs;
            };
            allowApplyAll = false;
          };
          nixbox = {
            imports = defaultModules ++ [
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
            home-manager.users.willy.imports = [
              ./hardware/keyboard-user.nix
              {
                jemand771.desktopLagFix.enable = true;
                jemand771.ssh = {
                  enable = true;
                  hostsets = {
                    d39s.enable = true;
                    homelab.enable = true;
                  };
                };
              }
            ];
            jemand771.meta.personal-system = true;
            system.stateVersion = "23.11";
          };
          nixbook = {
            imports = defaultModules ++ [
              ./hosts/nixbook.nix
              ./hardware/nixbook.nix
              ./hardware/mouse.nix
              ./hardware/printer.nix
            ];
            jemand771.meta.personal-system = true;
            system.stateVersion = "24.05";
          };
          nixtique = {
            imports = defaultModules ++ [
              ./hosts/nixtique.nix
              ./hardware/nixtique.nix
              ./hardware/mouse.nix
            ];
            jemand771.meta.personal-system = true;
            home-manager.users.willy.imports = [
              {
                jemand771.ssh = {
                  enable = true;
                  hostsets = {
                    d39s.enable = true;
                    homelab.enable = true;
                  };
                };
              }
            ];
            system.stateVersion = "24.05";
          };
          nixbox2 = {
            imports = defaultModules ++ [
              ./hosts/nixbox2.nix
              ./hardware/nixbox2.nix
              ./hardware/mouse.nix
            ];
            jemand771.meta.personal-system = true;
            system.stateVersion = "24.05";
          };
          cnb004 = {
            imports = defaultModules ++ [
              ./hosts/cnb004.nix
            ];
            jemand771.wsl.enable = true;
            jemand771.dev-python.enable = true;
            jemand771.dev-infra.enable = true;
            jemand771.shell-utils.enable = true;
            jemand771.office-utils.enable = true;
            jemand771.home-manager.enable = true;
            home-manager.users.willy.imports = [
              {
                jemand771.ssh = {
                  enable = true;
                  hostsets = {
                    homelab.enable = true;
                    intenta.enable = true;
                  };
                };
              }
            ];
            system.stateVersion = "23.11";
          };
          # TODO for all LXCs: is this the right way to grab this thing?
          apt-cache = {
            imports = defaultModules ++ [
              ("${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix")
              ./software/apt-cache.nix
            ];
            deployment.tags = [ "homelab" ];
            jemand771.auto-upgrade.enable = true;
            system.stateVersion = "23.11";
          };
          syncthing-arbiter = {
            imports = defaultModules ++ [
              ("${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix")
            ];
            deployment.tags = [ "homelab" ];
            users.users.willy.isNormalUser = true;
            jemand771.syncthing.enable = true;
            jemand771.auto-upgrade.enable = true;
            system.stateVersion = "24.05";
          };
          nix-cache = {
            imports = defaultModules ++ [
              ("${nixpkgs}/nixos/modules/virtualisation/proxmox-lxc.nix")
              ./software/nix-cache.nix
            ];
            deployment.tags = [ "homelab" ];
            jemand771.auto-upgrade.enable = true;
            system.stateVersion = "24.05";
          };
        };
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
