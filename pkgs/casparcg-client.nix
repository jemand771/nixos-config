{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  ninja,
  boost,
  libvlc,
  qt6,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "casparcg-client";
  version = "2.3.1";

  src = fetchFromGitHub {
    owner = "CasparCG";
    repo = "client";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-G1BiGq88z1gQfbQETyvsv6hlPfgk78vETI4CFPwyzJg=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  patches = [
    # boost >= 1.87 compatibility
    (fetchpatch {
      url = "https://github.com/CasparCG/client/commit/41a1fc5105ae9d668cc4b354ab2a7ba1872a8f8e.patch";
      stripLen = 1;
      hash = "sha256-gNX4WKi0e91xKaSYWQ4VjIAJpkXrjOsls4AtlvsDS/E=";
    })
  ];

  postPatch = ''
    substituteInPlace ../resources/linux/casparcg-client.desktop \
      --replace-fail "Exec=/usr/bin/casparcg-client" "Exec=casparcg-client" \
      --replace-fail "Icon=/usr/share/icons/casparcg-client/CasparCG.png" "Icon=casparcg-client"
    substituteInPlace Packaging.cmake \
      --replace-fail 'DESTINATION share/icons/casparcg-client/)' 'DESTINATION share/pixmaps RENAME casparcg-client.png)'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    boost
    libvlc
    qt6.qt5compat
    qt6.qtbase
    qt6.qtwebsockets
  ];

  env = {
    GIT_TIMESTAMP = "2025-11-13 18:01:02 +0000";
    GIT_VERSION = "9fa6050882";
  };
  qtWrapperArgs = [ "--set QT_QPA_PLATFORM xcb" ];

  meta = {
    description = "Client for controlling CasparCG Server";
    homepage = "https://github.com/CasparCG/client";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "casparcg-client";
  };
})
