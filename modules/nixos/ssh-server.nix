{
  lib,
  config,
  ...
}:
{
  options.jemand771.openssh.enable = lib.mkEnableOption "opinionated openssh";
  config = lib.mkIf config.jemand771.openssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    networking.firewall.allowedTCPPorts = [ 22 ];
  };
}
