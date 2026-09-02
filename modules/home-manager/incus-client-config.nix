{
  config,
  lib,
  osConfig,
  ...
}:
{
  config.jemand771.incus-client = lib.mkIf config.jemand771.incus-client.enable {
    # "local" default doesn't make sense here
    defaultRemote = "cloudlab";
    remotes.cloudlab = {
      addresses = map (ip: "https://${ip}:8443") [
        "88.99.147.182"
        "88.99.66.165"
        "178.105.206.248"
      ];
      clientCertificate = ../../certs/incus-client-willy.crt;
      clientKey = osConfig.age.secrets.incus-client-willy-key.path;
      serverCertificate = ../../certs/incus-server-cloudlab.crt;
    };
  };
}
