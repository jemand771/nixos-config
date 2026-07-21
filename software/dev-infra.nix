{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.jemand771.dev-infra.enable = lib.mkEnableOption "infra development";
  config = lib.mkIf config.jemand771.dev-infra.enable {
    environment.systemPackages = with pkgs; [
      apacheHttpd # for htpasswd
      argocd
      cilium-cli
      dive
      k9s
      kube-capacity
      kube-linter
      kubernetes-helm
      kubectl
      kubectl-cnpg
      kubectl-df-pv
      kubeseal
      kustomize
      minikube
      headlamp
      opentofu
      postgresql
      pv-migrate
      rancher
      samba
      spice-gtk
      quickemu
      velero
      virt-viewer
    ];
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
