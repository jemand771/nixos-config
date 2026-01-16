{
  pkgs ? import <nixpkgs> { },
}:
let
  version = "1.34.0";
  # we have to steal the cats from an official release because the author doesn't want vscode-pets to vendor them on github
  # I guess I should maybe pay for the sprite pack if I'm already putting this much effort into getting it?
  # note that this also applied to some other sprites, but I only care about the cats.
  cats =
    pkgs.runCommand "vscode-pets-cats"
      {
        src = pkgs.fetchurl {
          url = "https://github.com/tonybaloney/vscode-pets/releases/download/1.34.0/vscode-pets-${version}.vsix";
          hash = "sha256-+4D9QKMB0BsIm8qy4ZNC5H87V21wgLD7ztrYJ/R3UJQ=";
        };
        # did you know that .vsix is just .zip ?
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        unzip $src
        mkdir $out
        cp extension/media/cat/*.gif $out/
      '';
  vsix = pkgs.buildNpmPackage {
    name = "vscode-pets-${version}.vsix";
    pname = "vscode-pets";
    inherit version;
    src = pkgs.fetchFromGitHub {
      owner = "tonybaloney";
      repo = "vscode-pets";
      tag = version;
      hash = "sha256-lSQjL8M0msCXw8L6bO0S9+McuQJe93X4h8GdjrI9Ps4=";
    };
    npmDepsHash = "sha256-2Wl3NrVy+7Tmnbc2GZtreAJHnCj+LKpCFwS1ClJtYls=";
    env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

    patches = [
      (pkgs.fetchpatch {
        url = "https://github.com/tonybaloney/vscode-pets/commit/cfc090c30cb977761ebd83dbea57be0a96b93ff3.diff";
        hash = "sha256-aM3jH+dGnY3cAC21LoyAVbdeI1x3B2wK3ORhCRJiXX4=";
      })
    ];
    postPatch = ''
      mkdir -p media/cat/
      cp ${cats}/* media/cat/
    '';

    nativeBuildInputs = [ pkgs.vsce ];
    npmBuildScript = "compile";
    installPhase = ''
      runHook preInstall

      vsce package
      cp *.vsix $out

      runHook postInstall
    '';
  };
in
# it's a bit strange to build a nice vsix package only to extract it right after, but this is "the official way"
pkgs.vscode-utils.buildVscodeExtension {
  pname = "vscode-pets";
  inherit version;
  src = vsix;
  vscodeExtPublisher = "tonybaloney";
  vscodeExtName = "vscode-pets";
  vscodeExtUniqueId = "tonybaloney.vscode-pets";
}
