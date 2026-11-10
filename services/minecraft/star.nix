{ config, lib, ... }:
let
  cfg = config.homelab.services.star;
in
{
  imports = [
    ./base.nix
    ./forge.nix
  ];

  options.homelab.services.star = {
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
      default = "/srv/minecraft/StarT-Theta-2-Hotfix-1/";
      description = "Directory containing the existing Forge installation and world.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-servers.enable = true;
    services.forge-servers.servers.star = {
      enable = true;
      autoStart = cfg.autoStart;
      description = "Minecraft Server: Star Tech";
      dataDir = cfg.dataDir;
      javaArgs =
        "@user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.4.20/unix_args.txt --nogui"
        + lib.optionalString (cfg.port != null) " --port ${toString cfg.port}";
    };
  };
}
