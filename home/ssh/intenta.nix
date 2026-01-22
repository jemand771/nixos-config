{ config, lib, ... }:
{
  options.jemand771.ssh.hostsets.intenta.enable = lib.mkEnableOption "ssh.hostsets.intenta";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.intenta.enable {
    "*.intop01.de" = {
      user = "root";
      identityFile = "~/.ssh/id_seinf";
    };
    "sftp.intenta.de" = {
      user = "wihi";
      identityFile = "~/.ssh/id_sftp";
    };
    "sfgz001.intop01.de" = lib.hm.dag.entryBefore [ "*.intop01.de" ] {
      user = "wihi";
    };
    "sstrint001.intop01.de" = lib.hm.dag.entryBefore [ "*.intop01.de" ] {
      user = "adm_wihi";
    };
    rms = {
      user = "root";
      hostname = "rms.intenta.de";
      identityFile = "~/.ssh/id_rms";
    };
    rd3 = {
      user = "ubuntu";
      hostname = "10.153.12.113";
      identityFile = "~/.ssh/id_rd";
    };
    rd1r = {
      user = "ubuntu";
      hostname = "localhost";
      port = 22118;
      identityFile = "~/.ssh/id_rd";
      proxyJump = "rms";
    };
    rd4r = {
      user = "ubuntu";
      hostname = "localhost";
      port = 22193;
      identityFile = "~/.ssh/id_rd";
      proxyJump = "rms";
    };
    nbptpm = {
      user = "adm_wihi";
      hostname = "217.160.252.63";
      identityFile = "~/.ssh/id_nbptp";
    };
    nbptpi = {
      user = "adm_wihi";
      hostname = "10.7.224.11";
      proxyJump = "nbptpm";
      identityFile = "~/.ssh/id_nbptp";
    };
    nbptpo = {
      user = "adm_wihi";
      hostname = "10.7.224.13";
      proxyJump = "nbptpm";
      identityFile = "~/.ssh/id_nbptp";
    };
    "192.168.122.*" = {
      user = "root";
      identityFile = "~/.ssh/id_virt-manager";
    };
  };
}
