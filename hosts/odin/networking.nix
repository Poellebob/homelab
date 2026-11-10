{ config, ... }:
{
  imports = [
    ../../networking/playit.nix
    ../../networking/cloudflared.nix
  ];

  age.secrets = {
    playit-secret.file = ../../secrets + "/${config.networking.hostName}/playit-secret.age";
    cloudflared-token.file =
      ../../secrets + "/${config.networking.hostName}/cloudflared-credentials.age";
  };

  services.cloudflared.tunnels."08a28900-8147-4461-9e13-23bd661b4d95" = {
    credentialsFile = config.age.secrets.cloudflared-token.path;
    default = "http_status:404";
    ingress = {
      "odin.poellebob.xyz".service = "ssh://localhost:22";
    };
  };
}
