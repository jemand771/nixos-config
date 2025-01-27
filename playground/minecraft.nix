{ inputs, pkgs, ... }:
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    managementSystem = {
      tmux.enable = false;
      systemd-socket.enable = true;
    };
    servers.smp5-test = {
      enable = true;
      restart = "always";
      whitelist = {
        jemand771 = "bf13f2b6-a269-4f52-97cf-853136e1823d";
      };
      operators = {
        jemand771 = "bf13f2b6-a269-4f52-97cf-853136e1823d";
      };
      serverProperties = {
        server-port = 25565;
        difficulty = 3;
        gamemode = 1;
        max-players = 5;
        motd = "Hello NixOS :)";
        white-list = true;
        spawn-protection = 0;
      };
      # TODO mc-monitor (or similar) to observe healthiness
      package = pkgs.fabricServers.fabric-1_20_4;
      jvmOpts = "-Xms8G -Xmx8G";
      # TODO: announce, delay, stop
      stopCommand = ''
        /kick @a restarting, be right back!
        /stop
      '';
      # TODO vanilltweaks x3
      symlinks = {
        "allowed_symlinks.txt" = pkgs.writeText "allowed_symlinks" "/nix/store";
        "world/datapacks" = pkgs.linkFarmFromDrvs "datapacks" [
          # TODO that's not how you do it
          inputs.nix-vanillatweaks.legacyPackages.x86_64-linux.datapacks."1.21".decorative-cosmetic.name-colors
        ];
        mods = pkgs.linkFarmFromDrvs "mods" (
          builtins.attrValues {
            # TODO all mods
            #     https://media.forgecdn.net/files/3559/638/cloth-config-6.1.48-fabric.jar,
            #     https://media.forgecdn.net/files/3549/539/bettersleeping-0.5.1%2B1.18.jar,
            #     https://media.forgecdn.net/files/3577/46/fabric-api-0.45.0%2B1.18.jar,
            #     https://media.forgecdn.net/files/3542/18/fabric-carpet-1.18-1.4.56%2Bv211130.jar,
            #     https://media.forgecdn.net/files/3550/48/ferritecore-4.0.0-fabric.jar,
            #     https://github.com/astei/krypton/releases/download/v0.1.6/krypton-0.1.6.jar
            #     https://cdn.modrinth.com/data/hvFnDODi/versions/0.1.2/lazydfu-0.1.2.jar,
            #     https://media.forgecdn.net/files/3565/566/lithium-fabric-mc1.18.1-0.7.6.jar,
            #     https://cdn.modrinth.com/data/H8CaAYZC/versions/Starlight%201.0.0%201.18.x/starlight-1.0.0+fabric.d0a3220.jar,
            #     https://media.forgecdn.net/files/3542/373/textile_backup-2.3.0-1.18.jar,
            #     https://media.forgecdn.net/files/3591/173/spark-fabric.jar,
            #     https://github.com/gnembon/carpet-extra/releases/download/1.4.56/carpet-extra-1.18-1.4.56.jar,
            #     https://media.forgecdn.net/files/3554/499/Couplings-1.7.1%2B1.18.jar,
            #     https://cdn.modrinth.com/data/NNqujQWr/versions/1.0.10/healthcare-1.0.10.jar,
            #     https://media.forgecdn.net/files/3579/660/Chunky-1.2.164.jar,
            #     https://github.com/jpenilla/MiniMOTD/releases/download/v2.0.5/minimotd-fabric-mc1.18-2.0.5.jar,
            #     https://github.com/plan-player-analytics/Plan/releases/download/5.4.1516/PlanFabric-5.4-build-1516.jar,
            #     https://media.forgecdn.net/files/3542/724/BlueMap-1.7.2-fabric-1.18.jar,
            #     https://cdn.modrinth.com/data/doqSKB0e/versions/1.2.3+1.18.1/styled-chat-1.2.3+1.18.jar,
            #     https://media.forgecdn.net/files/3573/712/fabric-language-kotlin-1.7.1%2Bkotlin.1.6.10.jar,
            #     https://cdn.modrinth.com/data/p1ewR5kV/versions/0.3.4/unifiedmetrics-platform-fabric-0.3.4.jar,
            #     https://media.forgecdn.net/files/3541/799/ledger-1.2.0.jar,
            #     https://media.forgecdn.net/files/3585/804/beenfo-1.18.1-fabric0.45.0-1.3.3.jar,
            #     https://media.forgecdn.net/files/3545/767/LuckPerms-Fabric-5.3.86.jar
            ClothConfig = pkgs.fetchurl {
              url = "https://cdn.modrinth.com/data/9s6osm5g/versions/2deYQULk/cloth-config-13.0.138-fabric.jar";
              sha256 = "0spmq7b0b54b3r050hjip1rmshznxc95zzzxdpdff8kqgwmxrc54";
            };
          }
        );
      };
    };
  };
  users.users.willy.extraGroups = [ "minecraft" ];
}
