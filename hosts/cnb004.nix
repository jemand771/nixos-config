{ pkgs, ... }:
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
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  # TODO security.pki.certificates (or certificateFiles, I guess)
  # TODO network shares (if I can get them to work)
  # TODO svp2 schroot config, or ignore and abandon? (build locally and just reference hardcoded path to avoid delays from IFD?)
}
