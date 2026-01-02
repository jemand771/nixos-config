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
      findutils
      ffmpeg
      gnutar
      inotify-tools
      iperf3
      jq
      minicom
      nano
      ncdu
      nmap
      openssl
      pv
      rclone
      ripgrep
      screen
      sqlite
      traceroute
      unzip
      usbutils
      yt-dlp
      yq
    ];

  config.programs.fish.enable = true;
  # TODO the interactiveShellInit below feels wrong? what about:
  # users.users.willy.shell = pkgs.fish;
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
