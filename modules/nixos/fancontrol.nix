{
  pkgs,
  lib,
  config,
  ...
}:
# turns out hwmonX indices just aren't stable. hack around this by providing stable symlinks
# see https://github.com/lm-sensors/lm-sensors/issues/227
let
  runDir = "/run/hwmon";
in
{
  options.jemand771.fancontrol.enable = lib.mkEnableOption "fancontrol";
  options.jemand771.fancontrol.hwmons = lib.mkOption {
    description = "hardware monitors for udev rules";
    type = lib.types.attrsOf lib.types.str;
    example = {
      nct6799 = "ATTR{name}==\"nct6799\"";
    };
    default = { };
  };
  options.jemand771.fancontrol.interval = lib.mkOption {
    type = lib.types.int;
    description = "fancontrol update interval";
    default = 1;
  };
  options.jemand771.fancontrol.controllers = lib.mkOption {
    description = "fan control loops";
    type = lib.types.listOf (
      lib.types.submodule {
        options = {
          temp = lib.mkOption { type = lib.types.str; };
          pwm = lib.mkOption { type = lib.types.str; };
          fan = lib.mkOption { type = lib.types.str; };
          mintemp = lib.mkOption { type = lib.types.int; };
          maxtemp = lib.mkOption { type = lib.types.int; };
          minstart = lib.mkOption { type = lib.types.int; };
          minstop = lib.mkOption { type = lib.types.int; };
          minpwm = lib.mkOption { type = lib.types.int; };
        };
      }
    );
    example = [
      {
        temp = "k10temp/temp1_input";
        pwm = "nct6799/pwm2";
        fan = "nct6799/fan2_input";
        mintemp = 60;
        maxtemp = 90;
        minstart = 50;
        minstop = 50;
        minpwm = 50;
      }
    ];
    default = [ ];
  };
  options.jemand771.fancontrol.enableNixboxProfile = lib.mkEnableOption "nixbox fancontrol profile";
  config = lib.mkIf config.jemand771.fancontrol.enable {
    hardware.fancontrol.enable = true;
    # udev can sometimes take a bit
    systemd.services.fancontrol.serviceConfig.RestartSec = 1;

    services.udev.extraRules =
      let
        mkLink = pkgs.writeShellScript "hwmon-stable-link" ''
          ${lib.getExe' pkgs.coreutils "mkdir"} -p ${runDir}
          ${lib.getExe' pkgs.coreutils "ln"} -sfn "/sys$2" "${runDir}/$1"
        '';
      in
      builtins.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value: "SUBSYSTEM==\"hwmon\", ${value}, RUN+=\"${mkLink} ${name} %p\""
        ) config.jemand771.fancontrol.hwmons
      );

    hardware.fancontrol.config =
      let
        concat =
          valkey:
          builtins.concatStringsSep " " (
            builtins.map (
              entry:
              let
                value = entry.${valkey};
                valuePrefix = if builtins.isString value then "${runDir}/" else "";
              in
              "${runDir}/${entry.pwm}=${valuePrefix}${builtins.toString value}"
            ) config.jemand771.fancontrol.controllers
          );
      in
      ''
        INTERVAL=${builtins.toString config.jemand771.fancontrol.interval}
        FCTEMPS=${concat "temp"}
        FCFANS=${concat "fan"}
        MINTEMP=${concat "mintemp"}
        MAXTEMP=${concat "maxtemp"}
        MINSTART=${concat "minstart"}
        MINSTOP=${concat "minstop"}
        MINPWM=${concat "minpwm"}
      '';

    jemand771.fancontrol = lib.mkIf config.jemand771.fancontrol.enableNixboxProfile {
      hwmons = {
        # k10temp is cpu temp, rest (case sensor + all fans) go via nct6799
        k10temp = "ATTR{name}==\"k10temp\"";
        nct6799 = "ATTR{name}==\"nct6799\"";
      };
      # setting a minpwm of 50 might seem excessive, but the fans are still almost silent going that speed.
      # that is, quieter than ambient (coil whine).
      # also, keeping them on feels "safer" for now, although stopped fans are a pretty good flex.
      controllers =
        let
          cpuFanCurve = {
            mintemp = 60;
            maxtemp = 90;
            minstart = 50;
            minstop = 50;
            minpwm = 50;
          };
          caseFanCurve = {
            mintemp = 40;
            maxtemp = 50;
            minstart = 50;
            minstop = 50;
            minpwm = 50;
          };
        in
        [
          # cpu fans, y-splitter
          (
            cpuFanCurve
            // {
              temp = "k10temp/temp1_input";
              pwm = "nct6799/pwm2";
              fan = "nct6799/fan2_input";
            }
          )
          # back case fan
          (
            caseFanCurve
            // {
              temp = "nct6799/temp2_input";
              pwm = "nct6799/pwm4";
              fan = "nct6799/fan4_input";
            }
          )
          # front case fans (daisy chained)
          (
            caseFanCurve
            // {
              temp = "nct6799/temp2_input";
              pwm = "nct6799/pwm6";
              fan = "nct6799/fan6_input";
            }
          )
        ];
    };
  };
}
