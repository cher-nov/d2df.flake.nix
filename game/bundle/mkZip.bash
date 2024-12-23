#!/bin/bash
mkdir -p doom2df-win32
nix build --print-build-logs .#legacyPackages.x86_64-linux."outputs'.x86_64-linux.mingw32.bundles.default"
cp -r result/* doom2df-win32/

nix run --inputs-from . nixpkgs#_7zz -- a -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/.
nix run --inputs-from .  nixpkgs#_7zz -- a -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/assets/.