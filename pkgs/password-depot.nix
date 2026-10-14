{ pkgs }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "password-depot";
  version = "19.1.1.0";

  # curl -s -o /dev/null -w '%{redirect_url}\n' https://web.archive.org/save/https://www.password-depot.de/download/v19/linux/pdepot19.deb
  # nix store prefetch-file https://www.password-depot.de/download/v19/linux/pdepot19.deb
  src = pkgs.fetchurl {
    url = "https://web.archive.org/web/20261014113130/https://www.password-depot.de/download/v19/linux/pdepot19.deb";
    hash = "sha256-w0xxZoRS4PZyetxMQXM3kVmR3uLQwmKj63NZT2ylEDo=";
  };

  nativeBuildInputs = with pkgs; [
    copyDesktopItems
    dpkg
    makeWrapper
  ];

  desktopItems = [
    (pkgs.makeDesktopItem {
      name = "password-depot";
      desktopName = "Password Depot 19";
      exec = "password-depot";
      icon = "password-depot";
      categories = [ "Utility" ];
      startupWMClass = "de.acebit.passworddepot.linux.Main";
    })
  ];

  installPhase = ''
    runHook preInstall
    install -Dm444 opt/password-depot-19/lib/app/PasswordDepotLinux-${finalAttrs.version}-all.jar \
      $out/share/password-depot/password-depot.jar
    install -Dm444 opt/password-depot-19/lib/Password_Depot_19.png $out/share/pixmaps/password-depot.png
    # GTK look and feel deadlocks swing init on the javafx thread
    makeWrapper ${pkgs.lib.getExe' pkgs.jdk21 "java"} $out/bin/password-depot \
      --add-flags "-Djpackage.app-version=${finalAttrs.version}" \
      --add-flags "-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel" \
      --add-flags "-Djna.library.path=${pkgs.lib.makeLibraryPath [ pkgs.libsecret ]}" \
      --add-flags "-jar $out/share/password-depot/password-depot.jar" \
      --prefix LD_LIBRARY_PATH : ${
        pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            at-spi2-core
            cairo
            fontconfig
            freetype
            gdk-pixbuf
            glib
            gtk3
            libGL
            libx11
            libxtst
            libxxf86vm
            pango
            stdenv.cc.cc.lib
          ]
        )
      }
    runHook postInstall
  '';

  meta = {
    license = pkgs.lib.licenses.unfree;
    mainProgram = "password-depot";
  };
})
