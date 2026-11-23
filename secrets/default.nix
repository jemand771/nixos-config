let
  nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5uOqFENq1oDlZLOxWEp7cwnKm6eom4ZdSYOAHu0+h";
  nixbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINYEVnmOd0Qjy3UZJE9AhpgTUI1WJ9QudxK6K2Fi7cYy";
  cnb004 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzafjoKVvEzC+J10uq6hy9T3ARprkRtuzogVs34b29j";
in
{
  hosts = { inherit nixbox cnb004; };
  secrets = {
    restic-password.hosts = [ nixbox ];
    intenta-jenkins-mcp-auth = {
      hosts = [ cnb004 ];
      owner = "willy";
    };
    d39s-jenkins-mcp-auth = {
      hosts = [
        nixbox
        nixbook
        cnb004
      ];
      owner = "willy";
    };
    github-mcp-pat = {
      hosts = [
        nixbox
        nixbook
        cnb004
      ];
      owner = "willy";
    };
    claude-code-oauth-token = {
      hosts = [
        nixbox
        nixbook
        cnb004
      ];
      owner = "willy";
    };
    incus-client-willy-key = {
      hosts = [
        nixbox
        nixbook
      ];
      owner = "willy";
    };
    caltrain-vpn-password.hosts = [ cnb004 ];
    intop01-smb-credentials.hosts = [ cnb004 ];
    kubeconfig-771-new-key = {
      hosts = [
        nixbox
        nixbook
        cnb004
      ];
      owner = "willy";
    };
  };
}
