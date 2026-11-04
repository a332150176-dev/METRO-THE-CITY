extends CharacterBody3D
class_name CityPedestrian

var waypoints: PackedVector3Array = PackedVector3Array()
var waypoint_index: int = 0
var walk_speed: float = 1.35
var walk_phase: float = 0.0
var shirt_color: Color = Color("#526d85")

func setup(points: PackedVector3Array, color: Color) -> void:
	waypoints = points
	shirt_color = color
	if waypoints.size() > 0:
		position = waypoints[0]
		waypoint_index = 1 if waypoints.size() > 1 else 0
	_build_person()

func _ready() -> void:
	if get_child_count() == 0:
		_build_person()

func _build_person() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.55
	collider.shape = capsule
	collider.position.y = 0.78
	add_child(collider)

	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.23
	body_mesh.height = 0.9
	body.mesh = body_mesh
	body.position.y = 0.82
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = shirt_color
	body.material_override = body_material
	add_child(body)

	var legs := MeshInstance3D.new()
	var legs_mesh := BoxMesh.new()
	legs_mesh.size = Vector3(0.34, 0.66, 0.22)
	legs.mesh = legs_mesh
	legs.position.y = 0.32
	var legs_material := StandardMaterial3D.new()
	legs_material.albedo_color = Color("#30343b")
	legs.material_override = legs_material
	add_child(legs)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.15
	head_mesh.height = 0.3
	head.mesh = head_mesh
	head.position.y = 1.48
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("#d4a17f")
	head.material_override = skin
	add_child(head)

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
	move_and_slide()
