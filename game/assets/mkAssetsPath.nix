{
  doom2dWad,
  doomerWad,
  standartWad,
  shrshadeWad,
  gameWad,
  editorWad,
  editorLangRu,
  extraRoots ? [],
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
  lib,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-assets-path";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils];

  buildPhase = ''
    mkdir -p data/models wads maps/megawads/ data/lang
    cp ${doom2dWad} maps/megawads/doom2d.wad
    cp ${doomerWad} data/models/doomer.wad
    cp ${shrshadeWad} wads/shrshade.wad
    cp ${standartWad} wads/standart.wad
    cp ${editorWad} data/editor.wad
    cp ${gameWad} data/game.wad
    cp ${editorLangRu} data/lang/
    ${lib.concatStringsSep "\n"
      (lib.map
        (root: "find ${root} -type f -exec sh -c 'cp \"$0\" $(pwd)' {} +")
        extraRoots)}
  '';

  installPhase = ''
    mkdir -p $out
    mv * $out
    rm $out/env-vars
  '';
}
