# METRO: THE CITY — Game Design & Development Plan

## Approved direction

- Platform: Android, optimized for the M36 Plus test device.
- Genre and camera: third-person, open-world action/adventure.
- Visual target: detailed, believable urban architecture, realistic materials, varied human characters and a fully dressed street environment.
- Quality-first workflow: do not simplify the visual target in advance; profile and optimize only after the intended visual result is in place.
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

The current project uses the Godot 4.3 Mobile renderer with anisotropic texture filtering, 2x 3D MSAA, sky-based ambient/reflected lighting, filmic tonemapping, fog and restrained glow. The city road graph now uses a 9×9 intersection grid (81 intersections) with eight blocks in each direction (64 continuous blocks). The residential districts use eight authored CC0 building models, with detailed Poly Haven apartment facades repeated through mixed-use and residential blocks; downtown uses five separate textured skyscraper models and additional Quaternius city set pieces. Asphalt uses PBR albedo, normal and roughness maps, and the avenues are dressed with authored trees, pedestrian crossings and 72 street lamps. One commercial lot is reserved for an enterable minimarket with authored 3D food/drink stock, product selection, checkout and saved inventory. Eight authored CC0 vehicle models provide civilian, delivery and emergency traffic. Vehicle theft and driving collisions trigger wanted levels; up to three police pursuit cars are dispatched, remain active outside the normal simulation radius, and flash red/blue emergency lights during pursuit. The city populates 24 traffic vehicles and 48 animated pedestrians, with three visual character palettes; distant actors are paused outside a 190 m player radius. Interior visits pause city traffic and hide the minimap.

## Performance rules

1. Preserve the high-detail visual target first; profile performance after visual content is complete.
2. Use instancing/batched meshes for repeated detail such as windows, lane paint and crosswalks.
3. Keep traffic and pedestrian counts moderate and measure before increasing them.
4. Add level-of-detail and distance-based visibility before filling distant neighborhoods with expensive detail.
5. Test each major city expansion on the physical M36 Plus; editor/CI success is not proof of device performance. This is a final validation step, not a reason to pre-emptively reduce asset quality.

## Roadmap

### Phase 1 — Expand and dress the city
- Expand the road grid and minimap together.
- Create residential, mixed-use and downtown building profiles.
- Add façade windows, roof details, balconies and more street furniture.
- Preserve a stable navigation and traffic graph.

### Phase 2 — Make the open world playable
- Add multiple enterable vehicle classes and vehicle interaction feedback.
- Add free-roam activities, discoverable locations and optional tasks.
- Add selected enterable interiors and transitions. (Initial minimarket interior and purchase loop are implemented.)

### Phase 3 — Systems
- [x] Police response: five-star wanted level, theft/collision reports, backup dispatch, road-based pursuit, emergency lights and escape decay.
- Improve character creator, clothing and appearance persistence.
- Add activity progression, save/load and Hebrew interface polish.

### Phase 4 — Visual and device optimization
- Add authored or licensed low-poly/realistic assets where possible. (Initial suburban, downtown, vehicle and shop food models are integrated.)
- Add LOD, visibility ranges, pooled traffic and distance-based pedestrian simulation.
- Profile frame time, memory, heat and controls on the M36 Plus.

## Acceptance checks for each device build

- App opens and reaches gameplay without crashing.
- Walking, camera movement, touch controls and vehicle entry/exit work.
- City navigation and mini-map agree on the expanded street grid.
- Traffic routes do not stop at the old map boundary.
- A 10-minute drive does not introduce persistent stutter or severe heating.
- The game aims for 30 FPS; any measured shortfall must be recorded before adding more detail.
