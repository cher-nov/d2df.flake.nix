{
  outName ? "game",
  lstPath ? "game.lst",
  doom2df-res,
  buildWadScript,
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
  bash,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-${outName}-wad";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils];

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
      bash -c 'awk -f ${buildWadScript} -v prefix="temp" -v outputPath="${outName}.zip" ${lstPath}'
    '';

  installPhase = ''
    mv "${outName}.zip" $out
  '';
}
