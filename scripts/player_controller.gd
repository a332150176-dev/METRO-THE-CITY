extends CharacterBody3D
class_name PlayerController

signal interaction_requested

const GRAVITY: float = 22.0
const ACCELERATION: float = 22.0
const DECELERATION: float = 26.0

var joystick: TouchJoystick
var sprinting: bool = false
var jump_requested: bool = false
var character_id: String = "noam"
var camera: Camera3D
var camera_pivot: Node3D
var visual_root: Node3D
var look_touch_index: int = -1
var mouse_look_active: bool = false
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var walk_phase: float = 0.0
var humanoid_factory: HumanoidFactory
var character_animation_player: AnimationPlayer

func _ready() -> void:
	_build_body()
	_build_camera()

func configure(id: String, factory: HumanoidFactory = null) -> void:
	character_id = id
	humanoid_factory = factory
	if is_inside_tree():
		if not _install_rigged_model():
			_apply_character_appearance()

func _install_rigged_model() -> bool:
	if humanoid_factory == null or not humanoid_factory.assets_ready():
		return false
	var authored_model := humanoid_factory.create_character(character_id)
	if authored_model == null:
		return false
	if visual_root != null and is_instance_valid(visual_root):
		remove_child(visual_root)
		visual_root.queue_free()
	visual_root = authored_model
	visual_root.name = "CharacterVisual"
	add_child(visual_root)
	left_arm = null
	right_arm = null
	left_leg = null
	right_leg = null
	character_animation_player = visual_root.find_child("CharacterAnimationPlayer", true, false) as AnimationPlayer
	if character_animation_player != null and character_animation_player.has_animation("Idle_A"):
		character_animation_player.play("Idle_A")
	return character_animation_player != null

func set_joystick_source(source: TouchJoystick) -> void:
	joystick = source

func set_sprinting(enabled: bool) -> void:
	sprinting = enabled

func request_jump() -> void:
	jump_requested = true

func request_interaction() -> void:
	interaction_requested.emit()

func _new_material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _make_capsule(parent: Node3D, node_name: String, radius: float, height: float, color: Color, offset: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 5
	instance.mesh = mesh
	instance.position = offset
	instance.material_override = _new_material(color)
	parent.add_child(instance)
	return instance

func _make_sphere(parent: Node3D, node_name: String, radius: float, color: Color, offset: Vector3, stretch: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 10
	instance.mesh = mesh
	instance.position = offset
	instance.scale = stretch
	instance.material_override = _new_material(color)
	parent.add_child(instance)
	return instance

func _make_shoe(parent: Node3D, node_name: String, offset: Vector3) -> void:
	var shoe := MeshInstance3D.new()
	shoe.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.19, 0.13, 0.34)
	shoe.mesh = mesh
	shoe.position = offset
	shoe.material_override = _new_material(Color("#25282d"), 0.72)
	parent.add_child(shoe)

func _build_body() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.86
	collider.shape = capsule
	collider.position.y = 0.93
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "CharacterVisual"
	add_child(visual_root)

	_make_capsule(visual_root, "Torso", 0.235, 0.88, Color("#2876a8"), Vector3(0.0, 1.08, 0.0))
	_make_capsule(visual_root, "Pelvis", 0.18, 0.34, Color("#303947"), Vector3(0.0, 0.64, 0.0))
	_make_capsule(visual_root, "Neck", 0.075, 0.17, Color("#d9a27d"), Vector3(0.0, 1.57, 0.0))
	_make_sphere(visual_root, "Head", 0.16, Color("#d9a27d"), Vector3(0.0, 1.78, 0.0), Vector3(0.95, 1.08, 0.95))
	_make_sphere(visual_root, "Hair", 0.163, Color("#29231f"), Vector3(0.0, 1.89, 0.015), Vector3(1.0, 0.48, 1.0))
	_make_sphere(visual_root, "EarLeft", 0.045, Color("#d9a27d"), Vector3(-0.155, 1.77, 0.0))
	_make_sphere(visual_root, "EarRight", 0.045, Color("#d9a27d"), Vector3(0.155, 1.77, 0.0))

	left_arm = Node3D.new()
	left_arm.name = "LeftArm"
	left_arm.position = Vector3(-0.27, 1.34, 0.0)
	visual_root.add_child(left_arm)
	_make_capsule(left_arm, "Sleeve", 0.095, 0.62, Color("#2876a8"), Vector3(0.0, -0.29, 0.0))
	_make_sphere(left_arm, "Hand", 0.075, Color("#d9a27d"), Vector3(0.0, -0.63, -0.015))

	right_arm = Node3D.new()
	right_arm.name = "RightArm"
	right_arm.position = Vector3(0.27, 1.34, 0.0)
	visual_root.add_child(right_arm)
	_make_capsule(right_arm, "Sleeve", 0.095, 0.62, Color("#2876a8"), Vector3(0.0, -0.29, 0.0))
	_make_sphere(right_arm, "Hand", 0.075, Color("#d9a27d"), Vector3(0.0, -0.63, -0.015))

	left_leg = Node3D.new()
	left_leg.name = "LeftLeg"
	left_leg.position = Vector3(-0.115, 0.62, 0.0)
	visual_root.add_child(left_leg)
	_make_capsule(left_leg, "TrouserLeg", 0.105, 0.67, Color("#303947"), Vector3(0.0, -0.29, 0.0))
	_make_shoe(left_leg, "Shoe", Vector3(0.0, -0.61, -0.055))

	right_leg = Node3D.new()
	right_leg.name = "RightLeg"
	right_leg.position = Vector3(0.115, 0.62, 0.0)
	visual_root.add_child(right_leg)
	_make_capsule(right_leg, "TrouserLeg", 0.105, 0.67, Color("#303947"), Vector3(0.0, -0.29, 0.0))
	_make_shoe(right_leg, "Shoe", Vector3(0.0, -0.61, -0.055))
	_apply_character_appearance()

func _apply_character_appearance() -> void:
	if visual_root == null:
		return
	var data := CharacterCatalog.get_character(character_id)
	var shirt: Color = data["shirt"]
	var skin: Color = data["skin"]
	var pants: Color = data["pants"]
	var shirt_material := _new_material(shirt)
	var pants_material := _new_material(pants)
	var skin_material := _new_material(skin)
	for path in ["Torso", "LeftArm/Sleeve", "RightArm/Sleeve"]:
		var part := visual_root.get_node_or_null(path) as MeshInstance3D
		if part != null:
			part.material_override = shirt_material
	for path in ["Pelvis", "LeftLeg/TrouserLeg", "RightLeg/TrouserLeg"]:
		var part := visual_root.get_node_or_null(path) as MeshInstance3D
		if part != null:
			part.material_override = pants_material
	for path in ["Head", "Neck", "EarLeft", "EarRight", "LeftArm/Hand", "RightArm/Hand"]:
		var part := visual_root.get_node_or_null(path) as MeshInstance3D
		if part != null:
			part.material_override = skin_material

func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	camera_pivot.position = Vector3(0.0, 1.55, 0.0)
	camera_pivot.rotation_degrees.x = -13.0
	add_child(camera_pivot)

	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.position = Vector3(0.0, 2.7, 6.8)
	camera.fov = 72.0
	camera.current = true
	camera_pivot.add_child(camera)

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if joystick != null:
		var touch := joystick.value
		if touch.length() > 0.08:
			input_vector = touch

	var camera_forward := -camera.global_transform.basis.z
	var camera_right := camera.global_transform.basis.x
	var direction := (camera_right * input_vector.x + camera_forward * input_vector.y)
	direction.y = 0.0
	direction = direction.normalized()

	var max_speed := 9.2 if sprinting else 5.8
	var target_x := direction.x * max_speed
	var target_z := direction.z * max_speed
	var rate := ACCELERATION if direction.length_squared() > 0.01 else DECELERATION
	velocity.x = move_toward(velocity.x, target_x, rate * delta)
	velocity.z = move_toward(velocity.z, target_z, rate * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1

	if direction.length_squared() > 0.01:
		var target_angle := atan2(-direction.x, -direction.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, minf(1.0, delta * 9.0))
		walk_phase += delta * (12.0 if sprinting else 8.5)
		visual_root.position.y = absf(sin(walk_phase * 2.0)) * (0.035 if sprinting else 0.02)
		if character_animation_player != null:
			var movement_animation := "Running_A" if sprinting else "Walking_A"
			if character_animation_player.has_animation(movement_animation) and character_animation_player.current_animation != movement_animation:
				character_animation_player.play(movement_animation, 0.18)
		elif left_arm != null and is_instance_valid(left_arm):
			var stride := 0.62 if sprinting else 0.42
			left_arm.rotation.x = sin(walk_phase) * stride
			right_arm.rotation.x = -sin(walk_phase) * stride
			left_leg.rotation.x = -sin(walk_phase) * stride
			right_leg.rotation.x = sin(walk_phase) * stride
	else:
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 0.2)
		if character_animation_player != null:
			if character_animation_player.has_animation("Idle_A") and character_animation_player.current_animation != "Idle_A":
				character_animation_player.play("Idle_A", 0.2)
		elif left_arm != null and is_instance_valid(left_arm):
			left_arm.rotation.x = move_toward(left_arm.rotation.x, 0.0, delta * 3.0)
			right_arm.rotation.x = move_toward(right_arm.rotation.x, 0.0, delta * 3.0)
			left_leg.rotation.x = move_toward(left_leg.rotation.x, 0.0, delta * 3.0)
			right_leg.rotation.x = move_toward(right_leg.rotation.x, 0.0, delta * 3.0)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().get_visible_rect().size.x * 0.44 and look_touch_index == -1:
			look_touch_index = event.index
		elif not event.pressed and event.index == look_touch_index:
			look_touch_index = -1
	elif event is InputEventScreenDrag and event.index == look_touch_index:
		_apply_camera_look(event.relative)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_look_active = event.pressed
	elif event is InputEventMouseMotion and mouse_look_active:
		_apply_camera_look(event.relative)

func _apply_camera_look(relative: Vector2) -> void:
	if camera_pivot == null:
		return
	camera_pivot.rotation.y -= relative.x * 0.0045
	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - relative.y * 0.0035,
		deg_to_rad(-37.0),
		deg_to_rad(12.0)
	)
