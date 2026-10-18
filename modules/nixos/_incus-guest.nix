{ modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/incus-virtual-machine.nix" ];

  # lxc-instance-common.nix
  system.installer.channel.enable = false;
}
