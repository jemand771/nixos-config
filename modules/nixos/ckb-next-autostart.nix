{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.hardware.ckb-next.enable {
    systemd.user.services.ckb-next = {
      description = "ckb-next (background)";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${config.hardware.ckb-next.package}/bin/ckb-next --background";
    };
  };
}
