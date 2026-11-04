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
var wheel_meshes: Array[MeshInstance3D] = []

func setup(network: RoadNetwork, controller: TrafficController, start_id: int, goal_id: int, color: Color, lane: float = 3.1, manager: TrafficManager = null, type: String = "sedan") -> void:
	route_network = network
	lights = controller
	traffic_manager = manager
	route_goal_id = goal_id
	paint_color = Color("#f0c43e") if type == "taxi" else color
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
		"van", "delivery":
			body_length = 5.0
			body_width = 2.0
		"ambulance":
			body_length = 5.3
			body_width = 2.05
		"firetruck":
			body_length = 6.6
			body_width = 2.35
		"suv":
			body_length = 4.55
			body_width = 1.95
		"taxi", "police":
			body_length = 4.25
			body_width = 1.85
		_:
			vehicle_type = "sedan"
			body_length = 4.2
			body_width = 1.85

func _paint(color: Color, roughness: float = 0.58, metallic: float = 0.12) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _add_box(parent: Node3D, dimensions: Vector3, offset: Vector3, color: Color, roughness: float = 0.58, metallic: float = 0.12) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.position = offset
	instance.material_override = _paint(color, roughness, metallic)
	parent.add_child(instance)
	return instance

func _add_quad(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material
	parent.add_child(instance)

func _add_cabin_shell(parent: Node3D, width: float, profile: Array[Vector2], material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := width * 0.5
	for i in range(profile.size()):
		var next_index := (i + 1) % profile.size()
		var a := profile[i]
		var b := profile[next_index]
		var left_a := Vector3(-half, a.y, a.x)
		var right_a := Vector3(half, a.y, a.x)
		var left_b := Vector3(-half, b.y, b.x)
		var right_b := Vector3(half, b.y, b.x)
		surface.add_vertex(left_a)
		surface.add_vertex(right_a)
		surface.add_vertex(right_b)
		surface.add_vertex(left_a)
		surface.add_vertex(right_b)
		surface.add_vertex(left_b)
	for i in range(1, profile.size() - 1):
		var p0 := profile[0]
		var p1 := profile[i]
		var p2 := profile[i + 1]
		surface.add_vertex(Vector3(-half, p0.y, p0.x))
		surface.add_vertex(Vector3(-half, p1.y, p1.x))
		surface.add_vertex(Vector3(-half, p2.y, p2.x))
		surface.add_vertex(Vector3(half, p0.y, p0.x))
		surface.add_vertex(Vector3(half, p2.y, p2.x))
		surface.add_vertex(Vector3(half, p1.y, p1.x))
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = surface.commit()
	instance.material_override = material
	parent.add_child(instance)

func _add_wheel(parent: Node3D, side: float, axle: float) -> void:
	var wheel := MeshInstance3D.new()
	var tire := CylinderMesh.new()
	tire.top_radius = 0.34
	tire.bottom_radius = 0.34
	tire.height = 0.22
	tire.radial_segments = 16
	wheel.mesh = tire
	wheel.rotation_degrees.z = 90.0
	wheel.position = Vector3(side * (body_width * 0.51), 0.36, axle)
	wheel.material_override = _paint(Color("#171a1d"), 0.92, 0.0)
	parent.add_child(wheel)
	wheel_meshes.append(wheel)

	var rim := MeshInstance3D.new()
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.205
	rim_mesh.bottom_radius = 0.205
	rim_mesh.height = 0.035
	rim_mesh.radial_segments = 12
	rim.mesh = rim_mesh
	rim.rotation_degrees.z = 90.0
	rim.position = wheel.position + Vector3(side * 0.12, 0.0, 0.0)
	rim.material_override = _paint(Color("#9da6aa"), 0.34, 0.7)
	parent.add_child(rim)

	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.07
	hub_mesh.bottom_radius = 0.07
	hub_mesh.height = 0.045
	hub_mesh.radial_segments = 12
	hub.mesh = hub_mesh
	hub.rotation_degrees.z = 90.0
	hub.position = rim.position + Vector3(side * 0.025, 0.0, 0.0)
	hub.material_override = _paint(Color("#333a3e"), 0.42, 0.5)
	parent.add_child(hub)

func _build_vehicle() -> void:
	if get_node_or_null("VehicleVisual") != null:
		return
	wheel_meshes.clear()
	var collider := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(body_width, 1.55 if vehicle_type == "van" else 1.38, body_length)
	collider.shape = box_shape
	collider.position.y = 0.72
	add_child(collider)

	var visual := Node3D.new()
	visual.name = "VehicleVisual"
	add_child(visual)

	var authored_scene: PackedScene = null
	if traffic_manager != null:
		authored_scene = traffic_manager.get_vehicle_scene(vehicle_type)
	if authored_scene != null:
		var authored_model := authored_scene.instantiate() as Node3D
		if authored_model != null:
			authored_model.name = "AuthoredVehicleModel"
			var model_scale := Vector3(1.2, 1.45, 1.55)
			if vehicle_type == "van" or vehicle_type == "delivery":
				model_scale = Vector3(1.22, 1.28, 1.38)
			elif vehicle_type == "ambulance":
				model_scale = Vector3(1.25, 1.3, 1.32)
			elif vehicle_type == "firetruck":
				model_scale = Vector3(1.45, 1.25, 1.55)
			authored_model.scale = model_scale
			# The source vehicles face +Z; METRO driving uses -Z as forward.
			authored_model.rotation.y = PI
			visual.add_child(authored_model)
			_collect_authored_wheels(authored_model)
			return

	var body_material := _paint(paint_color, 0.42, 0.22)
	body_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var glass_material := _paint(Color("#152b38"), 0.2, 0.28)
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome_material := _paint(Color("#aeb9bd"), 0.28, 0.72)
	
	# Sculpted lower body, hood and rear deck.
	_add_box(visual, Vector3(body_width, 0.67, body_length * 0.94), Vector3(0.0, 0.59, 0.0), paint_color, 0.42, 0.22)
	_add_box(visual, Vector3(body_width * 0.92, 0.11, body_length * 0.30), Vector3(0.0, 0.91, -body_length * 0.32), paint_color.lightened(0.035), 0.4, 0.2)
	_add_box(visual, Vector3(body_width * 0.90, 0.10, body_length * 0.22), Vector3(0.0, 0.89, body_length * 0.34), paint_color.darkened(0.025), 0.46, 0.18)

	var roof_y := 1.76
	var front_z := -0.88
	var rear_z := 0.78
	if vehicle_type == "suv":
		roof_y = 1.88
		front_z = -1.02
		rear_z = 0.90
	elif vehicle_type == "van":
		roof_y = 2.05
		front_z = -1.28
		rear_z = 1.32
	var cabin_width := body_width * (0.82 if vehicle_type == "van" else 0.79)
	var profile: Array[Vector2] = [
		Vector2(-body_length * 0.36, 1.02),
		Vector2(front_z, roof_y),
		Vector2(rear_z, roof_y),
		Vector2(body_length * 0.36, 1.03)
	]
	_add_cabin_shell(visual, cabin_width, profile, body_material)

	# Dark, inset side windows with visible pillars.
	var side_x := cabin_width * 0.5 + 0.012
	var window_top := roof_y - 0.16
	var window_bottom := 1.17
	for side in [-1.0, 1.0]:
		var x: float = side * side_x
		var front_window: Array[Vector3] = [
			Vector3(x, window_top, front_z + 0.10),
			Vector3(x, window_top, -0.12),
			Vector3(x, window_bottom, -0.30),
			Vector3(x, window_bottom, front_z - 0.18)
		]
		_add_quad(visual, front_window[0], front_window[1], front_window[2], front_window[3], glass_material)
		var rear_window: Array[Vector3] = [
			Vector3(x, window_top, 0.12),
			Vector3(x, window_top, rear_z - 0.10),
			Vector3(x, window_bottom, body_length * 0.30),
			Vector3(x, window_bottom, 0.30)
		]
		_add_quad(visual, rear_window[0], rear_window[1], rear_window[2], rear_window[3], glass_material)
		_add_box(visual, Vector3(0.035, 0.055, 0.12), Vector3(side * (body_width * 0.5), 0.83, -0.08), Color("#aeb9bd"), 0.3, 0.65)

	# Windshield and rear glass follow the sloped roof line.
	_add_quad(visual,
		Vector3(-cabin_width * 0.37, roof_y - 0.13, front_z + 0.04),
		Vector3(cabin_width * 0.37, roof_y - 0.13, front_z + 0.04),
		Vector3(body_width * 0.36, 1.10, -body_length * 0.36 - 0.012),
		Vector3(-body_width * 0.36, 1.10, -body_length * 0.36 - 0.012),
		glass_material)
	_add_quad(visual,
		Vector3(cabin_width * 0.36, roof_y - 0.13, rear_z - 0.04),
		Vector3(-cabin_width * 0.36, roof_y - 0.13, rear_z - 0.04),
		Vector3(-body_width * 0.35, 1.11, body_length * 0.36 + 0.012),
		Vector3(body_width * 0.35, 1.11, body_length * 0.36 + 0.012),
		glass_material)

	# Bumpers, grille, registration plates and lighting.
	_add_box(visual, Vector3(body_width * 0.92, 0.16, 0.12), Vector3(0.0, 0.42, -body_length * 0.49), Color("#252b30"))
	_add_box(visual, Vector3(body_width * 0.92, 0.16, 0.12), Vector3(0.0, 0.42, body_length * 0.49), Color("#252b30"))
	_add_box(visual, Vector3(0.62, 0.19, 0.035), Vector3(0.0, 0.62, -body_length * 0.505), Color("#252b30"))
	_add_box(visual, Vector3(0.42, 0.10, 0.025), Vector3(0.0, 0.51, -body_length * 0.52), Color("#aeb9bd"))
	for side in [-1.0, 1.0]:
		var headlight := _add_box(visual, Vector3(0.34, 0.14, 0.045), Vector3(side * body_width * 0.34, 0.76, -body_length * 0.49), Color("#f5e8bd"), 0.24, 0.08)
		var lamp_material := headlight.material_override as StandardMaterial3D
		lamp_material.emission_enabled = true
		lamp_material.emission = Color("#ffe7ad") * 0.22
		_add_box(visual, Vector3(0.30, 0.13, 0.045), Vector3(side * body_width * 0.34, 0.76, body_length * 0.49), Color("#a52e2e"), 0.3, 0.0)
		_add_box(visual, Vector3(0.07, 0.10, 0.06), Vector3(side * body_width * 0.50, 1.08, -0.66), paint_color.darkened(0.08))

	# Four wheels with metallic hubs.
	for side in [-1.0, 1.0]:
		for axle in [-body_length * 0.30, body_length * 0.30]:
			_add_wheel(visual, side, axle)
		_add_box(visual, Vector3(0.08, 0.07, 0.22), Vector3(side * body_width * 0.50, 0.82, 0.16), Color("#aeb9bd"), 0.3, 0.7)

	_add_box(visual, Vector3(body_width * 0.84, 0.045, 0.07), Vector3(0.0, roof_y + 0.02, 0.0), paint_color.lightened(0.08), 0.36, 0.18)
	if vehicle_type == "taxi":
		_add_box(visual, Vector3(0.46, 0.16, 0.27), Vector3(0.0, roof_y + 0.15, 0.0), Color("#f5cf35"), 0.34, 0.1)
		_add_box(visual, Vector3(0.42, 0.035, 0.23), Vector3(0.0, roof_y + 0.24, 0.0), Color("#fff1a5"), 0.3, 0.0)
	if vehicle_type == "van":
		_add_box(visual, Vector3(0.05, 0.52, 0.04), Vector3(0.0, 1.39, 1.62), paint_color.darkened(0.13), 0.6, 0.0)

func _collect_authored_wheels(node: Node) -> void:
	if node is MeshInstance3D and str(node.name).begins_with("wheel"):
		wheel_meshes.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_authored_wheels(child)

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
	for wheel in wheel_meshes:
		if is_instance_valid(wheel):
			wheel.rotation.x -= speed * delta / 0.34
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
