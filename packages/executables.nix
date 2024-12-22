{
  pkgs,
  lib,
  fpcPkgs,
  d2dfPkgs,
  d2df-sdl,
  d2df-editor,
}: let
  android = (import ../cross/android) {
    inherit pkgs lib;
  };
  mingw = (import ../cross/mingw) {
    inherit pkgs lib;
  };
  f = crossPkgs: let
    fromCrossPkgsAttrs = let
      universal = rec {
        fpc = pkgs.callPackage fpcPkgs.fpc {
          archsAttrs = lib.mapAttrs (arch: archAttrs: archAttrs.infoAttrs.fpcAttrs) crossPkgs;
        };
        lazarus =
          if (lib.any (archAttrs: archAttrs.infoAttrs.lazarusExists) crossPkgs)
          then
            (pkgs.callPackage fpcPkgs.lazarus {
              fpc = fpc;
            })
          else null;
      };
    in
      arch: archAttrs: let
        gamePkgs = rec {
          fpc = pkgs.callPackage fpcPkgs.fpcWrapper rec {
            fpc = universal.fpc;
            fpcAttrs = let
              prevFpcAttrs = archAttrs.infoAttrs.fpcAttrs;
            in
              prevFpcAttrs
              // {
                toolchainPaths =
                  prevFpcAttrs.toolchainPaths
                  ++ [
                    "${pkgs.writeShellScriptBin
                      "${prevFpcAttrs.makeArgs.CPU_TARGET}-${prevFpcAttrs.makeArgs.OS_TARGET}-fpcres"
                      "${fpc}/bin/fpcres $@"}/bin"
                  ];
              };
          };
          lazarus =
            if (archAttrs.lazarusExists)
            then
              (pkgs.callPackage fpcPkgs.lazarusWrapper {
                fpc = universal.fpc-mingw;
                fpcAttrs = archAttrs.fpcAttrs;
                lazarus = universal.lazarus-mingw;
              })
            else null;
          editor =
            if (archAttrs.lazarusExists)
            then
              (pkgs.callPackage d2dfPkgs.editor {
                inherit d2df-editor;
                inherit (crossPkgs) lazarus;
              })
            else null;
          doom2d = pkgs.callPackage d2dfPkgs.doom2df-base {
            inherit d2df-sdl;
            inherit fpc;
            inherit
              (archAttrs)
              enet
              SDL
              SDL_mixer
              SDL2
              SDL2_mixer
              openal
              libvorbis
              libogg
              libxmp
              mpg123
              libopus
              opusfile
              libgme
              miniupnpc
              fluidsynth
              libmodplug
              game-music-emu
              ;
          };
        };
      in
        lib.recursiveUpdate archAttrs gamePkgs;
  in
    lib.mapAttrs fromCrossPkgsAttrs crossPkgs;
in
  f (android // mingw)
