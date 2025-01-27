{ pkgs, ... }:
{
  services.atticd = {
    enable = true;

    # TODO this should ideally live in /etc and be managed by agenix
    environmentFile = "/attic/atticd.env";

    # defaults from https://docs.attic.rs/admin-guide/deployment/nixos.html
    settings = {
      listen = "[::]:8080";

      jwt = { };

      # Data chunking
      #
      # Warning: If you change any of the values here, it will be
      # difficult to reuse existing chunks for newly-uploaded NARs
      # since the cutpoints will be different. As a result, the
      # deduplication ratio will suffer for a while after the change.
      chunking = {
        # The minimum NAR size to trigger chunking
        #
        # If 0, chunking is disabled entirely for newly-uploaded NARs.
        # If 1, all NARs are chunked.
        nar-size-threshold = 64 * 1024; # 64 KiB

        # The preferred minimum size of a chunk, in bytes
        min-size = 16 * 1024; # 16 KiB

        # The preferred average size of a chunk, in bytes
        avg-size = 64 * 1024; # 64 KiB

        # The preferred maximum size of a chunk, in bytes
        max-size = 256 * 1024; # 256 KiB
      };
    };
  };
  networking.firewall.enable = false;
}

# TODO nix-ify this config?
# manual setup:
# create token: atticd-atticadm  make-token --sub nixbox --validity 10y --pull '*' --push '*' --delete '*' --create-cache '*' --configure-cache '*' --configure-cache-retention '*' --destroy-cache '*'
# client: attic login home http://10.7.5.4:8080/ ey... (copy paste)
# create and configure the cache:
# attic cache create cache (also remember to update the public key in nix.conf)
# attic cache configure cache --public
# attic cache configure cache --retention-period "1 month"
# attic cache configure cache --priority 30
# attic cache configure cache --upstream-cache-key-name ""
