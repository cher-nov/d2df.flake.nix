{callPackage}: {
  androidRoot = ./android;
  androidIcons = ./dirtyAssets/android/res;
  mkAssetsPath = callPackage ./mkAssetsPath.nix;

  # FIXME
  # Dirty, hardcoded assets
  dirtyAssets = {
    flexuiWad = ./dirtyAssets/flexui.wad;
    botlist = ./dirtyAssets/botlist.txt;
    botnames = ./dirtyAssets/botnames.txt;
  };
}
