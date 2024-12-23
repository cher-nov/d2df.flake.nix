let
  gameBundle = {
    stdenv,
    gameAssetsPath,
    gameExecutablePath,
    git,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-game-path";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      buildInputs = [git];

      dontStrip = true;
      dontPatchELF = true;
      dontFixup = true;
      dontBuild = true;
      dontUnpack = true;

      src = null;

      installPhase = ''
        mkdir -p $out/assets $out/executables
        cp -r ${gameAssetsPath}/* $out/assets
        cp -r ${gameExecutablePath}/* $out/executables
      '';
    });
in
  gameBundle
