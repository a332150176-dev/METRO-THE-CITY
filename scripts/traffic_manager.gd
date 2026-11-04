extends Node3D
class_name TrafficManager

const CAR_SCRIPT := preload("res://scripts/traffic_car.gd")
const PEDESTRIAN_SCRIPT := preload("res://scripts/pedestrian.gd")

var rng := RandomNumberGenerator.new()
var network: RoadNetwork
var lights: TrafficController
var cars: Array[TrafficCar] = []
var pedestrians: Array[CityPedestrian] = []
var spawn_clock: float = 0.0
var simulation_clock: float = 0.0
var player_tracker: Node3D
var simulation_radius: float = 190.0
var target_car_count: int = 14
var vehicle_types: Array[String] = ["sedan", "suv", "van", "taxi"]
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
	for i in range(target_car_count):
		_spawn_one_car(i)
	_spawn_pedestrians(24)

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
		var active := car.player_driving or player_position.distance_to(car_position) <= simulation_radius
		if car.is_physics_processing() != active:
			car.set_physics_process(active)
	for pedestrian in pedestrians:
		if not is_instance_valid(pedestrian) or pedestrian.is_queued_for_deletion():
			continue
		var pedestrian_position := Vector2(pedestrian.global_position.x, pedestrian.global_position.z)
		var active := player_position.distance_to(pedestrian_position) <= simulation_radius
		if pedestrian.is_physics_processing() != active:
			pedestrian.set_physics_process(active)

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
