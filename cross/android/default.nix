{
  lib,
  pkgs,
  pins,
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

  architectures = {
    armv7 = rec {
      androidAbi = "armeabi-v7a";
      clangTriplet = "arm-linux-androideabi";
      compiler = "armv7a-linux-androideabi";
      sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
      ndkLib = "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}";
      ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      name = "android-armeabi-v7a";
      isAndroid = true;
      isWindows = false;
      bundleFormats = ["apk"];
      caseSensitive = true;
      pretty = "Android ${androidAbi}, platform level ${androidPlatform}, NDK ${ndkVersion}";
      d2dforeverFeaturesSuport = {
        openglDesktop = false;
        openglEs = true;
        supportsHeadless = false;
        loadedAsLibrary = true;
      };
      fpcAttrs = rec {
        lazarusExists = false;
        cpuArgs = ["-CpARMV7A" "-CfVFPV3" "-Fl${ndkLib}" "-XP${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/${clangTriplet}/bin/"];
        targetArg = "-Tandroid";
        basename = "crossarm";
        makeArgs = {
          OS_TARGET = "android";
          CPU_TARGET = "arm";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
          NDK = "${androidNdk}";
        };
        toolchainPaths = [
          ndkToolchain
          ndkBinutilsToolchain
        ];
      };
    };

    armv8 = let
      sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
      androidAbi = "arm64-v8a";
      clangTriplet = "aarch64-linux-android";
      ndkLib = "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}";
      ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      pretty = "Android ${androidAbi}, platform level ${androidPlatform}, NDK ${ndkVersion}";
    in rec {
      compiler = clangTriplet;
      name = "android-arm64-v8a";
      isAndroid = true;
      isWindows = false;
      bundleFormats = ["apk"];
      caseSensitive = true;
      d2dforeverFeaturesSuport = {
        openglDesktop = false;
        openglEs = true;
        supportsHeadless = false;
        loadedAsLibrary = true;
      };
      fpcAttrs = rec {
        lazarusExists = false;
        cpuArgs = ["-CpARMV8" "-CfVFP" "-Fl${ndkLib}" "-XP${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/${clangTriplet}/bin/"];
        targetArg = "-Tandroid";
        basename = "crossa64";
        makeArgs = {
          OS_TARGET = "android";
          CPU_TARGET = "aarch64";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
          NDK = "${androidNdk}";
        };
        toolchainPaths = [
          ndkToolchain
          ndkBinutilsToolchain
        ];
      };
    };
  };

  #mkArch = androidAbi: clangTriplet: name: fpcCpu: fpcFloat: basename: androidPlatform: let
  mkArch = args @ {
    androidNativeBundleAbi,
    clangTriplet,
    compiler,
    name,
    CPU_TARGET,
    fpcCpu,
    fpcFloat,
    basename,
    isOldNdk ? false,
    ndkOldArch ? null,
    androidPlatform,
  }: let
    /*
    androidAbi = "arm64-v8a";
    name = "android-arm64-v8a";
    clangTriplet = "aarch64-linux-android";
    compiler = clangTriplet;
    CPU_TARGET = "aarch64";
    fpcCpu = "ARMV8";
    fpcFloat = "VFP";
    androidPlatform = "21";
    */
    sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
    ndkLib =
      if !isOldNdk
      then "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}"
      else "${androidNdkBinutils}/platforms/android-${androidPlatform}/arch-${ndkOldArch}/usr/lib";
    ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
    ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
    pretty = "Android ${androidNativeBundleAbi}, platform level ${androidPlatform}, NDK ${ndkVersion}";
  in rec {
    inherit androidNativeBundleAbi;
    isAndroid = true;
    isWindows = false;
    bundleFormats = ["apk"];
    caseSensitive = true;
    d2dforeverFeaturesSuport = {
      openglDesktop = false;
      openglEs = true;
      supportsHeadless = false;
      loadedAsLibrary = true;
    };
    fpcAttrs = let
      cpuArgs = ["-Cp${fpcCpu}" "-Cf${fpcFloat}" "-Fl${ndkLib}" "-XP${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/${clangTriplet}/bin/"];
    in {
      lazarusExists = false;
      inherit cpuArgs;
      targetArg = "-Tandroid";
      basename = basename;
      makeArgs = {
        OS_TARGET = "android";
        CPU_TARGET = CPU_TARGET;
        CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
        NDK = "${androidNdk}";
      };
      toolchainPaths = [
        ndkToolchain
        ndkBinutilsToolchain
      ];
    };
  };

  mkCrossPkg = args @ {
    androidNativeBundleAbi,
    clangTriplet,
    name,
    compiler,
    CPU_TARGET,
    fpcCpu,
    fpcFloat,
    basename,
    isOldNdk ? false,
    ndkOldArch ? false,
    androidPlatform,
  }: let
    common = import ../_common {
      inherit lib pkgs pins;
      arch = androidNativeBundleAbi;
      cmake = let
        cmakeFlags = lib.concatStringsSep " " [
          "-DCMAKE_POLICY_DEFAULT_CMP0057=NEW"
          "-DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake"
          "-DANDROID_ABI=${androidNativeBundleAbi}"
          "-DANDROID_PLATFORM=${androidPlatform}"
          "-DANDROID_NDK=${androidNdk}"
          "-DANDROID_STL=c++_static"
        ];
      in "${pkgs.cmake}/bin/cmake ${cmakeFlags}";
    };
  in
    lib.recursiveUpdate {
      infoAttrs = mkArch args;
      inherit androidSdk;
    }
    common;
in {
  arm64-v8a-linux-android = mkCrossPkg {
    androidNativeBundleAbi = "arm64-v8a";
    name = "android-arm64-v8a";
    clangTriplet = "aarch64-linux-android";
    compiler = "aarch64-linux-android";
    CPU_TARGET = "aarch64";
    basename = "crossa64";
    fpcCpu = "ARMV8";
    fpcFloat = "VFP";
    isOldNdk = false;
    androidPlatform = let
      int = lib.strings.toInt androidPlatform;
    in
      if int < 21
      then "21"
      else androidPlatform;
  };

  armeabi-v7a-linux-android = mkCrossPkg {
    androidNativeBundleAbi = "armeabi-v7a";
    name = "armv7a-linux-androideabi";
    clangTriplet = "arm-linux-androideabi";
    compiler = "armv7a-linux-androideabi";
    CPU_TARGET = "arm";
    basename = "crossarm";
    fpcCpu = "ARMV7A";
    fpcFloat = "VFPV3";
    isOldNdk = false;
    androidPlatform = let
      int = lib.strings.toInt androidPlatform;
    in
      if int < 5
      then "5"
      else androidPlatform;
  };
}
