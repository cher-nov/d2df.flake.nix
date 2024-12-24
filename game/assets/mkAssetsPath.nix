{
  doom2dWad,
  doomerWad,
  standartWad,
  shrshadeWad,
  gameWad,
  editorWad,
  botlist,
  botnames,
  flexuiWad,
  editorLangRu,
  extraRoot ? null,
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
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
    cp ${flexuiWad} data/flexui.wad
    cp ${botlist} data/botlist.txt
    cp ${botnames} data/botnames.txt
    cp ${editorLangRu} data/lang/
  '';

  installPhase = ''
    mkdir -p $out
    mv * $out
    rm $out/env-vars
  '';
}
