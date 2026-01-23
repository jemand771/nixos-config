{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/nix-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  jemand771.auto-upgrade.enable = true;
  system.stateVersion = "24.05";
}
