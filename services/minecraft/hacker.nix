{ pkgs, ... }:
{
  services.forge-servers.servers.hacker = {
    enable = true;
    description = "Minecraft Server: Hacker man";
    dataDir = "/srv/minecraft/hacker-hytten/";
    java = pkgs.temurin-bin-17;
    javaArgs = "-Xmx10G @libraries/net/minecraftforge/forge/1.20.1-47.4.0/unix_args.txt";
  };
}
