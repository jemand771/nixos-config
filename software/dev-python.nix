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
      (python3.withPackages (
        ps: with ps; [
          beautifulsoup4
          pandas
          requests
          tabulate
        ]
      ))
      nodejs_20
      # TODO move me
      prusa-slicer
      platformio
      platformio-core
      nixpkgs-review
    ];
}
