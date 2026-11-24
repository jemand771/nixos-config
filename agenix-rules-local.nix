# sudo AGENIX_RULES=agenix-rules-local.nix agenix -r -i /etc/ssh/ssh_host_ed25519_key
# sudo chown willy:users secrets/*.age
let
  keyRaw = builtins.readFile /etc/ssh/ssh_host_ed25519_key.pub;
  key = builtins.head (builtins.match "(ssh-ed25519 [^[:space:]]+).*?" keyRaw);
  rules = import ./agenix-rules.nix;
in
builtins.removeAttrs rules (
  builtins.filter (f: !builtins.elem key rules.${f}.publicKeys) (builtins.attrNames rules)
)
