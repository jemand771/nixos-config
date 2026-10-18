{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.jemand771.ssh.hostsets.cloudlab.enable = lib.mkEnableOption "ssh.hostsets.cloudlab";
  config.programs.ssh.settings = lib.mkIf config.jemand771.ssh.hostsets.cloudlab.enable (
    {
      "cin-vip" = {
        hostname = "46.225.196.58";
        user = "willy";
        identityFile = "~/.ssh/id_cloudlab";
        hostKeyAlias = "cin-vip";
        userKnownHostsFile = "${pkgs.writeText "cin-vip-known-hosts" ''
          cin-vip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILCbPNTcfYaNK14fuECGIyfN05LujS11pU7sXJ2Ztr9y root@cina
          cin-vip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqlR+E85FcrI56Ed15u1bhl9/FDFjTTMlwKKpPJY+eU root@cinb
        ''}";
      };
      "cina" = {
        hostname = "10.6.0.21";
        user = "willy";
        identityFile = "~/.ssh/id_cloudlab";
        proxyJump = "cin-vip";
      };
      "cinb" = {
        hostname = "10.6.0.22";
        user = "willy";
        identityFile = "~/.ssh/id_cloudlab";
        proxyJump = "cin-vip";
      };
    }
    // builtins.listToAttrs (
      map
        (
          { name, ip }:
          {
            inherit name;
            value = {
              hostname = ip;
              user = "willy";
              identityFile = "~/.ssh/id_cloudlab";
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
