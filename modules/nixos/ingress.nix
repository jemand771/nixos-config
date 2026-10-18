{
  lib,
  config,
  ...
}:
let
  cfg = config.jemand771.ingress;
  prefixLength = lib.last (lib.splitString "/" cfg.uplink.subnet);
  # last octet doubles as vrid and routing table id
  id = lib.last (lib.splitString "." cfg.vip);
in
{
  options.jemand771.ingress = {
    enable = lib.mkEnableOption "VRRP ingress";
    ip = lib.mkOption {
      type = lib.types.str;
      description = "own address on the guest network";
      example = "10.6.0.21";
    };
    peer = lib.mkOption {
      type = lib.types.str;
      description = "peer's address on the guest network";
      example = "10.6.0.22";
    };
    vip = lib.mkOption {
      type = lib.types.str;
      description = "public address shared by the pair";
      example = "46.225.196.58";
    };
    primary = lib.mkOption {
      type = lib.types.bool;
      description = "whether this node should handle traffic if both are healthy";
      default = false;
    };
    uplink = {
      subnet = lib.mkOption {
        type = lib.types.str;
        description = "public subnet the vip lives in";
        example = "46.225.196.56/29";
      };
      gateway = lib.mkOption {
        type = lib.types.str;
        description = "gateway for vip return traffic";
        example = "46.225.196.57";
      };
    };
    internalInterface = lib.mkOption {
      type = lib.types.str;
      description = "guest network nic";
      default = "enp5s0";
    };
    uplinkInterface = lib.mkOption {
      type = lib.types.str;
      description = "public network nic";
      default = "enp6s0";
    };
  };

  config = lib.mkIf cfg.enable {
    jemand771.openssh.enable = true;

    networking = {
      useNetworkd = true;
      useDHCP = false;
      firewall.trustedInterfaces = [ cfg.internalInterface ];
    };

    systemd.network.networks = {
      "10-internal" = {
        matchConfig.Name = cfg.internalInterface;
        networkConfig.DHCP = "yes";
        # networkd by default ignores the (correct) mtu ovn hands out
        dhcpV4Config.UseMTU = true;
        linkConfig.RequiredForOnline = "routable";
      };
      "10-uplink" = {
        matchConfig.Name = cfg.uplinkInterface;
        networkConfig.LinkLocalAddressing = "no";
        # hetzner vSwitch mtu limit
        linkConfig.MTUBytes = "1400";
        linkConfig.RequiredForOnline = "carrier";
      };
    };

    services.keepalived = {
      enable = true;
      vrrpInstances."vip-${id}" = {
        interface = cfg.internalInterface;
        state = if cfg.primary then "MASTER" else "BACKUP";
        priority = if cfg.primary then 150 else 100;
        virtualRouterId = lib.toInt id;
        unicastSrcIp = cfg.ip;
        unicastPeers = [ cfg.peer ];
        virtualIps = [
          {
            addr = "${cfg.vip}/${prefixLength}";
            dev = cfg.uplinkInterface;
          }
        ];
        # default route (guest nic) would get stuck on ovn port security
        extraConfig = ''
          virtual_routes {
            ${cfg.uplink.subnet} dev ${cfg.uplinkInterface} scope link table ${id}
            default via ${cfg.uplink.gateway} dev ${cfg.uplinkInterface} table ${id}
          }
          virtual_rules {
            from ${cfg.vip} table ${id} preference ${id}
          }
        '';
      };
    };
  };
}
