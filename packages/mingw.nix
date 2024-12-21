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
    byArchAdditional = lib.mapAttrs (target: targetAttrs: let
    in {})
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
