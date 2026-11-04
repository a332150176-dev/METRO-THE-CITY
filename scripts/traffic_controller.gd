extends Node3D
class_name TrafficController

const CYCLE_SECONDS: float = 24.0
var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, CYCLE_SECONDS)

func phase() -> float:
	return elapsed

func is_green_for_direction(direction: Vector3) -> bool:
	var horizontal_road := absf(direction.x) > absf(direction.z)
	if elapsed < 10.0:
		return not horizontal_road
	if elapsed >= 12.0 and elapsed < 22.0:
		return horizontal_road
	return false

func state_for_direction(direction: Vector3) -> String:
	var horizontal_road := absf(direction.x) > absf(direction.z)
	if (not horizontal_road and elapsed < 10.0) or (horizontal_road and elapsed >= 12.0 and elapsed < 22.0):
		return "green"
	if (not horizontal_road and elapsed >= 10.0 and elapsed < 12.0) or (horizontal_road and elapsed >= 22.0):
		return "red"
	return "red"
