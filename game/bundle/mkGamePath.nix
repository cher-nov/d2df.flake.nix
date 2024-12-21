let
  gameBundle = {
    stdenv,
    gameAssetsPath,
    gameExecutablePath,
    git,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-game-bundle";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      buildInputs = [git];

      dontStrip = true;
      dontPatchELF = true;
      dontBuild = true;
      dontUnpack = true;

      src = null;

      installPhase = ''
        mkdir -p $out
        mkdir -p temp/assets temp/executables
        cp -r ${gameAssetsPath}/* $out
        cp -r ${gameExecutablePath}/* $out
      '';
    });
in
  gameBundle
