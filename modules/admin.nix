{ config, lib, ... }:
{
  # Nix trust permits remote store operations and is root-equivalent access.
  nix.settings.trusted-users = [ "admin" ];

  users.users.admin = {
    description = "admin";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ] ++ lib.optional (lib.any (name: config.homelab.services.${name}.enable)
      [ "htx" "andrea" "bedwars" "star" "hacker" ]) "minecraft";
    openssh.authorizedKeys.keys = import ../keys.nix;
  };

  security.sudo.wheelNeedsPassword = true;
  security.sudo.extraConfig = ''
    Defaults:admin noninteractive_auth
  '';
  security.pam = {
    sshAgentAuth.enable = true;
    services.sudo.sshAgentAuth = true;
  };

  assertions = [
    {
      assertion = config.users.users.admin.openssh.authorizedKeys.keys != [ ];
      message = "Configure an admin SSH public key in keys.nix or the host's users.nix.";
    }
  ];
}
