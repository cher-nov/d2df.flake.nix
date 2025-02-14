#!/bin/bash
set -euo pipefail

[ ! -f "df_distro_content.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"') df_distro_content.rar

if [ ! -d "android/assets" ]; then
    mkdir -p android/assets
    rar x -tsp df_distro_content.rar android/assets
fi

if [[ -n "${ASSETS_SOUNDFONT:-}" ]]; then
    [ ! -f "df_distro_soundfont.rar" ] && cp $(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"') df_distro_soundfont.rar
    mkdir -p android/assets/data/banks
    rar x -tsp df_distro_soundfont.rar android/assets
fi

if [[ -n "${ASSETS_GUS:-}" && -n "${TIMIDITY_CFG:-}" ]]; then
    mkdir -p android/assets/instruments
    cp "${ASSETS_GUS}"/* android/assets/instruments/
    cp "${TIMIDITY_CFG}" android/assets/
fi

nix build --print-build-logs .#android.bundles.default
cp result doom2df-android.apk
chmod 777 doom2df-android.apk
pushd android
7zz a -y -mtm -ssp -tzip ../doom2df-android.apk -w .
popd

openssl req -x509 -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com" -nodes -days 10000 -newkey rsa:2048 -keyout keyfile.pem -out certificate.pem
openssl pkcs12 -export -in certificate.pem -inkey keyfile.pem -out my_keystore.p12 -passout "pass:" -name my_key
apksigner sign --ks my_keystore.p12 --ks-pass "pass:" doom2df-android.apk 
