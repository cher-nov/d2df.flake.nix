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
    enet = pkgs.pkgsCross.${crossTarget}.enet.overrideAttrs (prev: let
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
    SDL2 = pkgs.pkgsCross.${crossTarget}.SDL2;
    doom2d = let
      pkg = d2dfPkgs;
    in
      pkgs.callPackage pkg.doom2df-unwrapped {
        inherit SDL2 enet;
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
        disableSound = true;
        withSDL2 = true;
        headless = false;
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
