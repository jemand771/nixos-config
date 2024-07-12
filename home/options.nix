{ lib, ... }:
{
  # this is all technically wrong because I create system-wide options to configure user-specific settings.
  # since I'm the only user on all of my systems, I currently couldn't care less.
  options.jemand771.plasma.enable = lib.mkEnableOption "plasma-manager";
}