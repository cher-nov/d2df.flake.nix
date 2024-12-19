{callPackage}: {
  androidRoot = ./android;
  androidIcons = ./dirtyAssets/android/res;
  mkAssetsPath = callPackage ./mkAssetsPath.nix;
}
