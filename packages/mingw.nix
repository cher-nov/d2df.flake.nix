{
  default = {
    pkgs,
    lib,
    fpcPkgs,
    d2dfPkgs,
    mkGamePath,
    mkAssetsPath,
    mkExecutablePath,
    gameAssetsPath,
    d2df-sdl,
    doom2df-res,
    d2df-editor,
  }: let
    mingwPkgs = import ../cross/mingw {
      inherit pkgs lib;
      inherit d2df-sdl doom2df-res d2df-editor;
      inherit fpcPkgs d2dfPkgs;
      inherit mkGamePath gameAssetsPath mkExecutablePath mkAssetsPath;
    };
    byArchAdditional =
      lib.mapAttrs (arch: archAttrs: let
      in rec {
        editor = pkgs.callPackage d2dfPkgs.editor {
          inherit d2df-editor;
          inherit (archAttrs) lazarus;
        };
        doom2d = pkgs.callPackage d2dfPkgs.doom2df-unwrapped {
          inherit d2df-sdl;
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
          fpc = pkgs.callPackage fpcPkgs.wrapper rec {
            fpc = mingwPkgs.universal.fpc-mingw;
            fpcAttrs = let
              prevFpcAttrs = mingwPkgs.architectures.${arch}.fpcAttrs;
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
          disableGraphics = false;
          disableIo = false;
          disableSound = false;
          withOpenGL2 = true;
          withSDL2 = true;
          withFmod = true;
        };
        gameExecutablePath_fmodex = pkgs.callPackage mkExecutablePath rec {
          byArchPkgsAttrs = {
            "${arch}" = {
              sharedLibraries = [archAttrs.enet archAttrs.SDL2 archAttrs.fmodex];
              doom2df = doom2d;
              editor = editor;
              isWindows = true;
              withEditor = true;
              asLibrary = false;
              prefix = ".";
            };
          };
        };
      })
      mingwPkgs.byArch;
    universalAdditional = rec {
    };
  in
    lib.recursiveUpdate mingwPkgs {
      byArch = byArchAdditional;
      universal = universalAdditional;
    };

  # Maybe WIN95 support or something...
  /*
  old = ...;
  */
}
