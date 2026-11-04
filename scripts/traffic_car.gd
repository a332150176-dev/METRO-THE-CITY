extends CharacterBody3D
class_name TrafficCar

var body_length: float = 4.2
var body_width: float = 1.85
var vehicle_type: String = "sedan"

var route_network: RoadNetwork
var lights: TrafficController
var traffic_manager: TrafficManager
var route: PackedVector3Array = PackedVector3Array()
var route_index: int = 1
var route_goal_id: int = 0
var speed: float = 0.0
var cruise_speed: float = 10.5
var paint_color: Color = Color("#287c9b")
var overtaking: bool = false
var overtake_clock: float = 0.0
var player_driving: bool = false
var driver: PlayerController
var driving_joystick: TouchJoystick
var vehicle_camera: Camera3D

func setup(network: RoadNetwork, controller: TrafficController, start_id: int, goal_id: int, color: Color, lane: float = 3.1, manager: TrafficManager = null, type: String = "sedan") -> void:
	route_network = network
	lights = controller
	traffic_manager = manager
	route_goal_id = goal_id
	paint_color = color
	vehicle_type = type
	_match_vehicle_dimensions()
	route = network.build_route(start_id, goal_id, lane)
	if route.size() > 0:
		position = route[0]
	_build_vehicle()

func _ready() -> void:
	if get_node_or_null("VehicleVisual") == null:
		_build_vehicle()

func _match_vehicle_dimensions() -> void:
	match vehicle_type:
		"van":
			body_length = 4.9
			body_width = 1.95
		"suv":
			body_length = 4.55
			body_width = 1.95
		"taxi":
			body_length = 4.25
			body_width = 1.85
		_:
			vehicle_type = "sedan"
			body_length = 4.2
			body_width = 1.85

func _build_vehicle() -> void:
	if get_node_or_null("VehicleVisual") != null:
		return
	var collider := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(body_width, 1.5 if vehicle_type == "van" else 1.25, body_length)
	collider.shape = box_shape
	collider.position.y = 0.68
	add_child(collider)

	var visual := Node3D.new()
	visual.name = "VehicleVisual"
	add_child(visual)
	_add_box(visual, Vector3(body_width, 0.82, body_length), Vector3(0.0, 0.62, 0.0), paint_color)
	var cabin_length := 2.65 if vehicle_type == "van" else (2.25 if vehicle_type == "suv" else 2.0)
	var cabin_height := 0.92 if vehicle_type == "van" else (0.78 if vehicle_type == "suv" else 0.68)
	var cabin_width := body_width * (0.84 if vehicle_type == "van" else 0.80)
	_add_box(visual, Vector3(cabin_width, cabin_height, cabin_length), Vector3(0.0, 1.34 if vehicle_type == "van" else 1.22, -0.12), Color("#273946"))
	_add_box(visual, Vector3(body_width * 0.82, 0.12, 0.62), Vector3(0.0, 0.98, -body_length * 0.36), Color("#d7d9d4"))
	if vehicle_type == "taxi":
		_add_box(visual, Vector3(0.48, 0.16, 0.3), Vector3(0.0, 1.72, -0.12), Color("#f2c94c"))
	for side in [-1.0, 1.0]:
		for axle in [-1.25, 1.25]:
			var wheel := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.34
			cylinder.bottom_radius = 0.34
			cylinder.height = 0.2
			wheel.mesh = cylinder
			wheel.rotation_degrees.z = 90.0
			wheel.position = Vector3(side * (body_width * 0.51), 0.38, axle * (body_length / 4.2))
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

func enter_vehicle(player: PlayerController, joystick: TouchJoystick) -> void:
	if player_driving or player == null:
		return
	player_driving = true
	driver = player
	driving_joystick = joystick
	driver.camera.current = false
	driver.hide()
	driver.set_physics_process(false)
	driver.collision_layer = 0
	driver.collision_mask = 0
	driver.velocity = Vector3.ZERO
	vehicle_camera = Camera3D.new()
	vehicle_camera.name = "VehicleCamera"
	vehicle_camera.position = Vector3(0.0, 3.3, 7.6)
	vehicle_camera.rotation_degrees.x = -15.0
	vehicle_camera.fov = 78.0
	add_child(vehicle_camera)
	vehicle_camera.current = true

func exit_vehicle() -> void:
	if not player_driving:
		return
	player_driving = false
	if vehicle_camera != null:
		vehicle_camera.current = false
		vehicle_camera.queue_free()
		vehicle_camera = null
	if is_instance_valid(driver):
		driver.show()
		driver.set_physics_process(true)
		driver.collision_layer = 1
		driver.collision_mask = 1
		driver.global_position = global_position + global_transform.basis.x * 2.4 + Vector3(0.0, 0.05, 0.0)
		driver.velocity = Vector3.ZERO
		driver.camera.current = true
	driver = null
	driving_joystick = null
	overtaking = false
	var nearest := route_network.nearest_intersection(global_position)
	route = route_network.build_route(int(nearest["id"]), route_goal_id)
	route_index = 1
	speed = 0.0

func _physics_process(delta: float) -> void:
	if player_driving:
		_drive_player(delta)
		return
	if route.size() < 2 or route_index >= route.size():
		queue_free()
		return

	var target := route[route_index]
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

func _drive_player(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if driving_joystick != null and driving_joystick.value.length() > 0.08:
		input_vector = driving_joystick.value

	if input_vector.y > 0.08:
		speed = move_toward(speed, 15.0, 9.0 * delta)
	elif input_vector.y < -0.08:
		speed = move_toward(speed, -5.0, 12.0 * delta)
	else:
		speed = move_toward(speed, 0.0, 3.0 * delta)

	if absf(speed) > 0.4:
		rotation.y -= input_vector.x * delta * 1.25 * signf(speed)
	var forward := -global_transform.basis.z
	velocity = forward * speed
	velocity.y = 0.0
	move_and_slide()
