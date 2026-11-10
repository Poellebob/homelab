{ pkgs, ... }:
let
  htxServerModHash = "c7bfc2397e9d5151a6e7c42a8362d7fb329fcfe7";
  modpack = pkgs.fetchPackwizModpack {
    url = "https://raw.githubusercontent.com/SESG-HTX-LAN/server-modpack/${htxServerModHash}/pack.toml";
    packHash = "sha256-LKRBDHmSQ/cvRM1BS9VQKw6yseGLijzgpCYmQdQsFVs=";
  };
in
{
  services.minecraft-servers.servers.htx = {
    enable = true;
    autoStart = true;
    openFirewall = true;
    enableReload = true;

    jvmOpts = "-Xms2G -Xmx4G";
    serverProperties = {
      server-port = 25565;
      difficulty = "normal";
      gamemode = "survival";
      motd = "HTX Minecraft server! Installer simple voice chat for ingame proxi chat";
      max-players = 20;
      level-name = "world.2627";
    };
    package = pkgs.fabricServers.fabric-26_1_2.override {
      jre_headless = pkgs.openjdk25_headless;
    };
    symlinks = {
      mods = "${modpack}/mods";
    };
    files = {
      config = "${modpack}/config";
      "config/voicechat/voicechat-server.properties" = pkgs.writeTextFile {
        name = "voicechat-server.properties";
        text = ''
          port=24454
          bind_address=
          max_voice_distance=48.0
          whisper_distance=24.0
          codec=VOIP
          mtu_size=1275
          tcp_rate_limit=16
          keep_alive=1000
          enable_groups=true
          voice_host=69.9.185.16:12864
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
            forced_address = "http://209.25.141.17:24224";
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
}
