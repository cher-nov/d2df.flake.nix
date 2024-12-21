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
  version = "v0.667-${d2df-editor.shortRev}";
  name = "${finalAttrs.pname}-${finalAttrs.version}";
  src = d2df-editor;
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    lazarus
    gtk2
    glibc
    libGL
    libX11
    pango
    cairo
    gdk-pixbuf
    gcc
  ];

  buildInputs = with pkgs; [gtk2 glibc libGL libX11 pango cairo gdk-pixbuf];

  dontStrip = true;
  dontPatchELF = true;

  patches = [./temp-fix-error.patch];

  env = {
    D2DF_BUILD_USER = "nixbld";
    D2DF_BUILD_HASH = d2df-editor.rev;
  };

  buildPhase = ''
    runHook preInstall
    pushd src/editor
    gcc -shared ${./nosched.c} -ldl -o nosched.so
    chmod +x nosched.so
    HOME=. INSTANTFPCCACHE=./lazarus LD_PRELOAD=$PWD/nosched.so lazbuild --bm=Debug Editor.lpi
    popd
    runHook postInstall
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/editor.exe $out/bin/Editor
  '';
})
