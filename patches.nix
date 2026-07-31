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
      (npr 545542 "sha256-5U2DTTLvvCOTQJd3wTJIzL/1HFdX0u7w4XGKTOAR0cw=") # CUDAToolkit_ROOT
      (npr 547077 "sha256-JdSO+k6+KottM99+7K5vU2J2d9/4DiRKn0CdEck9pIc=") # onnxruntime
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
