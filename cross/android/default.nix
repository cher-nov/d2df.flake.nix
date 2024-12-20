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
            inherit SDL2 SDL2_mixer enet openal fluidsynth libxmp vorbis opus opusfile mpg123 libgme ogg libmodplug;
            libopus = opus;
            libogg = ogg;
            libmpg123 = mpg123;
            libvorbis = vorbis;
            disableSound = false;
            withSDL2_mixer = true;
            withFluidsynth = true;
            withModplug = true;
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
  };
in
  universal // {byArch = ndkPackagesByArch;}
