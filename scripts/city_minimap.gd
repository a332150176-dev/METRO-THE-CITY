extends Control
class_name CityMiniMap

var player: PlayerController
var missions: MissionManager
var refresh_clock: float = 0.0
var map_radius: float = 86.0

func set_sources(player_node: PlayerController, mission_node: MissionManager) -> void:
	player = player_node
	missions = mission_node
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(168.0, 168.0)
	queue_redraw()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock >= 0.12:
		refresh_clock = 0.0
		queue_redraw()

func _world_to_map(position: Vector3) -> Vector2:
	var center := size * 0.5
	var scale := minf(size.x, size.y) / (map_radius * 2.0)
	return center + Vector2(position.x, position.z) * scale

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("#0a1724"), true)
	draw_rect(bounds, Color("#91a4b8"), false, 2.0)

	var center := size * 0.5
	var scale := minf(size.x, size.y) / (map_radius * 2.0)

	for block_x in [-38.0, 38.0]:
		for block_z in [-38.0, 38.0]:
			var block_center := center + Vector2(block_x, block_z) * scale
			var block_rect := Rect2(block_center - Vector2(15.0, 15.0) * scale, Vector2(30.0, 30.0) * scale)
			draw_rect(block_rect, Color("#1c3440"), true)

	for road in [-76.0, 0.0, 76.0]:
		var x := center.x + road * scale
		var z := center.y + road * scale
		draw_line(Vector2(x, 4.0), Vector2(x, size.y - 4.0), Color("#6c7d87"), 8.0, true)
		draw_line(Vector2(4.0, z), Vector2(size.x - 4.0, z), Color("#6c7d87"), 8.0, true)
		draw_line(Vector2(x, 4.0), Vector2(x, size.y - 4.0), Color("#c0c5c3"), 0.8, true)
		draw_line(Vector2(4.0, z), Vector2(size.x - 4.0, z), Color("#c0c5c3"), 0.8, true)

	if missions != null and missions.current_index < missions.missions.size():
		var mission: Dictionary = missions.missions[missions.current_index]
		var target: Vector3 = mission["target"]
		var target_point := _world_to_map(target)
		draw_circle(target_point, 7.0, Color("#14d6c0"))
		draw_arc(target_point, 10.0, 0.0, TAU, 24, Color("#a2fff2"), 1.5, true)

	if player != null and is_instance_valid(player):
		var tracked_position := player.global_position
		var heading := player.global_rotation.y
		if missions != null and missions.vehicle != null and is_instance_valid(missions.vehicle) and missions.vehicle.player_driving:
			tracked_position = missions.vehicle.global_position
			heading = missions.vehicle.global_rotation.y
		var point := _world_to_map(tracked_position)
		var forward := Vector2(-sin(heading), -cos(heading))
		var tip := point + forward * 8.0
		var left := point - forward * 5.0 + Vector2(-forward.y, forward.x) * 4.5
		var right := point - forward * 5.0 - Vector2(-forward.y, forward.x) * 4.5
		draw_colored_polygon(PackedVector2Array([tip, left, right]), Color("#ffb44f"))
		draw_circle(point, 3.0, Color("#ffffff"))
