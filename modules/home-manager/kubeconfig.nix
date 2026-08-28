{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  options.jemand771.kubeconfig.enable = lib.mkEnableOption "declarative kubeconfig";
  config = lib.mkIf config.jemand771.kubeconfig.enable {
    home.activation.kubeconfig =
      let
        target = "${config.home.homeDirectory}/.kube/config";
        stamp = "${config.home.homeDirectory}/.kube/.nix-source";
        kubeconfig = (pkgs.formats.yaml { }).generate "kubeconfig" {
          apiVersion = "v1";
          kind = "Config";
          clusters = [
            {
              name = "771-new";
              cluster = {
                server = "https://moxy2.jemand771.net:6443";
                certificate-authority = ../../certs/771-new-ca.crt;
              };
            }
            {
              name = "d39s-intern";
              cluster.server = "https://rancher.d39s.de/k8s/clusters/c-m-8c7zgn9s";
            }
            {
              name = "d39s-wiegand";
              cluster.server = "https://rancher.d39s.de/k8s/clusters/c-m-r4gvt6v2";
            }
          ];
          users = [
            {
              name = "771-new";
              user = {
                client-certificate = ../../certs/771-new-client.crt;
                client-key = osConfig.age.secrets.kubeconfig-771-new-key.path;
              };
            }
            {
              name = "d39s-rancher";
              user.exec = {
                apiVersion = "client.authentication.k8s.io/v1beta1";
                command = lib.getExe pkgs.rancher;
                args = [
                  "token"
                  "--server=rancher.d39s.de"
                  "--user=d39s-rancher"
                ];
                interactiveMode = "IfAvailable";
                provideClusterInfo = false;
              };
            }
          ];
          contexts = [
            {
              name = "771-new";
              context = {
                cluster = "771-new";
                user = "771-new";
              };
            }
            {
              name = "d39s-intern";
              context = {
                cluster = "d39s-intern";
                user = "d39s-rancher";
              };
            }
            {
              name = "d39s-wiegand";
              context = {
                cluster = "d39s-wiegand";
                user = "d39s-rancher";
              };
            }
          ];
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ "$(readlink ${stamp})" != "${kubeconfig}" ]; then
          run install -Dm600 ${kubeconfig} ${target}
          run ln -sfn ${kubeconfig} ${stamp}
        fi
      '';
  };
}
