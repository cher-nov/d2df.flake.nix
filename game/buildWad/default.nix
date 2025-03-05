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
    dos2unix,
    dfwad,
    dfwadCompression ? "none",
  }:
    stdenvNoCC.mkDerivation {
      pname = "d2df-${outName}-wad";
      version = "git";

      dontStrip = true;
      dontPatchELF = true;
      dontFixup = true;

      nativeBuildInputs = [bash gawk gnused convmv dfwad coreutils util-linux dos2unix];

      src = DF-Assets;

      buildPhase =
        # FIXME
        # Script should be able to support arbitrary paths, not just in the current directory
        # FIXME
        # For some reason, shrshade.lst specifies the source folder in lowercase.
        # This doesn't fly in Linux.
        ''
          set -euo pipefail
          echo "Fixing shrshade.wad paths"
          sed -i 's\shrshadewad\ShrShadeWAD\g' shrshade.lst
        ''
        + ''
          mkdir -p temp
          chmod -R 777 temp
          echo "Moving files from ${lstPath} to dfwad suitable directory"
          ${gawk}/bin/awk -f ${buildWadScript} -v RS=$'\r\n' -v prefix="temp" ${lstPath}
          # For some reason, this AWK script sets wrong perms
          chmod -R 777 temp
          echo "Converting win1251 names to UTF-8"
          convmv -f CP1251 -t UTF-8 --notest -r temp
          echo "Removing extensions from nested wads"
          find temp -mindepth 4 -type f -exec bash -c '
                     WITHOUT_EXT=$(basename $1 | rev | cut -f 2- -d '.' | rev);
                     echo "moving $1 to $(dirname $1)/$WITHOUT_EXT";
                     mv "$1" "$(dirname $1)/$WITHOUT_EXT";
                     ' bash {} \;
          echo "Calling dfwad"
          dfwad -v -z "${dfwadCompression}" temp/ ${outName}.wad pack
        '';

      installPhase = ''
        mv "${outName}.wad" $out
      '';
    };
}
