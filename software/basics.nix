{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    google-chrome
    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        ms-python.python
        bbenoist.nix
      ];
    })
  ];
}
