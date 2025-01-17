{
  pkgs,
  lib,
  pins,
}: let
  mkMingwCrossPkg = arch: vendor: sys: nixpkgsArch: fpcTarget: fpcCpu: fpcBasename: let
    crossPkgs = pkgs.pkgsCross.${nixpkgsArch};
    gcc = crossPkgs.buildPackages.wrapCC (crossPkgs.buildPackages.gcc-unwrapped.override {
      threadsCross = {
        model = "win32";
        package = null;
      };
    });
    stdenvWin32Threads = crossPkgs.buildPackages.overrideCC crossPkgs.stdenv gcc;
    set = rec {
      enet = (crossPkgs.enet.override {stdenv = stdenvWin32Threads;}).overrideAttrs (prev: let
        mingwPatchNoUndefined = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/msys2/MINGW-packages/a4bc312869703bda3703fc1cb327fdd7659f0c4b/mingw-w64-enet/001-no-undefined.patch";
          hash = "sha256-t3fXrYG0h2OkZHx13KPKaJL4hGGJKZcN8vdsWza51Hk=";
        };
        mingwPatchWinlibs = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/msys2/MINGW-packages/a4bc312869703bda3703fc1cb327fdd7659f0c4b/mingw-w64-enet/002-win-libs.patch";
          hash = "sha256-vD3sKSU4OVs+zHKuMTNpcZC+LnCyiV/SJqf9G9Vj/cQ=";
        };
      in {
        nativeBuildInputs = [crossPkgs.buildPackages.autoreconfHook];
        patches = [mingwPatchNoUndefined mingwPatchWinlibs];
        postFixup = ''
          mv $out/bin/libenet-7.dll $out/bin/enet.dll
        '';
      });
      SDL2 = (crossPkgs.SDL2.override {stdenv = stdenvWin32Threads;}).overrideAttrs (finalAttrs: {});
      SDL2_mixer =
        (crossPkgs.SDL2_mixer.override {
          enableSdltest = false;
          enableSmpegtest = false;
          SDL2 = crossPkgs.SDL2;
          fluidsynth = null;
          smpeg2 = null;
          flac = null;
          timidity = SDL2;
          stdenv = stdenvWin32Threads;
        })
        .overrideAttrs (prev: {
          buildInputs = prev.buildInputs ++ [crossPkgs.game-music-emu];
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
      libmodplug = crossPkgs.libmodplug.overrideAttrs (final: prev: {
        nativeBuildInputs = [pkgs.autoreconfHook];
      });
      libvorbis = crossPkgs.libvorbis.overrideAttrs (final: prev: {
        patches = [];
        nativeBuildInputs = [pkgs.autoreconfHook];
        outputs = ["out"];
      });
      opusfile = crossPkgs.opusfile.overrideAttrs (final: prev: {
        patches = lib.filter (patch: lib.hasSuffix "multistream.patch" patch) prev.patches;
        nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config];
        outputs = ["out"];
        configureFlags = ["--disable-examples" "--disable-http"];
      });
      libopus = crossPkgs.libopus.overrideAttrs (final: prev: {
        nativeBuildInputs = [pkgs.autoreconfHook];
      });
      libmpg123 = crossPkgs.libmpg123.overrideAttrs (final: prev: {
        nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config];
      });
      game-music-emu = crossPkgs.game-music-emu;
      wavpack = crossPkgs.wavpack;
      miniupnpc = (crossPkgs.miniupnpc.override {stdenv = stdenvWin32Threads;}).overrideAttrs (final: {
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
      libxmp = crossPkgs.libxmp.overrideAttrs (final: prev: {
        patches = [];
        nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config];
        outputs = ["out"];
      });
      libogg = crossPkgs.libogg.override {stdenv = stdenvWin32Threads;};
      fluidsynth = crossPkgs.fluidsynth.override {
        glib = null;
        libsndfile = null;
        libjack2 = null;
      };
      fmodex = let
        drv = {
          stdenv,
          lib,
          fetchurl,
          p7zip,
          is64Bit ? arch == "x86_64",
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
            sha256 =
              if is64Bit
              then "sha256-F6kFWvkpbUawIMSZBLoHytlth/T3QUSS+Ke7cU1O12c="
              else "sha256-aPK+/b1dwo1MsegzXTaxBozF56Rko0jxBJYuVi1f0LQ=";
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
              dllSuffix = lib.optionalString installerHasSuffix (lib.optionalString is64Bit "64");
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
        (crossPkgs.openal.override {
          pipewire = null;
          dbus = null;
          alsa-lib = null;
          libpulseaudio = null;
          stdenv = stdenvWin32Threads;
        })
        .overrideAttrs (prev: {
          preConfigure = ''
            cmakeFlagsArray+=(
              -DCMAKE_REQUIRED_COMPILER_FLAGS="-D_WIN32_WINNT=0x0501 -static-libgcc -static-libstdc++"
              -DCMAKE_SHARED_LINKER_FLAGS="-D_WIN32_WINNT=0x0501 -static-libgcc -static-libstdc++"
            )
          '';

          postInstall = "";
        });
    };
    finalSet = lib.pipe set [
      (lib.mapAttrs (name: value:
        if pins ? "${name}"
        then
          (value.overrideAttrs (final: prev: {
            version = pins.${name}.version;
            src = pins.${name}.src;
          }))
        else value))
      (let
        dontStripIfDrv = drv:
          if drv ? overrideAttrs
          then
            drv.overrideAttrs (final: {
              dontStrip = true;
            })
          else drv;
      in
        lib.mapAttrs (name: value: dontStripIfDrv value))
    ];
  in let
    ld = "${crossPkgs.buildPackages.gcc}/bin/${arch}-${vendor}-${sys}-ld";
    as = "${crossPkgs.buildPackages.gcc}/bin/${arch}-${vendor}-${sys}-as";
  in
    lib.recursiveUpdate
    {
      infoAttrs = mkMingwArch arch vendor sys fpcTarget fpcCpu fpcBasename as ld;
    }
    finalSet;
  mkMingwArch = arch: vendor: sys: fpcTarget: fpcCpu: fpcBasename: as: ld: {
    caseSensitive = false;
    d2dforeverFeaturesSuport = {
      openglDesktop = true;
      openglEs = true;
      supportsHeadless = true;
      loadedAsLibrary = false;
    };
    isWindows = true;
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
      targetArg = "-T${fpcTarget}";
      basename = fpcBasename;
      makeArgs = {
        OS_TARGET = fpcTarget;
        CPU_TARGET = fpcCpu;
        CROSSOPT = "\"" + (lib.concatStringsSep " " cpuArgs) + "\"";
      };
      toolchainPaths = [
        "${pkgs.writeShellScriptBin "${fpcCpu}-${fpcTarget}-as" "${as} $@"}/bin"
        "${pkgs.writeShellScriptBin "${fpcCpu}-${fpcTarget}-ld" "${ld} $@"}/bin"
      ];
    };
  };
in {
  mingw32 = mkMingwCrossPkg "i686" "w64" "mingw32" "mingw32" "win32" "i386" "cross386";
  mingw64 = mkMingwCrossPkg "x86_64" "w64" "mingw32" "mingwW64" "win64" "x86_64" "cx64";
}
