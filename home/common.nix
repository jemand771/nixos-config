{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Willy";
    userEmail = "jemand771@gmx.net";
    extraConfig = {
      push = {
        autoSetupRemote = true;
      };
    };
    ignores = [
      ".venv"
      ".direnv"
      ".envrc"
    ];
  };

  # TODO htop's own config menu can still overwrite (delete and recreate) this file - how to prevent this?
  programs.htop.enable = true;
  programs.htop.settings = {
    hide_userland_threads = 1;
  };

  programs.vscode.enable = true;
  programs.vscode.userSettings = {
    "files.simpleDialog.enable" = true;
    "git.autofetch" = true;
    "git.confirmSync" = false;
    "git.enableSmartCommit" = true;
    "explorer.confirmDelete" = false;
    "workbench.startupEditor" = "none";
    "gitlens.showWelcomeOnInstall" = false;
    "explorer.confirmDragAndDrop" = false;
    "vs-kubernetes" = {
      "vs-kubernetes.crd-code-completion" = "enabled";
    };
    "platformio-ide.useBuiltinPIOCore" = false;
  };
  # TODO enable me when cpp extension is available again
  # programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions = with pkgs.vscode-marketplace; [
    ms-python.python
    bbenoist.nix
    gamunu.opentofu
    redhat.vscode-yaml
    ms-azuretools.vscode-docker
    editorconfig.editorconfig
    astro-build.astro-vscode
    mkhl.direnv
    unifiedjs.vscode-mdx
    # ms-vscode.cpptools
    platformio.platformio-ide
    marlinfirmware.auto-build
  ];

  programs.ssh = {
    enable = true;
    matchBlocks =
      {
        "github.com" = {
          identityFile = "~/.ssh/id_github";
        };
        # not part of the magic loop below because of special proxyJump
        "d39s-sxlh" = {
          hostname = "10.0.2.4";
          user = "root";
          identityFile = "~/.ssh/id_d39s";
          proxyJump = "d39s-sx";
        };
        "d39s-wp-shopdata" = {
          hostname = "10.0.121.50";
          user = "root";
          identityFile = "~/.ssh/id_d39s";
          port = 30022;
        };
      }
      // builtins.listToAttrs (
        map
          (
            { name, ip }:
            {
              inherit name;
              value = {
                hostname = ip;
                user = "root";
              };
            }
          )
          [
            {
              name = "apt-cache";
              ip = "10.7.5.2";
            }
            {
              name = "syncthing-arbiter";
              ip = "10.7.5.3";
            }
            {
              name = "nix-cache";
              ip = "10.7.5.4";
            }
          ]
      )
      // builtins.listToAttrs (
        map
          (
            { name, ip }:
            {
              name = "d39s-${name}";
              value = {
                hostname = ip;
                user = "root";
                identityFile = "~/.ssh/id_d39s";
              };
            }
          )
          [
            {
              name = "old";
              ip = "138.201.134.54";
            }
            {
              name = "sx";
              ip = "88.99.58.198";
            }
            {
              name = "sxvm";
              ip = "88.99.58.196";
            }
            {
              name = "spg";
              ip = "168.119.251.136";
            }
            {
              name = "innung";
              ip = "159.69.35.76";
            }
            {
              name = "buildbox";
              ip = "95.217.233.49";
            }
            {
              name = "jitsi";
              ip = "49.13.22.182";
            }
            {
              name = "control-1";
              ip = "162.55.169.122";
            }
            {
              name = "control-2";
              ip = "167.235.242.88";
            }
            {
              name = "control-3";
              ip = "5.75.226.245";
            }
            {
              name = "worker-1";
              ip = "78.46.237.164";
            }
            {
              name = "worker-2";
              ip = "167.235.229.191";
            }
            {
              name = "worker-3";
              ip = "168.119.96.92";
            }
            {
              name = "worker-4";
              ip = "5.75.242.73";
            }
            {
              name = "wp-control-1";
              ip = "49.12.78.242";
            }
            {
              name = "wp-control-2";
              ip = "195.201.20.201";
            }
            {
              name = "wp-control-3";
              ip = "116.203.99.54";
            }
            {
              name = "wp-worker-4";
              ip = "188.245.68.87";
            }
            {
              name = "wp-worker-5";
              ip = "49.13.230.248";
            }
            {
              name = "wp-worker-6";
              ip = "188.245.174.105";
            }
            {
              name = "wp-worker-7";
              ip = "188.245.174.104";
            }
            {
              name = "wp-worker-9";
              ip = "49.13.237.69";
            }
            {
              name = "wp-worker-10";
              ip = "188.245.187.252";
            }
          ]
      );
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
    shellAbbrs = {
      k = "kubectl";
      kc = "kubectl config use-context";
      kn = "kubectl config set-context --current --namespace";
    };
  };
  programs.starship = {
    enable = true;
    package = pkgs.unstable.starship;
    settings = {
      gcloud.disabled = true;
      kubernetes = {
        disabled = false;
        detect_env_vars = [ "STARSHIP_KUBERNETES" ];
      };
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
