{callPackage}: {
  androidRoot = ./android;
  androidIcons = ./dirtyAssets/android/res;
  mkAndroidManifest = callPackage ./androidManifest.nix;
  mkAssetsPath = callPackage ./mkAssetsPath.nix;
}
