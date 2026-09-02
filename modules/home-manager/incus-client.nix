{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.jemand771.incus-client = {
    enable = lib.mkEnableOption "incus client config";
    defaultRemote = lib.mkOption {
      type = lib.types.str;
      description = "remote to use when a command doesn't name one";
      default = "local";
    };
    remotes = lib.mkOption {
      description = "incus remotes to configure";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            addresses = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "server urls, may list multiple/all members for clustered setups";
              example = [ "https://192.168.9.10:8443" ];
            };
            project = lib.mkOption {
              type = lib.types.str;
              description = "project to select on this remote";
              default = "default";
            };
            clientCertificate = lib.mkOption {
              type = lib.types.path;
              description = "certificate to authenticate with, must be in the server's trust store";
            };
            clientKey = lib.mkOption {
              type = lib.types.path;
              description = "private key for clientCertificate";
            };
            serverCertificate = lib.mkOption {
              type = lib.types.path;
              description = "incus server certificate";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf config.jemand771.incus-client.enable {
    home.packages = [ pkgs.incus.client ];
    home.activation.incus =
      let
        cfg = config.jemand771.incus-client;
        configDir = "${config.home.homeDirectory}/.config/incus";
        stamp = "${configDir}/.nix-source";
        clientConfig = (pkgs.formats.yaml { }).generate "incus-config" {
          default-remote = cfg.defaultRemote;
          remotes = {
            # present by default, keep around
            images = {
              addr = "https://images.linuxcontainers.org";
              protocol = "simplestreams";
              public = true;
            };
          }
          // lib.mapAttrs (_: remote: {
            addr = lib.concatStringsSep "," remote.addresses;
            protocol = "incus";
            public = false;
            inherit (remote) project;
          }) cfg.remotes;
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        ''
          run mkdir -p ${configDir}/clientcerts ${configDir}/servercerts
        ''
        + lib.concatLines (
          lib.mapAttrsToList (name: remote: ''
            run ln -sfn ${remote.clientCertificate} ${configDir}/clientcerts/${name}.crt
            run ln -sfn ${remote.clientKey} ${configDir}/clientcerts/${name}.key
            run ln -sfn ${remote.serverCertificate} ${configDir}/servercerts/${name}.crt
          '') cfg.remotes
        )
        + ''
          # incus can self-rewrite config like kubens/kubectx
          if [ "$(readlink ${stamp})" != "${clientConfig}" ]; then
            run install -Dm600 ${clientConfig} ${configDir}/config.yml
            run ln -sfn ${clientConfig} ${stamp}
          fi
        ''
      );
  };
}
