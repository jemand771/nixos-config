#!/usr/bin/env fish

set fish_trace 1

mkdir -p out

for config in $(nix flake show --json | jq ".nixosConfigurations | keys[]")
  nom build .#nixosConfigurations.$config.config.system.build.toplevel -o out/$config || exit 1
  attic push cache result || exit 1
end
