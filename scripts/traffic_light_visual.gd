extends Node3D
class_name TrafficLightVisual

var controller: TrafficController
var horizontal_road: bool = false
var red_lamp: MeshInstance3D
var yellow_lamp: MeshInstance3D
var green_lamp: MeshInstance3D

func setup(signal_controller: TrafficController, is_horizontal: bool) -> void:
	controller = signal_controller
	horizontal_road = is_horizontal
	_build_lamps()

func _build_lamps() -> void:
	for child in get_children():
		child.queue_free()
	red_lamp = _lamp(Vector3(0.0, 0.0, 0.0), Color("#4a1717"))
	yellow_lamp = _lamp(Vector3(0.0, -0.27, 0.0), Color("#4b3c13"))
	green_lamp = _lamp(Vector3(0.0, -0.54, 0.0), Color("#123f27"))

func _lamp(position: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.11
	sphere.height = 0.22
	mesh_instance.mesh = sphere
	mesh_instance.position = position
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.25
	mesh_instance.material_override = material
	add_child(mesh_instance)
	return mesh_instance

func _process(_delta: float) -> void:
	if controller == null or red_lamp == null:
		return
	var direction := Vector3.RIGHT if horizontal_road else Vector3.FORWARD
	var state := controller.state_for_direction(direction)
	_set_lamp(red_lamp, state == "red", Color("#ff3434"))
	_set_lamp(yellow_lamp, state == "yellow", Color("#ffd34a"))
	_set_lamp(green_lamp, state == "green", Color("#47ef91"))

func _set_lamp(lamp: MeshInstance3D, active: bool, active_color: Color) -> void:
	var material := lamp.material_override as StandardMaterial3D
	if active:
		material.albedo_color = active_color
		material.emission = active_color
	else:
		material.albedo_color = active_color * 0.18
		material.emission = active_color * 0.06
