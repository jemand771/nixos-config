{
  config,
  lib,
  pkgs,
  ...
}:
let
  prismJdks = with pkgs; [
    jdk8
    jdk17
    jdk21
    jdk25
  ];
  javaPath = package: "java/${package.name}";
in
{
  options.jemand771.gaming.enable = lib.mkEnableOption "gaming";
  config = lib.mkIf config.jemand771.gaming.enable {
    environment.systemPackages = with pkgs; [
      heroic
      tetrio-desktop
      obs-studio
      (prismlauncher.override {
        jdks = map (package: "/etc/${javaPath package}") prismJdks;
      })
    ];

    environment.etc = lib.listToAttrs (
      map (package: {
        name = javaPath package;
        value.source = package;
      }) prismJdks
    );

    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}
