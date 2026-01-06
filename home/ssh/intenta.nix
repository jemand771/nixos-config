{ config, lib, options, ... }:
{
  options.jemand771.ssh.hostsets.intenta.enable = lib.mkEnableOption "ssh.hostsets.intenta";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.intenta.enable {
    "*.intop01.de" = {
      user = "root";
      identityFile = "~/.ssh/id_seinf";
    };
    "sstrint001.intop01.de" = lib.hm.dag.entryBefore [ "*.intop01.de" ] {
      user = "adm_wihi";
    };
    # TODO import more stuff
  };
}
