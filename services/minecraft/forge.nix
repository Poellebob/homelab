{
  config,
  lib,
  pkgs,
  ...
}:
let
  servers = lib.filterAttrs (_: server: server.enable) config.services.forge-servers.servers;

  mkForgeServer =
    name: server:
    let
      sock = "/run/minecraft/${name}.sock";
    in
    {
      description = server.description;
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [
        pkgs.bashInteractive
        pkgs.coreutils
        pkgs.tmux
      ];

      serviceConfig = {
        Type = "forking";
        GuessMainPID = true;
        User = "minecraft";
        Group = "minecraft";
        WorkingDirectory = server.dataDir;

        RuntimeDirectory = "minecraft";
        RuntimeDirectoryPreserve = true;
        RuntimeDirectoryMode = "0770";

        Environment = [
          "SHELL=${pkgs.bashInteractive}/bin/bash"
        ];

        ExecStart = pkgs.writeShellScript "start-${name}" ''
          sock=${sock}
          rm -f "$sock"
          export SHELL="${pkgs.bashInteractive}/bin/bash"
          ${pkgs.tmux}/bin/tmux -S "$sock" set-option -g default-shell "${pkgs.bashInteractive}/bin/bash" \; new-session -d -s mc \
            '${server.java}/bin/java ${server.javaArgs}'
          ${pkgs.tmux}/bin/tmux -S "$sock" server-access -agw minecraft 2>/dev/null || true
          ${pkgs.tmux}/bin/tmux -S "$sock" server-access -aw admin 2>/dev/null || true
          ${pkgs.coreutils}/bin/chmod 660 "$sock" || true
        '';

        ExecStop = pkgs.writeShellScript "stop-${name}" ''
          sock=${sock}
          server_running() { ${pkgs.tmux}/bin/tmux -S "$sock" has-session 2>/dev/null; }
          if ! server_running; then exit 0; fi
          ${pkgs.tmux}/bin/tmux -S "$sock" send-keys -t mc C-u "stop" Enter
          while server_running; do sleep 1; done
        '';

        TimeoutStopSec = "120s";
        Restart = "on-failure";
        RestartSec = "10s";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
in
{
  options.services.forge-servers.servers = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        enable = lib.mkEnableOption "this custom Forge server";

        description = lib.mkOption {
          type = lib.types.str;
          default = "Minecraft Forge server";
          description = "Description of the systemd unit.";
        };

        dataDir = lib.mkOption {
          type = lib.types.path;
          description = "Working directory containing the existing Forge installation and world data.";
        };

        java = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jdk17_headless;
          description = "JDK used to run the server.";
        };

        javaArgs = lib.mkOption {
          type = lib.types.str;
          description = "Arguments passed to java, including JVM options and @argfiles.";
        };
      };
    });
    default = { };
    description = "Custom tmux-managed Forge servers, one systemd unit and socket per server.";
  };

  config = {
    systemd.services = lib.mapAttrs' (
      name: server: lib.nameValuePair "minecraft-server-${name}" (mkForgeServer name server)
    ) servers;
  };
}
