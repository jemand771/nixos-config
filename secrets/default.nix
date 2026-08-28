let
  nixbox = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMS5uOqFENq1oDlZLOxWEp7cwnKm6eom4ZdSYOAHu0+h";
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
        cnb004
      ];
      owner = "willy";
    };
    github-mcp-pat = {
      hosts = [
        nixbox
        cnb004
      ];
      owner = "willy";
    };
    kubeconfig-771-new-key = {
      hosts = [
        nixbox
        cnb004
      ];
      owner = "willy";
    };
  };
}
