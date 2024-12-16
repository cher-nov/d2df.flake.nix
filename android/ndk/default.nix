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
in {
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
  /*

  doom2df-library = {
    stdenv,
    fetchgit,
    fpc,
    ndkToolchain,
    SDL2,
    enet,
    customNdkLibraries,
  }:
    stdenv.mkDerivation (finalAttrs: {
      version = "0.667-git";
      pname = "d2df-android-lib";
      name = "${finalAttrs.pname}-${finalAttrs.version}";

      src = fetchgit {
        url = "https://repo.or.cz/d2df-sdl.git";
        rev = "58bea163d93100936cfe20515526e76f6cdf8ddb";
        sha256 = "sha256-oCxv3VjAqxB887Rwe6JLELjHo4b9ISjvdpme6Zs12j4=";
      };

      patches = [./0001-Experimental-network-patch.patch];

      buildPhase = ''
        pushd src/game
        mkdir bin tmp
        PATH='${ndkToolchain}:$PATH' \
          ${fpc}/bin/fpc \
            -g -gl -O1 \
            -FEbin -FUtmp \
            -dUSE_SDL2 -dUSE_SOUNDSTUB -dUSE_GLES1 \
            ${lib.concatStringsSep " " (lib.map (drv: "-Fl${drv}/lib") customNdkLibraries)}
            -olibDoom2DF.so \
            -al Doom2DF.lpr
        popd
      '';

      installPhase = ''
        mkdir -p $out/lib
        cp src/game/bin/libDoom2DF.so $out/lib
      '';
    });
  */
}
