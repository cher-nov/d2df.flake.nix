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
      archsAttrs = lib.mapAttrs (arch: archAttrs: archAttrs.infoAttrs.fpcAttrs) crossPkgs;
      universal = rec {
        fpc-trunk = fpcPkgs.fpc-trunk.override {inherit archsAttrs;};
        fpc-3_0_4 = fpcPkgs.fpc-3_0_4.override {inherit archsAttrs;};
        fpc-3_2_2 = fpcPkgs.fpc-3_2_2.override {inherit archsAttrs;};
        fpc = fpc-trunk;
        lazarus =
          if (lib.any (archAttrs: archAttrs.infoAttrs.fpcAttrs.lazarusExists) (lib.attrValues crossPkgs))
          then
            (pkgs.callPackage fpcPkgs.lazarus {
              # TODO
              # Check if it still crashes with trunk
              fpc = fpc;
            })
          else null;
      };
    in
      arch: archAttrs: let
        fpcWrapper = fpc:
          pkgs.callPackage fpcPkgs.fpcWrapper rec {
            fpc = universal.fpc;
            fpcAttrs = let
              prevFpcAttrs = archAttrs.infoAttrs.fpcAttrs;
            in
              prevFpcAttrs
              // {
                cpuArgs = prevFpcAttrs.cpuArgs ++ ["-O1" "-g" "-gl"];
                toolchainPaths =
                  prevFpcAttrs.toolchainPaths
                  ++ [
                    "${pkgs.writeShellScriptBin
                      "${prevFpcAttrs.makeArgs.CPU_TARGET}-${prevFpcAttrs.makeArgs.OS_TARGET}-fpcres"
                      "${fpc}/bin/fpcres $@"}/bin"
                  ];
              };
          };
        gamePkgs = rec {
          fpc-3_0_4 = fpcWrapper universal.fpc-3_0_4;
          fpc-3_2_2 = fpcWrapper universal.fpc-3_2_2;
          fpc-trunk = fpcWrapper universal.fpc-trunk;
          fpc = fpcWrapper universal.fpc-trunk;
          lazarus =
            if (archAttrs.infoAttrs.fpcAttrs.lazarusExists)
            then
              (pkgs.callPackage fpcPkgs.lazarusWrapper {
                # FIXME
                # lazarus doesn't compile editor with trunk fpc
                fpc = universal.fpc-3_2_2;
                fpcAttrs = archAttrs.infoAttrs.fpcAttrs;
                lazarus = universal.lazarus;
              })
            else null;
          editor =
            if (archAttrs.infoAttrs.fpcAttrs.lazarusExists)
            then
              (pkgs.callPackage d2dfPkgs.editor {
                inherit d2df-editor;
                inherit lazarus;
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
              libmpg123
              libopus
              opusfile
              game-music-emu
              miniupnpc
              fluidsynth
              libmodplug
              fmodex
              ;
          };
        };
      in
        lib.recursiveUpdate archAttrs gamePkgs;
  in
    lib.mapAttrs fromCrossPkgsAttrs crossPkgs;
in
  f (android // mingw)
