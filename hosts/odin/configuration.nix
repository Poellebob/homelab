{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./users.nix
  ];

  networking.hostName = "odin";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "26.05";

  nix.settings.auto-optimise-store = true;
  programs.nix-ld.enable = true;
}
