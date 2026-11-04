# METRO: THE CITY

A third-person 3D Android action/adventure game built with Godot 4.3+, using the Compatibility renderer (OpenGL ES 3) for mobile hardware.

## Open the playable source

Open the repository root in Godot 4.3 or newer by opening `project.godot`.

The current reconstructed gameplay baseline includes:
- A connected Tel Aviv-inspired 3D city with a 9×9 intersection grid (81 intersections), 64 city blocks and distinct residential, mixed-use and downtown districts.
- Destination-based routing between intersections, including curved paths for turns.
- AI traffic that obeys green/yellow/red traffic-light phases, follows other vehicles and attempts lane changes/overtakes when the adjacent lane is clear.
- Pedestrians moving along sidewalk routes.
- Third-person player movement, three selectable character profiles, persistent shirt-color customization, jump, and on-screen Android touch controls.
- Enterable vehicles with a third-person driving camera, forward/reverse controls, steering and an exit action.
- A starter campaign with objectives, rewards, money and reputation, with local save data between launches.
- A live mini-map showing the expanded city grid, next mission target and the player's position, including while driving.
- A wanted-level system with five levels, vehicle-theft and driving-collision reports, road-routed police pursuits, flashing emergency lights and backup dispatch.

The scene uses procedural geometry and intentionally modest rendering settings as a first playable baseline for the M36 Plus target. The source here is a reconstruction from the established V10 design requirements; the original V10 archive is still being transferred and has not yet been verified as restored.

## Validation

GitHub Actions runs a headless Godot import and a gameplay smoke test when the game source changes. The smoke test checks city generation, road routing, AI population, campaign initialization and vehicle entry/exit.

## Original V10 archive

The original source ZIP is transferred in ten ordered parts. Parts may be stored as one `.txt` file or as numbered sub-fragments (for example, `.source_transfer/part-09-01.txt`).

To validate and restore the complete archive locally:

```bash
python tools/restore_source_archive.py
```

The script checks that all ten parts are present, joins their sub-fragments in numeric order, validates Base64 and ZIP integrity, confirms `project.godot` is present, and rejects unsafe paths before extraction.

The **Restore V10 source archive** GitHub Actions workflow also runs when a transfer file is pushed. The original V10 archive is not considered restored until the workflow completes successfully and its source files have been committed.
