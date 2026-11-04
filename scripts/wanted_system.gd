extends Node
class_name WantedSystem

signal wanted_level_changed(level: int)
signal status_changed(message: String)

var player: Node3D
var traffic: TrafficManager
var wanted_level: int = 0
var decay_clock: float = 0.0
var decay_delay: float = 35.0
var safe_distance: float = 72.0

func configure(player_node: Node3D, traffic_manager: TrafficManager) -> void:
	player = player_node
	traffic = traffic_manager
	wanted_level = 0
	decay_clock = 0.0
	wanted_level_changed.emit(wanted_level)

func report_vehicle_theft() -> void:
	if wanted_level >= 5:
		return
	wanted_level = mini(5, wanted_level + 1)
	decay_clock = 0.0
	if traffic != null:
		traffic.set_wanted_level(wanted_level, player)
	wanted_level_changed.emit(wanted_level)
	status_changed.emit("המשטרה קיבלה דיווח על גניבת רכב. רמת מבוקשות: %d/5" % wanted_level)

func _process(delta: float) -> void:
	if wanted_level <= 0 or player == null or not is_instance_valid(player) or traffic == null:
		return
	var police_distance := traffic.closest_police_distance(player)
	if police_distance > safe_distance:
		decay_clock += delta
	else:
		decay_clock = 0.0
	if decay_clock >= decay_delay:
		decay_clock = 0.0
		wanted_level = maxi(0, wanted_level - 1)
		traffic.set_wanted_level(wanted_level, player)
		wanted_level_changed.emit(wanted_level)
		if wanted_level == 0:
			status_changed.emit("הצלחת להתחמק מהמשטרה.")
		else:
			status_changed.emit("רמת המבוקשות ירדה ל־%d/5." % wanted_level)
