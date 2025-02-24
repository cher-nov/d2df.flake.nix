#!/bin/bash
set -euo pipefail
EDITOR_DATE="2025-02-21 17:58:06 +1000"
GAME_DATE="2025-02-21 17:58:06 +1000"
ASSETS_DATE="2025-02-21 17:58:06 +1000"
CMD=$(
cat <<EOF
(builtins.getFlake (toString ./.)).outputs.legacyPackages.x86_64-linux.$BUNDLE_NAME.override
(prev: {
  executables = prev.executables.override {gameDate = "$GAME_DATE"; withDates = true;};
  assets = prev.assets.override {editorDate = "$EDITOR_DATE"; assetsDate = "$ASSETS_DATE"; withDates = true;};
})
EOF
)
nix build --impure --expr "$CMD"
