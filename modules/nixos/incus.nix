{
  lib,
  config,
  ...
}:
{
  options.jemand771.incus.enable = lib.mkEnableOption "Incus (assumes preservation + rpool)";
  config = lib.mkIf config.jemand771.incus.enable {
    preservation.preserveAt."/persist" = {
      directories = [
        "/var/lib/incus"
        # TODO put in their respective modules once they exist
        "/var/lib/ovn"
        "/var/lib/linstor"
        "/var/lib/linstor.d"
      ];
    };
  };
  # TODO incus, ovn, linstor
}
