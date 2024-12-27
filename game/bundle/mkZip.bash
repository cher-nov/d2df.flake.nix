#!/bin/bash
export IS_WINDOWS=1

D2DF_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-sdl".locked.rev')
EDITOR_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."d2df-editor".locked.rev')
RES_REV=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."doom2df-res".locked.rev')

git clone https://repo.or.cz/d2df-sdl
git clone https://repo.or.cz/d2df-editor
git clone https://github.com/Doom2D/DF-Res

D2DF_LAST_COMMIT_DATE=$(git   --git-dir d2df-sdl/.git    show -s --format=%ad --date=iso $D2DF_REV)
EDITOR_LAST_COMMIT_DATE=$(git --git-dir d2df-editor/.git show -s --format=%ad --date=iso $EDITOR_REV)
RES_LAST_COMMIT_DATE=$(git    --git-dir DF-Res/.git      show -s --format=%ad --date=iso $RES_REV)

printf 'This build has the following inputs:\nd2df-sdl: %s\ndoom2d-res: %s\nd2df-editor: %s' $D2DF_REV $RES_REV $EDITOR_REV > release_body

echo "D2DF_REV=$D2DF_REV" >> "$GITHUB_ENV"
echo "EDITOR_REV=$RES_REV" >> "$GITHUB_ENV"
echo "RES_REV=$RES_REV" >> "$GITHUB_ENV"
echo "D2DF_LAST_COMMIT_DATE=\"$D2DF_LAST_COMMIT_DATE\"" >> "$GITHUB_ENV"
echo "EDITOR_LAST_COMMIT_DATE=\"$EDITOR_LAST_COMMIT_DATE\"" >> "$GITHUB_ENV"
echo "RES_LAST_COMMIT_DATE=\"$RES_LAST_COMMIT_DATE\"" >> "$GITHUB_ENV"

mkdir -p doom2df-win32
nix build --print-build-logs .#mingw32.bundles.default
cp -r result/* doom2df-win32/
# Because the result is copied from the nix store, files are readonly.
# Make them writable.
find doom2df-win32 -exec chmod 777 {} \;
[[ -n "$IS_WINDOWS" ]] && find doom2df-win32/assets -iname "*.txt" -exec unix2dos {} \;
find doom2df-win32/executables/ -type f -iname 'doom2df*' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
find doom2df-win32/executables/ -type f -iname 'editor*' -exec touch -d "$EDITOR_LAST_COMMIT_DATE" {} \;
find doom2df-win32/assets/ -type f -exec touch -d "$RES_LAST_COMMIT_DATE" {} \;

if [[ -n "$IS_WINDOWS" ]]; then
    find doom2df-win32/executables/ -type f -iname '*.dll' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
else
    find doom2df-win32/executables/ -type f -iname '*.so' -exec touch -d "$D2DF_LAST_COMMIT_DATE" {} \;
fi

7zz a -mtm -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/executables/.
7zz a -mtm -stl -ssp -tzip doom2df-win32.zip -w doom2df-win32/assets/.