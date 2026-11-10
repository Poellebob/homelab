{ ... }:
{
  services.forge-servers.servers.star = {
    enable = true;
    description = "Minecraft Server: Star Tech";
    dataDir = "/srv/minecraft/StarT-Theta-2-Hotfix-1/";
    javaArgs = "@user_jvm_args.txt @libraries/net/minecraftforge/forge/1.20.1-47.4.20/unix_args.txt --nogui";
  };
}
