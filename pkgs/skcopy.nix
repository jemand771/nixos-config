{ pkgs }:
let
  script = pkgs.writeShellApplication {
    name = "skcopy";
    runtimeInputs = with pkgs; [
      curl
      jq
      skopeo
    ];
    text = /* bash */ ''
      registry="docker-registry.intenta.de"
      args=()
      skopeo_args=()

      usage() {
        echo "usage: skcopy [-r REGISTRY] SOURCE_PROJECT IMAGE:TAG TARGET_PROJECT [-- SKOPEO_ARG...]"
        echo "       skcopy [-r REGISTRY] --projects"
      }

      # same lookup order as skopeo itself, see containers-auth.json(5)
      registry_auth() {
        local file
        if [ -n "''${REGISTRY_AUTH_FILE:-}" ]; then
          file="$REGISTRY_AUTH_FILE"
        elif [ -f "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/containers/auth.json" ]; then
          file="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/containers/auth.json"
        else
          file="$HOME/.docker/config.json"
        fi
        [ -f "$file" ] || return 0
        jq -r --arg registry "$registry" '.auths[$registry].auth // empty' "$file"
      }

      projects() {
        local auth
        local -a header=()
        auth="$(registry_auth)"
        if [ -n "$auth" ]; then
          header=(-H "Authorization: Basic $auth")
        fi
        curl -fsS -m 10 "''${header[@]}" "https://$registry/api/v2.0/projects?page_size=100" | jq -r '.[].name'
      }

      while [ $# -gt 0 ]; do
        case "$1" in
          --)
            shift
            skopeo_args=("$@")
            break
            ;;
          -r | --registry)
            registry="''${2:?missing registry}"
            shift 2
            ;;
          --registry=*)
            registry="''${1#*=}"
            shift
            ;;
          --projects)
            list_projects=true
            shift
            ;;
          -h | --help)
            usage
            exit 0
            ;;
          -*)
            echo "unknown flag: $1" >&2
            usage >&2
            exit 1
            ;;
          *)
            args+=("$1")
            shift
            ;;
        esac
      done

      if [ -n "''${list_projects:-}" ]; then
        projects
        exit 0
      fi

      if [ "''${#args[@]}" -ne 3 ]; then
        usage >&2
        exit 1
      fi

      image="''${args[1]}"
      case "''${image##*/}" in
        *:*) ;;
        *)
          echo "image must include a tag: $image" >&2
          exit 1
          ;;
      esac

      skopeo copy --all "''${skopeo_args[@]}" \
        "docker://$registry/''${args[0]}/$image" \
        "docker://$registry/''${args[2]}/$image"
    '';
  };
  completion = pkgs.writeText "skcopy.fish" ''
    complete -c skcopy -f
    complete -c skcopy -n '__fish_is_nth_token 1' -a '(skcopy --projects 2>/dev/null)' -d 'source project'
    complete -c skcopy -n '__fish_is_nth_token 3' -a '(skcopy --projects 2>/dev/null)' -d 'target project'
    complete -c skcopy -s r -l registry -x -d 'registry host'
    complete -c skcopy -l projects -d 'list projects'
    complete -c skcopy -s h -l help -d 'show usage'
  '';
in
pkgs.symlinkJoin {
  inherit (script) name;
  paths = [
    script
    (pkgs.runCommand "skcopy-completions" {
      nativeBuildInputs = [ pkgs.installShellFiles ];
      inherit completion;
    } "installShellCompletion $completion")
  ];
}
