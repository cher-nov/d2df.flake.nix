{
  description = "Doom2D flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-github-actions.url = "github:nix-community/nix-github-actions";

    doom2df-res = {
      url = "github:Doom2D/DF-Res";
      flake = false;
    };
    d2df-sdl = {
      url = "git://repo.or.cz/d2df-sdl.git?submodules=1";
      flake = false;
    };
    d2df-editor = {
      url = "git://repo.or.cz/d2df-editor.git?submodules=1";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nix-github-actions,
    doom2df-res,
    d2df-sdl,
    d2df-editor,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = {
          android_sdk.accept_license = true;
          allowUnfree = true;
          allowUnsupportedSystem = true;
        };
        overlays = [
          (final: prev: {
            dfwad = final.callPackage d2dfPkgs.dfwad {};
          })
        ];
      };
      lib = pkgs.lib;
      fpcPkgs = import ./fpc {
        inherit (pkgs) callPackage fetchgit stdenv;
        inherit pkgs;
        inherit lib;
      };
      d2dfPkgs = import ./game;
      bundles = import ./game/bundle {
        inherit (pkgs) callPackage;
      };
      assets = import ./game/assets {
        inherit (pkgs) callPackage;
      };
    in {
      dfInputs = {
        inherit d2df-sdl d2df-editor doom2df-res;
      };

      checks = lib.mapAttrs (n: v: v.drv) (lib.foldl (acc: x: acc // x) {} (lib.map (x: x.executables) (lib.attrValues self.legacyPackages.${system})));

      assets = assets;

      executables = import ./packages/executables.nix {
        inherit pkgs lib fpcPkgs d2dfPkgs;
        inherit d2df-sdl d2df-editor;
      };

      legacyPackages =
        (import ./packages {
          inherit lib;
          inherit (pkgs) callPackage writeText stdenv;
          inherit (d2dfPkgs) buildWad;
          inherit doom2df-res d2df-editor;
          inherit (assets) mkAssetsPath dirtyAssets androidRoot;
          androidRes = assets.androidIcons;
          inherit (bundles) mkExecutablePath mkGamePath mkAndroidApk;
          executablesAttrs = self.executables.${system};
        })
        // {
          fpc-trunk = fpcPkgs.fpc-trunk;
          fpc-3_0_4 = fpcPkgs.fpc-3_0_4;
          fpc-3_2_2 = fpcPkgs.fpc-3_2_2;
        };

      devShells = {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bash
            alejandra
            nixd
            jq
            _7zz
            git
            findutils
            dos2unix
            libfaketime
            coreutils
          ];
        };
      };
    })
    // {
      githubActions = nix-github-actions.lib.mkGithubMatrix {
        # Inherit GHA actions matrix from a subset of platforms supported by hosted runners
        checks = {
          inherit (self.checks) x86_64-linux;
        };
      };
    };
}
