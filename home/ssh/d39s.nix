{ config, lib, options, ... }:
{
  options.jemand771.ssh.hostsets.d39s.enable = lib.mkEnableOption "ssh.hostsets.d39s";
  config.programs.ssh.matchBlocks = lib.mkIf config.jemand771.ssh.hostsets.d39s.enable {
    "gl.hanwis.com" = {
      identityFile = "~/.ssh/id_hanwis";
    };
    # not part of the magic loop below because of special proxyJump
    "d39s-sxlh" = {
      hostname = "10.0.2.4";
      user = "root";
      identityFile = "~/.ssh/id_d39s";
      proxyJump = "d39s-sx";
    };
    "d39s-wp-shopdata" = {
      hostname = "10.0.121.50";
      user = "root";
      identityFile = "~/.ssh/id_d39s";
      port = 30022;
    };
  }
  // builtins.listToAttrs (
    map
      (
        { name, ip }:
        {
          name = "d39s-${name}";
          value = {
            hostname = ip;
            user = "root";
            identityFile = "~/.ssh/id_d39s";
          };
        }
      )
      [
        {
          name = "old";
          ip = "138.201.134.54";
        }
        {
          name = "sx";
          ip = "88.99.58.198";
        }
        {
          name = "sxvm";
          ip = "88.99.58.196";
        }
        {
          name = "spg";
          ip = "168.119.251.136";
        }
        {
          name = "innung";
          ip = "159.69.35.76";
        }
        {
          name = "buildbox";
          ip = "95.217.233.49";
        }
        {
          name = "jitsi";
          ip = "49.13.22.182";
        }
        {
          name = "control-1";
          ip = "162.55.169.122";
        }
        {
          name = "control-2";
          ip = "167.235.242.88";
        }
        {
          name = "control-3";
          ip = "5.75.226.245";
        }
        {
          name = "worker-1";
          ip = "78.46.237.164";
        }
        {
          name = "worker-2";
          ip = "167.235.229.191";
        }
        {
          name = "worker-3";
          ip = "168.119.96.92";
        }
        {
          name = "worker-4";
          ip = "5.75.242.73";
        }
        {
          name = "wp-control-1";
          ip = "49.12.78.242";
        }
        {
          name = "wp-control-2";
          ip = "195.201.20.201";
        }
        {
          name = "wp-control-3";
          ip = "116.203.99.54";
        }
        {
          name = "wp-worker-4";
          ip = "188.245.68.87";
        }
        {
          name = "wp-worker-5";
          ip = "49.13.230.248";
        }
        {
          name = "wp-worker-6";
          ip = "188.245.174.105";
        }
        {
          name = "wp-worker-7";
          ip = "188.245.174.104";
        }
        {
          name = "wp-worker-9";
          ip = "49.13.237.69";
        }
        {
          name = "wp-worker-10";
          ip = "188.245.187.252";
        }
        {
          name = "wp-worker-11";
          ip = "128.140.114.98";
        }
        {
          name = "wp-worker-12";
          ip = "91.99.237.177";
        }
        {
          name = "wp-worker-13";
          ip = "138.199.198.46";
        }
        {
          name = "wp-worker-14";
          ip = "91.98.122.212";
        }
        {
          name = "data-exchange";
          ip = "91.99.223.24";
        }
      ]
  );
}
