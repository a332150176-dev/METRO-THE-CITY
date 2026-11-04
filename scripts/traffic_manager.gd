extends Node3D
class_name TrafficManager

const CAR_SCRIPT := preload("res://scripts/traffic_car.gd")
const PEDESTRIAN_SCRIPT := preload("res://scripts/pedestrian.gd")
const VEHICLE_MODEL_NAMES := ["sedan", "suv", "van", "taxi", "police", "ambulance", "firetruck", "delivery"]

var rng := RandomNumberGenerator.new()
var network: RoadNetwork
var lights: TrafficController
var cars: Array[TrafficCar] = []
var pedestrians: Array[CityPedestrian] = []
var police_units: Array[TrafficCar] = []
var wanted_level: int = 0
var spawn_clock: float = 0.0
var simulation_clock: float = 0.0
var player_tracker: Node3D
var simulation_radius: float = 190.0
var target_car_count: int = 14
var vehicle_types: Array[String] = ["sedan", "suv", "sedan", "van", "sedan", "taxi", "sedan", "suv", "sedan", "delivery", "sedan", "police", "sedan", "ambulance", "sedan", "van", "sedan", "suv", "sedan", "taxi", "sedan", "sedan", "firetruck", "sedan"]
var vehicle_scenes: Dictionary = {}
var car_colors: Array[Color] = [
	Color("#24799a"), Color("#c2c6c5"), Color("#b64d3b"),
	Color("#d4a843"), Color("#343b43"), Color("#6d8a6f")
]
var pedestrian_colors: Array[Color] = [
	Color("#496b88"), Color("#9a5948"), Color("#577d61"),
	Color("#9b8756"), Color("#55566d"), Color("#8a8f94")
]

func configure(road_network: RoadNetwork, controller: TrafficController) -> void:
	network = road_network
	lights = controller
	rng.seed = 884422
	_load_vehicle_models()
	for i in range(target_car_count):
		_spawn_one_car(i)
	_spawn_pedestrians(24)

func _load_vehicle_models() -> void:
	vehicle_scenes.clear()
	for model_name_value in VEHICLE_MODEL_NAMES:
		var model_name := str(model_name_value)
		var asset_path := "res://assets/vehicles/%s.glb.b64" % model_name
		if not FileAccess.file_exists(asset_path):
			continue
		var encoded := FileAccess.get_file_as_string(asset_path).strip_edges()
		if encoded.is_empty():
			continue
		var binary := Marshalls.base64_to_raw(encoded)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var parse_error := document.append_from_buffer(binary, "res://assets/vehicles/", state, 0)
		if parse_error != OK:
			push_warning("Could not load vehicle model %s: %s" % [model_name, error_string(parse_error)])
			continue
		var model_scene := document.generate_scene(state)
		if model_scene == null:
			continue
		var packed := PackedScene.new()
		var pack_error := packed.pack(model_scene)
		if pack_error == OK:
			vehicle_scenes[model_name] = packed
		else:
			push_warning("Could not pack vehicle model %s: %s" % [model_name, error_string(pack_error)])
		model_scene.free()

func set_wanted_level(level: int, player_node: Node3D) -> void:
	wanted_level = clampi(level, 0, 5)
	var active_units := mini(wanted_level, 3)
	while police_units.size() < active_units:
		_spawn_police_unit(player_node)
	while police_units.size() > active_units:
		var unit: TrafficCar = police_units.pop_back()
		if is_instance_valid(unit):
			unit.pursuit_target = null
			unit.queue_free()

func _spawn_police_unit(player_node: Node3D) -> void:
	if player_node == null or not is_instance_valid(player_node) or network == null:
		return
	var target_data := network.nearest_intersection(player_node.global_position)
	var target_id := int(target_data["id"])
	var target_position: Vector3 = target_data["position"]
	var candidates: Array[int] = []
	var fallback_id := 0
	var fallback_distance := -1.0
	for id in range(network.GRID_SIZE * network.GRID_SIZE):
		var point := network.intersection_position(id)
		var distance := Vector2(point.x, point.z).distance_to(Vector2(player_node.global_position.x, player_node.global_position.z))
		if distance > fallback_distance:
			fallback_distance = distance
			fallback_id = id
		if distance >= 85.0 and distance <= 220.0 and id != target_id:
			candidates.append(id)
	var start_id := fallback_id
	if not candidates.is_empty():
		start_id = candidates[rng.randi_range(0, candidates.size() - 1)]
	var lane := 3.1 if police_units.size() % 2 == 0 else -3.1
	var police := CAR_SCRIPT.new() as TrafficCar
	police.name = "PolicePursuit_%02d" % (police_units.size() + 1)
	police.setup(network, lights, start_id, target_id, Color("#f1eee7"), lane, self, "police")
	add_child(police)
	cars.append(police)
	police_units.append(police)
	police.begin_pursuit(player_node)

func closest_police_distance(player_node: Node3D) -> float:
	if player_node == null or not is_instance_valid(player_node):
		return INF
	var closest := INF
	for police in police_units:
		if not is_instance_valid(police) or police.is_queued_for_deletion():
			continue
		var distance := Vector2(police.global_position.x, police.global_position.z).distance_to(Vector2(player_node.global_position.x, player_node.global_position.z))
		closest = minf(closest, distance)
	return closest

func get_vehicle_scene(model_name: String) -> PackedScene:
	var requested := model_name
	if not vehicle_scenes.has(requested):
		requested = "sedan"
	return vehicle_scenes.get(requested) as PackedScene

func set_player_tracker(player_node: Node3D) -> void:
	player_tracker = player_node
	_refresh_actor_simulation()

func _process(delta: float) -> void:
	for i in range(cars.size() - 1, -1, -1):
		if not is_instance_valid(cars[i]) or cars[i].is_queued_for_deletion():
			cars.remove_at(i)
	simulation_clock += delta
	if simulation_clock >= 0.45:
		simulation_clock = 0.0
		_refresh_actor_simulation()
	spawn_clock += delta
	if cars.size() < target_car_count and spawn_clock >= 3.5:
		spawn_clock = 0.0
		_spawn_one_car(rng.randi_range(0, 1000))

func _refresh_actor_simulation() -> void:
	if player_tracker == null or not is_instance_valid(player_tracker):
		return
	var player_position := Vector2(player_tracker.global_position.x, player_tracker.global_position.z)
	for car in cars:
		if not is_instance_valid(car) or car.is_queued_for_deletion():
			continue
		var car_position := Vector2(car.global_position.x, car.global_position.z)
		var car_active := car.player_driving or player_position.distance_to(car_position) <= simulation_radius
		if car.is_physics_processing() != car_active:
			car.set_physics_process(car_active)
	for pedestrian in pedestrians:
		if not is_instance_valid(pedestrian) or pedestrian.is_queued_for_deletion():
			continue
		var pedestrian_position := Vector2(pedestrian.global_position.x, pedestrian.global_position.z)
		var pedestrian_active := player_position.distance_to(pedestrian_position) <= simulation_radius
		if pedestrian.is_physics_processing() != pedestrian_active:
			pedestrian.set_physics_process(pedestrian_active)

func _spawn_one_car(seed_value: int) -> void:
	var intersection_count := network.GRID_SIZE * network.GRID_SIZE
	var start_id := seed_value if seed_value >= 0 and seed_value < intersection_count else rng.randi_range(0, intersection_count - 1)
	var goal_id := rng.randi_range(0, intersection_count - 1)
	while goal_id == start_id:
		goal_id = rng.randi_range(0, intersection_count - 1)
	var car: TrafficCar = CAR_SCRIPT.new()
	car.name = "TrafficCar_%02d" % (seed_value % 1000)
	var lane := 3.0 if seed_value % 2 == 0 else -3.0
	car.setup(network, lights, start_id, goal_id, car_colors[posmod(seed_value, car_colors.size())], lane, self, vehicle_types[posmod(seed_value, vehicle_types.size())])
	add_child(car)
	cars.append(car)

func _spawn_pedestrians(count: int) -> void:
	for i in range(count):
		var pedestrian: CityPedestrian = PEDESTRIAN_SCRIPT.new()
		pedestrian.name = "Pedestrian_%02d" % i
		pedestrian.setup(_make_sidewalk_route(i), pedestrian_colors[i % pedestrian_colors.size()])
		add_child(pedestrian)
		pedestrians.append(pedestrian)

func _make_sidewalk_route(seed_offset: int) -> PackedVector3Array:
	var points := PackedVector3Array()
	var center_index := int((network.GRID_SIZE - 1) / 2)
	var road_line := float(rng.randi_range(0, network.GRID_SIZE - 1) - center_index) * 76.0
	var side := -1.0 if seed_offset % 2 == 0 else 1.0
	var lane := road_line + side * 11.5
	var road_edge := float(network.GRID_SIZE - 1) * 0.5 * 76.0
	var start := rng.randf_range(-road_edge, road_edge)
	points.append(Vector3(start, 0.05, lane))
	points.append(Vector3(road_edge, 0.05, lane))
	points.append(Vector3(road_edge, 0.05, lane + side * 8.0))
	points.append(Vector3(-road_edge, 0.05, lane + side * 8.0))
	points.append(Vector3(-road_edge, 0.05, lane))
	return points

func lead_distance(source: TrafficCar, direction: Vector3) -> float:
	var closest := INF
	for other in cars:
		if not is_instance_valid(other) or other == source or other.is_queued_for_deletion() or other.player_driving:
			continue
		var relative := other.global_position - source.global_position
		var ahead := relative.dot(direction)
		var lateral := absf(relative.x * direction.z - relative.z * direction.x)
		if ahead > 0.5 and ahead < closest and lateral < 2.6:
			closest = ahead
	return closest

func lane_clear(source: TrafficCar, direction: Vector3) -> bool:
	for other in cars:
		if not is_instance_valid(other) or other == source or other.is_queued_for_deletion() or other.player_driving:
			continue
		var relative := other.global_position - source.global_position
		var ahead := relative.dot(direction)
		var lateral := absf(relative.x * direction.z - relative.z * direction.x)
		if absf(lateral - 6.0) < 2.2 and ahead > -7.0 and ahead < 18.0:
			return false
	return true
