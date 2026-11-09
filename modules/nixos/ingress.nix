{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.jemand771.ingress;
  id = lib.last (lib.splitString "." cfg.vip);
in
{
  options.jemand771.ingress = {
    enable = lib.mkEnableOption "VRRP + IPVS ingress";
    ip = lib.mkOption {
      type = lib.types.str;
      description = "own address on the interconnect network";
      example = "192.168.58.21";
    };
    prefixLength = lib.mkOption {
      type = lib.types.ints.between 0 32;
      description = "prefix length of the interconnect network";
      default = 24;
    };
    peer = lib.mkOption {
      type = lib.types.str;
      description = "peer's address on the interconnect network";
      example = "192.168.58.22";
    };
    vip = lib.mkOption {
      type = lib.types.str;
      description = "public address shared by the pair";
      example = "46.225.196.58";
    };
    primary = lib.mkOption {
      type = lib.types.bool;
      description = "whether this node should handle traffic initially (no preemption)";
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
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "tcp ports balanced across both nodes, services must listen on the vip (direct/forwarded) AND interconnect (healthcheck) address";
    };
    internalInterface = lib.mkOption {
      type = lib.types.str;
      description = "guest network nic";
      default = "enp5s0";
    };
    uplinkInterface = lib.mkOption {
      type = lib.types.str;
      description = "public network nic holding the vip";
      default = "enp6s0";
    };
    interconnectInterface = lib.mkOption {
      type = lib.types.str;
      description = "second public network nic for vrrp, ipvs sync, direct routing, vip return traffic";
      default = "enp7s0";
    };
  };

  config = lib.mkIf cfg.enable {
    jemand771.openssh.enable = true;
    jemand771.ingress.ports = [ 22 ];

    networking = {
      useNetworkd = true;
      useDHCP = false;
      nftables.enable = true;
      firewall = {
        trustedInterfaces = [ cfg.internalInterface ];
        allowedTCPPorts = cfg.ports;
        # ipvs sync daemon
        interfaces.${cfg.interconnectInterface}.allowedUDPPorts = [ 8848 ];
        # vip traffic arrives on the uplink (direct) or interconnect (forwarded) but always leaves via the interconnect
        checkReversePath = "loose";
        # notrack means icmp packets don't get associated to existing connections; explicitly allow
        extraInputRules = ''
          ip daddr ${cfg.vip} icmp type { destination-unreachable, time-exceeded } accept
        '';
      };
      nftables.tables.ingress =
        let
          ports = "{ ${lib.concatMapStringsSep ", " toString cfg.ports} }";
        in
        {
          family = "inet";
          content = ''
            chain prerouting {
              type filter hook prerouting priority raw;
              # replies from forwarded flows never come back through the forwarding node, don't attempt to track
              ip daddr ${cfg.vip} tcp dport ${ports} notrack
              # same for icmp (accepted via extraInputRules)
              ip daddr ${cfg.vip} icmp type { destination-unreachable, time-exceeded } notrack
            }
            chain output {
              type filter hook output priority raw;
              # don't track replies to untracked incoming connections on their way out
              ip saddr ${cfg.vip} tcp sport ${ports} notrack
            }
            chain balance {
              type filter hook prerouting priority mangle;
              # mark connections from the internet (but not peer's forwarded ones) to prevent forwarding loops
              iifname "${cfg.uplinkInterface}" ip daddr ${cfg.vip} tcp dport ${ports} meta mark set tcp dport
            }
          '';
        };
    };

    boot.kernelModules = [ "ip_vs" ];
    boot.kernel.sysctl = {
      # only answer arp from interfaces that actually hold the vip (uplink on primary)
      # (otherwise both primary and backup reply from both uplink and interconnect)
      "net.ipv4.conf.all.arp_ignore" = 1;
      # arp requests _from_ the vip would make everyone believe the sending mac has the vip, so don't do that
      # (use interconnect address instead)
      "net.ipv4.conf.all.arp_announce" = 2;
      # immediately flush local connections when keepalived leaves ipvs
      "net.ipv4.vs.expire_nodest_conn" = 1;
      # sync connections more aggressively
      "net.ipv4.vs.sync_threshold" = "0 0";
      "net.ipv4.vs.sync_refresh_period" = 60;
    };

    environment.systemPackages = [ pkgs.ipvsadm ];

    systemd.network.networks = {
      "10-lo" = {
        matchConfig.Name = "lo";
        # vip is a real ip locally for incoming forwarded connections even when the other node is the primary
        # (don't advertise (see above), since that would cause conflicts)
        address = [ "${cfg.vip}/32" ];
      };
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
        # we want "unknown" traffic to get to us (the vip on lo) after the vip moves away.
        # (note: even loose mode drops traffic on an interface with no IP, i.e. the backup)
        networkConfig.IPv4ReversePathFilter = "no";
        # hetzner vSwitch mtu limit
        linkConfig.MTUBytes = "1400";
        linkConfig.RequiredForOnline = "carrier";
      };
      "10-interconnect" = {
        matchConfig.Name = cfg.interconnectInterface;
        address = [ "${cfg.ip}/${toString cfg.prefixLength}" ];
        networkConfig.LinkLocalAddressing = "no";
        # hetzner vSwitch
        linkConfig.MTUBytes = "1400";
        linkConfig.RequiredForOnline = "routable";
        # default route hits ovn port security (and rightfully so) for vip return traffic
        routes = [
          # uplink is directly reachable via the vSwitch, because both bridge to incus' public net
          {
            Destination = cfg.uplink.subnet;
            Table = 100;
          }
          # new default route
          {
            Gateway = cfg.uplink.gateway;
            Table = 100;
          }
        ];
        routingPolicyRules = [
          # match only vip return traffic
          {
            From = cfg.vip;
            Table = 100;
            Priority = 100;
          }
        ];
      };
    };

    services.keepalived = {
      enable = true;
      openFirewall = true;
      extraGlobalDefs = ''
        lvs_sync_daemon ${cfg.interconnectInterface} vip-${id} id ${id} maxlen 1372
        # has to be higher than the kernel's tcp keepalive (2h)
        lvs_timeouts tcp 7500
      '';
      vrrpInstances."vip-${id}" = {
        interface = cfg.interconnectInterface;
        state = "BACKUP";
        noPreempt = true;
        priority = if cfg.primary then 150 else 100;
        virtualRouterId = lib.toInt id;
        unicastSrcIp = cfg.ip;
        unicastPeers = [ cfg.peer ];
        virtualIps = [
          {
            addr = "${cfg.vip}/${lib.last (lib.splitString "/" cfg.uplink.subnet)}";
            dev = cfg.uplinkInterface;
          }
        ];
        # sub-second adverts need vrrpv3
        extraConfig = ''
          version 3
          advert_int 0.1
          check_unicast_src
        '';
        trackFiles = [ "vip-drain" ];
      };
      # FAULT moves the vip but, unlike stopping keepalived, keeps ipvs forwarding
      vrrpTrackFiles."vip-drain" = {
        file = "/run/keepalived/vip-drain";
        weight = 0;
        init = {
          value = 0;
          overwrite = true;
        };
      };
      extraConfig = lib.concatMapStringsSep "\n" (
        port:
        let
          # inhibit: set weight to 0 (keep existing connections) instead of removing the server (closing all connections)
          # this feels a bit backwards but ensures we can gracefully drain.
          # a service that's actually down (but keeps getting traffic) will close (or not accept) connections on its own,
          # at which new connections no longer get routed to it
          realServer = address: ''
            real_server ${address} {
              inhibit_on_failure
              TCP_CHECK {
                connect_port ${toString port}
                connect_timeout 1
              }
            }
          '';
        in
        # balance only marked packets (coming directly from the internet)
        # ((unmarked means it got forwarded to us by the other node))
        ''
          virtual_server fwmark ${toString port} {
            delay_loop 1
            lvs_sched wlc
            lvs_method DR
            ${realServer cfg.ip}
            ${realServer cfg.peer}
          }
        ''
      ) cfg.ports;
    };

    # stopping keepalived removes its ipvs services (bad), so hand the vip over first
    systemd.services.keepalived.serviceConfig.ExecStop = pkgs.writeShellScript "keepalived-vip-drain" ''
      [ -n "$MAINPID" ] || exit 0
      [ -n "$(${pkgs.iproute2}/bin/ip -o addr show dev ${cfg.uplinkInterface} to ${cfg.vip})" ] || exit 0
      echo 1 > ${config.services.keepalived.vrrpTrackFiles."vip-drain".file}
      sleep 2
    '';
  };
}
