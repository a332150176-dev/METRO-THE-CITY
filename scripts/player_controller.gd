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

func _ready() -> void:
	_build_body()
	_build_camera()

func configure(id: String) -> void:
	character_id = id
	if is_inside_tree():
		_apply_character_appearance()

func set_joystick_source(source: TouchJoystick) -> void:
	joystick = source

func set_sprinting(enabled: bool) -> void:
	sprinting = enabled

func request_jump() -> void:
	jump_requested = true

func request_interaction() -> void:
	interaction_requested.emit()

func _build_body() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	collider.shape = capsule
	collider.position.y = 0.93
	add_child(collider)

	visual_root = Node3D.new()
	visual_root.name = "CharacterVisual"
	add_child(visual_root)

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.39
	torso_mesh.height = 1.18
	torso.mesh = torso_mesh
	torso.position.y = 1.0
	visual_root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.23
	head_mesh.height = 0.46
	head.mesh = head_mesh
	head.position.y = 1.78
	var skin_material := StandardMaterial3D.new()
	skin_material.albedo_color = Color("#d6a07c")
	head.material_override = skin_material
	visual_root.add_child(head)

	var legs := MeshInstance3D.new()
	var legs_mesh := BoxMesh.new()
	legs_mesh.size = Vector3(0.54, 0.56, 0.32)
	legs.mesh = legs_mesh
	legs.position.y = 0.34
	var pants_material := StandardMaterial3D.new()
	pants_material.albedo_color = Color("#303947")
	legs.material_override = pants_material
	visual_root.add_child(legs)
	_apply_character_appearance()

func _apply_character_appearance() -> void:
	if visual_root == null:
		return
	var data := CharacterCatalog.get_character(character_id)
	var torso := visual_root.get_node_or_null("Torso") as MeshInstance3D
	if torso == null:
		torso = visual_root.get_child(0) as MeshInstance3D
	var head := visual_root.get_child(1) as MeshInstance3D
	var legs := visual_root.get_child(2) as MeshInstance3D
	var shirt_material := StandardMaterial3D.new()
	shirt_material.albedo_color = data["shirt"]
	torso.material_override = shirt_material
	var skin_material := StandardMaterial3D.new()
	skin_material.albedo_color = data["skin"]
	head.material_override = skin_material
	var pants_material := StandardMaterial3D.new()
	pants_material.albedo_color = data["pants"]
	legs.material_override = pants_material

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

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport_rect().size.x * 0.44 and look_touch_index == -1:
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
