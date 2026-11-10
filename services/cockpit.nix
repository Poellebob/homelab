{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.services.cockpit;
in
{
  options.homelab.services.cockpit = {
    enable = lib.mkEnableOption "Cockpit";
    port = lib.mkOption {
      type = lib.types.port;
      description = "Local listening port; declare explicitly in flake.nix.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      port = cfg.port;
      openFirewall = true;
      plugins = with pkgs; [
        cockpit-podman
      ];
    };
  };
}
