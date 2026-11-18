{ modulesPath, ... }:
{
  imports = [
    ("${modulesPath}/virtualisation/proxmox-lxc.nix")
    ../software/apt-cache.nix
  ];
  deployment.tags = [ "homelab" ];
  jemand771.user.sshKeyset = "homelab";
  system.stateVersion = "23.11";
}
