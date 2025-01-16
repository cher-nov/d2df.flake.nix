{
  stdenv,
  Doom2D-Forever,
  fpc,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wadcvt";
  version = "0.667-git";
  name = "${finalAttrs.pname}-${finalAttrs.version}";

  src = Doom2D-Forever;
  dontStrip = true;
  dontPatchELF = true;
  dontFixup = true;
  nativeBuildInputs = [fpc];

  buildPhase = ''
    pushd src/tools
    mkdir -p bin temp
    fpc -dUSE_SOUNDSTUB wadcvt.dpr
    popd
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp src/tools/wadcvt $out/bin
  '';
})
