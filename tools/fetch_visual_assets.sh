#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/assets/visual_upgrade"
mkdir -p "$OUT"

fetch_git_blob() {
  local url="$1"
  local destination="$2"
  local expected="$3"
  echo "Downloading $(basename "$destination")"
  curl -fL --retry 3 --retry-delay 2 "$url" -o "$destination"
  local actual
  actual="$(git -C "$ROOT" hash-object "$destination")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Asset checksum mismatch for $destination: expected $expected, got $actual" >&2
    exit 1
  fi
}

BASE="https://raw.githubusercontent.com/HelloClyde/tesla-media-center/master/web/public"
fetch_git_blob "$BASE/models/city-sample/downtown.glb" "$OUT/downtown.glb" "fccf995c46572a63bb552c8f881e34bf7ac825ae"
fetch_git_blob "$BASE/models/city-sample/alley-apartments.glb" "$OUT/alley-apartments.glb" "e2b6a80ed68899bf85e21f6f2fced55ae7608613"
fetch_git_blob "$BASE/models/city-sample/tree.glb" "$OUT/tree.glb" "fac9b0c12c97221c452fbabdc02a454d50abf2ec"
echo "Verified high-detail visual asset source checksums."
