{ config, pkgs, ... }:

{
  home.file."${config.xdg.configHome}/autostart/ckb-next.desktop".source = "${
    (pkgs.runCommand "ckb-next-desktop" { } ''
      mkdir $out
      cp ${pkgs.ckb-next}/share/applications/ckb-next.desktop $out
      sed -i '/^Exec=.*/s/$/ --background/' $out/*
    '')
  }/ckb-next.desktop";
}
