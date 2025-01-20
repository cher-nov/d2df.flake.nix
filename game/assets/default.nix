{callPackage}: {
  androidRoot = ./android;
  androidIcons = ./dirtyAssets/android/res;
  macOsIcns = ./dirtyAssets/macOS/Doom2DF.icns;
  macOsPlist = ./macOS/Info.plist;
  mkAndroidManifest = callPackage ./androidManifest.nix;
  mkAssetsPath = callPackage ./mkAssetsPath.nix;
}
