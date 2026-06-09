{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
  ];
  deployment.tags = [ "homelab" ];
  jemand771.syncthing.enable = true;
  system.stateVersion = "24.05";
}
