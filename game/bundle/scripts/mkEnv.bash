#!/bin/bash
TZ="Europe/Moscow"
export TZ=$TZ
nix flake update d2df-sdl d2df-editor DF-res

NIXPKGS_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."nixpkgs".locked.rev')
D2DF_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-sdl".locked.rev')
EDITOR_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-editor".locked.rev')
RES_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."DF-res".locked.rev')
DISTRO_CONTENT_PATH=$(nix eval '.#dfInputs' --json 2>/dev/null | jq --raw-output '."x86_64-linux"."d2df-distro-content"')

git clone https://repo.or.cz/d2df-sdl
git clone https://repo.or.cz/d2df-editor
git clone https://github.com/Doom2D/DF-Res

D2DF_LAST_COMMIT_DATE=$(git   --git-dir d2df-sdl/.git    show -s --format=%ad --date=iso $D2DF_REV)
EDITOR_LAST_COMMIT_DATE=$(git --git-dir d2df-editor/.git show -s --format=%ad --date=iso $EDITOR_REV)
RES_LAST_COMMIT_DATE=$(git    --git-dir DF-Res/.git      show -s --format=%ad --date=iso $RES_REV)
DISTRO_CONTENT_CREATION_DATE="$(rar ltb '-x*' "$DISTRO_CONTENT_PATH" | grep "Original time" | cut -d' ' -f3-)"
DISTRO_CONTENT_CREATION_DATE_PRETTY="$(date --date="$DISTRO_CONTENT_CREATION_DATE" +'%d %B %Y %H:%M %Z')"
DISTRO_CONTENT_CREATION_NAME="$(rar ltb '-x*' "$DISTRO_CONTENT_PATH" | grep "Original name" | cut -d' ' -f3-)"

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
printf \
    'This build has the following inputs:\nd2df-sdl: %s\nDF-res: %s\nd2df-editor: %s\nnixpkgs: %s\n%s - %s' \
    "$D2DF_REV" "$RES_REV" "$EDITOR_REV" "$NIXPKGS_REV" "$DISTRO_CONTENT_CREATION_NAME" "$DISTRO_CONTENT_CREATION_DATE_PRETTY" > release_body