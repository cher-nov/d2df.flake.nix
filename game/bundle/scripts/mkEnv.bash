#!/bin/bash
set -euo pipefail
if [[ "${UPDATE_FLAKE:-1}" == "1" ]]; then
    nix flake update Doom2D-Forever d2df-editor DF-Assets d2df-distro-soundfont d2df-distro-content
fi

NIXPKGS_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."nixpkgs".locked.rev')
D2DF_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."Doom2D-Forever".locked.rev')
EDITOR_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-editor".locked.rev')
RES_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."DF-Assets".locked.rev')
DISTRO_CONTENT_PATH=$(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"')
DISTRO_SOUNDFONT_PATH=$(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-soundfont"')

git clone https://github.com/Doom2D/Doom2D-Forever || :
git clone https://github.com/Doom2D/DF-Res || :

D2DF_LAST_COMMIT_DATE=$(git   --git-dir Doom2D-Forever/.git    show -s --format=%ad --date=iso $D2DF_REV)
EDITOR_LAST_COMMIT_DATE=$(git --git-dir Doom2D-Forever/.git show -s --format=%ad --date=iso $EDITOR_REV)
RES_LAST_COMMIT_DATE=$(git    --git-dir DF-Res/.git      show -s --format=%ad --date=iso $RES_REV)
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
                 "Doom2D-Forever" "$D2DF_REV" \
                 "d2df-editor" "$EDITOR_REV" \
                 "DF-Assets" "$RES_REV" \
                 "nixpkgs" "$NIXPKGS_REV" \
                 "$DISTRO_CONTENT_CREATION_NAME" "$DISTRO_CONTENT_CREATION_DATE_PRETTY" \
                 "$DISTRO_SOUNDFONT_CREATION_NAME" "$DISTRO_SOUNDFONT_CREATION_DATE_PRETTY" \
                 >> release_body
