{ lib }:
dir:
builtins.filter (
  path:
  let
    name = baseNameOf path;
  in
  lib.hasSuffix ".nix" name && name != "default.nix" && !lib.hasPrefix "_" name
) (lib.filesystem.listFilesRecursive dir)
