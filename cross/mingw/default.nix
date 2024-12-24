{
  pkgs,
  lib,
}: let
  createCrossPkgSet = arch: archInfoAttrs: let
    crossTarget = arch;
  in rec {
    infoAttrs = archInfoAttrs;
    gcc = pkgs.pkgsCross.${crossTarget}.buildPackages.wrapCC (pkgs.pkgsCross.${crossTarget}.buildPackages.gcc-unwrapped.override {
      threadsCross = {
        model = "win32";
        package = null;
      };
    });
    stdenvWin32Threads = pkgs.pkgsCross.${crossTarget}.buildPackages.overrideCC pkgs.pkgsCross.${crossTarget}.stdenv gcc;
    enet = (pkgs.pkgsCross.${crossTarget}.enet.override {stdenv = stdenvWin32Threads;}).overrideAttrs (prev: let
      mingwPatchNoUndefined = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/msys2/MINGW-packages/a4bc312869703bda3703fc1cb327fdd7659f0c4b/mingw-w64-enet/001-no-undefined.patch";
        hash = "sha256-t3fXrYG0h2OkZHx13KPKaJL4hGGJKZcN8vdsWza51Hk=";
      };
      mingwPatchWinlibs = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/msys2/MINGW-packages/a4bc312869703bda3703fc1cb327fdd7659f0c4b/mingw-w64-enet/002-win-libs.patch";
        hash = "sha256-vD3sKSU4OVs+zHKuMTNpcZC+LnCyiV/SJqf9G9Vj/cQ=";
      };
    in {
      nativeBuildInputs = [pkgs.pkgsCross.${crossTarget}.buildPackages.autoreconfHook];
      patches = [mingwPatchNoUndefined mingwPatchWinlibs];
      postFixup = ''
        mv $out/bin/libenet-7.dll $out/bin/enet.dll
      '';
    });
    SDL2 = (pkgs.pkgsCross.${crossTarget}.SDL2.override {stdenv = stdenvWin32Threads;}).overrideAttrs (finalAttrs: {});
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
            (lib.enableFeature true "music-mod")
            (lib.enableFeature false "music-mod-modplug")
            (lib.enableFeature false "music-mod-modplug-shared")
            (lib.enableFeature true "music-mod-xmp")
            (lib.enableFeature false "music-mod-xmp-shared")
          ];
      });
    libmodplug = pkgs.pkgsCross.${crossTarget}.libmodplug;
    libvorbis = pkgs.pkgsCross.${crossTarget}.libvorbis;
    opusfile = pkgs.pkgsCross.${crossTarget}.opusfile;
    libopus = pkgs.pkgsCross.${crossTarget}.libopus;
    libmpg123 = pkgs.pkgsCross.${crossTarget}.libmpg123;
    game-music-emu = pkgs.pkgsCross.${crossTarget}.game-music-emu;
    wavpack = pkgs.pkgsCross.${crossTarget}.wavpack;
    miniupnpc = (pkgs.pkgsCross.${crossTarget}.miniupnpc.override {stdenv = stdenvWin32Threads;}).overrideAttrs (final: {
      env.NIX_CFLAGS_COMPILE = "-static-libgcc";
      postFixup =
        (
          if final ? postFixup
          then final.postFixup
          else ""
        )
        + ''
          mv $out/bin/libminiupnpc.dll $out/bin/miniupnpc.dll
        '';
    });
    libxmp = pkgs.pkgsCross.${crossTarget}.libxmp;
    libogg = pkgs.pkgsCross.${crossTarget}.libogg.override {stdenv = stdenvWin32Threads;};
    fmodex = let
      drv = {
        stdenv,
        lib,
        fetchurl,
        p7zip,
        is64Bit ? false,
        installerHasSuffix ? true,
      }: let
        installerSuffix = lib.optionalString installerHasSuffix (
          if is64Bit
          then "64"
          else "32"
        );
        version = "4.28.07";
        shortVersion = builtins.replaceStrings ["."] [""] version;
        src = fetchurl {
          url = "https://zdoom.org/files/fmod/fmodapi${shortVersion}win${installerSuffix}-installer.exe";
          sha256 = "sha256-aPK+/b1dwo1MsegzXTaxBozF56Rko0jxBJYuVi1f0LQ=";
        };
      in
        stdenv.mkDerivation rec {
          pname = "fmod";
          inherit version shortVersion;

          nativeBuildInputs = [p7zip];

          unpackPhase = false;
          dontUnpack = true;
          dontStrip = true;
          dontPatchELF = true;
          dontBuild = true;

          installPhase = let
            dllSuffix = lib.optionalString (!installerHasSuffix) (lib.optionalString is64Bit "64");
          in
            lib.optionalString stdenv.hostPlatform.isLinux ''
              mkdir -p $out/bin
              7z e -aoa ${src}
              cp fmodex${dllSuffix}.dll $out/bin/
            '';

          meta = with lib; {
            description = "Programming library and toolkit for the creation and playback of interactive audio";
            homepage = "http://www.fmod.org/";
            license = licenses.unfreeRedistributable;
            platforms = [
              "i686-mingw32"
            ];
            maintainers = [];
          };
        };
    in
      pkgs.callPackage drv {};
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
  };
  crossPkgs = lib.mapAttrs createCrossPkgSet architectures;
  architectures = {
    mingw32 = rec {
      toolchainPrefix = "i686-w64-mingw32";
      name = "mingw64-32";
      d2dforeverFeaturesSuport = {
        openglDesktop = true;
        openglEs = false;
        supportsHeadless = true;
        loadedAsLibrary = false;
      };
      bundleFormats = ["zip"];
      isWindows = true;
      isAndroid = false;
      pretty = "Windows ${toolchainPrefix}";
      bundle = {
        io = "SDL2";
        sound = "FMOD";
        graphics = "OpenGL2";
        headless = "Disable";
        holmes = "Enable";
      };
      fpcAttrs = rec {
        lazarusExists = true;
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
in let
  dontStripIfDrv = drv:
    if drv ? overrideAttrs
    then
      drv.overrideAttrs (final: {
        dontStrip = true;
      })
    else drv;
in
  lib.mapAttrs (_: archAttrs: lib.mapAttrs (_: dontStripIfDrv) archAttrs)
  crossPkgs
