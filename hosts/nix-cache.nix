{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/nix-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  system.stateVersion = "24.05";
}
