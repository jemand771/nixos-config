{ config, ... }:

{
  services.restic.backups = {
    home = {
      paths = [
        "/home/willy"
      ];
      exclude = [
        "/home/willy/.cache"
        "/home/willy/Games"
        "/home/willy/.local/share/Steam"
      ];
      initialize = true;
      repository = "/mnt/backup/nixbox-home";
      passwordFile = config.age.secrets.restic-password.path;
    };
  };
}
