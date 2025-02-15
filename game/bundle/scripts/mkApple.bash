set -euo pipefail

export BUILD_ARCH="x86_64-apple-darwin"
export BASE_FOLDER="macos"
export APP_BASE="${BASE_FOLDER}/Doom2DF.app"
export ASSETS_DIR="${APP_BASE}/Contents/Resources"
export MACOS_ICNS="$(nix build --verbose --show-trace --print-build-logs --print-out-paths .#assetsLib.x86_64-linux.macOsIcns)"
export MACOS_INFO="$(nix build --verbose --show-trace --print-build-logs --print-out-paths .#assetsLib.x86_64-linux.macOsPlist)"

mkdir -p $APP_BASE/Contents/{MacOS,Resources}

nix build --print-build-logs ".#${BUILD_ARCH}.bundles.default"
cp -r result/executables/* $APP_BASE/Contents/MacOS
mv $APP_BASE/Contents/MacOS/Doom2DF $APP_BASE/Contents/MacOS/Doom2DF_unwrapped
cp $MACOS_INFO $APP_BASE/Contents/Info.plist
cat << EOF > $APP_BASE/Contents/MacOS/Doom2DF
#!/bin/sh
LAUNCH_PATH="\$(dirname "\$0")"
cd \$LAUNCH_PATH/../Resources
DYLD_FALLBACK_LIBRARY_PATH="\$LAUNCH_PATH:\$DYLD_FALLBACK_LIBRARY_PATH" \
    LD_LIBRARY_PATH="\$LAUNCH_PATH:\$LD_LIBRARY_PATH" \
    "\$LAUNCH_PATH/Doom2DF_unwrapped"
EOF
touch -d "$D2DF_LAST_COMMIT_DATE" "$APP_BASE/Contents/MacOS/Doom2DF_unwrapped"
touch -d "$D2DF_LAST_COMMIT_DATE" "$APP_BASE/Contents/MacOS/Doom2DF"
touch -d "$D2DF_LAST_COMMIT_DATE" "$APP_BASE/Contents/Info.plist"
find $APP_BASE/Contents/MacOS/ -type f -iname '*.dylib' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;

cp -r result/assets/* $APP_BASE/Contents/Resources
find $APP_BASE/Contents/Resources -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;
find $APP_BASE/Contents/Resources -type f  -iname 'editor*.lng' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
touch -d "$DISTRO_CONTENT_CREATION_DATE" "${APP_BASE}/Contents/Resources/Get MORE game content HERE.txt"

chmod -R 777 $APP_BASE

cp "$MACOS_ICNS" $ASSETS_DIR/Doom2DF.icns
touch -d "$D2DF_LAST_COMMIT_DATE" $ASSETS_DIR/Doom2DF.icns
[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar
rar x -tsp df_distro_content.rar $ASSETS_DIR

if [[ -n "${ASSETS_SOUNDFONT:-}" ]]; then
    [ ! -f "df_distro_soundfont.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"') df_distro_soundfont.rar
    rar x -tsp df_distro_soundfont.rar "data/banks/*" $ASSETS_DIR
fi

if [[ -n "${ASSETS_GUS:-}" ]]; then
    [ ! -f "df_distro_soundfont.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"') df_distro_soundfont.rar
    rar x -tsp df_distro_soundfont.rar "instruments/*" "timidity.cfg" $ASSETS_DIR
fi

genisoimage -D -V "Doom2D Forever" -no-pad -r -apple -file-mode 0555 -o Doom2D-Forever.dmg $BASE_FOLDER
