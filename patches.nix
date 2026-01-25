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
      (npr 423815 "sha256-nlR80hiNLmLAOLo4RbIzzcFWTcDykiaz/KWZWJL2l5M")
      (npr 483377 "sha256-Pw4VKtukEkxy1UIOlo2+cnTnfKR61HTwk3n6BkU6OX8=")
      (pkgs.fetchpatch {
        url = "https://github.com/NixOS/nixpkgs/compare/master...jemand771:nixpkgs:jenkins.diff";
        hash = "sha256-/huCC+rIOPmzxXC5VWyIElTmhuBxWpVWrxR7ct2KowQ=";
      })
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
