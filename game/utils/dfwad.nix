{
  lib,
  fetchFromGitHub,
  rustPlatform,
  src,
}:
rustPlatform.buildRustPackage rec {
  pname = "dfwad";
  version = "v0.1.0";
  buildType = "debug";

  inherit src;

  cargoHash = "sha256-0pasD+ApgSniwiUNkQY7Iz580wWH+fGRBBGRXYHOM5k=";

  meta = {
    description = "Manage your DFWADs, extract and create them.";
    homepage = "https://github.com/poybluez/dfwad";
    license = lib.licenses.mit0;
  };
}
