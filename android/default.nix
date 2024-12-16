{
  androidSdk,
  androidNdk,
  androidPlatform,
  fpc-custom,
  lib,
  pkgs,
}: let
  customNdkPkgs = import ./ndk {
    inherit lib pkgs;
    inherit (pkgs) fetchFromGitHub stdenv;
  };

  architectures = {
    armv7 = rec {
      androidAbi = "armeabi-v7a";
      ndkLib = "${androidNdk}/platforms/android-${androidPlatform}/arch-arm/usr/lib";
      ndkToolchain = "${androidNdk}/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin";
      fpcAttrs = rec {
        cpuArgs = ["-CpARMV7A" "-CfVFPV3" "-Fl${ndkLib}"];
        targetArg = "-Tandroid";
        basename = "crossarm";
        makeArgs = {
          OS_TARGET = "android";
          CPU_TARGET = "arm";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
          NDK = "${androidNdk}";
        };
        extraPaths = [ndkToolchain];
      };
    };
    armv8 = rec {
      androidAbi = "arm64-v8a";
      ndkLib = "${androidNdk}/platforms/android-${androidPlatform}/arch-arm64/usr/lib";
      ndkToolchain = "${androidNdk}/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin";
      fpcAttrs = rec {
        cpuArgs = ["-CpARMV8" "-CfVFP" "-Fl${ndkLib}"];
        targetArg = "-Tandroid";
        basename = "crossa64";
        makeArgs = {
          OS_TARGET = "android";
          CPU_TARGET = "aarch64";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
          NDK = "${androidNdk}";
        };
        extraPaths = [ndkToolchain];
      };
    };
  };

  doom2df-android = {
    stdenv,
    jdk17,
    findutils,
    coreutils-full,
    file,
    androidSdk,
    lib,
    SDL2ForJava,
    # Example:
    # {"arm64-v8a" = { nativeBuildInputs = [SDL2_custom enet_custom]; doom2df = ...}; }
    customAndroidFpcPkgs,
  }:
    stdenv.mkDerivation (finalAttrs: let
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_JAR = "${ANDROID_HOME}/platforms/android-34/android.jar";
      aapt = "${ANDROID_HOME}/build-tools/28.0.3/aapt";
      d8 = "${ANDROID_HOME}/build-tools/34.0.0/d8";
      jdk = jdk17;
    in {
      version = "0.667-git";
      pname = "d2df-apk";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      nativeBuildInputs = [findutils jdk coreutils-full file];

      src = ../game/android;

      buildPhase =
        # Precreate directories to be used in the build process.
        ''
          mkdir -p bin obj gen
          mkdir -p resources ass/lib
        ''
        # Populate native library directories for supported platforms.
        + (let
          copyLibraries = abi: libraries: let
            i = lib.map (x: "ln -s ${x}/lib/*.so ass/lib/${abi}") libraries;
          in
            lib.concatStringsSep "\n" i;
          f = abi: abiAttrs: ''
            mkdir -p "ass/lib/${abi}"
            ${(copyLibraries abi abiAttrs.nativeBuildInputs)}
            ln -s "${abiAttrs.doom2df}/lib/libDoom2DF.so" ass/lib/${abi}/libDoom2DF.so
          '';
        in
          (lib.foldlAttrs (acc: name: value: acc + (f name value)) "" customAndroidFpcPkgs)
          + ''
            cp -r assets/* resources
          '')
        # Use SDL Java sources from the version we compiled our game with.
        + ''
          rm -r src/org/libsdl/app/*
          cp -r "${SDL2ForJava.src}/android-project/app/src/main/java/org/libsdl/app" "src/org/libsdl"
        ''
        # Build the APK.
        + ''
          ${aapt} package -f -m -S res -J gen -M AndroidManifest.xml -I ${ANDROID_JAR}
          ${jdk}/bin/javac -encoding UTF-8 -source 1.8 -target 1.8 -classpath "${ANDROID_JAR}" -d obj gen/org/d2df/app/R.java $(find src -name '*.java')
          ${d8} $(find obj -name '*.class') --lib ${ANDROID_JAR} --output bin/classes.jar
          ${d8} ${ANDROID_JAR} bin/classes.jar --output bin
          ${aapt} package -f -M ./AndroidManifest.xml -S res -I ${ANDROID_JAR} -F bin/d2df.unsigned.apk -A resources bin ass
          ${jdk}/bin/keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -v
          ${jdk}/bin/jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar bin/d2df.signed.apk bin/d2df.unsigned.apk androiddebugkey
        '';

      installPhase = ''
        mkdir -p $out/bin
        cp bin/d2df.signed.apk $out/bin
      '';
    });

  ndkPackagesByArch =
    lib.mapAttrs (abi: abiAttrs: let
      inherit (abiAttrs) androidAbi ndkToolchain ndkLib fpcAttrs;
      enet = customNdkPkgs.enet {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      SDL2 = customNdkPkgs.SDL2 {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      fpc = customNdkPkgs.fpc {
        inherit androidSdk androidNdk androidAbi androidPlatform;
        inherit ndkToolchain ndkLib;
        inherit fpcAttrs;
      };
      fpc-wrapper = customNdkPkgs.fpc-wrapper {
        inherit androidSdk androidNdk androidAbi androidPlatform;
        inherit ndkToolchain ndkLib;
        inherit fpcAttrs fpc;
      };
    in {
      inherit enet SDL2 fpc;
      doom2df-library = pkgs.callPackage customNdkPkgs.doom2df-library {
        inherit SDL2 enet;
        fpc = fpc-wrapper;
      };
    })
    architectures;
  universal = {
    doom2df-android = pkgs.callPackage doom2df-android {
      inherit androidSdk;
      SDL2ForJava = ndkPackagesByArch.armv8.SDL2;
      customAndroidFpcPkgs = {
        "arm64-v8a" = {
          nativeBuildInputs = [ndkPackagesByArch.armv8.enet ndkPackagesByArch.armv8.SDL2];
          doom2df = ndkPackagesByArch.armv8.doom2df-library;
        };
      };
    };
  };
in
  universal // ndkPackagesByArch
