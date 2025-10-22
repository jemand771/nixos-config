{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.home-attic = lib.mkEnableOption "Use attic at home";
  config = lib.mkIf config.jemand771.home-attic {
    environment.systemPackages = with pkgs; [
      attic-client
    ];

    nix.settings.substituters = [
      # TODO: only as long as all my NixOS systems are physically at home
      # TODO completely breaks rebuilds while on the go
      # "http://10.7.5.4:8080/cache"
    ];
    nix.settings.trusted-public-keys = [
      # "cache:tYBQfUirWSN3x1H31lKbKHEBQn4xCWGf56dfbEgMDnQ="
    ];
  };
}
