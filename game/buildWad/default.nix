let
  standard = ./scripts/parse.awk;
in {
  buildWadScript = standard;
  buildWad = {
    outName ? "game",
    lstPath ? "game.lst",
    doom2df-res,
    buildWadScript ? standard,
    stdenvNoCC,
    gnused,
    gawk,
    convmv,
    dfwad,
    dfwadCompression ? "none",
  }:
    stdenvNoCC.mkDerivation {
      pname = "d2df-${outName}-wad";
      version = "git";
      phases = ["buildPhase" "installPhase"];

      dontStrip = true;
      dontPatchELF = true;
      dontFixup = true;

      nativeBuildInputs = [gawk gnused convmv dfwad];

      buildPhase =
        # FIXME
        # Script should be able to support arbitrary paths, not just in the current directory
        # But it doesn't for now, so we copy files from doom2df-res to build directory.
        ''
          cp -r ${doom2df-res}/*WAD ${doom2df-res}/*.lst .
        ''
        # FIXME
        # For some reason, shrshade.lst specifies the source folder in lowercase.
        # This doesn't fly in Linux.
        + ''
          sed -i 's\shrshadewad\ShrShadeWAD\g' shrshade.lst
        ''
        + ''
          awk -f ${buildWadScript} -v prefix="temp" ${lstPath}
          convmv -f CP1251 -t UTF-8 --notest -r temp
          dfwad -v -z "${dfwadCompression}" temp/ ${outName}.wad pack
        '';

      installPhase = ''
        mv "${outName}.wad" $out
      '';
    };
}
