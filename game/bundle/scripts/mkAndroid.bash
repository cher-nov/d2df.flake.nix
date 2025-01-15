#!/bin/bash
set -euo pipefail

[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar
if [ ! -d "android" ]; then
    mkdir -p android/assets
    rar x -tsp df_distro_content.rar android/assets
fi

# MIDI playback with fluidsynth won't work if timidity is not available and timidity.cfg can't be found.
# This happens because CWD is set in other location, not relative to instruments/ folder.
# There exists a hack in the game to switch CWD to a folder with timidity.cfg, and we use that.
# So create timidity.cfg in either case.
if [[ -n "${ASSETS_GUS:-}" || -n "${ASSETS_SOUNDFONT:-}" ]]; then
    mkdir -p android/assets/data/banks
    printf '%s\n%s\n%s' \
        '# DO NOT REMOVE!!!' \
        '# This file is a placeholder and is necessary even though fluidsynth is used.' \
        '# It is essential because of a quirk with how the game handles MIDI playback.' \
        > android/assets/timidity.cfg
fi

if [[ -n "${ASSETS_SOUNDFONT:-}" ]]; then
    cp "${ASSETS_SOUNDFONT}" android/assets/data/banks/default.sf2
fi

if [[ -n "${ASSETS_GUS:-}" && -n "${TIMIDITY_CFG:-}" ]]; then
    cp -r "${ASSETS_GUS}/*" android/assets/data/banks/
    cp "${TIMIDITY_CFG}" android/assets/timidity.cfg
fi

nix build --print-build-logs .#android.bundles.default
cp result doom2df-android.apk
chmod 777 doom2df-android.apk
pushd android
7zz a -y -mtm -ssp -tzip ../doom2df-android.apk -w .
popd

keytool -genkey -validity 10000 -dname "CN=AndroidDebug, O=Android, C=US" -keystore d2df.keystore -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -v
jarsigner -sigalg SHA1withRSA -digestalg SHA1 -keystore d2df.keystore -storepass android -keypass android -signedjar doom2df-android.apk doom2df-android.apk androiddebugkey