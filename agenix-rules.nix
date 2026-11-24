let
  inherit (import ./secrets) secrets;
in
builtins.listToAttrs (
  map (name: {
    name = "secrets/${name}.age";
    value.publicKeys = secrets.${name}.hosts;
  }) (builtins.attrNames secrets)
)
