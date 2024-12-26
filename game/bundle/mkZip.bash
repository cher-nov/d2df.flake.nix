#!/bin/bash
export IS_WINDOWS=1
mkdir -p doom2df-win32
nix build --print-build-logs .#legacyPackages.x86_64-linux.mingw32.bundles.default
cp -r result/* doom2df-win32/
# Because the result is copied from the nix store, files are readonly.
# Make them writable.
find doom2df-win32 -exec chmod 777 {} \;
[[ -n "$IS_WINDOWS" ]] && find doom2df-win32/assets -iname "*.txt" -exec unix2dos {} \;

nix run --inputs-from . nixpkgs#_7zz -- a -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/.
nix run --inputs-from .  nixpkgs#_7zz -- a -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/assets/.