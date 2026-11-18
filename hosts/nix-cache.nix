{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/nix-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  jemand771.user.sshKeyset = "homelab";
  system.stateVersion = "24.05";
}
