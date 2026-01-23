{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/apt-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  jemand771.auto-upgrade.enable = true;
  system.stateVersion = "23.11";
}
