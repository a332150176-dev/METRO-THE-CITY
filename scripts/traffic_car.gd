extends CharacterBody3D
class_name TrafficCar

const BODY_LENGTH: float = 4.2

var route_network: RoadNetwork
var lights: TrafficController
var traffic_manager: TrafficManager
var route: PackedVector3Array = PackedVector3Array()
var route_index: int = 1
var speed: float = 0.0
var cruise_speed: float = 10.5
var paint_color: Color = Color("#287c9b")
var overtaking: bool = false
var overtake_clock: float = 0.0

func setup(network: RoadNetwork, controller: TrafficController, start_id: int, goal_id: int, color: Color, lane: float = 3.1, manager: TrafficManager = null) -> void:
	route_network = network
	lights = controller
	traffic_manager = manager
	paint_color = color
	route = network.build_route(start_id, goal_id, lane)
	if route.size() > 0:
		global_position = route[0] + Vector3(0.0, 0.15, 0.0)
	_build_vehicle()

func _ready() -> void:
	if get_node_or_null("VehicleVisual") == null:
		_build_vehicle()

func _build_vehicle() -> void:
	if get_node_or_null("VehicleVisual") != null:
		return
	var collider := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(1.85, 1.25, BODY_LENGTH)
	collider.shape = box_shape
	collider.position.y = 0.68
	add_child(collider)

	var visual := Node3D.new()
	visual.name = "VehicleVisual"
	add_child(visual)
	_add_box(visual, Vector3(1.85, 0.78, BODY_LENGTH), Vector3(0.0, 0.58, 0.0), paint_color)
	_add_box(visual, Vector3(1.48, 0.68, 2.0), Vector3(0.0, 1.22, -0.18), Color("#273946"))
	_add_box(visual, Vector3(1.5, 0.12, 0.62), Vector3(0.0, 0.94, -1.55), Color("#d7d9d4"))
	for side in [-1.0, 1.0]:
		for axle in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.34
			cylinder.bottom_radius = 0.34
			cylinder.height = 0.2
			wheel.mesh = cylinder
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(side * 0.94, 0.38, axle)
			var tire := StandardMaterial3D.new()
			tire.albedo_color = Color("#171a1d")
			wheel.material_override = tire
			visual.add_child(wheel)

func _add_box(parent: Node3D, dimensions: Vector3, offset: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.position = offset
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)

func _physics_process(delta: float) -> void:
	if route.size() < 2 or route_index >= route.size():
		queue_free()
		return

	var target := route[route_index] + Vector3(0.0, 0.15, 0.0)
	var to_target := target - global_position
	to_target.y = 0.0
	var distance := to_target.length()
	if distance < 2.0:
		route_index += 1
		return

	var direction := to_target.normalized()
	var desired_speed := cruise_speed
	var lead := INF
	if traffic_manager != null:
		lead = traffic_manager.lead_distance(self, direction)
		if lead < 12.0 and not overtaking and traffic_manager.lane_clear(self, direction):
			overtaking = true
			overtake_clock = 0.0
		if overtaking:
			overtake_clock += delta
			target += Vector3(direction.z, 0.0, -direction.x) * -3.0
			to_target = target - global_position
			to_target.y = 0.0
			direction = to_target.normalized()
			if lead > 15.0 or overtake_clock > 4.5:
				overtaking = false
		elif lead < 9.0:
			desired_speed = minf(desired_speed, maxf(0.0, (lead - 3.0) * 1.1))

	var intersection := route_network.nearest_intersection(global_position)
	if intersection.distance < 15.0 and intersection.distance > 6.0 and lights != null:
		if not lights.is_green_for_direction(direction):
			desired_speed = 0.0
		else:
			desired_speed = minf(desired_speed, 7.0)
	elif distance < 15.0:
		desired_speed = minf(desired_speed, 6.5)

	speed = move_toward(speed, desired_speed, (8.5 if desired_speed > speed else 15.0) * delta)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = 0.0
	if speed > 0.2:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 4.0))
	move_and_slide()
