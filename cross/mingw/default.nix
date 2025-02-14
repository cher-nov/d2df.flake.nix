{
  pkgs,
  lib,
  pins,
}: let
  mkMingwCrossPkg = arch': vendor: sys: nixpkgsArch: fpcTarget: fpcCpu: fpcBasename: let
    crossPkgs = pkgs.pkgsCross.${nixpkgsArch};
    gcc =
      crossPkgs.buildPackages.wrapCC
      (
        crossPkgs.buildPackages.gcc-unwrapped.override (prev: {
          threadsCross = {
            model = "win32";
            package = null;
          };
        })
      );
    stdenvWin32Threads = crossPkgs.buildPackages.overrideCC crossPkgs.stdenv gcc;
    fmodex = let
      drv = {
        stdenv,
        lib,
        fetchurl,
        p7zip,
        is64Bit ? arch' == "x86_64",
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
          in ''
            mkdir -p $out/bin
            7z e -aoa ${src}
            cp fmodex${dllSuffix}.dll $out/bin/fmodex.dll
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
    set = import ../_common rec {
      inherit lib pkgs pins;
      arch = "${arch'}-${vendor}-${sys}";
      cmake = let
        windres = "${pkgs.writeShellScript "${arch}-windres" "echo $@; PATH=${stdenvWin32Threads.cc}/bin/ ${stdenvWin32Threads.cc}/bin/${arch}-windres $@"}";
        toolchain = pkgs.writeTextFile {
          name = "${arch}.cmake-toolchain";
          text = ''
            set(CMAKE_SYSTEM_NAME Windows)
            set(CMAKE_SYSTEM_PROCESSOR x86_64)
            set(CMAKE_HOST_SYSTEM_NAME Linux)
            set(CMAKE_HOST_SYSTEM_PROCESSOR x86_64)
            set(CMAKE_CROSSCOMPILING ON)
            # search for programs in the build host directories
            set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
            # for libraries and headers in the target directories
            set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
            set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
            set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
            set(CMAKE_FIND_ROOT_PATH
              "${stdenvWin32Threads.cc}")

            set(CMAKE_C_COMPILER "${stdenvWin32Threads.cc}/bin/${arch}-cc")
            set(CMAKE_CXX_COMPILER "${stdenvWin32Threads.cc}/bin/${arch}-c++")
            set(CMAKE_AR "${stdenvWin32Threads.cc}/bin/${arch}-ar" CACHE FILEPATH "ar")
            set(CMAKE_RANLIB "${stdenvWin32Threads.cc}/bin/${arch}-ranlib" CACHE FILEPATH "ranlib")
            set(CMAKE_WINDRES "${windres}" CACHE FILEPATH "windres")
            set(CMAKE_RC_COMPILER "${windres}" CACHE FILEPATH "windres")
          '';
        };
        cmakeFlags = lib.concatStringsSep " " [
          "-D_WIN32_WINNT=0x0400"
          "-DWINVER=0x0400"
          "-DCMAKE_TOOLCHAIN_FILE=${toolchain}"
        ];
        exports = let
          CFLAGS = lib.concatStringsSep " " [
            "-DWINVER=0x0400"
            "-D_WIN32_WINNT=0x0400"
            "-static-libgcc"
            #"-I${lib.trace "${crossPkgs.windows.mingw_w64_pthreads}" crossPkgs.windows.mingw_w64_pthreads}/include"
            #"-L${crossPkgs.windows.mingw_w64}/lib"
            #"-L${crossPkgs.windows.mingw_w64}/lib64"
            #"-L${pthread}/lib"
            #"-L${pthread}/lib64"
          ];
          CXXFLAGS = CFLAGS + " -static-libstdc++";
          LDFLAGS = lib.concatStringsSep " " [
            "-DWINVER=0x0400"
            "-D_WIN32_WINNT=0x0400"
          ];
        in
          lib.concatStringsSep " " [
            "PATH=\"$PATH:${stdenvWin32Threads.cc}/bin\""
            "CFLAGS=\"$CFLAGS ${CFLAGS}\""
            "CXXFLAGS=\"$CXXFLAGS ${CXXFLAGS}\""
            "LDFLAGS=\"$CFLAGS ${LDFLAGS}\""
            "CC='${stdenvWin32Threads.cc}/bin/${arch}-gcc'"
            "CXX='${stdenvWin32Threads.cc}/bin/${arch}-g++'"
            "LD='${stdenvWin32Threads.cc}/bin/${arch}-ld'"
            "AR='${stdenvWin32Threads.cc}/bin/${arch}-ar'"
            "RANLIB='${stdenvWin32Threads.cc}/bin/${arch}-ranlib'"
            "WINDRES='${stdenvWin32Threads.cc}/bin/${arch}-windres'"
            "RC='${stdenvWin32Threads.cc}/bin/${arch}-windres'"
          ];
      in "${exports} ${crossPkgs.buildPackages.cmake}/bin/cmake ${cmakeFlags}";
    };
    ld = "${crossPkgs.buildPackages.gcc}/bin/${arch'}-${vendor}-${sys}-ld";
    as = "${crossPkgs.buildPackages.gcc}/bin/${arch'}-${vendor}-${sys}-as";
  in
    lib.recursiveUpdate
    {
      infoAttrs = mkMingwArch arch' vendor sys fpcTarget fpcCpu fpcBasename as ld;
      inherit fmodex;
    }
    set;
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
  mingw32 = lib.removeAttrs (mkMingwCrossPkg "i686" "w64" "mingw32" "mingw32" "win32" "i386" "cross386") ["openal" "fluidsynth"];
  mingw64 = lib.removeAttrs (mkMingwCrossPkg "x86_64" "w64" "mingw32" "mingwW64" "win64" "x86_64" "cx64") ["openal" "fluidsynth"];
}
