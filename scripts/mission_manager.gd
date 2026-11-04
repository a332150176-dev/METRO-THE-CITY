extends Node3D
class_name MissionManager

signal mission_updated(title: String, description: String, reward: int, index: int)
signal mission_completed(reward: int)

var player: PlayerController
var current_index: int = 0
var marker: MeshInstance3D
var missions: Array[Dictionary] = [
	{"title": "המשימה הראשונה", "description": "הגיע לנקודת המפגש במרכז העיר", "target": Vector3(0.0, 0.0, 0.0), "reward": 120},
	{"title": "שליחות בעיר", "description": "המשך לנקודת האיסוף בשכונה המזרחית", "target": Vector3(76.0, 0.0, 76.0), "reward": 180},
	{"title": "סיור בשדרה", "description": "הגע לצומת הדרומי", "target": Vector3(-76.0, 0.0, 76.0), "reward": 240},
	{"title": "העיר מתעוררת", "description": "סיים את המסלול בצפון העיר", "target": Vector3(76.0, 0.0, -76.0), "reward": 320}
]

func setup(player_node: PlayerController, starting_index: int = 0) -> void:
	player = player_node
	current_index = clampi(starting_index, 0, missions.size())
	_build_marker()
	_publish_current()

func _build_marker() -> void:
	marker = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.8
	cylinder.bottom_radius = 1.8
	cylinder.height = 0.16
	marker.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#19c8ba")
	material.emission_enabled = true
	material.emission = Color("#0b756e")
	marker.material_override = material
	add_child(marker)

	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 2.0
	torus.outer_radius = 2.2
	ring.mesh = torus
	ring.position.y = 0.14
	ring.material_override = material
	marker.add_child(ring)

func _publish_current() -> void:
	if current_index >= missions.size():
		mission_updated.emit("הקמפיין הושלם", "כל הכבוד! סיימת את רצף המשימות הראשון.", 0, current_index)
		marker.visible = false
		return
	var mission: Dictionary = missions[current_index]
	marker.visible = true
	marker.global_position = mission["target"] + Vector3(0.0, 0.22, 0.0)
	mission_updated.emit(mission["title"], mission["description"], mission["reward"], current_index)

func _process(_delta: float) -> void:
	if player == null or current_index >= missions.size():
		return
	var target: Vector3 = missions[current_index]["target"]
	if Vector2(player.global_position.x, player.global_position.z).distance_to(Vector2(target.x, target.z)) < 5.5:
		_complete_current()

func _complete_current() -> void:
	var mission: Dictionary = missions[current_index]
	var reward: int = int(mission["reward"])
	GameState.add_reward(reward, 2)
	mission_completed.emit(reward)
	current_index += 1
	GameState.advance_mission()
	_publish_current()
