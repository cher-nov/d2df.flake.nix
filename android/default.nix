{
  androidSdk,
  androidNdk,
  androidAbi,
  androidPlatform,
}: let
  customNdkPkgs = import ./ndk;
in {
  enet = customNdkPkgs {inherit androidSdk androidNdk androidAbi androidPlatform;};
  SDL2 = customNdkPkgs {inherit androidSdk androidNdk androidAbi androidPlatform;};
}
