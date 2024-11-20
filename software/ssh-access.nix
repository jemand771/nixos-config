{ config, lib, ... }:
let keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjygB98U3+QUD24oga93Lej5ZCtSah9KI/DneSQgVjL willy@nixbox"
];
in
{
  # if I have a user, allow ssh as that, otherwise root
  # TODO broken
  # users.users.willy = lib.mkIf (lib.hasAttr "willy" config.users.users) {
  #   openssh.authorizedKeys.keys = keys;
  # };
  users.users.root.openssh.authorizedKeys.keys = lib.mkIf (!lib.hasAttr "willy" config.users.users) keys;
}
