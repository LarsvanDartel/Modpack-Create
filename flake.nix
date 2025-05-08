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
  in {
    packages = eachSystem ({system, ...}: let
      inherit
        (packwiz2nix.lib.${system})
        fetchPackwizModpack
        mkMultiMCPack
        ;
    in rec {
      modpack = fetchPackwizModpack {
        manifest = "${self}/pack.toml";
        hash = "sha256-cA8W3+D/UGK9mEqkQ9Y3JrPBpZFa/DI93oPXjH4pnZw=";
      };

      modpack-zip = mkMultiMCPack {
        src = modpack;
        instanceCfg = ./multimc-files/instance.cfg;
        extraFiles = {
          "mmc-pack.json" = ./multimc-files/mmc-pack.json;
        };
      };

      default = modpack-zip;
    });

    devShells = eachSystem ({pkgs, ...}: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          packwiz
        ];
      };
    });
  };
}
