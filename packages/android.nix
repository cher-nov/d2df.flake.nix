{
  default = {
    pkgs,
    lib,
    fpcPkgs,
    d2dfPkgs,
    androidRoot,
    androidRes,
    gameAssetsPath,
    mkAndroidApk,
    d2df-sdl,
    doom2df-res,
    d2df-editor,
    ...
  }: let
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
    androidPkgs = import ../cross/android {
      inherit androidSdk androidNdk androidPlatform androidNdkBinutils;
      inherit d2df-sdl doom2df-res;
      inherit fpcPkgs d2dfPkgs;
      lib = pkgs.lib;
      inherit pkgs;
    };
    universalAdditional = {
      doom2df-sdl2_mixer-apk = mkAndroidApk {
        inherit androidSdk;
        inherit androidRoot androidRes gameAssetsPath;
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
    };
  in
    lib.recursiveUpdate androidPkgs universalAdditional;

  # If one ever dared to compile for ancient Android, they would need this.
  /*
  old = ...
  */
}
