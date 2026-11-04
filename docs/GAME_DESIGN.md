# METRO: THE CITY — Game Design & Development Plan

## Approved direction

- Platform: Android, optimized for the M36 Plus test device.
- Genre and camera: third-person, open-world action/adventure.
- Visual target: realistic and detailed, with performance-aware asset budgets.
- Performance target: stable 30 FPS on the target device before increasing visual complexity.
- World: a large, connected city with distinct neighborhoods and districts.
- Traffic and pedestrians: moderate population to preserve frame time.
- Activities: free-roam first, with optional activities and missions.
- Vehicles: multiple vehicle types; most common city vehicles should be enterable and drivable.
- Interiors: selected buildings and venues can be entered.
- Characters: a choice of preset characters plus deeper player customization.
- Police: wanted level, patrol response and pursuit gameplay.
- Controls: on-screen joystick and contextual action buttons.
- Language: Hebrew.

## Existing playable baseline

The first APK was deliberately a compatibility and gameplay test. It demonstrated that the Android export installs and runs on the M36 Plus. It is not the intended visual quality bar.

The current project uses Godot 4.3 Compatibility renderer. The first city uses procedural primitive geometry; the next development phase replaces the tiny test layout with a larger district-based layout and improved building façades.

## Performance rules

1. Keep 30 FPS as the primary target; visual effects must earn their cost.
2. Use instancing/batched meshes for repeated detail such as windows, lane paint and crosswalks.
3. Keep traffic and pedestrian counts moderate and measure before increasing them.
4. Add level-of-detail and distance-based visibility before filling distant neighborhoods with expensive detail.
5. Test each major city expansion on the physical M36 Plus; editor/CI success is not proof of device performance.

## Roadmap

### Phase 1 — Expand and dress the city
- Expand the road grid and minimap together.
- Create residential, mixed-use and downtown building profiles.
- Add façade windows, roof details, balconies and more street furniture.
- Preserve a stable navigation and traffic graph.

### Phase 2 — Make the open world playable
- Add multiple enterable vehicle classes and vehicle interaction feedback.
- Add free-roam activities, discoverable locations and optional tasks.
- Add selected enterable interiors and transitions.

### Phase 3 — Systems
- Build a police response and wanted-level system.
- Improve character creator, clothing and appearance persistence.
- Add activity progression, save/load and Hebrew interface polish.

### Phase 4 — Visual and device optimization
- Add authored or licensed low-poly/realistic assets where possible.
- Add LOD, visibility ranges, pooled traffic and distance-based pedestrian simulation.
- Profile frame time, memory, heat and controls on the M36 Plus.

## Acceptance checks for each device build

- App opens and reaches gameplay without crashing.
- Walking, camera movement, touch controls and vehicle entry/exit work.
- City navigation and mini-map agree on the expanded street grid.
- Traffic routes do not stop at the old map boundary.
- A 10-minute drive does not introduce persistent stutter or severe heating.
- The game aims for 30 FPS; any measured shortfall must be recorded before adding more detail.
