{
  description = "Flutter 3.13.x";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
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
          })
        ];
      };
      lib = pkgs.lib;
      fpcPkgs = import ./fpc;
      d2dfPkgs = import ./game;

      doom2df-res = pkgs.fetchgit {
        url = "https://github.com/Doom2D/DF-Res.git";
        rev = "08172877ab51feafb50469523a6ebe738efdd16d";
        hash = "sha256-XEb/8DRcQA6BOOQVHcsA3SiR1IPKLoBEwirfmDK0Xmw=";
      };

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
      legacyPackages.android = (import ./packages/android.nix).default {
        inherit pkgs lib fpcPkgs d2dfPkgs;
        androidRoot = assets.androidRoot;
        androidRes = assets.androidIcons;
        gameAssetsPath = defaultAssetsPath;
        mkAndroidApk = bundles.mkAndroidApk;
      };

      legacyPackages.mingw = (import ./packages/mingw.nix).default {
        inherit pkgs lib fpcPkgs d2dfPkgs;
        gameAssetsPath = defaultAssetsPath;
        mkGameBundle = bundles.mkGameBundle;
      };

      legacyPackages.fpc-git = pkgs.fpc;
      legacyPackages.wads = wads;

      devShell = with pkgs;
        mkShell rec {
          buildInputs = [
            bash
            alejandra
            nixd
          ];
        };
    });
}
