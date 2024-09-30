{ config, lib, pkgs, ... }:

{
  options.jemand771.dev-infra.enable = lib.mkEnableOption "infra development";
  config.environment.systemPackages = with pkgs; lib.mkIf config.jemand771.dev-infra.enable [
    argocd
    k9s
    kubernetes-helm
    kubectl
    unstable.kubectl-df-pv
    kubeseal
    kustomize
    minikube
    # TODO headlamp desktop file
    (pkgs.appimageTools.wrapType1 {
      name = "headlamp";
      src = pkgs.fetchurl {
        url = "https://github.com/headlamp-k8s/headlamp/releases/download/v0.22.0/Headlamp-0.22.0-linux-x64.AppImage";
        hash = "sha256-KA4lxfiZLkkMANOg77n9mANTYXI+BJRwGUa1TRalFGM=";
      };
    })
    opentofu
  ];
}
