{
  description = "Doom2D flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

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
            fpc = prev.callPackage fpcPkgs.base {
              fpc = prev.fpc;
              archsAttrs = {};
            };
            wadcvt = final.callPackage d2dfPkgs.wadcvt {
              #inherit d2df-sdl;
              # FIXME
              # wadcvt stopped building due to a regression some long time ago
              # Pin some old commit to keep it building meanwhile
              d2df-sdl = final.fetchgit {
                url = "https://repo.or.cz/d2df-sdl.git";
                rev = "f628f55ae39e87c3a8e0c6204e3e8a847d683618";
                sha256 = "sha256-e16bVIufFPo2JpD/dKeyZoNr6j1ps49xcEGqJU1YT30=";
              };
              fpc = final.fpc;
            };
            dfwad = final.callPackage d2dfPkgs.dfwad {};
          })
        ];
      };
      lib = pkgs.lib;
      fpcPkgs = import ./fpc;
      d2dfPkgs = import ./game;

      buildWadScript = d2dfPkgs.buildWadScript;
      wads = lib.listToAttrs (lib.map (wad: {
        name = wad;
        value = pkgs.callPackage d2dfPkgs.buildWad {
          outName = wad;
          lstPath = "${wad}.lst";
          inherit buildWadScript doom2df-res;
        };
      }) ["game" "editor" "shrshade" "standart" "doom2d" "doomer"]);
      bundles = import ./game/bundle {
        inherit (pkgs) callPackage;
      };
      assets = import ./game/assets {
        inherit (pkgs) callPackage;
      };
      defaultAssetsPath = assets.mkAssetsPath {
        doom2dWad = wads.doom2d;
        doomerWad = wads.doomer;
        standartWad = wads.standart;
        shrshadeWad = wads.shrshade;
        gameWad = wads.game;
        editorWad = wads.editor;
        # FIXME
        # Dirty, hardcoded assets
        flexuiWad = ./game/assets/dirtyAssets/flexui.wad;
        botlist = ./game/assets/dirtyAssets/botlist.txt;
        botnames = ./game/assets/dirtyAssets/botnames.txt;
      };
    in {
      dfInputs = {
        inherit d2df-sdl d2df-editor doom2df-res;
      };
      legacyPackages.android = (import ./packages/android.nix).default {
        inherit pkgs lib fpcPkgs d2dfPkgs d2df-sdl doom2df-res d2df-editor;
        androidRoot = assets.androidRoot;
        androidRes = assets.androidIcons;
        gameAssetsPath = defaultAssetsPath;
        inherit (bundles) mkAndroidApk mkExecutablePath;
      };

      legacyPackages.assets = assets;
      legacyPackages.defaultAssets = defaultAssetsPath;

      legacyPackages.mingw = (import ./packages/mingw.nix).default {
        inherit pkgs lib fpcPkgs d2dfPkgs d2df-sdl doom2df-res d2df-editor;
        inherit (bundles) mkExecutablePath mkAssetsPath mkGamePath;
        gameAssetsPath = defaultAssetsPath;
      };

      legacyPackages.lazarus = pkgs.callPackage ./lazarus {
        fpc-git = pkgs.fpc;
      };

      legacyPackages.fpc-git = pkgs.fpc;
      legacyPackages.wadcvt = pkgs.wadcvt;
      legacyPackages.dfwad = pkgs.dfwad;
      legacyPackages.wads = wads;

      devShell = with pkgs;
        mkShell rec {
          buildInputs = [
            bash
            alejandra
            nixd
            jq
            _7zz
            git
            findutils
          ];
        };
    });
}
