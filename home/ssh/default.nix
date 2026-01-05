{ config, lib, options, ... }:
{
  imports = [
    ./d39s.nix
    ./homelab.nix
    ./intenta.nix
  ];
  options.jemand771.ssh.enable = lib.mkEnableOption "ssh";
  config.programs.ssh = lib.mkIf config.jemand771.ssh.enable {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "bitbucket.org" = {
        identityFile = "~/.ssh/id_bitbucket";
      };
      "github.com" = {
        identityFile = "~/.ssh/id_github";
      };
    };
  };
}
