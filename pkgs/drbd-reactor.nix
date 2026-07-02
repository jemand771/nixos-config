{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "drbd-reactor";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "LINBIT";
    repo = "drbd-reactor";
    tag = "v${version}";
    hash = "sha256-eg9hRqGYVpXWjcp7anzUKleeDyygur/zaycXr0YQ2ME=";
  };
  cargoHash = "sha256-XoYRl5xRe3bPI3NWR3G5bPLqHD1MFfFYkNjfJm1KaSI=";

  meta = {
    description = "Monitors DRBD resources via plugins";
    homepage = "https://github.com/LINBIT/drbd-reactor";
    license = lib.licenses.asl20;
    mainProgram = "drbd-reactor";
  };
}
