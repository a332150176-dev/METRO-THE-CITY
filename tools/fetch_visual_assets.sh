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
  node --input-type=module - "$url" "$destination" "$expected" <<'NODE'
import { createHash } from 'node:crypto';
import { writeFile } from 'node:fs/promises';

const [url, destination, expected] = process.argv.slice(2);
const response = await fetch(url, { redirect: 'follow' });
if (!response.ok) {
  throw new Error(`Download failed (${response.status}): ${url}`);
}
const data = Buffer.from(await response.arrayBuffer());
const gitHeader = Buffer.from(`blob ${data.length}\0`);
const actual = createHash('sha1').update(gitHeader).update(data).digest('hex');
if (actual !== expected) {
  throw new Error(`Asset checksum mismatch for ${destination}: expected ${expected}, got ${actual}`);
}
await writeFile(destination, data);
console.log(`Verified ${destination} (${data.length.toLocaleString()} bytes)`);
NODE
}

BASE="https://raw.githubusercontent.com/HelloClyde/tesla-media-center/master/web/public"
fetch_git_blob "$BASE/models/city-sample/downtown.glb" "$OUT/downtown.glb" "fccf995c46572a63bb552c8f881e34bf7ac825ae"
fetch_git_blob "$BASE/models/city-sample/alley-apartments.glb" "$OUT/alley-apartments.glb" "e2b6a80ed68899bf85e21f6f2fced55ae7608613"
fetch_git_blob "$BASE/models/city-sample/tree.glb" "$OUT/tree.glb" "fac9b0c12c97221c452fbabdc02a454d50abf2ec"
echo "Verified high-detail visual asset source checksums."
