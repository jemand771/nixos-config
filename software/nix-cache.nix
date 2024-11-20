{ pkgs, ... }:
{
  services.atticd = {
    enable = true;

    # TODO this should ideally live in /etc and be managed by agenix
    environmentFile = "/root/atticd.env";
  };
}
