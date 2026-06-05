{ ... }:

{
  age.secrets.restic-password.file = ./secrets/restic-password.age;
  age.secrets.github-mcp-pat = {
    file = secrets/github-mcp-pat.age;
    owner = "willy";
  };
  age.secrets.d39s-jenkins-mcp-auth = {
    file = secrets/d39s-jenkins-mcp-auth.age;
    owner = "willy";
  };
}
