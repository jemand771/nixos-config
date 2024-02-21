let
  willy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM9sH3u7h+CoBNQXw88MTMVrAnWJE4d6BsCm2LgV+PHN willy@nixos";
  nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5uOqFENq1oDlZLOxWEp7cwnKm6eom4ZdSYOAHu0+h";
in
{
  "secrets/restic-password.age".publicKeys = [ nixbox ];
}
