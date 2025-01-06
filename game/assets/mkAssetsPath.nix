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
  toLower ? false,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-assets-path";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils];

  buildPhase = let
    resName = res:
      if (!toLower)
      then res
      else lib.toLower res;
  in ''
    mkdir -p data/models wads maps/megawads/ data/lang
    cp ${doom2dWad} maps/megawads/${resName "Doom2D.WAD"}
    cp ${doomerWad} data/models/${resName "Doomer.WAD"}
    cp ${shrshadeWad} wads/${resName "shrshade.WAD"}
    cp ${standartWad} wads/${resName "standart.WAD"}
    cp ${editorWad} data/${resName "editor.WAD"}
    cp ${gameWad} data/${resName "game.WAD"}
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
