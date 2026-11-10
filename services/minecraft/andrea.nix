{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  port = mkOption {
    type = types.port;
    description = "Local listening port; declare explicitly in flake.nix.";
  };
  cfg = config.homelab.services.andrea;
  serverSidedModHash = "a081467fdd8fc497b74faa39efcec39edf167c71";
  serversided = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/SESG-HTX-LAN/server-modpack/${serverSidedModHash}/pack.toml";
    packHash = "sha256-yjMV6GZ2ZNP2j/v6am4bGpP0jQobGvjhyoRYpNvtuX4=";
  };
in
{
  imports = [ ./base.nix ];

  options.homelab.services.andrea = {
    enable = lib.mkEnableOption "this Minecraft Fabric server";
    autoStart = lib.mkOption {
      type = types.bool;
      default = true;
      description = "Start the server automatically at boot.";
    };
    inherit port;
    voiceChat = {
      inherit port;
      bindAddress = mkOption {
        type = types.str;
        default = "";
        description = "Voice-chat bind address; empty uses the server address.";
      };
      publicEndpoint = mkOption {
        type = types.str;
        description = "Advertised voice-chat host:port; external mapping is managed separately.";
      };
    };
    resourcePack.publicUrl = mkOption {
      type = types.str;
      description = "Advertised resource-pack URL; external mapping is managed separately.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.minecraft-servers.enable = true;
    services.minecraft-servers.servers.andrea = {
      enable = true;
      autoStart = cfg.autoStart;
      openFirewall = true;
      enableReload = true;

      jvmOpts = "-Xms2G -Xmx4G";
      serverProperties = {
        server-port = cfg.port;
        difficulty = "normal";
        gamemode = "survival";
        motd = "Velkommen til the Dreamhouse (for alle goblins og eller Barbi entusiaster)";
        max-players = 20;
        level-name = "world";
      };

      package = pkgs.fabricServers.fabric-26_1_2.override {
        jre_headless = pkgs.openjdk25_headless;
      };

      symlinks = {
        mods = "${serversided}/mods";
      };

      files = {
        config = "${serversided}/config";
        "config/voicechat/voicechat-server.properties" = pkgs.writeTextFile {
          name = "voicechat-server.properties";
          text = ''
            port=${toString cfg.voiceChat.port}
            bind_address=${cfg.voiceChat.bindAddress}
            max_voice_distance=48.0
            whisper_distance=24.0
            codec=VOIP
            mtu_size=1275
            tcp_rate_limit=16
            keep_alive=1000
            enable_groups=true
            voice_host=${cfg.voiceChat.publicEndpoint}
            allow_recording=true
            spectator_interaction=false
            spectator_player_possession=false
            force_voice_chat=false
            login_timeout=10000
            broadcast_range=-1.0
            allow_pings=true
            use_natives=true
            threaded_server_support=false
          '';
        };
        "config/polymer/auto-host.json" = pkgs.writeTextFile {
          name = "auto-host";
          text = builtins.toJSON {
            enabled = true;
            required = true;
            mod_override = true;
            type = "polymer:automatic";

            settings = {
              forced_address = cfg.resourcePack.publicUrl;
            };

            message = "This server uses resource pack to enhance gameplay with custom textures and models. It might be unplayable without them.";
            disconnect_message = "Couldn't apply server resourcepack!";
            informative_disconnect = true;
            external_resource_packs = [ ];
            setup_early = false;
            resource_pack_status_dialog = true;
            dialog_title = "The server's resource pack is still generating!";
            dialog_default_body = "Waiting...";
            dialog_body_header = "This server requires a resource pack, which hasn't finished generating yet...\nIt might take a while for it to finish!";
            dialog_show_status = true;
            dialog_show_dots = true;
            clear_all_client_resource_packs = false;
            include_hash_in_name = true;
            cache_control_max_age = 31536000;
            delay_player_list_motd_until_generated = false;
          };
        };
      };
    };

    users.users.minecraft = {
      shell = pkgs.bashInteractive;
    };
  };
}
