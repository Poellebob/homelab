{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  config = lib.mkIf config.services.minecraft-servers.enable {
    services.minecraft-servers = {
      eula = true;
      user = "minecraft";
      group = "minecraft";
      managementSystem.tmux.enable = true;
    };

    environment.systemPackages = [
      pkgs.tmux
      pkgs.mcrcon
      (pkgs.writeShellApplication {
        name = "mc-attach";
        runtimeInputs = with pkgs; [
          tmux
          coreutils
        ];
        text = ''
          if [ $# -eq 0 ]; then
            echo "Usage: mc-attach <server-name>"
            echo ""
            echo "Available servers:"
            for sock in /run/minecraft/*.sock; do
              [ -e "$sock" ] || continue
              name=$(basename "$sock" .sock)
              echo "  $name -> tmux -S $sock attach"
            done
            exit 1
          fi

          name=$1
          sock="/run/minecraft/$name.sock"

          if [ ! -S "$sock" ]; then
            echo "error: socket $sock not found" >&2
            exit 1
          fi

          exec tmux -S "$sock" attach
        '';
      })
      (pkgs.writeShellApplication {
        name = "mc-console";
        runtimeInputs = [ pkgs.tmux ];
        text = ''
          if [ $# -eq 0 ]; then
            echo "Usage: mc-console <server-name> [command]"
            echo "  Sends a command to the server console without attaching."
            exit 1
          fi

          name=$1
          shift
          sock="/run/minecraft/$name.sock"

          if [ ! -S "$sock" ]; then
            echo "error: socket $sock not found" >&2
            exit 1
          fi

          tmux -S "$sock" send-keys -t mc "$*" Enter
        '';
      })
    ];
  };
}
