{
  pkgs,
  lib,
  fpcPkgs,
  d2dfPkgs,
  ...
}: let
  architectures = {
    mingw32 = rec {
      toolchainPrefix = "i686-w64-mingw32";
      fpcAttrs = rec {
        cpuArgs = [""];
        targetArg = "-Twin32";
        basename = "cross386";
        makeArgs = {
          OS_TARGET = "win32";
          CPU_TARGET = "i386";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
        };
        toolchainPaths = [
          "${pkgs.pkgsCross.mingw32.buildPackages.gcc}/bin"
          "${pkgs.writeShellScriptBin "i386-win32-as" "${pkgs.pkgsCross.mingw32.buildPackages.gcc}/bin/${toolchainPrefix}-as $@"}/bin"
          "${pkgs.writeShellScriptBin "i386-win32-ld" "${pkgs.pkgsCross.mingw32.buildPackages.gcc}/bin/${toolchainPrefix}-ld $@"}/bin"
        ];
      };
    };

    # FIXME
    # Doesn't pass install phase with FPC

    /*
    mingwW64 = rec {
      toolchainPrefix = "x86_64-w64-mingw32";
      fpcAttrs = rec {
        cpuArgs = [""];
        targetArg = "-Twin64";
        basename = "cx64";
        makeArgs = {
          OS_TARGET = "win64";
          CPU_TARGET = "x86_64";
          CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
        };
        toolchainPaths = [
          "${pkgs.pkgsCross.mingw32.buildPackages.gcc}/bin"
          "${pkgs.writeShellScriptBin "x86_64-win64-as" "${pkgs.pkgsCross.mingwW64.buildPackages.gcc}/bin/${toolchainPrefix}-as $@"}/bin"
          "${pkgs.writeShellScriptBin "x86_64-win64-ld" "${pkgs.pkgsCross.mingwW64.buildPackages.gcc}/bin/${toolchainPrefix}-ld $@"}/bin"
        ];
      };
    };
    */
  };
  createCrossPkgSet = abi: abiAttrs: let
    crossTarget = abi;
  in rec {
    gcc = pkgs.pkgsCross.${crossTarget}.buildPackages.wrapCC (pkgs.pkgsCross.${crossTarget}.buildPackages.gcc-unwrapped.override {
      threadsCross = {
        model = "win32";
        package = null;
      };
    });
    stdenvWin32Threads = pkgs.pkgsCross.${crossTarget}.buildPackages.overrideCC pkgs.pkgsCross.${crossTarget}.stdenv gcc;
    enet = (pkgs.pkgsCross.${crossTarget}.enet.override {stdenv = stdenvWin32Threads;}).overrideAttrs (prev: let
      mingwPatchNoUndefined = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/msys2/MINGW-packages/refs/heads/master/mingw-w64-enet/001-no-undefined.patch";
        hash = "sha256-t3fXrYG0h2OkZHx13KPKaJL4hGGJKZcN8vdsWza51Hk=";
      };
      mingwPatchWinlibs = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/msys2/MINGW-packages/refs/heads/master/mingw-w64-enet/002-win-libs.patch";
        hash = "sha256-vD3sKSU4OVs+zHKuMTNpcZC+LnCyiV/SJqf9G9Vj/cQ=";
      };
    in {
      nativeBuildInputs = [pkgs.pkgsCross.${crossTarget}.buildPackages.autoreconfHook];
      patches = [mingwPatchNoUndefined mingwPatchWinlibs];
    });
    SDL2 = pkgs.pkgsCross.${crossTarget}.SDL2.override {stdenv = stdenvWin32Threads;};
    SDL2_mixer =
      (pkgs.pkgsCross.${crossTarget}.SDL2_mixer.override {
        enableSdltest = false;
        enableSmpegtest = false;
        SDL2 = pkgs.pkgsCross.${crossTarget}.SDL2;
        fluidsynth = null;
        smpeg2 = null;
        flac = null;
        timidity = SDL2;
        stdenv = stdenvWin32Threads;
      })
      .overrideAttrs (prev: {
        buildInputs = prev.buildInputs ++ [pkgs.pkgsCross.${crossTarget}.game-music-emu];
        NIX_CFLAGS_LINK = "-D_WIN32_WINNT=0x0501 -static-libgcc";
        NIX_CFLAGS_COMPILE = "-D_WIN32_WINNT=0x0501 -static-libgcc";
        configureFlags =
          prev.configureFlags
          ++ [
            (lib.enableFeature false "music-flac")
            (lib.enableFeature false "music-gme")
            (lib.enableFeature false "music-gme-shared")
            (lib.enableFeature false "music-midi")
            (lib.enableFeature true "music-mp3")
            (lib.enableFeature true "music-mp3-mpg123")
          ];
      });
    libmodplug = pkgs.pkgsCross.${crossTarget}.libmodplug;
    libvorbis = pkgs.pkgsCross.${crossTarget}.libogg;
    opusfile = pkgs.pkgsCross.${crossTarget}.opusfile;
    libopus = pkgs.pkgsCross.${crossTarget}.libopus;
    mpg123 = pkgs.pkgsCross.${crossTarget}.mpg123;
    libgme = pkgs.pkgsCross.${crossTarget}.game-music-emu;
    wavpack = pkgs.pkgsCross.${crossTarget}.wavpack;
    libogg = pkgs.pkgsCross.${crossTarget}.libogg.override {stdenv = stdenvWin32Threads;};
    openal =
      (pkgs.pkgsCross.${crossTarget}.openal.override {
        pipewire = null;
        dbus = null;
        alsa-lib = null;
        libpulseaudio = null;
        stdenv = stdenvWin32Threads;
      })
      .overrideAttrs (prev: {
        /*
        buildInputs =
          prev.buildInputs
          ++ [
            (pkgs.pkgsCross.mingwW64.windows.mcfgthreads)
          ];
        */
        preConfigure = ''
          cmakeFlagsArray+=(
            -DCMAKE_REQUIRED_COMPILER_FLAGS="-D_WIN32_WINNT=0x0501 -static-libgcc -static-libstdc++"
            -DCMAKE_SHARED_LINKER_FLAGS="-D_WIN32_WINNT=0x0501 -static-libgcc -static-libstdc++"
          )
        '';

        postInstall = "";
      });
    #libogg,
    #libvorbis,
    #mpg123,
    doom2d = let
      pkg = d2dfPkgs;
    in
      pkgs.callPackage pkg.doom2df-unwrapped {
        inherit SDL2 enet SDL2_mixer mpg123;
        glibc = null;
        fpc = pkgs.callPackage fpcPkgs.wrapper {
          fpc = universal.fpc-mingw;
          fpcAttrs =
            abiAttrs.fpcAttrs
            // {
              toolchainPaths =
                abiAttrs.fpcAttrs.toolchainPaths
                ++ [
                  "${pkgs.writeShellScriptBin
                    "${abiAttrs.fpcAttrs.makeArgs.CPU_TARGET}-${abiAttrs.fpcAttrs.makeArgs.OS_TARGET}-fpcres"
                    "${universal.fpc-mingw}/bin/fpcres $@"}/bin"
                ];
            };
        };
        withOpenGLES = false;
        withOpenGL2 = true;
        disableGraphics = false;
        disableIo = false;
        disableSound = false;
        withSDL2 = true;
        withSDL2_mixer = false;
        withFmod = true;
        withOpenAL = false;
        withMpg123 = false;
        headless = false;
        # _WIN32_WINNT 0x0400
        buildAsLibrary = false;
      };
  };
  crossPkgs = lib.mapAttrs createCrossPkgSet architectures;
  universal = {
    fpc-mingw = pkgs.callPackage fpcPkgs.base {
      archsAttrs = lib.mapAttrs (abi: abiAttrs: abiAttrs.fpcAttrs) architectures;
    };
  };
in
  universal // crossPkgs
