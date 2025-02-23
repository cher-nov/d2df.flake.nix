{
  stdenv,
  executables,
  assets,
  licenses ? null,
  lib,
  _7zz,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "d2df-zip-bundle";
  version = "0.667";

  buildInputs = [_7zz];

  src = null;

  dontUnpack = true;

  buildPhase =
    ''
      mkdir -p build
      7zz x -mtm -ssp -y ${assets} -obuild
      7zz x -mtm -ssp -y ${executables} -obuild
    ''
    + lib.optionalString (!builtins.isNull licenses) "7zz x -mtm -ssp -y ${licenses} -obuild";

  installPhase = ''
    cd /build
    7zz a -y -mtm -ssp -tzip out.zip -w build/.
    mv out.zip $out
  '';
})
