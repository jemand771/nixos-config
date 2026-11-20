{
  lib,
  stdenv,
  fetchFromGitHub,
  makeWrapper,
  ffmpeg-headless,
  node-gyp,
  nodejs_24,
  nodejs-slim_24,
  python3,
  yarn-berry_4,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "casparcg-media-scanner";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "CasparCG";
    repo = "media-scanner";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Esa88aE2GzomrITFmxbcQGk20fKDuq3zzt187NipOAU=";
  };

  postPatch = ''
    cp ${./yarn.lock} yarn.lock
  '';

  missingHashes = ./missing-hashes.json;
  offlineCache = yarn-berry_4.fetchYarnBerryDeps {
    inherit (finalAttrs) src missingHashes;
    yarnLock = ./yarn.lock;
    hash = "sha256-szq1PS5kAK1dkyMuXN7N1YKA8OEwDSZVLsnav2mkC7I=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
    node-gyp
    nodejs_24
    python3
    yarn-berry_4.yarnBerryConfigHook
  ];

  # tools/build.mjs
  buildPhase = ''
    runHook preBuild
    node_modules/.bin/esbuild src/index.ts --bundle --platform=node --target=node24 --outfile=dist/scanner.js
    (cd node_modules/leveldown && node-gyp rebuild --nodedir=${nodejs_24})
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 dist/scanner.js -t $out/lib/casparcg-media-scanner
    install -Dm755 node_modules/leveldown/build/Release/leveldown.node -t $out/lib/casparcg-media-scanner/build/Release
    makeWrapper ${lib.getExe nodejs-slim_24} $out/bin/casparcg-media-scanner \
      --add-flags $out/lib/casparcg-media-scanner/scanner.js \
      --set-default NODE_ENV production \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg-headless ]}
    runHook postInstall
  '';

  meta = {
    description = "Media scanner for CasparCG Server";
    homepage = "https://github.com/CasparCG/media-scanner";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "casparcg-media-scanner";
  };
})
