{ config, lib, ... }:
let
  cfg = config.homelab.services.windrose;
in
{
  imports = [ ./docker.nix ];

  options.homelab.services.windrose = {
    enable = lib.mkEnableOption "the Windrose container";
    image = lib.mkOption {
      type = lib.types.str;
      default = "indifferentbroccoli/windrose-server-docker";
      description = "Container image (currently a mutable upstream tag).";
    };
    ports = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "OCI host:container/protocol mappings; empty publishes no ports.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.windrose-env.file = ../secrets + "/${config.networking.hostName}/windrose-env.age";

    systemd.tmpfiles.rules = [
      "d /srv/windrose/gooncave 0755 1001 100 -"
      "Z /srv/windrose/gooncave - 1001 100 -"
    ];

    virtualisation.oci-containers = {
      containers.windrose = {
        image = cfg.image;
        ports = cfg.ports;
        autoStart = true;
        volumes = [
          "/srv/windrose/gooncave/server-files:/home/steam/server-files"
        ];
        environment = {
          PUID = "1001";
          PGID = "100"; # users group
          UPDATE_ON_START = "true";
          SERVER_NAME = "SlaveUndertheTY Windrose";
          MAX_PLAYERS = "10";
        };
        environmentFiles = [
          config.age.secrets.windrose-env.path
        ];
      };
    };
  };
}
