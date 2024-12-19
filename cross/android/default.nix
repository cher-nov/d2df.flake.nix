{
  androidSdk,
  androidNdk,
  androidNdkBinutils,
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
      compiler = "armv7a-linux-androideabi";
      sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
      ndkLib = "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}";
      ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
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
        toolchainPaths = [
          ndkToolchain
          ndkBinutilsToolchain
        ];
      };
    };

    armv8 = rec {
      androidAbi = "arm64-v8a";
      clangTriplet = "aarch64-linux-android";
      sysroot = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/sysroot";
      ndkLib = "${sysroot}/usr/lib/${clangTriplet}/${androidPlatform}";
      ndkToolchain = "${androidNdk}/toolchains/llvm/prebuilt/linux-x86_64/bin";
      ndkBinutilsToolchain = "${androidNdkBinutils}/toolchains/llvm/prebuilt/linux-x86_64/bin";
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
        toolchainPaths = [
          ndkToolchain
          ndkBinutilsToolchain
        ];
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
      d8 = "${ANDROID_HOME}/build-tools/35.0.0/d8";
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
      openal =
        (customNdkPkgs.openal {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          cmakeExtraArgs = lib.concatStringsSep " " [
            "-DALSOFT_UTILS=off"
            "-DALSOFT_EXAMPLES=off"
            "-DALSOFT_BACKEND_SDL2=on"
            "-DALSOFT_REQUIRE_SDL2=on"
            "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
            "-DCMAKE_PREFIX_PATH=${SDL2}"
            "-DCMAKE_FIND_ROOT_PATH=${SDL2}"
          ];
        })
        .overrideAttrs (prev: {
          preBuild = ''
            rm -r build
          '';
        });
      vorbis = customNdkPkgs.vorbis {
        inherit androidSdk androidNdk androidAbi androidPlatform;
        cmakeExtraArgs = lib.concatStringsSep " " [
          "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
          "-DCMAKE_PREFIX_PATH=${ogg}"
          "-DCMAKE_FIND_ROOT_PATH=${ogg}"
        ];
      };
      libgme = customNdkPkgs.libgme {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      mpg123 = customNdkPkgs.libmpg123 {
        inherit androidSdk androidNdk androidAbi androidPlatform;
        cmakeListsPath = "ports/cmake";
      };
      libmodplug = customNdkPkgs.libmodplug {
        inherit androidSdk androidNdk androidAbi androidPlatform;
      };
      fluidsynth =
        (customNdkPkgs.fluidsynth {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          cmakeExtraArgs = lib.concatStringsSep " " [
            "-DBUILD_SHARED_LIBS=on"
            "-Denable-sdl2=on"
            "-Denable-threads=off"
            "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
            "-DCMAKE_PREFIX_PATH=${SDL2}"
            "-DANDROID_NDK=${androidNdk}"
            "-DANDROID_COMPILER_FLAGS=\"-shared\""
          ];
        })
        .overrideAttrs (prev: {
          nativeBuildInputs = [pkgs.buildPackages.stdenv.cc pkgs.pkg-config];
        });
      wavpack = customNdkPkgs.wavpack {
        inherit androidSdk androidNdk androidAbi androidPlatform;
        # fails on armv7 32 bit
        # See https://github.com/curl/curl/pull/13264
        cmakeExtraArgs = "-DCMAKE_REQUIRED_FLAGS=\"-D_FILE_OFFSET_BITS=64\"";
      };

      opusfile =
        (customNdkPkgs.opusfile {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          cmakeExtraArgs = lib.concatStringsSep " " [
            "-DOP_DISABLE_HTTP=on"
            "-DOP_DISABLE_DOCS=on"
            "-DOP_DISABLE_HTTP=on"
            "-DOP_DISABLE_EXAMPLES=on"
            "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
            "-DCMAKE_PREFIX_PATH=${pkgs.symlinkJoin {
              name = "cmake-packages";
              paths = [ogg opus];
            }}"
          ];
        })
        .overrideAttrs (prev: {
          patches = [
            (pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/NixOS/nixpkgs/refs/heads/nixos-24.11/pkgs/by-name/op/opusfile/include-multistream.patch";
              sha256 = "sha256-MXkkFmu6NgHbZL3ChtiYsOlwMBSvdSpBaLvrI1RhzgU=";
            })
          ];
          buildPhase =
            ''
              substituteInPlace CMakeLists.txt \
              --replace "list(GET PROJECT_VERSION_LIST 1 PROJECT_VERSION_MINOR)" ""
            ''
            + prev.buildPhase;
          installPhase =
            prev.installPhase
            + ''
              substituteInPlace $out/include/opus/opusfile.h \
              --replace "<opus_multistream.h>" "<opus/opus_multistream.h>"
            '';
          nativeBuildInputs = [pkgs.pkg-config];
        });

      SDL2_mixer =
        (customNdkPkgs.SDL2_mixer {
          inherit androidSdk androidNdk androidAbi androidPlatform;
          # FIXME
          # For some reason this doesn't pickup environment variables to change pkgconfig path.

          cmakeExtraArgs = let
            libs = pkgs.symlinkJoin {
              name = "cmake-packages";
              paths =
                [libxmp fluidsynth wavpack SDL2 opus ogg libgme libmodplug mpg123]
                # These are projects which are broken regarding packaging.
                # Specify their path manually.
                ++ [
                  # vorbis
                  # opusfile
                ];
            };
          in
            lib.concatStringsSep " " [
              "-DBUILD_SHARED_LIBS=on"
              "-DSDL2MIXER_VENDORED=off"

              "-DSDL2MIXER_VORBIS=VORBISFILE"
              "-DSDL2MIXER_VORBIS_VORBISFILE_SHARED=off"
              "-DVorbis_vorbisfile_INCLUDE_PATH=${vorbis}/include"
              "-DVorbis_vorbisfile_LIBRARY=${vorbis}/lib/libvorbisfile.so"

              "-DSDL2MIXER_MP3=on"
              "-DSDL2MIXER_MP3_MPG123=on"
              "-DSDL2MIXER_MP3_MPG123_SHARED=off"

              "-DSDL2MIXER_OPUS=on"
              "-DSDL2MIXER_OPUS_SHARED=off"
              "-DOpusFile_LIBRARY=${opusfile}/lib/libopusfile.so"
              "-DOpusFile_INCLUDE_PATH=${opusfile}/include"

              "-DSDL2MIXER_GME=on"
              "-DSDL2MIXER_GME_SHARED=off"

              "-DSDL2MIXER_MIDI=on"
              "-DSDL2MIXER_MIDI_TIMIDITY=off"
              "-DSDL2MIXER_MIDI_FLUIDSYNTH=on"
              "-DSDL2MIXER_MIDI_FLUIDSYNTH_SHARED=off"

              "-DSDL2MIXER_MOD=on"
              "-DSDL2MIXER_MOD_MODPLUG=off"
              "-DSDL2MIXER_MOD_XMP=on"
              "-DSDL2MIXER_MOD_XMP_SHARED=off"

              "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
              "-DCMAKE_PREFIX_PATH=${libs}"
              "-DCMAKE_FIND_ROOT_PATH=${libs}"
              "-DSDL2MIXER_MOD_XMP_SHARED=off"
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
        inherit enet SDL2 SDL2_mixer opusfile ogg opus libxmp fluidsynth wavpack vorbis libgme libmodplug openal mpg123;
        doom2df-library = let
          f = d2dfPkgs;
        in
          pkgs.callPackage f.doom2df-unwrapped {
            fpc = fpc-wrapper;
            inherit SDL2 SDL2_mixer enet openal fluidsynth libxmp vorbis opus opusfile mpg123 libgme ogg;
            libopus = opus;
            libogg = ogg;
            libmpg123 = mpg123;
            libvorbis = vorbis;
            disableSound = false;
            withSDL2_mixer = true;
            withFluidsynth = true;
            withLibxmp = true;
            withOpus = true;
            withVorbis = true;
            withOpenAL = false;
            withMpg123 = true;
            withLibgme = true;
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
          inherit (ndkPkgs) doom2df-library enet SDL2 SDL2_mixer libxmp fluidsynth opus opusfile ogg vorbis libgme libmodplug openal mpg123;
        in {
          nativeBuildInputs = [enet SDL2 openal fluidsynth SDL2_mixer libxmp opus opusfile ogg vorbis libgme libmodplug mpg123];
          doom2df = doom2df-library;
        })
        ndkPackagesByArch;
    };
  };
in
  universal // ndkPackagesByArch
