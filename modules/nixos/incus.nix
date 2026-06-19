{
  lib,
  config,
  ...
}:
{
  options.jemand771.incus.enable = lib.mkEnableOption "Incus (assumes preservation + rpool)";
  options.jemand771.incus.projects = lib.mkOption {
    type = lib.types.attrsOf lib.types.attrs;
    description = "extra project configuratoin";
    default = { };
    example = {
      myproject = {
        "limits.containers" = "1";
        "limits.instances" = "5";
      };
    };
  };
  config = lib.mkIf config.jemand771.incus.enable {
    preservation.preserveAt."/persist" = {
      directories = [
        "/var/lib/incus"
      ];
    };
    virtualisation.incus = {
      enable = true;
      ui.enable = true;
      preseed = {
        projects = builtins.map ({ name, value }: {
          inherit name;
          config = {
            "features.networks" = "false";
            "features.profiles" = "true";
            "features.images" = "true";
            "features.storage.volumes" = "true";
            "features.storage.buckets" = "true";
            "restricted" = "true";
          }
          // value;
        }) (lib.attrsToList (config.jemand771.incus.projects));
        profiles = builtins.map (project: {
          name = "default";
          inherit project;
          config = {
            "migration.stateful" = "true";
          };
          devices = {
            root = {
              type = "disk";
              path = "/";
              pool = "default";
            };
            eth0 = {
              type = "nic";
              network = "guests";
              name = "eth0";
            };
          };
        }) (lib.attrNames config.jemand771.incus.projects);
      };
    };
  };
}
