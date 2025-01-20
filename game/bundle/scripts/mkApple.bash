set -euo pipefail

export BUILD_ARCH="x86_64-apple-darwin"
export BUILD_FOLDER="Doom2DF.app"
export MACOS_ICNS="$(nix build --verbose --show-trace --print-build-logs --print-out-paths .#assetsLib.x86_64-linux.macOsIcns)"
export MACOS_INFO="$(nix build --verbose --show-trace --print-build-logs --print-out-paths .#assetsLib.x86_64-linux.macOsPlist)"

mkdir -p $BUILD_FOLDER/Contents/{MacOS,Resources}

nix build --print-build-logs ".#${BUILD_ARCH}.bundles.default"
cp -r result/executables/* $BUILD_FOLDER/Contents/MacOS
mv $BUILD_FOLDER/Contents/MacOS/Doom2DF $BUILD_FOLDER/Contents/MacOS/Doom2DF_unwrapped
cp $MACOS_INFO $BUILD_FOLDER/Contents/Info.plist
cat << EOF > $BUILD_FOLDER/Contents/MacOS/Doom2DF
LAUNCH_PATH="\$(dirname "\$0")"
DYLD_FALLBACK_LIBRARY_PATH="\$LAUNCH_PATH:\$DYLD_FALLBACK_LIBRARY_PATH" \
    LD_LIBRARY_PATH="\$LAUNCH_PATH:\$LD_LIBRARY_PATH" \
    "\$LAUNCH_PATH/Doom2DF_unwrapped"
EOF
touch -d "$D2DF_LAST_COMMIT_DATE" "$BUILD_FOLDER/Contents/MacOS/Doom2DF_unwrapped"
touch -d "$D2DF_LAST_COMMIT_DATE" "$BUILD_FOLDER/Contents/MacOS/Doom2DF"
touch -d "$D2DF_LAST_COMMIT_DATE" "$BUILD_FOLDER/Contents/Info.plist"
find $BUILD_FOLDER/Contents/MacOS/ -type f -iname '*.dylib' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;

cp -r result/assets/* $BUILD_FOLDER/Contents/Resources
find $BUILD_FOLDER/Contents/Resources -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;
find $BUILD_FOLDER/Contents/Resources -type f  -iname 'editor*.lng' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
touch -d "$DISTRO_CONTENT_CREATION_DATE" "${BUILD_FOLDER}/Contents/Resources/Get MORE game content HERE.txt"

chmod -R 777 $BUILD_FOLDER

cp "$MACOS_ICNS" $BUILD_FOLDER/Contents/Resources/Doom2DF.icns
[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar
rar x -tsp df_distro_content.rar $BUILD_FOLDER/Contents/Resources


genisoimage -D -V "Doom2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2DF.dmg $BUILD_FOLDER