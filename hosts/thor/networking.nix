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

  services.cloudflared.tunnels."b18d3ecb-208a-4124-8c9b-7ae9a5354679" = {
    credentialsFile = config.age.secrets.cloudflared-token.path;
    default = "http_status:404";
    ingress = {
      "thor.poellebob.xyz".service = "ssh://localhost:22";
    };
  };
}
