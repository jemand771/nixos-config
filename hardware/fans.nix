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
    DEVPATH=hwmon2=devices/pci0000:00/0000:00:18.3 hwmon1=devices/platform/nct6775.656
    DEVNAME=hwmon2=k10temp hwmon1=nct6799
    FCTEMPS=hwmon1/pwm2=hwmon2/temp1_input hwmon1/pwm4=hwmon1/temp2_input hwmon1/pwm6=hwmon1/temp2_input
    FCFANS=hwmon1/pwm2=hwmon1/fan2_input hwmon1/pwm4=hwmon1/fan4_input hwmon1/pwm6=hwmon1/fan6_input
    MINTEMP=hwmon1/pwm2=50 hwmon1/pwm4=40 hwmon1/pwm6=40
    MAXTEMP=hwmon1/pwm2=80 hwmon1/pwm4=50 hwmon1/pwm6=50
    MINSTART=hwmon1/pwm2=50 hwmon1/pwm4=50 hwmon1/pwm6=50
    MINSTOP=hwmon1/pwm2=50 hwmon1/pwm4=50 hwmon1/pwm6=50
    MINPWM=hwmon1/pwm2=50 hwmon1/pwm4=50 hwmon1/pwm6=50
    '';
}
