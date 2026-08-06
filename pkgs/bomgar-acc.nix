{
  pkgs ? import <nixpkgs> { },
}:

# mostly written by claude because I cba to reverse engineer this stupid thing.
# works well for now, may review/clean up and "humanize" later.
let
  version = "23.3.3";

  installer = pkgs.requireFile {
    name = "bomgar-acc-installer.desktop.download";
    hash = "sha256-s0vMvM5pPRPIYRDLuisfFICB/+d5NsBlDPZEuPgOIS8=";
    message = ''
      Log in to BeyondTrust, download the "installer" for linux and run:
        nix-store --add-fixed sha256 bomgar-acc-installer.desktop.download

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

      offset=$(head -n 140 "$src" | sed -n 's/.*tail -n +\([0-9]\+\) .*/\1/p' | head -1)
      test -n "$offset" || { echo "could not find stage-1 payload offset"; exit 1; }
      if ! tail -n +"$offset" "$src" | cut -b2- | gzip -d -c > stage2; then
        echo "note: gzip reported a truncated stream; verifying payload instead"
      fi
      test -s stage2

      offset2=$(head -n 100 stage2 | sed -n 's/.*tail -n +$((\([0-9]\+\) + 1)).*/\1/p' | head -1)
      test -n "$offset2" || { echo "could not find stage-2 tar offset"; exit 1; }
      mkdir payload
      tail -n +"$((offset2 + 1))" stage2 | tar -x --no-same-owner -C payload

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

  putty = pkgs.writeShellApplication {
    name = "putty";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      openssh
      util-linux
    ];
    text = ''
      conf_dir=$HOME/.ssh/config.d

      fail() { logger -t bomgar-acc-ssh-hook -p user.err "$*"; exit 1; }
      trap 'fail "unexpected failure at line $LINENO"' ERR

      user="" port=""
      while [ $# -gt 0 ]; do
        case $1 in
          -l) user=''${2-}; shift $(( $# > 1 ? 2 : 1 )) ;;
          -P) port=''${2-}; shift $(( $# > 1 ? 2 : 1 )) ;;
          *) shift ;;
        esac
      done

      case $port in ""|*[!0-9]*) fail "bad port '$port' in handoff" ;; esac
      case $user in ""|*[!A-Za-z0-9._-]*) fail "bad user in handoff" ;; esac

      errfile=$(mktemp)
      out=$(ssh \
        -F none \
        -o BatchMode=yes \
        -o PubkeyAuthentication=no \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o LogLevel=ERROR \
        -o ConnectTimeout=10 \
        -p "$port" -l "$user" 127.0.0.1 \
        'printf "BTFQDN=%s\n" "$(hostname -f 2>/dev/null || hostname)"' 2>"$errfile") || true
      err=$(tr '\n' ' ' < "$errfile")
      rm -f "$errfile"

      fqdn=$(printf '%s' "$out" | tr -d '\r' | sed -n 's/^BTFQDN=//p' | tail -n1)
      case $fqdn in
        ""|localhost*|127.*) fail "target behind port $port returned unusable hostname '$fqdn': $err" ;;
        *[!A-Za-z0-9._-]*) fail "target behind port $port returned unexpected hostname '$fqdn': $err" ;;
      esac

      alias_name="bt-''${fqdn%%.*}"

      umask 077
      mkdir -p "$conf_dir"
      chmod 700 "$conf_dir"

      tmp=$conf_dir/.beyondtrust-$alias_name.conf.$$
      cat > "$tmp" <<EOF
      Host $alias_name
        HostName 127.0.0.1
        Port $port
        User $user
        PubkeyAuthentication no
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
        ServerAliveInterval 30
      EOF
      mv -f "$tmp" "$conf_dir/beyondtrust-$alias_name.conf"

      logger -t bomgar-acc-ssh-hook -p user.notice "$alias_name -> $fqdn (127.0.0.1:$port)"
    '';
  };

  launcher = pkgs.writeShellApplication {
    name = "bomgar-acc-launch";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      util-linux
    ];
    text = ''
      runtime=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
      aliases=("$HOME"/.ssh/config.d/beyondtrust-*.conf "$HOME"/.ssh/config.d/.beyondtrust-*.conf.*)

      exec 9>"$runtime/bomgar-acc.lock"
      flock -n 9 || { logger -t bomgar-acc -p user.notice "already running"; exit 0; }

      rm -f "''${aliases[@]}"
      chmod -R u+rwX "$runtime"/bomgar-acc.?????? 2>/dev/null || true
      rm -rf "$runtime"/bomgar-acc.??????

      rundir=$(mktemp -d "$runtime/bomgar-acc.XXXXXX")
      trap 'chmod -R u+rwX "$rundir" 2>/dev/null || true; rm -rf "$rundir"; rm -f "''${aliases[@]}"' EXIT INT TERM HUP

      cp -rs ${payload}/libexec/bomgar-acc/. "$rundir/"
      chmod -R u+rwX "$rundir"
      cp --remove-destination ${payload}/libexec/bomgar-acc/bomgar-acc{,.bin} "$rundir/"

      {
        printf '%s\n' '[General]' 'locale_code="en-us"' 'open_ssh_in_external_tool=1' \
          'additional_external_tool_order="Putty;"'
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
    ])
    ++ [ putty ];

  profile = ''
    export QT_QPA_PLATFORM=xcb
  '';

  runScript = "${launcher}/bin/bomgar-acc-launch";
}
