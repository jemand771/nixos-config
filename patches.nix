inputs:
let
  pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
  pr =
    repo: number: hash:
    pkgs.fetchpatch {
      url = "https://github.com/${repo}/pull/${builtins.toString number}.diff";
      inherit hash;
    };
  npr = pr "NixOS/nixpkgs";
  patches = {
    nixpkgs = [
      (npr 423815 "sha256-JwbF7LJuukdQQ2s9t5CMIdqB52ukPO5aX7M1CflwtO4=") # cibuildwheel
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nixpkgs/compare/master...jemand771:nixpkgs:jenkins.diff";
        hash = "sha256-/huCC+rIOPmzxXC5VWyIElTmhuBxWpVWrxR7ct2KowQ=";
      }) # jenkins plugins
      (npr 513680 "sha256-pxpWSg6CI6G/mfCFjcvMx7MA6PoJ51z2c5I9RIEYw3E=") # aioboto3
    ];
  };
in
builtins.mapAttrs (
  name: value:
  if (patches.${name} or [ ]) == [ ] then
    value
  else
    pkgs.applyPatches {
      name = "source";
      src = value;
      patches = patches.${name};
    }
) inputs
