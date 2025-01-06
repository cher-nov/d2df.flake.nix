{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "dfwad";
  version = "v0.1.0";
  buildType = "debug";

  src = null;

  cargoHash = "sha256-SDiDQ7XoWc0aS+6JlpMwBwMVQUCWMqUt8Xs8gbcW26s=";

  meta = {
    description = "Manage your DFWADs, extract and create them.";
    homepage = "https://github.com/poybluez/dfwad";
    license = lib.licenses.mit0;
  };
}
