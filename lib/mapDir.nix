{ lib }:
dir: mkValue:
lib.mapAttrs' (filename: _: {
  name = lib.removeSuffix ".nix" filename;
  value = mkValue filename;
}) (builtins.readDir dir)
