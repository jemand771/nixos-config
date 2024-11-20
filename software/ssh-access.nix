{ config, lib, ... }:
let keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjygB98U3+QUD24oga93Lej5ZCtSah9KI/DneSQgVjL willy@nixbox"
];
in
{
  # if I have a user, allow ssh as that, otherwise root
  users.users.root.openssh.authorizedKeys.keys = lib.mkIf (!config.jemand771.meta.personal-system) keys;
}
