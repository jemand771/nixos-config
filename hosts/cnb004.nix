{ pkgs, self, ... }:
{
  # TODO this would like to be somewhere else
  networking.hostName = "cnb004";
  users.users.willy.extraGroups = [
    "docker"
    "dialout"
    "libvirtd"
  ];
  services.jenkins = {
    enable = true;
    port = 8040;
    plugins = pkgs.jenkins.withPlugins (
      with pkgs.jenkins.plugins;
      [
        ansicolor
        configuration-as-code
        dark-theme
        git
        pipeline-graph-view
        timestamper
        workflow-aggregator
      ]
    );
  };
  virtualisation.docker = {
    enable = true;
    daemon.settings.features.containerd-snapshotter = true;
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  virtualisation.podman.enable = true;
  boot.binfmt = {
    emulatedSystems = [
      "aarch64-linux"
      "armv7l-linux"
    ];
    preferStaticEmulators = true;
  };
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  security.pki.certificateFiles = [
    ../certs/intenta-root01.crt
    ../certs/intenta-sub01.crt
  ];
  # TODO network shares (if I can get them to work)
  # TODO svp2 schroot config, or ignore and abandon? (build locally and just reference hardcoded path to avoid delays from IFD?)
  # TODO warning, dangerous and ugly, see https://github.com/NixOS/nixpkgs/issues/30723
  nix.settings.extra-sandbox-paths = [ "/docker-auth.json" ];
  zramSwap.enable = true;
  environment.systemPackages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.play
  ];

  # no openssh here, so specify whatever it would do manually
  age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  age.secrets.intenta-jenkins-mcp-auth = {
    file = ../secrets/intenta-jenkins-mcp-auth.age;
    owner = "willy";
  };

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
      jemand771.ai.enable = true;
    }
  ];
  system.stateVersion = "23.11";
}
