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
    cp ${doom2dWad} maps/megawads/Doom2D.WAD
    cp ${doomerWad} data/models/Doomer.wad
    cp ${shrshadeWad} wads/shrshade.WAD
    cp ${standartWad} wads/standart.WAD
    cp ${editorWad} data/editor.WAD
    cp ${gameWad} data/game.WAD
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
