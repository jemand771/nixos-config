{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.jemand771.dev-python.enable = lib.mkEnableOption "python development";
  config.environment.systemPackages =
    with pkgs;
    lib.mkIf config.jemand771.dev-python.enable [
      black
      cibuildwheel
      # TODO broken
      # hatch
      mypy
      (python3.withPackages (
        ps: with ps; [
          beautifulsoup4
          pandas
          requests
          tabulate
        ]
      ))
      ruff
      twine
      nodejs_20
      # TODO move me
      prusa-slicer
      platformio
      platformio-core
      nixpkgs-review
      debian-devscripts
      qlcplus
      kdePackages.kdenlive
      audacity
    ];
  config.systemd.services.write-current-time = lib.mkIf config.jemand771.dev-python.enable {
    description = "Write current time to /run/current-time.txt every second";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${
        pkgs.writeShellApplication {
          name = "write-time";
          text = ''
            while true; do
              date +"%H:%M:%S" > /run/current-time.txt.tmp
              mv /run/current-time.txt.tmp /run/current-time.txt
              sleep 0.1
            done
          '';
        }
      }/bin/write-time";
      Restart = "always";
      RestartSec = 1;
    };
  };
}
