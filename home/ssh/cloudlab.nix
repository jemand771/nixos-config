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
          cin-vip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMoeTuadW1+Y8ULAD6DiP5HOKjj6YbxCntuv6Yhc1I9F root@cina
          cin-vip ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKinQVMx3tb+i4NlR3Vhoxqt8yLqWLFjIQeW0VgxH16T root@cinb
        ''}";
      };
    }
    // builtins.listToAttrs (
      map
        (name: {
          inherit name;
          value = {
            user = "willy";
            identityFile = "~/.ssh/id_cloudlab";
            proxyJump = "cin-vip";
          };
        })
        [
          "cina"
          "cinb"
        ]
    )
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
