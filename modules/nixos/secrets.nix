{
  config,
  lib,
  ...
}:
let
  inherit (import ../../secrets) hosts secrets;
  pubkey = hosts.${config.networking.hostName} or null;
in
{
  age.secrets = lib.mapAttrs (
    name: secret: removeAttrs secret [ "hosts" ] // { file = ../../secrets/${name}.age; }
  ) (lib.filterAttrs (_: secret: builtins.elem pubkey secret.hosts) secrets);
}
