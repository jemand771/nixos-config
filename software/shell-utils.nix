{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.jemand771.shell-utils.enable = lib.mkEnableOption "shell utils";
  config.environment.systemPackages =
    with pkgs;
    lib.mkIf config.jemand771.shell-utils.enable [
      aria2
      curl
      bat
      bc
      btop
      dig
      file
      ffmpeg
      iperf3
      jq
      nano
      ncdu
      nmap
      pv
      rclone
      unzip
      usbutils
      yt-dlp
    ];

  config.programs.fish.enable = true;
  config.programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };
}
