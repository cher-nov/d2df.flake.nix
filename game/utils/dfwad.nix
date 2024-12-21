{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
rustPlatform.buildRustPackage rec {
  pname = "dfwad";
  version = "v0.1.0";
  buildType = "debug";

  src = fetchFromGitHub {
    owner = "polybluez";
    repo = pname;
    rev = "fdb860ba1a35ad3555ac4d5f37c777ff4879a333";
    hash = "sha256-DmIDlIIwLpIZgU0NrXWN2z+Og7vDdEa4FNjqrAUUfV0=";
  };

  cargoHash = "sha256-SDiDQ7XoWc0aS+6JlpMwBwMVQUCWMqUt8Xs8gbcW26s=";

  meta = {
    description = "Manage your DFWADs, extract and create them.";
    homepage = "https://github.com/poybluez/dfwad";
    license = lib.licenses.mit0;
  };
}
