{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
  ];
  deployment.tags = [ "homelab" ];
  users.users.willy.isNormalUser = true;
  jemand771.syncthing.enable = true;
  system.stateVersion = "24.05";
}
