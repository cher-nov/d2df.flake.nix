let
  standard = ./scripts/parse.awk;
in {
  buildWadScript = standard;
  buildWad = {
    outName ? "game",
    lstPath ? "game.lst",
    DF-Assets,
    buildWadScript ? standard,
    stdenvNoCC,
    gnused,
    gawk,
    convmv,
    coreutils,
    util-linux,
    bash,
    lib,
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

      nativeBuildInputs = [bash gawk gnused convmv dfwad coreutils util-linux];

      buildPhase =
        # FIXME
        # Script should be able to support arbitrary paths, not just in the current directory
        # But it doesn't for now, so we copy files from DF-Assets to build directory.
        ''
          find "${DF-Assets.outPath}" -iname '*WAD' -maxdepth 1 -type d -exec cp -f -r {} "$(pwd)/" \;
          find "${DF-Assets.outPath}" -iname '*.lst' -maxdepth 1 -type f -exec cp -f -r {} "$(pwd)/" \;
        ''
        # FIXME
        # For some reason, shrshade.lst specifies the source folder in lowercase.
        # This doesn't fly in Linux.
        + ''
          sed -i 's\shrshadewad\ShrShadeWAD\g' shrshade.lst
        ''
        + ''
          awk -f ${buildWadScript} -v prefix="temp" ${lstPath}
          # For some reason, this AWK script sets wrong perms
          chmod -R 777 temp
          # Convert win1251 names to UTF-8
          convmv -f CP1251 -t UTF-8 --notest -r temp
          # Remove extensions from nested wads
          find temp -mindepth 4 -type f -exec bash -c '
                     WITHOUT_EXT=$(basename $1 | rev | cut -f 2- -d '.' | rev);
                     echo "moving $1 to $(dirname $1)/$WITHOUT_EXT" 1>&2;
                     mv "$1" "$(dirname $1)/$WITHOUT_EXT";
                     ' bash {} \;
          dfwad -v -z "${dfwadCompression}" temp/ ${outName}.wad pack
        '';

      installPhase = ''
        mv "${outName}.wad" $out
      '';
    };
}
