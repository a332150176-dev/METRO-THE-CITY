extends Node3D
class_name TrafficController

const CYCLE_SECONDS: float = 24.0
const GREEN_SECONDS: float = 9.0
const YELLOW_SECONDS: float = 2.0
const ALL_RED_SECONDS: float = 1.0

var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, CYCLE_SECONDS)

func phase() -> float:
	return elapsed

func is_green_for_direction(direction: Vector3) -> bool:
	return state_for_direction(direction) == "green"

func state_for_direction(direction: Vector3) -> String:
	var horizontal_road := absf(direction.x) > absf(direction.z)
	if horizontal_road:
		var horizontal_start := GREEN_SECONDS + YELLOW_SECONDS + ALL_RED_SECONDS
		if elapsed >= horizontal_start and elapsed < horizontal_start + GREEN_SECONDS:
			return "green"
		if elapsed >= horizontal_start + GREEN_SECONDS and elapsed < horizontal_start + GREEN_SECONDS + YELLOW_SECONDS:
			return "yellow"
		return "red"
	else:
		if elapsed < GREEN_SECONDS:
			return "green"
		if elapsed < GREEN_SECONDS + YELLOW_SECONDS:
			return "yellow"
		return "red"
