{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.services.bedwars;
  bedwarsConfHash = "f6aa2f19d2afdcfdf146ab7e7fbb8d65a21af2ff";
  bedwars = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/SESG-HTX-LAN/bedwars-server/${bedwarsConfHash}/pack.toml";
    packHash = "sha256-xw72z8BgbTXcaKffJyIVYR52bKgf16wIM9oFon8+COY=";
  };

  spigotJar = pkgs.fetchurl {
    url = "https://cdn.getbukkit.org/spigot/spigot-1.12.2.jar";
    hash = "sha256-RIa3gV7WyF6LLmr54vV5/wluWliL7BpEcBWZP9UhOPE=";
  };

  spigot = pkgs.vanillaServers.vanilla-1_12_2.overrideAttrs (_: {
    src = spigotJar;
    jre_headless = pkgs.openjdk17_headless;
  });
in
{
  imports = [ ./base.nix ];

  options.homelab.services.bedwars = {
    enable = lib.mkEnableOption "the Bedwars server";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start the server automatically at boot.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      description = "Local listening port; declare explicitly in flake.nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-servers.enable = true;
    services.minecraft-servers.servers.bedwars = {
      enable = true;
      autoStart = cfg.autoStart;
      openFirewall = true;
      enableReload = true;

      package = spigot;

      jvmOpts = "-javaagent:slimeworldmanager-classmodifier-2.2.1.jar -Xms1024M -Xmx6144M -Dfile.encoding=UTF-8";

      serverProperties = {
        server-port = cfg.port;
        motd = "Bedwars!!";
        max-players = 30;
      };

      extraReload = ''
        cp -rn ${bedwars}/* /srv/minecraft/bedwars
        chown -R minecraft:minecraft /srv/minecraft/bedwars/
      '';
    };
  };
}
