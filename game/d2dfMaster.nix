{pkgs, ...}: let
  inherit (pkgs) enet;
  inherit (pkgs) gcc gnumake;
  inherit (pkgs) fetchgit;
in
  pkgs.stdenv.mkDerivation {
    name = "doom2d-forever-master-server";
    pname = "d2df_master";

    src = fetchgit {
      url = "https://repo.or.cz/d2df-sdl.git";
      rev = "8588b7c95416f44e70773a7fc8f2cff890911889";
      sha256 = "sha256-WAtMnsVbd+AJ3+RJOCzciUjxU6dGD0h22oRG8+Flm3A=";
    };

    nativeBuildInputs = [gnumake];
    buildInputs = [enet];

    buildPhase = ''
      cd src/mastersrv
      mkdir -p bin
      make master
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp bin/d2df_master $out/bin/d2df_master
    '';
  }
