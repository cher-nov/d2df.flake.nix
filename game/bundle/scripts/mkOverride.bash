#!/bin/bash
set -euo pipefail
LAST_COMMIT=$(git rev-parse HEAD)
CMD=$(
cat <<EOF
(builtins.getFlake (builtins.toString ./.)).outputs.legacyPackages.x86_64-linux.$BUNDLE_NAME.override
(prev: {
  executables = prev.executables.override {gameDate = "$D2DF_LAST_COMMIT_DATE"; editorDate = "$EDITOR_LAST_COMMIT_DATE"; withDates = true;};
  assets = prev.assets.override {editorDate = "$EDITOR_LAST_COMMIT_DATE"; assetsDate = "$RES_LAST_COMMIT_DATE"; withDates = true;};
})
EOF
)
nix build \
    --verbose --show-trace --verbose --print-out-paths --print-build-logs \
    --impure --expr "$CMD"
