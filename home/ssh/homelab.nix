{ config, lib, ... }:
{
  options.jemand771.ssh.hostsets.homelab.enable = lib.mkEnableOption "ssh.hostsets.homelab";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.homelab.enable (
    builtins.listToAttrs (
      map
        (
          { name, ip }:
          {
            inherit name;
            value = {
              hostname = ip;
              user = "root";
            };
          }
        )
        [
          {
            name = "apt-cache";
            ip = "10.7.5.2";
          }
          {
            name = "syncthing-arbiter";
            ip = "10.7.5.3";
          }
          {
            name = "nix-cache";
            ip = "10.7.5.4";
          }
        ]
    )
  );
}
