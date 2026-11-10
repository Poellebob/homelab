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
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          colmena.packages.${system}.colmena
          inputs.agenix.packages.${system}.default
          pkgs.cloudflared
        ];
      };

      colmenaHive = colmena.lib.makeHive ({
        meta = {
          nixpkgs = pkgs;
          specialArgs = { inherit inputs; };
        };

        defaults = {
          imports = [
            ./modules/server.nix
            ./modules/services.nix
            inputs.agenix.nixosModules.default
          ];
          homelab.packages = with pkgs; [
            git
            vim
            neovim
            kitty
            btop
            wget
            curl
            cloudflared
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
          imports = [ ./hosts/odin/configuration.nix ];
          homelab = {
            packages = with pkgs; [ ];
            services = {
              htx = {
                enable = true;
                autoStart = true;
                port = 25565;
                voiceChat = {
                  port = 24454;
                  bindAddress = "";
                  publicEndpoint = "69.9.185.16:12864";
                };
                resourcePack.publicUrl = "http://209.25.141.17:24224";
              };
              bedwars = {
                enable = true;
                autoStart = false;
                port = 23344;
              };
            };
          };
          deployment.targetHost = "odin";
        };

        thor = {
          imports = [ ./hosts/thor/configuration.nix ];
          homelab = {
            packages = with pkgs; [
              steamcmd
            ];
            services = {
              andrea = {
                enable = true;
                autoStart = true;
                port = 23343;
                voiceChat = {
                  port = 24454;
                  bindAddress = "";
                  publicEndpoint = "69.9.185.16:37637";
                };
                resourcePack.publicUrl = "http://209.25.141.16:42867";
              };
              star = {
                enable = true;
                autoStart = true;
                port = null;
              };
              hacker = {
                enable = true;
                autoStart = true;
                port = null;
              };
              cockpit = {
                enable = true;
                port = 9090;
              };
              windrose = {
                enable = true;
                ports = [ ];
              };
            };
          };
          deployment.targetHost = "thor";
        };
      });

      nixosConfigurations = self.colmenaHive.nodes;
    };
}
