{
  pkgs,
  lib,
  pins,
  osxcross,
  fpcPkgs,
  d2dfPkgs,
  Doom2D-Forever,
  d2df-editor,
}: let
  android = (import ../cross/android) {
    inherit pkgs lib pins;
  };
  mingw = (import ../cross/mingw) {
    inherit pkgs lib pins;
  };
  mac = (import ../cross/mac) {
    inherit pkgs lib pins osxcross;
  };
  f = crossPkgs: let
    archsAttrs = lib.mapAttrs (arch: archAttrs: archAttrs.infoAttrs.fpcAttrs) crossPkgs;
    universal = rec {
      fpc-trunk = fpcPkgs.fpc-trunk.override {inherit archsAttrs;};
      fpc-3_0_4 = fpcPkgs.fpc-3_0_4.override {inherit archsAttrs;};
      fpc-3_2_2 = fpcPkgs.fpc-3_2_2.override {inherit archsAttrs;};
      fpc = fpc-3_2_2;
      lazarus-3_6 =
        if (lib.any (archAttrs: archAttrs.infoAttrs.fpcAttrs.lazarusExists) (lib.attrValues crossPkgs))
        then
          (pkgs.callPackage fpcPkgs.lazarus {
            fpc = fpc;
          })
        else null;
    };
    fromCrossPkgsAttrs = arch: archAttrs: let
      fpcWrapper = fpc:
        pkgs.callPackage fpcPkgs.fpcWrapper rec {
          inherit fpc;
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
        fpc = fpcWrapper universal.fpc-3_2_2;
        lazarus-3_6 =
          if (archAttrs.infoAttrs.fpcAttrs.lazarusExists)
          then
            (pkgs.callPackage fpcPkgs.lazarusWrapper {
              # FIXME
              # lazarus doesn't compile editor with trunk fpc
              fpc = universal.fpc;
              fpcAttrs = archAttrs.infoAttrs.fpcAttrs;
              lazarus = universal.lazarus-3_6;
            })
          else null;
        editor =
          if (archAttrs.infoAttrs.fpcAttrs.lazarusExists)
          then
            (pkgs.callPackage d2dfPkgs.editor {
              inherit d2df-editor;
              lazarus = lazarus-3_6;
            })
          else null;
        doom2d = pkgs.callPackage d2dfPkgs.doom2df-base {
          inherit Doom2D-Forever;
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
    (lib.mapAttrs fromCrossPkgsAttrs crossPkgs) // {universal = universal;};
in
  f (android // mingw // mac)
