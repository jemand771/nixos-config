{
  lib,
  config,
  ...
}:
{
  options.jemand771.ckb-next-autostart.enable = lib.mkEnableOption "ckb-next autostart if ckb-next is enabled";
  config = lib.mkIf (config.jemand771.ckb-next-autostart.enable && config.hardware.ckb-next.enable) {
    systemd.user.services.ckb-next = {
      description = "ckb-next (background)";
      wantedBy = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${config.hardware.ckb-next.package}/bin/ckb-next --background";
    };
  };
}
