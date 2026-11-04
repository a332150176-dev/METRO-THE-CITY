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
var target_car_count: int = 9
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
	_spawn_pedestrians(18)

func _process(delta: float) -> void:
	for i in range(cars.size() - 1, -1, -1):
		if not is_instance_valid(cars[i]) or cars[i].is_queued_for_deletion():
			cars.remove_at(i)
	spawn_clock += delta
	if cars.size() < target_car_count and spawn_clock >= 3.5:
		spawn_clock = 0.0
		_spawn_one_car(rng.randi_range(0, 1000))

func _spawn_one_car(seed_value: int) -> void:
	var start_id := seed_value if seed_value >= 0 and seed_value < 9 else rng.randi_range(0, 8)
	var goal_id := rng.randi_range(0, 8)
	while goal_id == start_id:
		goal_id = rng.randi_range(0, 8)
	var car: TrafficCar = CAR_SCRIPT.new()
	car.name = "TrafficCar_%02d" % (seed_value % 1000)
	var lane := 3.0 if seed_value % 2 == 0 else -3.0
	car.setup(network, lights, start_id, goal_id, car_colors[posmod(seed_value, car_colors.size())], lane, self)
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
	var road_line := float(rng.randi_range(-1, 1)) * 76.0
	var side := -1.0 if seed_offset % 2 == 0 else 1.0
	var lane := road_line + side * 11.5
	var start := rng.randf_range(-76.0, 76.0)
	points.append(Vector3(start, 0.08, lane))
	points.append(Vector3(76.0, 0.08, lane))
	points.append(Vector3(76.0, 0.08, lane + side * 8.0))
	points.append(Vector3(-76.0, 0.08, lane + side * 8.0))
	points.append(Vector3(-76.0, 0.08, lane))
	return points

func lead_distance(source: TrafficCar, direction: Vector3) -> float:
	var closest := INF
	for other in cars:
		if not is_instance_valid(other) or other == source or other.is_queued_for_deletion():
			continue
		var relative := other.global_position - source.global_position
		var ahead := relative.dot(direction)
		var lateral := absf(relative.x * direction.z - relative.z * direction.x)
		if ahead > 0.5 and ahead < closest and lateral < 2.6:
			closest = ahead
	return closest

func lane_clear(source: TrafficCar, direction: Vector3) -> bool:
	for other in cars:
		if not is_instance_valid(other) or other == source or other.is_queued_for_deletion():
			continue
		var relative := other.global_position - source.global_position
		var ahead := relative.dot(direction)
		var lateral := absf(relative.x * direction.z - relative.z * direction.x)
		if absf(lateral - 6.0) < 2.2 and ahead > -7.0 and ahead < 18.0:
			return false
	return true
