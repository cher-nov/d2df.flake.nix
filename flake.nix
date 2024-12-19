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
      buildToolsVersion = "35.0.0";
      cmakeVersion = "3.22.1";
      ndkVersion = "27.0.12077973";
      ndkBinutilsVersion = "22.1.7171670";
      platformToolsVersion = "35.0.2";
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [buildToolsVersion "28.0.3"];
        inherit platformToolsVersion;
        platformVersions = ["34" "31" "28" "21"];
        abiVersions = ["armeabi-v7a" "arm64-v8a"];
        cmakeVersions = [cmakeVersion];
        includeNDK = true;
        ndkVersions = [ndkVersion ndkBinutilsVersion];

        includeSources = false;
        includeSystemImages = false;
        useGoogleAPIs = false;
        useGoogleTVAddOns = false;
        includeEmulator = false;
      };
      androidSdk = androidComposition.androidsdk;
      androidNdk = "${androidSdk}/libexec/android-sdk/ndk-bundle";
      androidNdkBinutils = "${androidSdk}/libexec/android-sdk/ndk/${ndkBinutilsVersion}";
      androidPlatform = "21";
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
      androidPkgs = import ./cross/android {
        inherit androidSdk androidNdk androidPlatform androidNdkBinutils;
        inherit fpcPkgs d2dfPkgs;
        lib = pkgs.lib;
        inherit pkgs;
      };
      mingwPkgs = import ./cross/mingw {
        inherit pkgs lib;
        inherit fpcPkgs d2dfPkgs;
      };
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
      legacyPackages.android = androidPkgs;
      legacyPackages.mingw = mingwPkgs;
      legacyPackages.doom2df-sdl2_mixer-apk = bundles.mkAndroidApk {
        inherit androidSdk;
        androidRoot = assets.androidRoot;
        androidRes = assets.androidIcons;
        assetsPath = defaultAssetsPath;
        SDL2ForJava = androidPkgs.byArch.arm64-v8a.SDL2;
        customAndroidFpcPkgs =
          lib.mapAttrs (abi: ndkPkgs: let
            inherit (ndkPkgs) doom2df-library enet SDL2 SDL2_mixer libxmp fluidsynth opus opusfile ogg vorbis libgme libmodplug openal mpg123;  
          in {
            nativeBuildInputs = [enet SDL2 openal fluidsynth SDL2_mixer libxmp opus opusfile ogg vorbis libgme libmodplug mpg123];
            doom2df = doom2df-library;
          })
           androidPkgs.byArch;
      };
      legacyPackages.fpc-git = pkgs.fpc;
      legacyPackages.wads = wads;

      devShell = with pkgs;
        mkShell rec {
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          ANDROID_NDK = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          ANDROID_JAVA_HOME = "${pkgs.jdk17.home}";
          NDK = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          PATH = "${androidSdk}:${androidSdk}/libexec/android-sdk/ndk-bundle:\$PATH";
          nativeBuildInputs = [cmake];
          buildInputs = [
            bash
            alejandra
            nixd
            androidSdk # The customized SDK that we've made above
            jdk17
            gradle
            #self.packages."${system}".fpc-android
          ];

          shellHook = ''
            export PATH="$ANDROID_SDK_ROOT/cmake/${cmakeVersion}/bin:$PATH";
            export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH";
            export PATH="$ANDROID_SDK_ROOT/tools:$PATH";
            export PATH="$ANDROID_SDK_ROOT/build-tools:$PATH";
            export PATH="$ANDROID_SDK_ROOT/cmdline-tools:$PATH";
            export PATH="$ANDROID_SDK_ROOT/ndk-bundle:$PATH";
          '';
        };
    });
}
