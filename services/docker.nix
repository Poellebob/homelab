{ config, lib, ... }:
lib.mkIf config.homelab.services.windrose.enable {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
}
