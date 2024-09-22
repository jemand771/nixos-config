{ ... }:
{
    hardware.fancontrol.enable = true;
    # pwm2: cpu fans, y-splitter
    # pwm4: back case fan
    # pwm6: front case fans (daisy chained)
    # setting a minpwm of 50 might seem excessive, but the fans are still almost silent going that speed.
    # that is, quieter than ambient (coil whine).
    # also, keeping them on feels "safer" for now, although stopped fans are a pretty good flex.
    # it feels like I'm still thermal trottling (tops out at 92°C regardless of fan speed),
    # so I'll have to look into that some more.
    hardware.fancontrol.config = ''
    INTERVAL=1
    DEVPATH=hwmon1=devices/pci0000:00/0000:00:18.3 hwmon6=devices/platform/nct6775.656
    DEVNAME=hwmon1=k10temp hwmon6=nct6799
    FCTEMPS=hwmon6/pwm2=hwmon1/temp1_input hwmon6/pwm4=hwmon6/temp2_input hwmon6/pwm6=hwmon6/temp2_input
    FCFANS=hwmon6/pwm2=hwmon6/fan2_input hwmon6/pwm4=hwmon6/fan4_input hwmon6/pwm6=hwmon6/fan6_input
    MINTEMP=hwmon6/pwm2=60 hwmon6/pwm4=40 hwmon6/pwm6=40
    MAXTEMP=hwmon6/pwm2=90 hwmon6/pwm4=50 hwmon6/pwm6=50
    MINSTART=hwmon6/pwm2=50 hwmon6/pwm4=50 hwmon6/pwm6=50
    MINSTOP=hwmon6/pwm2=50 hwmon6/pwm4=50 hwmon6/pwm6=50
    MINPWM=hwmon6/pwm2=50 hwmon6/pwm4=50 hwmon6/pwm6=50
    '';
}
