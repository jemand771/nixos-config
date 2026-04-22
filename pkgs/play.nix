{ pkgs }:
let
  script = pkgs.writeShellApplication {
    name = "play";
    text = ''
      playbooks=()
      flags=()
      for arg in "$@"; do
        if [ -f "playbooks/$arg.yaml" ]; then
          playbooks+=("playbooks/$arg.yaml")
        else
          flags+=("$arg")
        fi
      done
      ansible-playbook "''${flags[@]}" "''${playbooks[@]}"
    '';
  };
  completion = pkgs.writeText "play.fish" ''
    complete -c play -f -a '(
      set -l files "";
      set -l cmd $(string split " " $(commandline));
      for f in playbooks/*;
        set -a files $(basename -s .yaml $f);
      end;
      for f in $files;
        contains $f $cmd || echo $f;
      end
    )'
  '';
in
pkgs.symlinkJoin {
  inherit (script) name;
  paths = [
    script
    (pkgs.runCommand "play-completions" {
      nativeBuildInputs = [ pkgs.installShellFiles ];
      inherit completion;
    } "installShellCompletion $completion")
  ];
}
