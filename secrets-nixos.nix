{ ... }:

{
  age.secrets.restic-password.file = ./secrets/restic-password.age;
  age.secrets.github-mcp-pat = {
    file = ../secrets/github-mcp-pat.age;
    owner = "willy";
  };
}
