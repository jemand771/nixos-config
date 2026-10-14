{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "outlook-web";
  version = "whatever";

  src = ./.;

  nativeBuildInputs = with pkgs; [
    copyDesktopItems
    librsvg
    makeWrapper
  ];

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "outlook-web";
      desktopName = "Outlook";
      exec = "outlook-web %u";
      icon = "internet-mail";
      categories = [
        "Network"
        "Email"
      ];
      mimeTypes = [ "x-scheme-handler/mailto" ];
      startupWMClass = "outlook-web";
    })
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/outlook-web
    cp *.js package.json $out/share/outlook-web/
    rsvg-convert -w 64 -h 64 \
      ${pkgs.kdePackages.breeze-icons}/share/icons/breeze/apps/48/internet-mail.svg \
      -o $out/share/outlook-web/icon.png
    makeWrapper ${pkgs.lib.getExe pkgs.electron} $out/bin/outlook-web \
      --add-flags $out/share/outlook-web \
      --set OUTLOOK_WEB_TEAMS ${pkgs.lib.getExe pkgs.teams-for-linux}
    runHook postInstall
  '';

  meta.mainProgram = "outlook-web";
}
