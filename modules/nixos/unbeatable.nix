# I know it's not very creative, and I've complained about people using "fancy" hostnames instead of just counting upwards before,
# but I was obsessed with this game when I sketched this. for lack of better names, might aswell embrace this
{
  lib,
  config,
  ...
}:
{
  options.jemand771.unbeatable = {
    enable = lib.mkEnableOption "base configs for my hetzner cluster";
    isCloud = lib.mkOption {
      type = lib.types.bool;
      description = "is this a hcloud node? (as opposed to a dedi (default))";
      default = false;
    };
    ip = lib.mkOption {
      type = lib.types.str;
      description = "internal IP address. cloud: 10.5.0.0/24, dedi: 10.5.1.0/24. 10.5.1.1 is reserved as hetzner's magic gateway";
    };
  };

  config = lib.mkIf config.jemand771.unbeatable.enable {
    deployment = {
      buildOnTarget = true;
      tags = [ "cloudlab" ];
    };
    # TODO is this correct?
    # boot.kernelParams = [ "console=tty0" "console=ttyS0,115200" ];
    networking = {
      useNetworkd = true;
      nftables.enable = true;
    }
    // (
      if config.jemand771.unbeatable.isCloud then
        {
          # to internal vswitch
          interfaces.enp7s0.mtu = 1400;
          firewall.trustedInterfaces = [ "enp7s0" ];
          # IP is assigned via hetzner UI, cloud node gets dhcp
        }
      else
        {
          # cluster traffic goes here
          vlans.cloudlab-int = {
            id = 4001;
            interface = "enp0s31f6";
          };
          interfaces.cloudlab-int = {
            mtu = 1400;
          };
          bridges.br-underlay.interfaces = [ "cloudlab-int" ];
          # for attaching vms to the incus host net
          interfaces.br-underlay = {
            mtu = 1400;
            ipv4.routes = [
              {
                # hetzner magic
                address = "10.5.0.0";
                prefixLength = 16;
                via = "10.5.1.1";
              }
            ];
          };
          interfaces.br-underlay.ipv4.addresses = [
            {
              address = config.jemand771.unbeatable.ip;
              prefixLength = 24;
            }
          ];
          firewall.trustedInterfaces = [ "br-underlay" ];
          # ingress traffic ("public subnets") comes in here
          vlans.cloudlab-ext = {
            id = 4002;
            interface = "enp0s31f6";
          };
          interfaces.cloudlab-ext = {
            mtu = 1400;
          };
        }
    );
    jemand771 = {
      openssh.enable = true;
      preservation.enable = true;
      zfs-rpool = {
        enable = true;
        # TODO this option is garbage
        createIncusDatasets = !config.jemand771.unbeatable.isCloud;
      };
      # TODO import incus
      # TODO import ovn
      # TODO import linstor
    };
  };
}
