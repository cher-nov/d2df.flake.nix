{
  doom2dWad ? null,
  doomerWad ? null,
  standartWad ? null,
  shrshadeWad ? null,
  gameWad ? null,
  withEditor ? false,
  editorWad ? null,
  editorLangRu ? null,
  withDates ? false,
  assetsDate ? null,
  editorDate ? null,
  withDistroContent ? false,
  distroContent ? null,
  distroMidiBanks ? null,
  withDistroGus ? false,
  withDistroSoundfont ? false,
  flexuiDistro ? false,
  extraRoots ? [],
  stdenvNoCC,
  gnused,
  gawk,
  zip,
  findutils,
  rar,
  _7zz,
  lib,
  toLower ? false,
}:
stdenvNoCC.mkDerivation {
  pname = "d2df-assets-path";
  version = "git";
  phases = ["buildPhase" "installPhase"];

  nativeBuildInputs = [gawk gnused zip findutils rar _7zz];

  buildPhase = let
    resName = res:
      if (!toLower)
      then res
      else lib.toLower res;
  in
    ''
      mkdir -p build
      cd build
      mkdir -p data/models wads maps/megawads/
      cp ${doom2dWad} maps/megawads/${resName "Doom2D.WAD"}
      cp ${doomerWad} data/models/${resName "Doomer.WAD"}
      cp ${shrshadeWad} wads/${resName "shrshade.WAD"}
      cp ${standartWad} wads/${resName "standart.WAD"}
      cp ${gameWad} data/${resName "game.WAD"}
    ''
    + lib.optionalString withEditor ''
      mkdir -p data/lang
      cp ${editorWad} data/${resName "editor.WAD"}
      cp ${editorLangRu} data/lang/
    ''
    + ''
      ${lib.concatStringsSep "\n"
        (lib.map
          (root: "find ${root} -type f -exec sh -c 'cp \"$0\" $(pwd)' {} +")
          extraRoots)}
    ''
    + lib.optionalString withDates ''
      find . -exec touch -d "${assetsDate}" {} \;
    ''
    + lib.optionalString (withEditor && withDates) ''
      touch -d "${editorDate}" data/${resName "editor.WAD"}
      find data/lang -type f -exec touch -d "${editorDate}" {} \;
    ''
    + lib.optionalString withDistroContent (let
      flexUiMask = lib.optionalString (!flexuiDistro) "data/flexui.wad";
      activeMasks = lib.filter (x: x != "") [flexUiMask];
      filters = lib.map (x: "-x\"${x}\"") activeMasks;
      switch = lib.concatStringsSep " " filters;
    in ''
      rar x -tsp ${distroContent} ${switch} .
    '')
    + lib.optionalString withDistroSoundfont ''
      rar x -tsp ${distroMidiBanks} "data/banks/*" .
    ''
    + lib.optionalString withDistroGus ''
      rar x -tsp ${distroMidiBanks} "instruments/*" "timidity.cfg" .
    '';

  installPhase = ''
    cd -
    7zz a -y -mtm -ssp -tzip out.zip -w build/.
    mv out.zip $out
  '';

  meta = {
    licenses = [];
    inherit distroMidiBanks distroContent withDistroSoundfont withDistroGus;
  };
}
