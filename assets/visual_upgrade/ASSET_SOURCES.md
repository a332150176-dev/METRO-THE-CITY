# METRO: THE CITY — higher-detail visual assets

All assets are bundled locally in the Android build. The game does not download assets at runtime.

## Player character

- File: `lagos_player.glb`
- Creator/source: Quaternius, mirrored in `johnAyodele1/lagos-gta`
- Original attribution record: https://github.com/johnAyodele1/lagos-gta/blob/main/assets/models/ASSET_CREDITS.md
- License: CC0 1.0 Universal
- The GLB contains a 31-joint rig and authored Idle, Walk and Run animations (along with additional action clips).

## Road surface PBR maps

- Files: `asphalt-color.jpg`, `asphalt-normalgl.jpg`, `asphalt-roughness.jpg`
- Source asset: ambientCG Asphalt012, bundled in the City Sample project.
- License: CC0 1.0 Universal
- Source: https://ambientcg.com/view?id=Asphalt012
- Used as albedo, OpenGL normal and roughness maps on road surfaces.

## Downtown buildings

- File fetched by `tools/fetch_visual_assets.sh`: `downtown.glb`
- Authors: Quaternius, Downtown City MegaKit (free Standard edition).
- Source: https://quaternius.com/packs/downtowncitymegakit.html
- License: CC0 1.0 Universal.
- Source manifest: https://github.com/HelloClyde/tesla-media-center/blob/master/web/public/models/city-sample/SOURCES.md

## Apartment facades

- File fetched by `tools/fetch_visual_assets.sh`: `alley-apartments.glb`
- Creator: James Ray Cock; Poly Haven Hidden Alley collection.
- Source: https://polyhaven.com/a/modular_urban_apartments_facade
- License: CC0 1.0 Universal.
- The source is a curated, combined set of four street facades with PBR materials.

## Trees

- File fetched by `tools/fetch_visual_assets.sh`: `tree.glb`
- Source: Poly Haven Island Tree 01.
- Source: https://polyhaven.com/a/island_tree_01
- License: CC0 1.0 Universal.

## Build preparation

The source city models use `EXT_meshopt_compression`. Godot 4.3 does not import that extension by itself, so CI downloads the pinned files, verifies their Git blob hashes, decodes them using glTF Transform, and then imports the plain GLB assets. Run the same preparation locally before opening the project:

```bash
bash tools/fetch_visual_assets.sh
npm install --prefix .github/visual-tools --no-save --no-audit --no-fund @gltf-transform/core@4.1.1 @gltf-transform/extensions@4.1.1 @gltf-transform/functions@4.1.1 meshoptimizer@0.22.0
node .github/visual-tools/decompress-assets.mjs
```
