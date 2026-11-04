extends Node3D
class_name CityBuilder

const LIGHT_VISUAL := preload("res://scripts/traffic_light_visual.gd")
const GRID_SPACING: float = 76.0
const ROAD_WIDTH: float = 18.0
const CITY_EDGE: float = 190.0

var rng := RandomNumberGenerator.new()
var traffic_controller: TrafficController

func build_city(controller: TrafficController) -> void:
	traffic_controller = controller
	rng.seed = 20261104
	_build_ground()
	_build_roads()
	_build_blocks()
	_build_intersections()

func _material(color: Color, roughness: float = 0.88) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	return result

func _box(parent: Node3D, size: Vector3, position: Vector3, color: Color, solid: bool = false) -> Node3D:
	var holder: Node3D
	if solid:
		var body := StaticBody3D.new()
		parent.add_child(body)
		body.position = position
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		holder = body
	else:
		var visual := Node3D.new()
		parent.add_child(visual)
		visual.position = position
		holder = visual

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	holder.add_child(mesh_instance)
	return holder

func _build_ground() -> void:
	_box(self, Vector3(260.0, 1.0, 260.0), Vector3(0.0, -0.62, 0.0), Color("#777d78"), true)
	_box(self, Vector3(220.0, 0.05, 220.0), Vector3(0.0, -0.08, 0.0), Color("#8b8b7b"))

func _build_roads() -> void:
	for grid in range(3):
		var coordinate := (grid - 1) * GRID_SPACING
		_box(self, Vector3(CITY_EDGE, 0.13, ROAD_WIDTH), Vector3(0.0, -0.01, coordinate), Color("#292e34"))
		_box(self, Vector3(ROAD_WIDTH, 0.13, CITY_EDGE), Vector3(coordinate, -0.005, 0.0), Color("#292e34"))
		_box(self, Vector3(CITY_EDGE, 0.12, 3.5), Vector3(0.0, 0.0, coordinate - 10.9), Color("#aaa99d"))
		_box(self, Vector3(CITY_EDGE, 0.12, 3.5), Vector3(0.0, 0.0, coordinate + 10.9), Color("#aaa99d"))
		_box(self, Vector3(3.5, 0.12, CITY_EDGE), Vector3(coordinate - 10.9, 0.0, 0.0), Color("#aaa99d"))
		_box(self, Vector3(3.5, 0.12, CITY_EDGE), Vector3(coordinate + 10.9, 0.0, 0.0), Color("#aaa99d"))

		for mark in range(15):
			var along := -88.0 + mark * 12.0
			_box(self, Vector3(5.5, 0.025, 0.18), Vector3(along, 0.075, coordinate), Color("#d9d8c7"))
			_box(self, Vector3(0.18, 0.025, 5.5), Vector3(coordinate, 0.075, along), Color("#d9d8c7"))

func _build_blocks() -> void:
	var building_colors: Array[Color] = [
		Color("#b7a991"), Color("#c9c1af"), Color("#9fa9a9"),
		Color("#d1c5b3"), Color("#aeb8b5"), Color("#b4a28f")
	]
	for block_x in range(2):
		for block_z in range(2):
			var center_x := -38.0 + block_x * GRID_SPACING
			var center_z := -38.0 + block_z * GRID_SPACING
			for offset_x in [-14.0, 14.0]:
				for offset_z in [-14.0, 14.0]:
					var width := rng.randf_range(12.0, 18.0)
					var depth := rng.randf_range(12.0, 18.0)
					var height := rng.randf_range(13.0, 34.0)
					if rng.randf() > 0.76:
						height += rng.randf_range(12.0, 20.0)
					var position := Vector3(center_x + offset_x, height * 0.5 - 0.05, center_z + offset_z)
					var color: Color = building_colors[rng.randi_range(0, building_colors.size() - 1)]
					_add_building(Vector3(width, height, depth), position, color)
			_add_tree(Vector3(center_x - 25.0, 0.0, center_z))
			_add_tree(Vector3(center_x + 25.0, 0.0, center_z))
			_add_bench(Vector3(center_x, 0.0, center_z - 25.0))

func _add_building(size: Vector3, position: Vector3, color: Color) -> void:
	var building := _box(self, size, position, color, true)
	var floors := maxi(2, int(size.y / 4.2))
	var window_material := _material(Color("#526b78"), 0.3)
	for floor_index in range(floors):
		var y := -size.y * 0.5 + 2.2 + floor_index * 3.8
		for window_index in range(3):
			var x := -size.x * 0.5 + 2.3 + window_index * maxf(3.0, size.x * 0.31)
			var window := MeshInstance3D.new()
			var pane := BoxMesh.new()
			pane.size = Vector3(1.0, 1.35, 0.08)
			window.mesh = pane
			window.material_override = window_material
			window.position = Vector3(x, y, -size.z * 0.5 - 0.045)
			building.add_child(window)
	_box(self, Vector3(size.x * 0.35, 0.35, size.z * 0.35), position + Vector3(0.0, size.y * 0.5 + 0.18, 0.0), color.darkened(0.16))

func _add_tree(position: Vector3) -> void:
	var trunk := _box(self, Vector3(0.42, 2.4, 0.42), position + Vector3(0.0, 1.2, 0.0), Color("#71543b"))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.45
	sphere.height = 2.9
	crown.mesh = sphere
	crown.position = Vector3(0.0, 2.7, 0.0)
	crown.material_override = _material(Color("#47765a"))
	trunk.add_child(crown)

func _add_bench(position: Vector3) -> void:
	_box(self, Vector3(2.4, 0.18, 0.65), position + Vector3(0.0, 0.72, 0.0), Color("#805c3e"))
	for x in [-0.85, 0.85]:
		_box(self, Vector3(0.15, 0.7, 0.55), position + Vector3(x, 0.35, 0.0), Color("#4b5052"))

func _build_intersections() -> void:
	for x in range(3):
		for z in range(3):
			var center := Vector3((x - 1) * GRID_SPACING, 0.0, (z - 1) * GRID_SPACING)
			for stripe in range(6):
				var offset := -6.0 + stripe * 2.4
				_box(self, Vector3(0.95, 0.035, 11.0), center + Vector3(offset, 0.09, -12.2), Color("#e6e4d8"))
				_box(self, Vector3(0.95, 0.035, 11.0), center + Vector3(offset, 0.09, 12.2), Color("#e6e4d8"))
				_box(self, Vector3(11.0, 0.035, 0.95), center + Vector3(-12.2, 0.09, offset), Color("#e6e4d8"))
				_box(self, Vector3(11.0, 0.035, 0.95), center + Vector3(12.2, 0.09, offset), Color("#e6e4d8"))
			_add_traffic_pole(center + Vector3(-10.0, 0.0, -10.0), true)
			_add_traffic_pole(center + Vector3(10.0, 0.0, 10.0), false)

func _add_traffic_pole(position: Vector3, horizontal: bool) -> void:
	_box(self, Vector3(0.16, 4.2, 0.16), position + Vector3(0.0, 2.1, 0.0), Color("#333b42"))
	var lamp := LIGHT_VISUAL.new()
	add_child(lamp)
	lamp.position = position + Vector3(0.0, 3.35, 0.0)
	lamp.setup(traffic_controller, horizontal)
