{
  description = "Doom2D flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-github-actions.url = "github:nix-community/nix-github-actions";

    DF-res = {
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
    d2df-distro-content = {
      url = "https://doom2d.org/doom2d_forever/latest/df_distro_content.rar";
      flake = false;
    };
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    nix-github-actions,
    DF-res,
    d2df-sdl,
    d2df-editor,
    d2df-distro-content,
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
            wadcvt = final.callPackage d2dfPkgs.wadcvt {
              inherit d2df-sdl;
            };
            dfwad =
              (final.callPackage d2dfPkgs.dfwad {
                })
              .overrideAttrs (final: prev: {
                src = pins.dfwad.src;
              });
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
      assetsLib = import ./game/assets {
        inherit (pkgs) callPackage;
      };

      pins = import ./pins/generated.nix {
        inherit (pkgs) fetchgit fetchurl fetchFromGitHub dockerTools;
      };
    in {
      dfInputs = {
        inherit d2df-sdl d2df-editor DF-res d2df-distro-content;
      };

      checks = let
        nativeArches = lib.removeAttrs self.legacyPackages.${system} ["android" "universal"];
      in
        lib.mapAttrs (n: v: v.drv) (lib.foldl (acc: x: acc // x) {} (lib.map (x: x.executables) (lib.attrValues nativeArches)));

      assetsLib = assetsLib;

      executables = import ./packages/executables.nix {
        inherit pkgs lib fpcPkgs d2dfPkgs;
        inherit d2df-sdl d2df-editor;
        inherit pins;
      };

      assets = import ./packages/assets.nix {
        inherit lib;
        inherit (pkgs) callPackage stdenv writeText;
        inherit DF-res d2df-editor;
        inherit (d2dfPkgs) buildWad;
        inherit (assetsLib) mkAssetsPath;
      };

      inherit pins;

      legacyPackages =
        (import ./packages {
          inherit lib;
          inherit pins;
          inherit (pkgs) callPackage;
          inherit (assetsLib) androidRoot androidIcons;
          defaultAssetsPath = self.assets.${system}.defaultAssetsPath;
          inherit (bundles) mkExecutablePath mkGamePath mkAndroidApk;
          executablesAttrs = self.executables.${system};
        })
        // {
          inherit (pkgs) wadcvt dfwad;
        };

      forPrebuild = let
        thisPkgs = self.legacyPackages.${system};
        allArches = lib.filter (x: x != "universal" && x != "android") (lib.attrNames thisPkgs);
        allDrvs = lib.flatten (lib.map (arch: thisPkgs.${arch}.__forPrebuild) allArches);
      in
        pkgs.linkFarmFromDrvs "cache" allDrvs;

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
            openjdk
            npins
            unrar-wrapper
            rar
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
