{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.services.hacker;
in
{
  imports = [ ./base.nix ./forge.nix ];

  options.homelab.services.hacker = {
    enable = lib.mkEnableOption "this existing Forge installation";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start the server automatically at boot.";
    };
    port = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "Override the game port; null keeps externally managed server.properties.";
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/minecraft/hacker-hytten/";
      description = "Directory containing the existing Forge installation and world.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-servers.enable = true;
    services.forge-servers.servers.hacker = {
      enable = true;
      autoStart = cfg.autoStart;
      description = "Minecraft Server: Hacker man";
      dataDir = cfg.dataDir;
      java = pkgs.temurin-bin-17;
      javaArgs =
        "-Xmx10G @libraries/net/minecraftforge/forge/1.20.1-47.4.0/unix_args.txt"
        + lib.optionalString (cfg.port != null) " --port ${toString cfg.port}";
    };
  };
}
