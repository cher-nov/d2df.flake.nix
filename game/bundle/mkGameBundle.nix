let
  gameBundle = {
    stdenv,
    lib,
    gameAssetsPath,
    # Example:
    # { sharedBundledLibraries = [...]; doom2df = ...; }
    # Android supports multiple targets in one unknownPkgs argument, this doesn't.
    # The need hasn't arised yet.
    unknownPkgsAttrs,
    # Necessarry to know because .dlls are installed in bin/
    isWindows ? false,
    withEditor ? false,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-game-bundle";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      dontStrip = true;
      dontPatchELF = true;
      dontBuild = true;

      src = gameAssetsPath;

      installPhase = let
        copyLibraries = libraries: let
          suffix =
            if isWindows
            then "bin"
            else "lib";
          extension =
            if isWindows
            then "dll"
            else "so";
          # FIXME
          # Use ln instead of cp
          i = lib.map (x: "cp -r ${x}/${suffix}/*.${extension} $out/") libraries;
        in
          lib.concatStringsSep "\n" i;
      in
        # Precreate directories to be used in the build process.
        ''
          mkdir -p $out
          cp -r * $out
          ${(copyLibraries unknownPkgsAttrs.sharedBundledLibraries)}
          cp ${unknownPkgsAttrs.doom2df}/bin/Doom2DF $out/Doom2DF.exe
          ${lib.optionalString withEditor "cp ${unknownPkgsAttrs.editor}/bin/Editor $out/Editor.exe"}
        '';
    });
in
  gameBundle
