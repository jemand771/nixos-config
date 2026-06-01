{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/apt-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  system.stateVersion = "23.11";
}
