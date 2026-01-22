#!/usr/bin/env fish

set fish_trace 1

mkdir -p out

for config in $(nix eval --impure --json --expr 'builtins.attrNames (builtins.getFlake "/etc/nixos").nixosConfigurations' | jq -r ". | values[]")
  nom build .#nixosConfigurations.$config.config.system.build.toplevel -o out/$config || exit 1
  attic push cache out/$config || exit 1
  rm -f out/$config
end
