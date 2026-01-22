let
  nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5uOqFENq1oDlZLOxWEp7cwnKm6eom4ZdSYOAHu0+h";
in
{
  "secrets/restic-password.age".publicKeys = [ nixbox ];
}
