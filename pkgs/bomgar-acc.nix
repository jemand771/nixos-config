{
  pkgs ? import <nixpkgs> { },
}:

# mostly written by claude because I cba to reverse engineer this stupid thing.
# works well for now, may review/clean up and "humanize" later.
let
  version = "25.1.4";

  installer = pkgs.requireFile {
    name = "bomgar-acc-installer.bin";
    hash = "sha256-vMYWKxGW9D8To8X1GQePAVWHiyLURaH9L9t3f4YxXeg=";
    message = ''
      Log in to BeyondTrust, download the "installer" for linux and run:
        nix-store --add-fixed sha256 bomgar-acc-installer.bin

      This is server-dependant, for some reason, and versions have to match exactly between client/server.
    '';
  };

  payload = pkgs.stdenvNoCC.mkDerivation {
    pname = "bomgar-acc-payload";
    inherit version;
    src = installer;

    dontUnpack = true;
    dontFixup = true;

    buildPhase = ''
      runHook preBuild

      offset=$(head -n 140 "$src" | sed -n 's/.*tail -n +$((\([0-9]\+\) + 1)).*/\1/p' | head -1)
      test -n "$offset" || { echo "could not find payload tar offset"; exit 1; }
      mkdir payload
      tail -n +"$((offset + 1))" "$src" | tar -x --no-same-owner -C payload

      for f in bomgar-acc bomgar-acc.bin libQt6Core.so.6 plugins/platforms/libqxcb.so; do
        test -e "payload/$f" || { echo "payload incomplete: missing $f"; exit 1; }
      done

      sed -n 's/^write_ini "\$INI" "\([^"]*\)" "\([^"]*\)" "\([^"]*\)"$/\1|\2|\3/p' \
        payload/install_after_unpack > ini-lines
      test "$(grep -c '^write_ini "\$INI" ' payload/install_after_unpack)" = "$(wc -l < ini-lines)" ||
        { echo "write_ini extraction incomplete"; exit 1; }

      prev=""
      while IFS='|' read -r section key value; do
        if [ "$section" != "$prev" ]; then
          printf '[%s]\n' "$section"
          prev=$section
        fi
        printf '%s=%s\n' "$key" "$value"
      done < ini-lines > bomgar.ini.template

      head -n1 bomgar.ini.template | grep -qx '\[General\]' ||
        { echo "template does not start with [General]"; exit 1; }
      test "$(grep -c '^\[' bomgar.ini.template)" = "$(grep '^\[' bomgar.ini.template | sort -u | wc -l)" ||
        { echo "duplicate ini sections"; exit 1; }
      grep -qxF 'build_version=${version}' bomgar.ini.template ||
        { echo "installer is not version ${version}"; exit 1; }

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      rm -f payload/install_after_unpack payload/bomgar.ini payload/uninstall
      mkdir -p "$out/libexec"
      mv payload "$out/libexec/bomgar-acc"
      install -Dm444 bomgar.ini.template "$out/share/bomgar-acc/bomgar.ini.template"
      runHook postInstall
    '';
  };

  sshConfig = "$HOME/.ssh/config.d/beyondtrust.conf";

  launcher = pkgs.writeShellApplication {
    name = "bomgar-acc-launch";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      util-linux
    ];
    text = ''
      runtime=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

      exec 9>"$runtime/bomgar-acc.lock"
      flock -n 9 || { logger -t bomgar-acc -p user.notice "already running"; exit 0; }

      chmod -R u+rwX "$runtime"/bomgar-acc.?????? 2>/dev/null || true
      rm -rf "$runtime"/bomgar-acc.??????

      rundir=$(mktemp -d "$runtime/bomgar-acc.XXXXXX")
      trap 'chmod -R u+rwX "$rundir" 2>/dev/null || true; rm -rf "$rundir"; : > "${sshConfig}"' EXIT INT TERM HUP
      umask 077
      mkdir -p "$(dirname "${sshConfig}")"
      : > "${sshConfig}"

      cp -rs ${payload}/libexec/bomgar-acc/. "$rundir/"
      chmod -R u+rwX "$rundir"
      cp --remove-destination ${payload}/libexec/bomgar-acc/bomgar-acc{,.bin} "$rundir/"

      {
        printf '%s\n' '[General]' 'locale_code="en-us"' 'open_ssh_in_external_tool=1' \
          'add_ssh_config_aliases=1' "ssh_config_path=${sshConfig}"
        sed -e '1{/^\[General\]$/d}' -e "s|[$]install_dir/|$rundir/|g" \
          ${payload}/share/bomgar-acc/bomgar.ini.template
      } > "$rundir/bomgar.ini"

      "$rundir/bomgar-acc" "$@"
    '';
  };
in
pkgs.buildFHSEnv {
  pname = "bomgar-acc";
  inherit version;

  targetPkgs =
    p:
    (with p; [
      alsa-lib
      dbus
      fontconfig
      freetype
      glib
      keyutils
      libdrm
      libglvnd
      libice
      libpulseaudio
      libsm
      libuuid
      libx11
      libxcb
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxinerama
      libxkbcommon
      libxrandr
      libxrender
      libxtst
      mesa
      openssl
      systemdLibs
      xcbutil
      zlib
      zstd
    ]);

  passthru = { inherit installer; };

  profile = ''
    export QT_QPA_PLATFORM=xcb
  '';

  runScript = "${launcher}/bin/bomgar-acc-launch";
}
