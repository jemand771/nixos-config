{ config, lib, options, osConfig, pkgs, ... }:
{
  options.jemand771.ai.enable = lib.mkEnableOption "AI tools";
  config = lib.mkIf config.jemand771.ai.enable {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      package = pkgs.writeShellScriptBin "claude" ''
        export INTENTA_JENKINS_MCP_AUTH=$(</run/agenix/intenta-jenkins-mcp-auth)
        export GITHUB_MCP_PAT=$(</run/agenix/github-mcp-pat)
        exec ${lib.getExe options.programs.claude-code.package.default} "$@"
      '';
      settings = {
        includeCoAuthoredBy = false;
        permissions.allow = [
          "WebSearch"
          "WebFetch"
          "Bash(nix build:*)"
          "Bash(nix-build:*)"
          "Bash(nix eval:*)"
          "Bash(nix repl:*)"
          "Read(/nix/store/**)"
          "mcp__plugin_claude-code-home-manager_intenta-jenkins__*"
          "mcp__plugin_claude-code-home-manager_nixos__*"
        ];
      };
    };
    home.file.".claude/CLAUDE.md".text = ''
      # Goals
      * you help with mostly devops/infrastructure tasks and some coding

      # Workflow
      * if you're unsure about something, ask instead of guessing
      * do things "the right way" instead of quickly hacking together a solution
      * try to use pre-approved tools to avoid unnecessary permission prompts
      * keep changes minimal and focused, don't refactor unless it's required for your task or you're asked to
      * clean up after yourself, e.g. remove temporary files and remove code you just made redundant

      # Environment
      * you're running on NixOS, use nix tooling if you need extra software
        * if you're ever unsure about the current system's configuration, feel free to look at /etc/nixos
      * `nixbox` and `nixbook` are personal machines, `cnb004` is an intenta company laptop running nixos-wsl
        * use surrounding tooling and mcp servers accordingly, e.g. intenta-jenkins-mcp-auth only on cnb004
        * anything labeled `d39s` falls under personal use aswell
        * access to personal tooling from cnb004 is fine, but pay extra attention to whether it's required
        * the current system is: `${osConfig.networking.hostName}`
    '';
    programs.mcp = {
      enable = true;
      servers = {
        intenta-jenkins = lib.mkIf (osConfig.networking.hostName == "cnb004") {
          url = "https://sjenkins001.intop01.de/mcp-server/mcp";
          headers.Authorization = "Basic \${INTENTA_JENKINS_MCP_AUTH}";
        };
        nixos = {
          command = lib.getExe pkgs.mcp-nixos;
        };
        github = {
          url = "https://api.githubcopilot.com/mcp/";
          headers.Authorization = "Bearer \${GITHUB_MCP_PAT}";
        };
      };
    };
  };
}
