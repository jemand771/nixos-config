{ ... }:

{
  # https://nixos.wiki/wiki/NFS
  services.rpcbind.enable = true; # needed for NFS
  boot.supportedFilesystems = [ "nfs" ];
  systemd.mounts = let commonMountOptions = {
    type = "nfs";
    mountConfig = {
      Options = "noatime";
    };
  };

  in

  [
    (commonMountOptions // {
      what = "10.7.5.1:/nfs/main";
      where = "/mnt/main";
    })

    (commonMountOptions // {
      what = "10.7.5.1:/nfs/backup";
      where = "/mnt/backup";
    })
  ];

  systemd.automounts = let commonAutoMountOptions = {
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
  };

  in

  [
    (commonAutoMountOptions // { where = "/mnt/main"; })
    (commonAutoMountOptions // { where = "/mnt/backup"; })
  ];
}
