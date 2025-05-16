{
  description = "Minecraft create modpack using fabric";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    packwiz2nix.url = "github:LarsvanDartel/packwiz2nix/rewrite";
    packwiz2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    packwiz2nix,
    ...
  }: let
    eachSystem = f:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system:
        f (import nixpkgs {inherit system;}));
    mkPackages = pkgs: let
      inherit (pkgs) system;
      inherit
        (packwiz2nix.lib.${system})
        fetchPackwizModpack
        mkMultiMCPack
        ;
    in rec {
      server = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        side = "server";
        hash = "sha256-vuxjQSUtmHo3GSYIBy9+LJjH/XPy2f72aUMpXTr0ub8=";
      };

      client = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        side = "client";
        hash = "sha256-yJxhJqrl1oZJnwYrM0/rt9zo8qKx0R6CQbZbj0wmVqc=";
      };

      client-instance = mkMultiMCPack {
        src = client;
        instanceCfg = ./multimc-files/instance.cfg;
        extraFiles = {
          "mmc-pack.json" = ./multimc-files/mmc-pack.json;
        };
      };

      default = client-instance;
    };
  in {
    overlay = final: prev: {
      modpack-create = mkPackages prev;
    };
    overlays.default = self.overlay;
    packages = eachSystem mkPackages;
    devShells = eachSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          packwiz
        ];
      };
    });
  };
}
