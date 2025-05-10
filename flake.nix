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
        f {
          inherit system;
          pkgs = import nixpkgs {inherit system;};
        });
    mkPackages = {
      system,
      pkgs,
    }: let
      inherit
        (packwiz2nix.lib.${system})
        fetchPackwizModpack
        mkMultiMCPack
        ;
    in rec {
      server = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        hash = "sha256-EJKJ8LN9aCqWGXBw3FcObZdyl0kCk+KXfF4i528FyHc=";
        side = "server";
      };

      client = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        hash = "sha256-bOKLp3KvjKAFrue7Q9FyTkXQ11rzLhhX+w5+N0Go5h4=";
        side = "client";
      };

      client-instance = mkMultiMCPack {
        src = client;
        instanceCfg = ./multimc-files/instance.cfg;
        extraFiles = {
          "mmc-pack.json" = ./multimc-files/mmc-pack.json;
        };
      };

      default = client;
    };
  in {
    overlay = final: prev:
      mkPackages {
        pkgs = prev;
        system = prev.system;
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
