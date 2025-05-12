{
  description = "Minecraft create modpack";

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
        hash = "sha256-Vovz1erZU+pVGFRtdi9fol4FNLjpJThBWOzj6LVA8qY=";
      };

      client = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        side = "client";
        hash = "sha256-CU8XTR/S7XrxP0GFUz9PanMOwGtvIq/W/7/az4ePAn4=";
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
