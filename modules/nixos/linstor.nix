{
  lib,
  config,
  pkgs,
  ...
}:
{
  options.jemand771.linstor = {
    enable = lib.mkEnableOption "linstor";
    controller.enable = lib.mkEnableOption "linstor controller (+drbd)";
    controllers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "linstor controllers for client connection";
      example = [
        "linstor://192.168.9.10"
        "linstor://192.168.9.11"
      ];
    };
  };
  config = lib.mkIf config.jemand771.linstor.enable {
    assertions = [
      {
        assertion = builtins.length config.jemand771.linstor.controllers > 0;
        message = "need at least one linstor controller";
      }
    ];

    preservation.preserveAt."/persist" = {
      directories = [
        # TODO needed?
        # "/var/lib/linstor"
        # "/var/lib/linstor.d"
      ];
    };

    environment.systemPackages = [ pkgs.linstor-client ];
    environment.etc."linstor/linstor-client.conf".text = ''
      [global]
      controllers = ${lib.concatStringsSep "," config.jemand771.linstor.controllers}
    '';
  };
}
