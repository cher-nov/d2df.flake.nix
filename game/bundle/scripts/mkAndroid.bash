#!/bin/bash
set -euo pipefail

[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar

if [ ! -d "android" ]; then
    mkdir -p android/assets
    rar x -tsp df_distro_content.rar android/assets
fi

if [[ -n "${ASSETS_GUS:-}" || -n "${ASSETS_SOUNDFONT:-}" ]]; then
    mkdir -p android/assets/data/banks
fi

if [[ -n "${ASSETS_SOUNDFONT:-}" ]]; then
    [ ! -f "df_distro_soundfont.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"') df_distro_soundfont.rar
    rar x -tsp df_distro_soundfont.rar android/assets
fi

if [[ -n "${ASSETS_GUS:-}" && -n "${TIMIDITY_CFG:-}" ]]; then
    # TODO
    # Copy GUS files
    # Copy Timidity cfg
    :
fi

nix build --print-build-logs .#android.bundles.default
cp result doom2df-android.apk
chmod 777 doom2df-android.apk
pushd android
7zz a -y -mtm -ssp -tzip ../doom2df-android.apk -w .
popd

keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -v
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar doom2df-android.apk doom2df-android.apk androiddebugkey