{ modulesPath, pkgs, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  environment.etc."acng/acng.conf" = {
    text = ''
      CacheDir: /var/cache/apt-cacher-ng
      LogDir: /var/log/apt-cacher-ng
      Port:80
      VerboseLog: 1
      ReportPage: acng-report.html
      AdminAuth: admin:admin
      ForeGround: 1
      ForceManaged: 1
      Remap-debian: /debian ; http://ftp.debian.org/debian/
      Remap-debian-security: /debian-security ; http://security.debian.org/debian-security
    '';
  };

  environment.systemPackages = [
    pkgs.apt-cacher-ng
  ];

  networking.firewall.enable = false;

  systemd.services.apt-cacher-ng = {
    enable = true;
    description = "apt-cacher-ng";
    serviceConfig = {
      ExecStart = "${pkgs.apt-cacher-ng}/bin/apt-cacher-ng -c /etc/nixos/acng/";
      Restart = "always";
      RestartSec = 5;
    };
    wantedBy = [ "multi-user.target" ]; 
  };
}
