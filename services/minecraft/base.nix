{ pkgs, ... }:
{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    user = "minecraft";
    group = "minecraft";
    managementSystem.tmux.enable = true;
  };

  environment.systemPackages = [ pkgs.tmux ];
}
