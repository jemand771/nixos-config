{ pkgs, ... }:

{
  hardware.ckb-next = {
    enable = true;
    # TODO remove after upstream fix
    package = pkgs.ckb-next.overrideAttrs (prev: {
      cmakeFlags = (prev.cmakeFlags or [ ]) ++ [ "-DUSE_DBUS_MENU=0" ];
    });
  };
}
