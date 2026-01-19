{ config, pkgs, osConfig, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = if osConfig.networking.hostName == "cnb004" then {
        name = "Willy Hille";
        email = "willy.hille@intenta.de";
      } else {
        name = "Willy";
        email = "jemand771@gmx.net";
      };
      push = {
        autoSetupRemote = true;
        submodule.recurse = true;
        pull.rebase = true;
      };
    };
    ignores = [
      ".venv"
      ".direnv"
      ".envrc"
      "__pycache__"
    ];
  };

  # TODO htop's own config menu can still overwrite (delete and recreate) this file - how to prevent this?
  programs.htop.enable = true;
  programs.htop.settings = {
    hide_userland_threads = 1;
  };

  programs.vscode.enable = true;
  programs.vscode.profiles.default.userSettings = {
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
    "editor.fontFamily" = "JetBrainsMono Nerd Font";
    "editor.fontLigatures" = true;
    "editor.fontSize" = 15;
    "extensions.ignoreRecommendations" = true;
    "git.openRepositoryInParentFolders" = "always";
    "update.mode" = "none";
    "python.analysis.typeCheckingMode" = "strict";
    "gitlens.plusFeatures.enabled" = false;
    "[python]" = {
      "editor.defaultFormatter" = "charliermarsh.ruff";
    };
    "diffEditor.ignoreTrimWhitespace" = false;
    "workbench.secondarySideBar.defaultVisibility" = "hidden";
    "files.exclude" = {
      "**/.direnv" = true;
      "**/__pycache__" = true;
    };
    "java.jdt.ls.java.home" = pkgs.javaPackages.compiler.openjdk25;
    "vscode-pets.petSize" = "medium";
    "vscode-pets.throwBallWithMouse" = true;
    "vscode-pets.theme" = "winter";
  };
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.profiles.default.extensions = with pkgs.vscode-marketplace; [
    ms-python.python
    bbenoist.nix
    opentofu.vscode-opentofu
    redhat.vscode-yaml
    ms-azuretools.vscode-docker
    editorconfig.editorconfig
    astro-build.astro-vscode
    mkhl.direnv
    unifiedjs.vscode-mdx
    puppet.puppet-vscode
    pkgs.vscode-marketplace-release.eamodio.gitlens
    twxs.cmake
    tamasfe.even-better-toml
    hashicorp.hcl
    pkgs.vscode-extensions.ms-vscode.cpptools
    platformio.platformio-ide
    marlinfirmware.auto-build
    ms-vsliveshare.vsliveshare
    ms-kubernetes-tools.vscode-kubernetes-tools
    ms-python.vscode-pylance
    ms-vscode-remote.remote-containers
    grafana.vscode-jsonnet
    harrydowning.yaml-embedded-languages
    golang.go
    redhat.java
    vscjava.vscode-maven
    vscjava.vscode-java-debug
    vscjava.vscode-java-test
    vscjava.vscode-gradle
    ms-vscode.cmake-tools
    bierner.markdown-mermaid
    samuelcolvin.jinjahtml
    charliermarsh.ruff
    ms-python.black-formatter
    ms-python.mypy-type-checker
    pkgs.vscode-extensions.github.copilot
    pkgs.vscode-extensions.github.copilot-chat
    buenon.scratchpads
    # tonybaloney.vscode-pets
    (pkgs.callPackage ./vscode-pets.nix { })
    mechatroner.rainbow-csv
  ];

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
    settings = {
      gcloud.disabled = true;
      kubernetes = {
        disabled = false;
        detect_env_vars = [ "STARSHIP_KUBERNETES" ];
      };
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      custom.chroot = {
        command = "cat /etc/debian_chroot";
        when = "test -f /etc/debian_chroot";
        format = "chroot [$output]($style) ";
      };
    };
  };
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}
