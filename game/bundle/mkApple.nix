{
  stdenv,
  executables,
  assets,
  licenses ? null,
  cdrkit,
  macOsIcns,
  lib,
  _7zz,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "d2df-app-bundle";
  version = "0.667";

  buildInputs = [_7zz cdrkit];

  src = null;

  dontUnpack = true;

  buildPhase =
    ''
      mkdir -p build
      cd build
    ''
    + (''
        mkdir -p Doom2DF.app/Contents/{MacOS,Resources,Licenses}
        cp ${macOsIcns} Doom2DF.app/Contents/Resources/Doom2DF.icns
        7zz x -mtm -ssp -y ${assets} -oDoom2DF.app/Contents/Resources
        7zz x -mtm -ssp -y ${executables} -oDoom2DF.app/Contents/MacOS
      ''
      + lib.optionalString (!builtins.isNull licenses) ''
        7zz x -mtm -ssp -y ${licenses} -oDoom2DF.app/Contents/Licenses
      '')
    + ''
      genisoimage -D -V "Doom2D Forever" -no-pad -r -apple -file-mode 0555 \
        -o out.dmg Doom2DF.app
    '';

  installPhase = ''
    cd /build
    mv build/out.dmg $out
  '';
})
