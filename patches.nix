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
      (npr 423815 "sha256-ULdnEXr6kYJsEVP/9LMSvbNlWgpuD0V/BEMZ8qsJvxA=") # cibuildwheel
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nixpkgs/compare/master...jemand771:nixpkgs:jenkins.diff";
        hash = "sha256-/huCC+rIOPmzxXC5VWyIElTmhuBxWpVWrxR7ct2KowQ=";
      }) # jenkins plugins
      (npr 582934 "sha256-MiLX6JWL8Ohl0MSF7apgR2pwEjiQhPL9tDnnuZBrdeE=") # coccinelle
      (npr 582751 "sha256-HX75M2vy4QSuPzm0jgHqJo+n0lEGUrSFqeH8yuSTcwc=") # openasar
      (npr 584169 "sha256-H+4HsXMkQQmMBs+sd2Pa3VNxW+L2vIr2kBfhGenQzM8=") # vencord
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
