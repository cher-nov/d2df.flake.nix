{callPackage}: {
  mkGameBundle = callPackage ./mkGameBundle.nix;
  mkAndroidApk = callPackage ./mkAndroidApk.nix;
}
