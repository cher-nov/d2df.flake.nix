#!/bin/bash
set -euo pipefail
if [[ "${UPDATE_FLAKE:-1}" == "1" ]]; then
    nix flake update Doom2D-Forever d2df-editor DF-Assets d2df-distro-soundfont d2df-distro-content
fi

NIXPKGS_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."nixpkgs".locked.rev')
NIXPKGS_URL="https://github.com/NixOS/nixpkgs"
D2DF_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."Doom2D-Forever".locked.rev')
D2DF_URL=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."Doom2D-Forever".locked.url')
EDITOR_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-editor".locked.rev')
EDITOR_URL=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-editor".locked.url')
RES_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."DF-Assets".locked.rev')
RES_URL=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."DF-Assets".locked.url')
DISTRO_CONTENT_PATH=$(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"')
DISTRO_CONTENT_URL=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-distro-content".locked.url')
DISTRO_SOUNDFONT_PATH=$(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"')
DISTRO_SOUNDFONT_URL=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-distro-soundfont".locked.url')

git clone https://github.com/Doom2D/Doom2D-Forever || :
git clone https://github.com/Doom2D/DF-Res || :

D2DF_LAST_COMMIT_DATE=$(git   --git-dir Doom2D-Forever/.git    show -s --format=%ad --date=iso $D2DF_REV)
EDITOR_LAST_COMMIT_DATE=$(git --git-dir Doom2D-Forever/.git show -s --format=%ad --date=iso $EDITOR_REV)
RES_LAST_COMMIT_DATE=$(git    --git-dir DF-Res/.git      show -s --format=%ad --date=iso $RES_REV)
D2DF_COMMIT_MESSAGE=$(  git --git-dir Doom2D-Forever/.git log  --format=%B -n 1 $D2DF_REV | head -n1)
EDITOR_COMMIT_MESSAGE=$(git --git-dir Doom2D-Forever/.git log  --format=%B -n 1 $EDITOR_REV | head -n1)
RES_COMMIT_MESSAGE=$(   git --git-dir DF-Res/.git         log  --format=%B -n 1 $RES_REV | head -n1)
DISTRO_CONTENT_CREATION_DATE="$(rar ltb '-x*' "$DISTRO_CONTENT_PATH" | grep "Original time" | cut -d' ' -f3-)"
DISTRO_CONTENT_CREATION_DATE_PRETTY="$(date --date="$DISTRO_CONTENT_CREATION_DATE" +'%d %B %Y %H:%M %Z')"
DISTRO_CONTENT_CREATION_NAME="$(rar ltb '-x*' "$DISTRO_CONTENT_PATH" | grep "Original name" | cut -d' ' -f3-)"
DISTRO_SOUNDFONT_CREATION_DATE="$(rar ltb '-x*' "$DISTRO_SOUNDFONT_PATH" | grep "Original time" | cut -d' ' -f3-)"
DISTRO_SOUNDFONT_CREATION_DATE_PRETTY="$(date --date="$DISTRO_SOUNDFONT_CREATION_DATE" +'%d %B %Y %H:%M %Z')"
DISTRO_SOUNDFONT_CREATION_NAME="$(rar ltb '-x*' "$DISTRO_SOUNDFONT_PATH" | grep "Original name" | cut -d' ' -f3-)"

echo "NIXPKGS_REV=$NIXPKGS_REV" >> "$GITHUB_ENV"
echo "D2DF_REV=$D2DF_REV" >> "$GITHUB_ENV"
echo "EDITOR_REV=$RES_REV" >> "$GITHUB_ENV"
echo "RES_REV=$RES_REV" >> "$GITHUB_ENV"
echo "D2DF_LAST_COMMIT_DATE=$D2DF_LAST_COMMIT_DATE" >> "$GITHUB_ENV"
echo "EDITOR_LAST_COMMIT_DATE=$EDITOR_LAST_COMMIT_DATE" >> "$GITHUB_ENV"
echo "RES_LAST_COMMIT_DATE=$RES_LAST_COMMIT_DATE" >> "$GITHUB_ENV"
echo "DISTRO_CONTENT_CREATION_DATE=$DISTRO_CONTENT_CREATION_DATE" >> "$GITHUB_ENV"
echo "DISTRO_CONTENT_CREATION_DATE_PRETTY=$DISTRO_CONTENT_CREATION_DATE_PRETTY" >> "$GITHUB_ENV"
echo "DISTRO_CONTENT_CREATION_NAME=$DISTRO_CONTENT_CREATION_NAME" >> "$GITHUB_ENV"
echo "DISTRO_SOUNDFONT_CREATION_DATE=$DISTRO_SOUNDFONT_CREATION_DATE" >> "$GITHUB_ENV"
echo "DISTRO_SOUNDFONT_CREATION_DATE_PRETTY=$DISTRO_SOUNDFONT_CREATION_DATE_PRETTY" >> "$GITHUB_ENV"
echo "DISTRO_SOUNDFONT_CREATION_NAME=$DISTRO_SOUNDFONT_CREATION_NAME" >> "$GITHUB_ENV"
printf '%s\n%s\n\n' \
       "Build creation date: $(date '+%d %B %Y %H:%M %Z')" \
       'Build info:' \
       > release_body
"$(dirname "$0")/markdown-table" -2 \
                 "Name" "Commit/Date" \
                 "Doom2D-Forever" "[$D2DF_REV](${D2DF_URL}/commit/${D2DF_REV}) ($D2DF_COMMIT_MESSAGE)" \
                 "d2df-editor" "[$EDITOR_REV](${EDITOR_URL}/commit/${EDITOR_REV}) ($EDITOR_COMMIT_MESSAGE)" \
                 "DF-Assets" "[$RES_REV](${RES_URL}/commit/${RES_REV}) ($RES_COMMIT_MESSAGE)" \
                 "nixpkgs" "[$NIXPKGS_REV](${NIXPKGS_URL}/commit/${NIXPKGS_REV})" \
                 "[$DISTRO_CONTENT_CREATION_NAME]($DISTRO_CONTENT_URL)" "$DISTRO_CONTENT_CREATION_DATE_PRETTY" \
                 "[$DISTRO_SOUNDFONT_CREATION_NAME]($DISTRO_SOUNDFONT_URL)" "$DISTRO_SOUNDFONT_CREATION_DATE_PRETTY" \
                 >> release_body
