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
  };
  programs.vscode.extensions = with pkgs.vscode-marketplace; [
    ms-python.python
    bbenoist.nix
    gamunu.opentofu
    redhat.vscode-yaml
    ms-azuretools.vscode-docker
    editorconfig.editorconfig
    astro-build.astro-vscode
    mkhl.direnv
  ];

  programs.ssh = {
    enable = true;
    matchBlocks = {
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
    } // builtins.listToAttrs ( map ( { name, ip }: {
      name = "d39s-${name}";
      value = {
        hostname = ip;
        user = "root";
        identityFile = "~/.ssh/id_d39s";
      };
    } ) [
      { name = "old"; ip = "138.201.134.54"; }
      { name = "sx"; ip = "88.99.58.198"; }
      { name = "sxvm"; ip = "88.99.58.196"; }
      { name = "spg"; ip = "168.119.251.136"; }
      { name = "innung"; ip = "159.69.35.76"; }
      { name = "buildbox"; ip = "95.217.233.49"; }
      { name = "control-1"; ip = "162.55.169.122"; }
      { name = "control-2"; ip = "167.235.242.88"; }
      { name = "control-3"; ip = "5.75.226.245"; }
      { name = "worker-1"; ip = "78.46.237.164"; }
      { name = "worker-2"; ip = "167.235.229.191"; }
      { name = "worker-3"; ip = "168.119.96.92"; }
      { name = "worker-4"; ip = "5.75.242.73"; }
      { name = "wp-control-1"; ip = "49.12.78.242"; }
      { name = "wp-control-2"; ip = "195.201.20.201"; }
      { name = "wp-control-3"; ip = "116.203.99.54"; }
      { name = "wp-worker-1"; ip = "157.90.160.195"; }
      { name = "wp-worker-2"; ip = "49.13.237.69"; }
      { name = "wp-worker-3"; ip = "128.140.97.2"; }
    ]);
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
    '';
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
  programs.direnv.enable = true;

  programs.home-manager.enable = true;
}
