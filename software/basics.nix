{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    google-chrome
    unstable.vesktop
  ];
}
