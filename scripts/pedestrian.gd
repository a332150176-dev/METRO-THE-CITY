extends CharacterBody3D
class_name CityPedestrian

var waypoints: PackedVector3Array = PackedVector3Array()
var waypoint_index: int = 0
var walk_speed: float = 1.35
var walk_phase: float = 0.0
var shirt_color: Color = Color("#526d85")
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var torso: MeshInstance3D
var skin_color: Color = Color("#c78d6b")
var humanoid_factory: HumanoidFactory
var rigged_model: Node3D
var rigged_animation: AnimationPlayer

func setup(points: PackedVector3Array, color: Color, factory: HumanoidFactory = null) -> void:
	waypoints = points
	shirt_color = color
	humanoid_factory = factory
	if waypoints.size() > 0:
		position = waypoints[0]
		waypoint_index = 1 if waypoints.size() > 1 else 0
	_build_person()

func _ready() -> void:
	if get_child_count() == 0:
		_build_person()

func _mat(color: Color, roughness: float = 0.92) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _capsule(parent: Node3D, node_name: String, radius: float, height: float, color: Color, offset: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	instance.mesh = mesh
	instance.position = offset
	instance.material_override = _mat(color)
	parent.add_child(instance)
	return instance

func _sphere(parent: Node3D, node_name: String, radius: float, color: Color, offset: Vector3, scale_value: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 8
	instance.mesh = mesh
	instance.position = offset
	instance.scale = scale_value
	instance.material_override = _mat(color)
	parent.add_child(instance)
	return instance

func _build_person() -> void:
	if get_node_or_null("BodyCollider") != null:
		return
	var collider := CollisionShape3D.new()
	collider.name = "BodyCollider"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.72
	collider.shape = capsule
	collider.position.y = 0.86
	add_child(collider)

	if humanoid_factory != null:
		rigged_model = humanoid_factory.create_character("pedestrian", shirt_color.to_html())
		if rigged_model != null:
			rigged_model.name = "RiggedPedestrian"
			add_child(rigged_model)
			rigged_animation = rigged_model.find_child("CharacterAnimationPlayer", true, false) as AnimationPlayer
			if rigged_animation != null and rigged_animation.has_animation("Walking_A"):
				rigged_animation.play("Walking_A")
			return

	var skin_tones: Array[Color] = [Color("#e0b18e"), Color("#c98e6c"), Color("#a96f52"), Color("#81533f")]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	skin_color = skin_tones[rng.randi_range(0, skin_tones.size() - 1)]
	var hair_colors: Array[Color] = [Color("#211d1b"), Color("#41302a"), Color("#655044")]
	var hair_color: Color = hair_colors[rng.randi_range(0, hair_colors.size() - 1)]
	var pants_colors: Array[Color] = [Color("#303944"), Color("#4b4c50"), Color("#363b32"), Color("#59616a")]
	var pants_color: Color = pants_colors[rng.randi_range(0, pants_colors.size() - 1)]

	var model := Node3D.new()
	model.name = "HumanModel"
	add_child(model)

	torso = _capsule(model, "Torso", 0.235, 0.88, shirt_color, Vector3(0.0, 1.08, 0.0))
	_capsule(model, "Pelvis", 0.18, 0.34, pants_color, Vector3(0.0, 0.64, 0.0))
	_capsule(model, "Neck", 0.075, 0.18, skin_color, Vector3(0.0, 1.59, 0.0))
	_sphere(model, "Head", 0.155, skin_color, Vector3(0.0, 1.78, 0.0), Vector3(0.92, 1.08, 0.92))
	_sphere(model, "Hair", 0.158, hair_color, Vector3(0.0, 1.88, 0.015), Vector3(1.0, 0.48, 1.0))
	_sphere(model, "EarL", 0.045, skin_color, Vector3(-0.15, 1.77, 0.0))
	_sphere(model, "EarR", 0.045, skin_color, Vector3(0.15, 1.77, 0.0))

	for side in [-1.0, 1.0]:
		var eye := _sphere(model, "Eye", 0.018, Color("#282522"), Vector3(side * 0.052, 1.79, -0.137))
		eye.scale = Vector3(1.0, 1.0, 0.55)

	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.27, 1.34, 0.0)
	model.add_child(left_arm)
	_capsule(left_arm, "Sleeve", 0.095, 0.62, shirt_color.darkened(0.06), Vector3(0.0, -0.29, 0.0))
	_sphere(left_arm, "Hand", 0.075, skin_color, Vector3(0.0, -0.63, -0.015))
	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.27, 1.34, 0.0)
	model.add_child(right_arm)
	_capsule(right_arm, "Sleeve", 0.095, 0.62, shirt_color.darkened(0.06), Vector3(0.0, -0.29, 0.0))
	_sphere(right_arm, "Hand", 0.075, skin_color, Vector3(0.0, -0.63, -0.015))

	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.115, 0.62, 0.0)
	model.add_child(left_leg)
	_capsule(left_leg, "TrouserLeg", 0.105, 0.67, pants_color, Vector3(0.0, -0.29, 0.0))
	var left_shoe := _shoe(left_leg, "Shoe", Color("#24272a"))
	left_shoe.position = Vector3(0.0, -0.61, -0.055)

	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.115, 0.62, 0.0)
	model.add_child(right_leg)
	_capsule(right_leg, "TrouserLeg", 0.105, 0.67, pants_color, Vector3(0.0, -0.29, 0.0))
	var right_shoe := _shoe(right_leg, "Shoe", Color("#24272a"))
	right_shoe.position = Vector3(0.0, -0.61, -0.055)

	if rng.randf() < 0.22:
		var bag := MeshInstance3D.new()
		var bag_mesh := BoxMesh.new()
		bag_mesh.size = Vector3(0.34, 0.42, 0.16)
		bag.mesh = bag_mesh
		bag.position = Vector3(0.0, 1.0, 0.22)
		bag.material_override = _mat(Color("#454b50"))
		model.add_child(bag)

func _shoe(parent: Node3D, node_name: String, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.17, 0.12, 0.31)
	instance.mesh = mesh
	instance.material_override = _mat(color, 0.75)
	parent.add_child(instance)
	return instance

func _physics_process(delta: float) -> void:
	if waypoints.is_empty():
		return
	if waypoint_index >= waypoints.size():
		waypoint_index = 0
	var target := waypoints[waypoint_index]
	var direction := target - global_position
	direction.y = 0.0
	if direction.length() < 0.75:
		waypoint_index = (waypoint_index + 1) % waypoints.size()
		return
	direction = direction.normalized()
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	velocity.y = 0.0
	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 4.0))
	walk_phase += delta * 8.0
	if rigged_animation != null:
		if rigged_animation.has_animation("Walking_A") and rigged_animation.current_animation != "Walking_A":
			rigged_animation.play("Walking_A", 0.16)
	elif left_arm != null:
		left_arm.rotation.x = sin(walk_phase) * 0.42
		right_arm.rotation.x = -sin(walk_phase) * 0.42
		left_leg.rotation.x = -sin(walk_phase) * 0.48
		right_leg.rotation.x = sin(walk_phase) * 0.48
		torso.position.y = 1.08 + absf(sin(walk_phase * 2.0)) * 0.025
	move_and_slide()
