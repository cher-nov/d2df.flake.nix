{
  pkgs,
  lib,
  pins,
  osxcross,
}: let
  toolchain = osxcross.packages.${pkgs.system}.toolchain_15_2;
  sdk = "${toolchain}/SDK/MacOSX15.2.sdk";
  target = "apple-darwin22.1";
  mkMacCmakeDrv = target: {
    pname,
    version,
    src,
  }: {
    cmakeListsPath ? null,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${pkgs.cmake}/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit version src;
      pname = "${pname}-${target}";

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = let
        CFLAGS = lib.concatStringsSep " " [
          "-target ${target}"
          "-resource-dir ${pkgs.llvmPackages_17.clang-unwrapped.lib}/lib/clang/17"
          "-L${sdk}/usr/lib"
          "-L${sdk}/usr/lib/system"
          "-isysroot ${sdk}"
          "-isystem ${sdk}/usr/include"
          "-iframework ${sdk}/System/Library/Frameworks"
          "-I${pkgs.llvmPackages_17.clang-unwrapped.lib}/lib/clang/17/include"
          "-I${sdk}/usr/include"
        ];
        CXXFLAGS = CFLAGS;
        LDFLAGS = lib.concatStringsSep " " [
          "-target ${target}"
          "-I${pkgs.llvmPackages_17.clang-unwrapped.lib}/lib/clang/17/include"
          "-L${sdk}/usr/lib"
          "-L${sdk}/usr/lib/system"
          "-I${sdk}/usr/include"
          "-isystem ${sdk}/usr/include"
          "-iframework ${sdk}/System/Library/Frameworks"
        ];
      in ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        export OSXCROSS_SDK="${sdk}"
        export OSXCROSS_HOST="${target}"
        export OSXCROSS_TARGET="${toolchain}"
        export OSXCROSS_TARGET_DIR="${toolchain}"
        export OSXCROSS_CLANG_INTRINSIC_PATH="${pkgs.llvmPackages.clang-unwrapped.lib}/lib/clang/"
        export CFLAGS="$CFLAGS ${CFLAGS}"
        export CXXFLAGS="$CXXFLAGS ${CXXFLAGS}"
        export LDFLAGS="$LDFLAGS ${LDFLAGS}"
        ${cmakePrefix} \
          ${cmake} .. \
            -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" \
            -DCMAKE_TOOLCHAIN_FILE=${osxcross}/tools/toolchain.cmake \
            -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF \
            -DCMAKE_INSTALL_PREFIX=$out \
            ${cmakeExtraArgs}
        make -j$(nproc)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        make install
        runHook postInstall
      '';
    });
  mkMacArch = target: fpcCpu: fpcBinary: {
    caseSensitive = true;
    d2dforeverFeaturesSuport = {
      openglDesktop = true;
      openglEs = true;
      supportsHeadless = true;
      loadedAsLibrary = false;
    };
    isWindows = false;
    bundle = {
      io = "SDL2";
      sound = "OpenAL";
      graphics = "OpenGL2";
      headless = "Disable";
      holmes = "Enable";
    };
    fpcAttrs = rec {
      cpuArgs = [
        "-XP${toolchain}/bin/${target}-"
        "-Fl${sdk}/usr/lib"
        "-Fl${sdk}/usr/lib/system"
        "-k-F${sdk}/System/Library/Frameworks/"
        "-k-L${sdk}/usr/lib"
        "-k-L${sdk}/usr/lib/system"
        #"-k-mmacosx-version-min=11.0"
      ];
      targetArg = "-Tdarwin";
      basename = fpcBinary;
      makeArgs = {
        OS_TARGET = "darwin";
        CPU_TARGET = fpcCpu;
        CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
      };
      lazarusExists = false;
      toolchainPaths = [
        "${toolchain}/bin"
      ];
    };
  };
  mkMacCrossPkg = target: triplet: fpcCpu: fpcBinary: let
    cross = (import ../_common {inherit pins;}) {cmakeDrv = mkMacCmakeDrv target;};
  in rec {
    infoAttrs = mkMacArch target fpcCpu fpcBinary;
    libxmp = cross.libxmp {
      cmakeExtraArgs = lib.concatStringsSep " " [
        "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
        "-DCMAKE_PREFIX_PATH=${libogg}"
      ];
    };
    libogg = cross.libogg {};
    openal = (cross.openal {}).overrideAttrs (prev: {
      preBuild = ''
        rm -r build
      '';
    });
    game-music-emu = cross.game-music-emu {
      cmakeExtraArgs = "-DENABLE_UBSAN=off";
    };
    miniupnpc = cross.miniupnpc {};
    libmpg123 = cross.libmpg123 {
      cmakeListsPath = "ports/cmake";
    };
    libmodplug = cross.libmodplug {};
    wavpack = cross.wavpack {};
    libopus = cross.libopus {};
    fluidsynth =
      (cross.fluidsynth {
        cmakeExtraArgs = lib.concatStringsSep " " [
          "-DBUILD_SHARED_LIBS=on"
          "-Denable-threads=off"
          "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
          "-Denable-sdl2=on"
          "-Denable-framework=off"
          "-DCMAKE_PREFIX_PATH=${SDL2}"
        ];
      })
      .overrideAttrs (final: prev: {
        nativeBuildInputs = [pkgs.buildPackages.stdenv.cc pkgs.pkg-config];
        installPhase =
          prev.installPhase
          + ''
            [[ -f "$out/lib64/libfluidsynth.dylib" ]] && cp -r $out/lib64/* $out/lib/ || :
          '';
      });
    libvorbis = cross.libvorbis {
      cmakeExtraArgs = lib.concatStringsSep " " [
        "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
        "-DCMAKE_PREFIX_PATH=${libogg}"
        "-DCMAKE_FIND_ROOT_PATH=${libogg}"
        "-DOGG_LIBRARY=${libogg}/lib/libogg.dylib"
        "-DOGG_INCLUDE_DIR=${libogg}/include"
      ];
    };
    SDL2_mixer =
      (cross.SDL2_mixer {
        cmakeExtraArgs = let
          libs = pkgs.symlinkJoin {
            name = "cmake-packages";
            paths =
              [libxmp fluidsynth wavpack SDL2 libopus libogg libmodplug libmpg123]
              # These are projects which can't be found by pkgconfig for some reason.
              # Specify their path manually.
              ++ [
                # vorbis
                # opusfile
                # libgme
              ];
          };
        in
          lib.concatStringsSep " " [
            "-DBUILD_SHARED_LIBS=on"
            "-DSDL2MIXER_VENDORED=off"

            "-DSDL2MIXER_VORBIS=VORBISFILE"
            "-DSDL2MIXER_VORBIS_VORBISFILE_SHARED=off"
            "-DVorbis_vorbisfile_INCLUDE_PATH=${libvorbis}/include"
            "-DVorbis_vorbisfile_LIBRARY=${libvorbis}/lib/libvorbisfile.dylib"

            "-DSDL2MIXER_MP3=on"
            "-DSDL2MIXER_MP3_MPG123=on"
            "-DSDL2MIXER_MP3_MPG123_SHARED=off"

            "-DSDL2MIXER_OPUS=on"
            "-DSDL2MIXER_OPUS_SHARED=off"
            "-DOpusFile_LIBRARY=${opusfile}/lib/libopusfile.dylib"
            "-DOpusFile_INCLUDE_PATH=${opusfile}/include"

            "-DSDL2MIXER_GME=on"
            "-DSDL2MIXER_GME_SHARED=off"
            "-Dgme_LIBRARY=${game-music-emu}/lib/libgme.dylib"
            "-Dgme_INCLUDE_PATH=${game-music-emu}/include"

            "-DSDL2MIXER_MIDI=on"
            "-DSDL2MIXER_MIDI_TIMIDITY=on"
            "-DSDL2MIXER_MIDI_FLUIDSYNTH=on"
            "-DSDL2MIXER_MIDI_FLUIDSYNTH_SHARED=off"
            "-DFluidSynth_LIBRARY=${fluidsynth}/lib/libfluidsynth.dylib"
            "-DFluidSynth_INCLUDE_PATH=${fluidsynth}/include"

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
    opusfile = let
      paths = pkgs.symlinkJoin {
        name = "cmake-packages";
        paths = [libogg libopus];
      };
    in
      (cross.opusfile {
        cmakeExtraArgs = lib.concatStringsSep " " [
          "-DOP_DISABLE_HTTP=on"
          "-DOP_DISABLE_DOCS=on"
          "-DOP_DISABLE_HTTP=on"
          "-DOP_DISABLE_EXAMPLES=on"
          "-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH"
          "-DCMAKE_PREFIX_PATH=${paths}"
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
    enet = cross.enet {};
    SDL2 = cross.SDL2 {};
  };
in {
  arm64-apple-darwin = mkMacCrossPkg "aarch64-apple-darwin22.1" "aarch64-apple-darwin" "aarch64" "crossa64";
  x86_64-apple-darwin = mkMacCrossPkg "x86_64-apple-darwin22.1" "x86_64-apple-macosx11.0.0" "x86_64" "cx64";
}
