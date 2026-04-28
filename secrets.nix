let
  nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5uOqFENq1oDlZLOxWEp7cwnKm6eom4ZdSYOAHu0+h";
  cnb004 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzafjoKVvEzC+J10uq6hy9T3ARprkRtuzogVs34b29j";
in
{
  "secrets/restic-password.age".publicKeys = [ nixbox ];
  "secrets/intenta-jenkins-mcp-auth.age".publicKeys = [ cnb004 ];
}
