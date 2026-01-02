{ config, lib, options, ... }:
{
  options.jemand771.ssh.hostsets.intenta.enable = lib.mkEnableOption "ssh.hostsets.intenta";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.intenta.enable {
    "*.intop01.de" = {
      user = "root";
      identityFile = "~/.ssh/id_seinf";
    };
    # TODO import more stuff
  };
}
