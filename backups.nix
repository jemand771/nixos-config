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
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 100"
      ];
    };
  };
}
