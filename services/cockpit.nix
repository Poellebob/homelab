{ pkgs, ... }:
{
  services.cockpit = {
    enable = true;
    port = 9090;
    openFirewall = true;
    plugins = with pkgs; [
      cockpit-podman
    ];
  };
}
