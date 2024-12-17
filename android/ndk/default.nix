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
  }: {
    androidSdk,
    androidNdk,
    androidAbi,
    androidPlatform,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit pname version src;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = ''
        runHook preBuild
        mkdir build
        cd build
        ${cmakePrefix} \
          ${cmake} .. \
            -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
            -DBUILD_SHARED_LIBS=ON -DANDROID_ABI=${androidAbi} -DANDROID_PLATFORM=${androidPlatform} \
            -DCMAKE_INSTALL_PREFIX=$out -DANDROID_STL=c++_static \
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

  SDL2_mixer = androidCmakeDrv {
    pname = "SDL2_mixer";
    version = "2.8.0-git";
    src = fetchFromGitHub {
      owner = "libsdl-org";
      repo = "SDL_mixer";
      rev = "73a3e316728646ded6495b4dfddf1869ace43edf";
      hash = "sha256-mMqgRGa9NhOJEhvVTaolp5P5s8qFCi1PspO+7s/kTMw=";
    };
  };

  # Upstream packaging is horrendous.
  opusfile = androidCmakeDrv {
    pname = "opusfile";
    version = "0.12-git";
    src = fetchFromGitHub {
      owner = "xiph";
      repo = "opusfile";
      rev = "9d718345ce03b2fad5d7d28e0bcd1cc69ab2b166";
      hash = "sha256-kyvH3b/6ouAXffAE4xmck4L5c3/nd2VWq0ss/XJlX7Q=";
    };
  };

  ogg = androidCmakeDrv {
    pname = "ogg";
    version = "1.3.5-git";
    src = fetchFromGitHub {
      owner = "xiph";
      repo = "ogg";
      rev = "db5c7a49ce7ebda47b15b78471e78fb7f2483e22";
      hash = "sha256-A8J/V8OSBG0Vkr9GLPmj3aNHe7wIYwdxTsvBJhJc0Qk=";
    };
  };

  opus = androidCmakeDrv {
    pname = "opus";
    version = "1.5.2-git";
    src = fetchFromGitHub {
      owner = "xiph";
      repo = "opus";
      rev = "7db26934e4156597cb0586bb4d2e44dccdde1a59";
      hash = "sha256-FTN7OeMpYfD9Dwj4sOROvu0WeZDNyhK73AZi1XLLKj8=";
    };
  };

  libxmp = androidCmakeDrv {
    pname = "libxmp";
    version = "4.6.0-git";
    src = fetchFromGitHub {
      owner = "libxmp";
      repo = "libxmp";
      rev = "343a02327806d4d7da98100408cb7d3f8da56858";
      hash = "sha256-SJuB0kjXJTMhR40xOOv+ygl1wIiLgp+YJiuj9jl3fVc=";
    };
  };

  # fluidsynth pulls glib, which is totally unnecessary
  # For now, use a fork I've found while scrolling discussions below
  # https://github.com/FluidSynth/fluidsynth/discussions/847
  fluidsynth = androidCmakeDrv {
    pname = "fluidsynth";
    version = "2.4.1-git";
    src = fetchFromGitHub {
      owner = "DominusExult";
      repo = "fluidsynth-sans-glib";
      rev = "aefd0a1083270810273ceb0373191fe3b3e4e83e";
      hash = "sha256-Z6kn1lAdYsV/hBEvVZmPc4f2Uzo7qxCXpYxFb9323GU=";
    };
  };

  wavpack = androidCmakeDrv {
    pname = "wavpack";
    version = "5.7.0-git";
    src = fetchFromGitHub {
      owner = "dbry";
      repo = "wavpack";
      rev = "d9c4a35e822bb274b8c94fc95ff16c5b4c04d346";
      hash = "sha256-I2Ggo93YAdU/knMMPDB4HXNn9fLQQ+xbCRKy6d6xP0c=";
    };
  };
}
