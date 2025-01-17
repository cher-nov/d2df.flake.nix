#!/bin/bash
set -euo pipefail

export BUILD_FOLDER="doom2df-${BUILD_ARCH}"
mkdir -p $BUILD_FOLDER
[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar
if [ ! -d "content" ]; then
    mkdir -p content
    rar x -tsp df_distro_content.rar content
fi

nix build --print-build-logs ".#${BUILD_ARCH}.bundles.default"
cp -r result/* ${BUILD_FOLDER}/
# Because the result is copied from the nix store, files are readonly.
# Make them writable.
find $BUILD_FOLDER -exec chmod 777 {} \;
[[ ! -z "${IS_WINDOWS-}" ]] && find "${BUILD_FOLDER}/assets" -iname "*.txt" -exec unix2dos {} \;
find $BUILD_FOLDER/executables/ -type f -iname 'doom2df*' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
find $BUILD_FOLDER/executables/ -type f -iname 'editor*' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
find $BUILD_FOLDER/assets/ -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;
find $BUILD_FOLDER/assets/data/lang/ -type f  -iname 'editor*.lng' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
touch -d "$DISTRO_CONTENT_CREATION_DATE" "${BUILD_FOLDER}/assets/Get MORE game content HERE.txt"

if [[ ! -z "${IS_WINDOWS-}" ]]; then
    find ${BUILD_FOLDER}/executables/ -type f -iname '*.dll' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
else
    find ${BUILD_FOLDER}/executables/ -type f -iname '*.dylib' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
    find ${BUILD_FOLDER}/executables/ -type f -iname '*.so' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
fi

7zz a -y -mtm -ssp -tzip "${BUILD_FOLDER}.zip" -w content/.
7zz a -y -mtm -ssp -tzip "${BUILD_FOLDER}.zip" -w "${BUILD_FOLDER}/executables/."
7zz a -y -mtm -ssp -tzip "${BUILD_FOLDER}.zip" -w "${BUILD_FOLDER}/assets/."