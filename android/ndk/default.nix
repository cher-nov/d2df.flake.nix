{
  lib,
  pkgs,
  fetchFromGitHub,
  stdenv,
}: let
  androidCmakeDrv = {
    pname,
    version,
    src,
    cmakeExtraArgs ? "",
  }: {
    androidSdk,
    androidNdk,
    androidAbi,
    androidPlatform,
    ...
  }: let
    cmake = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";
  in
    stdenv.mkDerivation (finalAttrs: {
      inherit pname version src;

      buildPhase = ''
        runHook preBuild
        mkdir build
        cd build
        export PATH="$ANDROID_SDK_ROOT/cmake/*/bin:$PATH";
        ${cmake} .. \
          -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
          -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${androidAbi} -DANDROID_PLATFORM=${androidPlatform} \
          -DCMAKE_INSTALL_PREFIX=$out \
          ${cmakeExtraArgs}
        make -j$(nproc)
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        make install
        runHook postInstall
      '';
    });
in rec {
  SDL2 = androidCmakeDrv rec {
    pname = "SDL2";
    version = "2.30.6";
    src = fetchFromGitHub {
      owner = "libsdl-org";
      repo = "SDL";
      rev = "release-${version}";
      hash = "sha256-ij9/VhSacUaPbMGX1hx2nz0n8b1tDb1PnC7IO9TlNhE=";
    };
  };

  enet = androidCmakeDrv {
    pname = "enet";
    version = "1.3.18";
    src = fetchFromGitHub {
      owner = "lsalzman";
      repo = "enet";
      rev = "1e80a78f481cb2d2e4d9a0e2718b91995f2de51c";
      hash = "sha256-YIqJC5wMTX4QiWebvGGm5EfZXLzufXBxUO7YdeQ+6Bk=";
    };
  };
}
