{
  lib,
  pkgs,
  ...
}:
{
  imports = [ ./admin.nix ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = lib.mkDefault true;
    firewall.enable = true;
  };

  services.openssh = {
    enable = true;
    openFirewall = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      UseDns = true;
    };
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    kitty
  ];

  nixpkgs.config.allowUnfree = true;
  time.timeZone = lib.mkDefault "Europe/Copenhagen";
  i18n.defaultLocale = lib.mkDefault "en_DK.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };
  services.xserver.xkb = {
    layout = lib.mkDefault "dk";
    variant = lib.mkDefault "winkeys";
  };
  console.keyMap = lib.mkDefault "dk-latin1";
}
