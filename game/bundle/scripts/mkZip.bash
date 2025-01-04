#!/bin/bash
set -euo pipefail
export IS_WINDOWS=1

mkdir -p doom2df-win32
[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar
if [ ! -d "content" ]; then
    mkdir -p content
    rar x -tsp df_distro_content.rar content
fi

nix build --print-build-logs .#mingw32.bundles.default
cp -r result/* doom2df-win32/
# Because the result is copied from the nix store, files are readonly.
# Make them writable.
find doom2df-win32 -exec chmod 777 {} \;
[[ -n "$IS_WINDOWS" ]] && find doom2df-win32/assets -iname "*.txt" -exec unix2dos {} \;
find doom2df-win32/executables/ -type f -iname 'doom2df*' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
find doom2df-win32/executables/ -type f -iname 'editor*' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
find doom2df-win32/assets/ -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;
find doom2df-win32/assets/data/lang/ -type f  -iname 'editor*.lng' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
touch -d "$DISTRO_CONTENT_CREATION_DATE" 'doom2df-win32/assets/Get MORE game content HERE.txt'

if [[ -n "$IS_WINDOWS" ]]; then
    find doom2df-win32/executables/ -type f -iname '*.dll' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
else
    find doom2df-win32/executables/ -type f -iname '*.so' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
fi

7zz a -y -mtm -ssp -tzip doom2df-win32.zip -w content/.
7zz a -y -mtm -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/.
7zz a -y -mtm -ssp -tzip doom2df-win32.zip -w doom2df-win32/assets/.