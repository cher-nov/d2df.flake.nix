{
  pkgs,
  lib,
  autoPatchelfHook,
  libX11 ? null,
  d2df-editor,
  lazarus,
  stdenv,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "doom2d-forever-editor";
  version = "v0.667-${d2df-editor.shortRev or "unknown"}";
  name = "${finalAttrs.pname}-${finalAttrs.version}";
  src = d2df-editor;
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    lazarus
    glibc
    gcc
  ];

  dontStrip = true;
  dontPatchELF = true;
  dontFixup = true;

  patches = [
    ./temp-fix-error.patch
  ];

  env = {
    D2DF_BUILD_USER = "nixbld";
    D2DF_BUILD_HASH = d2df-editor.rev or "unknown";
  };

  buildPhase = ''
    runHook preInstall
    pushd src/editor
    gcc -shared ${./nosched.c} -ldl -o nosched.so
    chmod +x nosched.so
    LD_PRELOAD=$PWD/nosched.so lazbuild --bm=Debug Editor.lpi
    popd
    runHook postInstall
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/editor.exe $out/bin/Editor
  '';
})
