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
      fd
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
      zip
    ];

  config.programs.fish.enable = true;
  config.users.defaultUserShell = pkgs.fish;
  config.programs.fish.interactiveShellInit = ''
    ${lib.getExe pkgs.nix-your-shell} fish | source
  '';
}
