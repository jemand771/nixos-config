{ ... }:
let
  mountOnDemand = device: {
    inherit device;
    fsType = "nfs";
    options = [
      "noatime"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
    ];
  };
in
{
  fileSystems = {
    "/mnt/main" = mountOnDemand "10.7.5.1:/nfs/main";
    "/mnt/backup" = mountOnDemand "10.7.5.1:/nfs/backup";
    "/mnt/ines" = mountOnDemand "10.7.5.1:/nfs/ines";
  };
}
