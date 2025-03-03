{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  fd,
}: let
  baseName = "D2DMP_0.6(130)_FULL";
in
  stdenvNoCC.mkDerivation rec {
    pname = "d2dmp-data";
    version = "1.0";

    src = fetchurl {
      url = "https://github.com/polybluez/filedump/releases/download/Tag1/D2DMP_0.6.130._FULL.zip";
      sha256 = "sha256-FUfSMttzC24MPeEoF1G3DKg6KBpn5+vKnWCjpX0zc4A=";
    };

    nativeBuildInputs = [unzip fd];

    unpackPhase = ''
      runHook preUnpack

      unzip -q ${src}
      mkdir -p "$out"
      mv '${baseName}'/* "$out"

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      runHook postInstall
    '';

    meta = with lib; {
      homepage = "https://doom2d.org";
      description = "Doom 2D Multiplayer game data";
      license = licenses.unfree;
      maintainers = [];
      platforms = platforms.all;
    };
  }
