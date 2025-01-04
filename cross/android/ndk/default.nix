{
  lib,
  pkgs,
  fetchFromGitHub,
  stdenv,
  pins,
}: let
  androidCmakeDrv = {
    pname,
    version,
    src,
  }: {
    androidSdk,
    androidNdk,
    androidAbi,
    androidPlatform,
    cmakeListsPath ? null,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit version src;
      pname = "${pname}-${androidAbi}";

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        ${cmakePrefix} \
          ${pkgs.cmake}/bin/cmake .. \
            -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
            -DCMAKE_POLICY_DEFAULT_CMP0057=NEW \
            -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${androidAbi} -DANDROID_PLATFORM=${androidPlatform} \
            -DCMAKE_INSTALL_PREFIX=$out -DANDROID_STL=c++_static \
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
in rec {
  SDL2 = androidCmakeDrv rec {
    pname = "SDL2";
    version = pins.SDL2.revision;
    src = pins.SDL2;
  };

  enet = androidCmakeDrv {
    pname = "enet";
    version = pins.enet.revision;
    src = pins.enet;
  };

  SDL2_mixer = androidCmakeDrv {
    pname = "SDL2_mixer";
    version = pins.SDL2_mixer.revision;
    src = pins.SDL2_mixer;
  };

  # Upstream packaging is horrendous.
  opusfile = androidCmakeDrv {
    pname = "opusfile";
    version = pins.opusfile_git.revision;
    src = pins.opusfile_git;
  };

  libogg = androidCmakeDrv {
    pname = "libogg";
    version = pins.libogg.revision;
    src = pins.libogg;
  };

  libopus = androidCmakeDrv {
    pname = "opus";
    version = pins.libopus.revision;
    src = pins.libopus;
  };

  libxmp = androidCmakeDrv {
    pname = "libxmp";
    version = pins.libxmp.revision;
    src = pins.libxmp;
  };

  fluidsynth = androidCmakeDrv {
    pname = "fluidsynth";
    version = pins.fluidsynth.revision;
    src = pins.fluidsynth;
  };

  wavpack = androidCmakeDrv {
    pname = "wavpack";
    version = pins.wavpack.revision;
    src = pins.wavpack;
  };

  libmpg123 = androidCmakeDrv {
    pname = "mpg123";
    version = pins.mpg123.revision;
    src = pins.mpg123;
  };

  libvorbis = androidCmakeDrv {
    pname = "vorbis";
    version = pins.vorbis.revision;
    src = pins.vorbis;
  };

  game-music-emu = androidCmakeDrv {
    pname = "game-music-emu";
    version = pins.game-music-emu.revision;
    src = pins.game-music-emu;
  };

  libmodplug = androidCmakeDrv {
    pname = "libmodplug";
    version = pins.modplug.revision;
    src = pins.modplug;
  };

  openal = androidCmakeDrv {
    pname = "openal-soft";
    version = pins.openal.revision;
    src = pins.openal;
  };
}
