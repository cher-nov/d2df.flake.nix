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

    armv8 = rec {
      androidAbi = "arm64-v8a";
      clangTriplet = "aarch64-linux-android";
      compiler = clangTriplet;
      sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
      ndkLib = "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}";
      ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      name = "android-arm64-v8a";
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

  ndkPackagesByArch =
    lib.mapAttrs' (abi: abiAttrs: let
      inherit (abiAttrs) androidAbi;
      common = import ../_common {
        inherit lib pkgs pins;
        arch = androidAbi;
        cmake = let
          cmakeFlags = lib.concatStringsSep " " [
            "-DCMAKE_POLICY_DEFAULT_CMP0057=NEW"
            "-DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake"
            "-DANDROID_ABI=${androidAbi}"
            "-DANDROID_PLATFORM=${androidPlatform}"
            "-DANDROID_STL=c++_static"
          ];
        in "${pkgs.cmake}/bin/cmake ${cmakeFlags}";
      };
    in {
      name = abiAttrs.name;
      value =
        lib.recursiveUpdate {
          infoAttrs = abiAttrs;
          inherit androidSdk;
        }
        common;
    })
    architectures;
in
  ndkPackagesByArch
