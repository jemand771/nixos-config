{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    google-chrome
    vscode
  ];
}
