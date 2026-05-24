{ config, lib, ... }:
{
  options.jemand771.ssh.hostsets.cloudlab.enable = lib.mkEnableOption "ssh.hostsets.cloudlab";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.cloudlab.enable (
    builtins.listToAttrs (
      map
        (
          { name, ip }:
          {
            inherit name;
            value = {
              hostname = ip;
              user = "willy";
              identityFile = "~/.ssh/id_servers";
            };
          }
        )
        [
          {
            name = "quaver";
            ip = "178.105.206.248";
          }
          {
            name = "treble";
            ip = "88.99.147.182";
          }
          {
            name = "clef";
            ip = "88.99.66.165";
          }
        ]
    )
  );
}
