{
  description = "Two-node NixOS homelab managed with Colmena";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    colmena = {
      url = "github:nix-community/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.stable.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    playit = {
      url = "github:pedorich-n/playit-nixos-module";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      colmena,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.nix-minecraft.overlays.default ];
      };
      hosts = [
        "thor"
        "odin"
      ];
    in
    {
      colmenaHive = colmena.lib.makeHive ({
        meta = {
          nixpkgs = pkgs;
          specialArgs = { inherit inputs; };
        };

        defaults = {
          imports = [
            ./modules/server.nix
            inputs.nix-minecraft.nixosModules.minecraft-servers
            inputs.agenix.nixosModules.default
          ];
          deployment = {
            targetUser = "admin";
            buildOnTarget = true;
            tags = [ "homelab" ];
            sshOptions = [
              "-o"
              "ForwardAgent=yes"
            ];
          };
        };

        odin = {
          imports = [
            ./hosts/odin/configuration.nix

            ./services/minecraft/base.nix
            ./services/minecraft/htx.nix
            ./services/minecraft/bedwars.nix
            ./services/minecraft/console.nix
          ];
          deployment.targetHost = "odin";

        };

        thor = {
          imports = [
            ./hosts/thor/configuration.nix

            ./services/minecraft/base.nix
            ./services/minecraft/forge.nix
            ./services/minecraft/andrea.nix
            ./services/minecraft/star.nix
            ./services/minecraft/hacker.nix
            ./services/minecraft/console.nix

            ./services/cockpit.nix
            ./services/windrose.nix
          ];
          deployment.targetHost = "thor";
        };
      });

      nixosConfigurations = self.colmenaHive.nodes;
    };
}
