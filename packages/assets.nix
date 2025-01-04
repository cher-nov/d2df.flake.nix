{
  lib,
  callPackage,
  stdenv,
  writeText,
  doom2df-res,
  d2df-editor,
  buildWad,
  mkAssetsPath,
}: rec {
  wads = lib.listToAttrs (lib.map (wad: {
    name = wad;
    value = callPackage buildWad {
      outName = wad;
      lstPath = "${wad}.lst";
      dfwadCompression = "best";
      inherit doom2df-res;
    };
  }) ["game" "editor" "shrshade" "standart" "doom2d" "doomer"]);
  defaultAssetsPath = mkAssetsPath {
    doom2dWad = wads.doom2d;
    doomerWad = wads.doomer;
    standartWad = wads.standart;
    shrshadeWad = wads.shrshade;
    gameWad = wads.game;
    editorWad = wads.editor;
    editorLangRu = "${d2df-editor}/lang/editor.ru_RU.lng";
    extraRoots = let
      mkTxtFile = name': txt:
        stdenv.mkDerivation {
          name = lib.replaceStrings [" "] ["_"] name';

          src = null;
          phases = ["installPhase"];

          installPhase = ''
            mkdir $out
            cp ${writeText "${name'}" txt} "$out/${name'}"
          '';
        };
      findMoreContentTxt = mkTxtFile "Get MORE game content HERE.txt" ''
        Дополнительные уровни и модели игрока можно скачать на https://doom2d.org
        You can download additional maps or user skins on our website: https://doom2d.org
      '';
    in [findMoreContentTxt];
  };
}
