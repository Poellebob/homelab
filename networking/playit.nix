{ config, inputs, ... }:
{
  imports = [ inputs.playit.nixosModules.default ];

  # Each importing host provides its own age.secrets.playit-secret.file.
  services.playit = {
    enable = true;
    secretPath = config.age.secrets.playit-secret.path;
  };
}
