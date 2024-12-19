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
  extraRoot ? null,
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-bundle";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils];

  buildPhase = ''
    mkdir -p data/models wads maps/megawads/
    cp ${doom2dWad} maps/megawads/doom2d.zip
    cp ${doomerWad} data/models/doomer.zip
    cp ${shrshadeWad} wads/shrshade.zip
    cp ${standartWad} wads/standart.zip
    cp ${editorWad} data/editor.zip
    cp ${gameWad} data/game.zip
    cp ${flexuiWad} data/flexui.wad
    cp ${botlist} data/botlist.txt
    cp ${botnames} data/botnames.txt
  '';

  installPhase = ''
    mkdir -p $out
    mv * $out
    rm $out/env-vars
  '';
}
