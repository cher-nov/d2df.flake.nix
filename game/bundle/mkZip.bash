#!/bin/bash
mkdir -p doom2df-win32
nix build --print-build-logs .#legacyPackages.x86_64-linux.outputs.mingw32.bundles.default
cp -r result/* doom2df-win32/
[ -f "doom2df-win32/executables/Doom2DF" ] && mv doom2df-win32/executables/Doom2DF doom2df-win32/executables/Doom2DF.exe
[ -f "doom2df-win32/executables/Editor" ] && mv doom2df-win32/executables/Editor doom2df-win32/executables/Editor.exe
find doom2df-win32/executables/ -type f -iname 'doom2df*' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
find doom2df-win32/executables/ -type f -iname 'editor*' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
find doom2df-win32/executables/ -type f -iname '*.dll' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
find doom2df-win32/assets -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;

nix run --inputs-from . nixpkgs#libfaketime -- "$EDITOR_LAST_COMMIT_DATE" nix run --inputs-from . nixpkgs#_7zz -- a -mtc -mta -mtm -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/. Editor.exe
nix run --inputs-from . nixpkgs#libfaketime -- "$D2DF_LAST_COMMIT_DATE" nix run --inputs-from .  nixpkgs#_7zz -- a -mtc -mta -mtm -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/. Doom2DF.exe
nix run --inputs-from . nixpkgs#libfaketime -- "$RES_LAST_COMMIT_DATE" nix run --inputs-from .  nixpkgs#_7zz -- a -mtc -mta -mtm -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/assets/.