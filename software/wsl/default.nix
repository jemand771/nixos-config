{
  lib,
  config,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  options.jemand771.wsl.enable = lib.mkEnableOption "Enable WSL stuffs";
  config = lib.mkIf config.jemand771.wsl.enable {
    wsl = {
      enable = true;
      defaultUser = "willy";
      interop.includePath = false;
      wslConf.automount.options = "metadata,umask=022,fmask=111,uid=1000,gid=100";
      usbip.enable = true;
    };

    # vscode antinag
    environment.variables.DONT_PROMPT_WSL_INSTALL = "1";
  };
}
