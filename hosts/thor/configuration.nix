{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ./users.nix
  ];

  networking.hostName = "thor";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "26.05";

  programs.nix-ld.enable = true;
}
