{callPackage}: {
  mkGamePath = callPackage ./mkGamePath.nix;
  mkExecutablePath = ./mkExecutablePath.nix;
  mkZipBundle = callPackage ./mkZipBundle.nix;
  mkAndroidApk = callPackage ./mkAndroidApk.nix;
}
