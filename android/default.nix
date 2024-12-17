{
  androidSdk,
  androidNdk,
  androidPlatform,
  fpcPkgs,
  d2dfPkgs,
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
      clangTriplet = "arm-linux-androideabi";
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
        toolchainPaths = [ndkToolchain];
      };
    };
    armv8 = rec {
      androidAbi = "arm64-v8a";
      clangTriplet = "aarch64-linux-android";
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
        toolchainPaths = [ndkToolchain];
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
    lib.mapAttrs' (abi: abiAttrs: let
      inherit (abiAttrs) androidAbi ndkToolchain ndkLib fpcAttrs;
      enet = customNdkPkgs.enet {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      SDL2 = customNdkPkgs.SDL2 {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      ogg = customNdkPkgs.ogg {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      opus = customNdkPkgs.opus {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      libxmp = customNdkPkgs.libxmp {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      fluidsynth =
        (customNdkPkgs.fluidsynth {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          cmakeExtraArgs = "--debug-output";
          #cmakeExtraArgs = "-DCMAKE_C_COMPILER=\"${toolchainPath}/bin/clang --target=${abiAttrs.clangTriplet}${androidPlatform}\"";
          #${toolchainPath}/bin/clang --target=${abiAttrs.clangTriplet}${androidPlatform}
        })
        .overrideAttrs {
          nativeBuildInputs = [pkgs.buildPackages.stdenv.cc];
        };
      wavpack = customNdkPkgs.wavpack {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };

      opusfile =
        (customNdkPkgs.opusfile {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          cmakeExtraArgs = "-DOP_DISABLE_HTTP=on -DOP_DISABLE_DOCS=on -DOP_DISABLE_HTTP=on";
        })
        .overrideAttrs (prev: {
          buildPhase =
            ''
              substituteInPlace CMakeLists.txt \
              --replace "list(GET PROJECT_VERSION_LIST 1 PROJECT_VERSION_MINOR)" ""
            ''
            + prev.buildPhase;
          nativeBuildInputs = [pkgs.pkg-config];
          env.PKG_CONFIG_PATH = "${ogg}/lib/pkgconfig:${opus}/lib/pkgconfig";
        });

      # opusfile is absolutely horrible.
      /*
      opusfile = let
        drv = {
          androidSdk,
          androidNdk,
          androidAbi,
          androidPlatform,
          abiAttrs,
        }:
          pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
            pname = "opusfile";
            version = "0.12-git";
            src = pkgs.fetchFromGitHub {
              owner = "xiph";
              repo = "opusfile";
              rev = "9d718345ce03b2fad5d7d28e0bcd1cc69ab2b166";
              hash = "sha256-kyvH3b/6ouAXffAE4xmck4L5c3/nd2VWq0ss/XJlX7Q=";
            };
            phases = ["unpackPhase" "buildPhase" "installPhase"];
            env = let
              toolchainPath = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64";
            in {
              LD = "${toolchainPath}/bin/ld";
              RANLIB = "${toolchainPath}/bin/llvm-ranlib";
              STRIP = "${toolchainPath}/bin/llvm-strip";
              CC = "${toolchainPath}/bin/clang --target=${abiAttrs.clangTriplet}${androidPlatform}";
              CXX = "${toolchainPath}/bin/clang++ --target=${abiAttrs.clangTriplet}${androidPlatform}";
              CFLAGS =
                (lib.concatStringsSep " " (lib.map (x: "-I${x}/include") [ogg opus]))
                + " "
                + (lib.concatStringsSep " " (lib.map (x: "-L${x}/lib") [ogg opus]))
                + " "
                + lib.concatStringsSep " " ["-lm" "-shared" "-lopus" "-logg" "-olibopusfile.so" "-Iinclude" "-I${opus}/include/opus"];
            };
            buildPhase = ''
              eval $CC $CFLAGS src/info.c src/internal.c src/opusfile.c src/stream.c
            '';

            installPhase = ''
              mkdir -p $out/{lib,include/opus}
              cp include/* $out/include/opus -r
              substituteInPlace $out/include/opus/opusfile.h \
                --replace "<ogg/ogg.h>" "<ogg.h>"
              cp libopusfile.so $out/lib
            '';
          });
      in
        drv {inherit androidSdk androidNdk androidAbi androidPlatform abiAttrs;};
      */

      SDL2_mixer =
        (customNdkPkgs.SDL2_mixer {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          # FIXME
          # For some reason this doesn't pickup environment variables to change pkgconfig path.

          cmakeExtraArgs = lib.concatStringsSep " " [
            "-DSDL2MIXER_VORBIS=off"
            "-DSDL2MIXER_OPUS=off"
            "-DSDL2MIXER_VENDORED=off"
            "-DBUILD_SHARED_LIBS=on"
            "-DSDL2_LIBRARY=${SDL2}/lib/libSDL2.so"
            "-DSDL2_INCLUDE_DIR=${SDL2}/include/SDL2"
            #"-DOpusFile_LIBRARY=${opusfile}/lib/libopusfile.so"
            #"-DOpusFile_INCLUDE_PATH=${opusfile}/include"
            "-Dlibxmp_LIBRARY=${libxmp}/lib/libxmp.so"
            "-Dlibxmp_INCLUDE_PATH=${libxmp}/include"
            "-DSDL2MIXER_MOD_XMP_SHARED=off"
            "-DFluidSynth_LIBRARY=${fluidsynth}/lib/libfluidsynth.so"
            "-DFluidSynth_INCLUDE_PATH=${fluidsynth}/include"
            "-Dwavpack_LIBRARY=${wavpack}/lib/libwavpack.so"
            "-Dwavpack_INCLUDE_PATH=${wavpack}/include"
          ];
        })
        .overrideAttrs (prev: {
          nativeBuildInputs = [pkgs.pkg-config];
        });
      fpc-wrapper = pkgs.callPackage fpcPkgs.wrapper {
        fpc = universal.fpc-android;
        inherit fpcAttrs;
      };
    in {
      name = androidAbi;
      value = {
        inherit enet SDL2 SDL2_mixer opusfile ogg opus libxmp fluidsynth wavpack;
        doom2df-library = let
          f = d2dfPkgs;
        in
          pkgs.callPackage f.doom2df-unwrapped {
            fpc = fpc-wrapper;
            inherit SDL2 enet SDL2_mixer;
            disableSound = false;
            withSDL2_mixer = true;
            glibc = null;
            buildAsLibrary = true;
          };
      };
    })
    architectures;
  universal = {
    fpc-android = pkgs.callPackage fpcPkgs.base {
      archsAttrs = lib.mapAttrs (abi: abiAttrs: abiAttrs.fpcAttrs) architectures;
    };
    doom2df-android = pkgs.callPackage doom2df-android {
      inherit androidSdk;
      SDL2ForJava = ndkPackagesByArch.arm64-v8a.SDL2;
      customAndroidFpcPkgs =
        lib.mapAttrs (abi: ndkPkgs: let
          inherit (ndkPkgs) doom2df-library enet SDL2 SDL2_mixer libxmp;
        in {
          nativeBuildInputs = [enet SDL2 SDL2_mixer libxmp];
          doom2df = doom2df-library;
        })
        ndkPackagesByArch;
    };
  };
in
  universal // ndkPackagesByArch
