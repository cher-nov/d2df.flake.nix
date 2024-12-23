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
    cmakeListsPath ? null,
    cmakePrefix ? "",
    cmakeExtraArgs ? "",
    ...
  }: let
    cmake = "${androidSdk}/libexec/android-sdk/cmake/3.22.1/bin/cmake";
  in
    pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
      inherit pname version src;

      dontStrip = true;
      dontPatchELF = true;

      phases = ["unpackPhase" "buildPhase" "installPhase"];

      buildPhase = ''
        runHook preBuild
        ${lib.optionalString (!builtins.isNull cmakeListsPath) "cd ${cmakeListsPath}"}
        mkdir build
        cd build
        ${cmakePrefix} \
          ${pkgs.cmake}/bin/cmake .. \
            -DCMAKE_TOOLCHAIN_FILE=${androidNdk}/build/cmake/android.toolchain.cmake \
            -DCMAKE_POLICY_DEFAULT_CMP0057=NEW \
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
      rev = "ad93f50ee6408c90eec0d96867b41046392bb426";
      hash = "sha256-rajAfb7NoF63Bv2JZsO8WJrRkqKBIc39u7fLWFrpanU=";
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

  libogg = androidCmakeDrv {
    pname = "libogg";
    version = "1.3.5-git";
    src = fetchFromGitHub {
      owner = "xiph";
      repo = "ogg";
      rev = "db5c7a49ce7ebda47b15b78471e78fb7f2483e22";
      hash = "sha256-A8J/V8OSBG0Vkr9GLPmj3aNHe7wIYwdxTsvBJhJc0Qk=";
    };
  };

  libopus = androidCmakeDrv {
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

  libmpg123 = androidCmakeDrv {
    pname = "mpg123";
    version = "1.32.8-git";
    src = fetchFromGitHub {
      owner = "madebr";
      repo = "mpg123";
      rev = "3c34e2af2ff4737959580c095e3e158af8adccb2";
      hash = "sha256-0BYPWEIz1Lzig6JXhidL4VrMJi2+PJbYje4N8UXKhoQ=";
    };
  };

  libvorbis = androidCmakeDrv {
    pname = "vorbis";
    version = "1.3.8-git";
    src = fetchFromGitHub {
      owner = "xiph";
      repo = "vorbis";
      rev = "84c023699cdf023a32fa4ded32019f194afcdad0";
      hash = "sha256-wCaqRF6Wa08ut9vcjjoxQ0/HKHV9AeDsHC/15Iq06QE=";
    };
  };

  game-music-emu = androidCmakeDrv {
    pname = "game-music-emu";
    version = "0.6.3-git";
    src = fetchFromGitHub {
      owner = "libgme";
      repo = "game-music-emu";
      rev = "cb2c1ccc7563ed58321cc3b6b8507b9015192b80";
      hash = "sha256-NP55kJp94fOwPq1sA4Z+LmAsYwWqnlPTqqrSGM6tqfI=";
    };
  };

  libmodplug = androidCmakeDrv {
    pname = "libmodplug";
    version = "d1b97ed";
    src = fetchFromGitHub {
      owner = "Konstanty";
      repo = "libmodplug";
      rev = "d1b97ed0020bc620a059d3675d1854b40bd2608d";
      hash = "sha256-wBOAbCLUExdU+rg5NSghC8QXlMwsYBUkt2EsEvFKMug=";
    };
  };

  openal = androidCmakeDrv {
    pname = "openal-soft";
    version = "1.24.1-git";
    src = fetchFromGitHub {
      owner = "kcat";
      repo = "openal-soft";
      rev = "ff497ad11182b48d1bfa57216c51a2ac0c723c7d";
      hash = "sha256-YejeK1qiddRjPAls+14HwUUWEk3kQR5eY/e1Uf/76aA=";
    };
  };
}
