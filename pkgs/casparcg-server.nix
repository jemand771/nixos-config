{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
  cmake,
  ninja,
  pkg-config,
  boost,
  ffmpeg_8,
  glew,
  icu,
  libGL,
  libX11,
  liberation_ttf,
  openal,
  sfml_2,
  tbb,
  zlib,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  libdrm,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libgbm,
  libxcb,
  libxkbcommon,
  nspr,
  nss,
  pango,
  udev,
}:

let
  # CMakeModules/Bootstrap_Linux.cmake
  cef = fetchurl {
    url = "https://github.com/CasparCG/dependencies/releases/download/cef/cef_binary_142.0.17+g60aac24+chromium-142.0.7444.176_linux64_minimal.tar.bz2";
    hash = "sha256-HYnhmy9EYQX5of5v3Ja87YYkm1iEJB3MQBO3yU2r9CQ=";
  };

  # libcef.so's dependencies
  cefDeps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    libdrm
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libgbm
    libxcb
    libxkbcommon
    nspr
    nss
    pango
    udev
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "casparcg-server";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "CasparCG";
    repo = "server";
    tag = "v${finalAttrs.version}-stable";
    hash = "sha256-9CsFJjwI2sUenEVrP+NhBxIiEo/wl36dFcq/IKxDt4E=";
  };

  sourceRoot = "${finalAttrs.src.name}/src";

  postPatch = ''
    substituteInPlace CMakeModules/Bootstrap_Linux.cmake \
      --replace-fail "COMPONENTS system thread" "COMPONENTS thread"
    echo 'set_source_files_properties(main.cpp PROPERTIES COMPILE_OPTIONS -fno-stack-protector)' >> shell/CMakeLists.txt
    echo 'set_source_files_properties(html.cpp PROPERTIES COMPILE_OPTIONS -fno-stack-protector)' >> modules/html/CMakeLists.txt
  '';

  strictDeps = true;

  nativeBuildInputs = [
    autoPatchelfHook
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    boost
    # libavcodec <= 62
    ffmpeg_8
    glew
    icu
    libGL
    libX11
    openal
    sfml_2
    tbb
    zlib
  ]
  ++ cefDeps;

  preConfigure = ''
    mkdir -p "$NIX_BUILD_TOP/casparcg-cache"
    ln -s ${cef} "$NIX_BUILD_TOP/casparcg-cache/${cef.name}"
    cmakeFlagsArray+=("-DCASPARCG_DOWNLOAD_CACHE=$NIX_BUILD_TOP/casparcg-cache")
  '';

  cmakeFlags = [
    (lib.cmakeBool "USE_SYSTEM_CEF" false)
    (lib.cmakeFeature "CASPARCG_BINARY_NAME" "casparcg-server")
    # don't install bundled CEF libraries
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib/casparcg-server")
    (lib.cmakeFeature "DIAG_FONT_PATH" "${liberation_ttf}/share/fonts/truetype/LiberationMono-Regular.ttf")
  ];

  env = {
    GIT_HASH = finalAttrs.src.tag;
    # libcef.so deps
    NIX_LDFLAGS = "-rpath-link ${lib.makeLibraryPath cefDeps}";
  };

  postInstall = ''
    rm $out/lib/casparcg-server/chrome-sandbox
  '';

  runtimeDependencies = [ libGL ];

  meta = {
    description = "Professional graphics and video playout server";
    homepage = "https://casparcg.com";
    license = with lib.licenses; [
      gpl3Plus
      # CEF
      bsd3
    ];
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      binaryNativeCode
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "casparcg-server";
  };
})
