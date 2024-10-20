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
        };
      };
      buildToolsVersion = "34.0.0";
      cmakeVersion = "3.22.1";
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        buildToolsVersions = [buildToolsVersion "28.0.3"];
        platformVersions = ["34" "31" "28" "21"];
        abiVersions = ["armeabi-v7a" "arm64-v8a"];
        cmakeVersions = [cmakeVersion];
        includeNDK = true;
        ndkVersions = ["21.4.7075529"];

        includeSources = false;
        includeSystemImages = false;
        useGoogleAPIs = false;
        useGoogleTVAddOns = false;
        includeEmulator = false;
      };
      androidSdk = androidComposition.androidsdk;
    in {
      packages.fpc-android = pkgs.callPackage ./fpc.nix {inherit androidSdk;};
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
            jdk8
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
