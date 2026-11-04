extends Node3D
class_name CityBuilder

const LIGHT_VISUAL := preload("res://scripts/traffic_light_visual.gd")
const GRID_SIZE: int = 5
const GRID_SPACING: float = 76.0
const ROAD_WIDTH: float = 18.0
const CITY_EDGE: float = 420.0

var rng := RandomNumberGenerator.new()
var traffic_controller: TrafficController
var window_frame_transforms: Array[Transform3D] = []
var window_glass_transforms: Array[Transform3D] = []
var road_mark_x_transforms: Array[Transform3D] = []
var road_mark_z_transforms: Array[Transform3D] = []
var crosswalk_x_transforms: Array[Transform3D] = []
var crosswalk_z_transforms: Array[Transform3D] = []

func build_city(controller: TrafficController) -> void:
	traffic_controller = controller
	rng.seed = 20261104
	_build_ground()
	_build_roads()
	_build_blocks()
	_build_intersections()
	_build_batched_details()

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

func _visual_box(parent: Node3D, size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _build_ground() -> void:
	_box(self, Vector3(460.0, 1.0, 460.0), Vector3(0.0, -0.5, 0.0), Color("#777d78"), true)
	_box(self, Vector3(430.0, 0.05, 430.0), Vector3(0.0, 0.02, 0.0), Color("#777e7b"))

func _build_roads() -> void:
	for grid in range(GRID_SIZE):
		var coordinate := (grid - 2) * GRID_SPACING
		_box(self, Vector3(CITY_EDGE, 0.13, ROAD_WIDTH), Vector3(0.0, -0.01, coordinate), Color("#30343a"))
		_box(self, Vector3(ROAD_WIDTH, 0.13, CITY_EDGE), Vector3(coordinate, -0.005, 0.0), Color("#292e34"))
		_box(self, Vector3(CITY_EDGE, 0.12, 3.5), Vector3(0.0, 0.0, coordinate - 10.9), Color("#8e9692"))
		_box(self, Vector3(CITY_EDGE, 0.12, 3.5), Vector3(0.0, 0.0, coordinate + 10.9), Color("#aaa99d"))
		_box(self, Vector3(3.5, 0.12, CITY_EDGE), Vector3(coordinate - 10.9, 0.0, 0.0), Color("#aaa99d"))
		_box(self, Vector3(3.5, 0.12, CITY_EDGE), Vector3(coordinate + 10.9, 0.0, 0.0), Color("#aaa99d"))

		for mark in range(35):
			var along := -204.0 + mark * 12.0
			road_mark_x_transforms.append(Transform3D(Basis(), Vector3(along, 0.075, coordinate)))
			road_mark_z_transforms.append(Transform3D(Basis(), Vector3(coordinate, 0.075, along)))

func _build_blocks() -> void:
	var residential_colors: Array[Color] = [
		Color("#b5a48e"), Color("#bdb5a6"), Color("#929f9f"),
		Color("#c2b49f"), Color("#9daaa7"), Color("#a89582")
	]
	var downtown_colors: Array[Color] = [
		Color("#87999e"), Color("#9eafb0"), Color("#839198"),
		Color("#b8ad9e"), Color("#91a4aa")
	]
	var mixed_colors: Array[Color] = [
		Color("#b4a18a"), Color("#aab3ac"), Color("#949f9b"),
		Color("#c1b29e"), Color("#91a3a4")
	]

	for block_x in range(GRID_SIZE - 1):
		for block_z in range(GRID_SIZE - 1):
			var center_x := (float(block_x) - 1.5) * GRID_SPACING
			var center_z := (float(block_z) - 1.5) * GRID_SPACING
			var downtown := block_x >= 1 and block_x <= 2 and block_z >= 1 and block_z <= 2
			var mixed := not downtown and (block_x == 1 or block_x == 2 or block_z == 1 or block_z == 2)
			var palette: Array[Color] = downtown_colors if downtown else (mixed_colors if mixed else residential_colors)

			for offset_x in [-14.0, 14.0]:
				for offset_z in [-14.0, 14.0]:
					var width := rng.randf_range(12.0, 18.0)
					var depth := rng.randf_range(12.0, 18.0)
					var height := rng.randf_range(13.0, 26.0)
					if mixed:
						height = rng.randf_range(20.0, 38.0)
					if downtown:
						height = rng.randf_range(34.0, 56.0)
					var position := Vector3(center_x + offset_x, height * 0.5 - 0.05, center_z + offset_z)
					var color: Color = palette[rng.randi_range(0, palette.size() - 1)]
					var is_minimarket_lot := block_x == 1 and block_z == 1 and is_equal_approx(float(offset_x), -14.0) and is_equal_approx(float(offset_z), -14.0)
					if not is_minimarket_lot:
						_add_building(Vector3(width, height, depth), position, color, downtown)

			_add_tree(Vector3(center_x - 25.0, 0.0, center_z))
			_add_tree(Vector3(center_x + 25.0, 0.0, center_z))
			_add_bench(Vector3(center_x, 0.0, center_z - 25.0))

func _add_building(size: Vector3, position: Vector3, color: Color, downtown: bool) -> void:
	var building := _box(self, size, position, color, true)
	var floors := maxi(2, int(size.y / 4.0))
	var horizontal_material := color.darkened(0.16)
	_visual_box(building, Vector3(size.x * 0.92, 0.24, size.z * 0.92), Vector3(0.0, size.y * 0.5 + 0.12, 0.0), horizontal_material)
	_visual_box(building, Vector3(size.x * 0.88, 0.18, 0.22), Vector3(0.0, -size.y * 0.5 + 3.8, -size.z * 0.5 - 0.07), horizontal_material)

	for side in range(4):
		var horizontal_length := size.x if side < 2 else size.z
		var window_count := clampi(int(horizontal_length / 4.6), 2, 4)
		var pitch := horizontal_length / float(window_count + 1)
		for floor_index in range(floors):
			var window_y := -size.y * 0.5 + 2.55 + floor_index * 3.75
			for window_index in range(window_count):
				var offset := -horizontal_length * 0.5 + pitch * float(window_index + 1)
				var frame_position := position
				var glass_position := position
				var rotation := 0.0
				if side == 0:
					frame_position += Vector3(offset, window_y, -size.z * 0.5 - 0.07)
					glass_position = frame_position + Vector3(0.0, 0.0, -0.08)
				elif side == 1:
					frame_position += Vector3(offset, window_y, size.z * 0.5 + 0.07)
					glass_position = frame_position + Vector3(0.0, 0.0, 0.08)
				elif side == 2:
					frame_position += Vector3(-size.x * 0.5 - 0.07, window_y, offset)
					glass_position = frame_position + Vector3(-0.08, 0.0, 0.0)
					rotation = PI * 0.5
				else:
					frame_position += Vector3(size.x * 0.5 + 0.07, window_y, offset)
					glass_position = frame_position + Vector3(0.08, 0.0, 0.0)
					rotation = PI * 0.5
				window_frame_transforms.append(Transform3D(Basis(Vector3.UP, rotation), frame_position))
				window_glass_transforms.append(Transform3D(Basis(Vector3.UP, rotation), glass_position))

				if side == 0 and floor_index > 0 and floor_index % 2 == 0 and window_index == 0:
					var balcony_y := window_y - 0.92
					_visual_box(building, Vector3(2.0, 0.12, 0.72), Vector3(offset, balcony_y, -size.z * 0.5 - 0.42), Color("#636c6d"))
					_visual_box(building, Vector3(2.0, 0.08, 0.08), Vector3(offset, balcony_y + 0.48, -size.z * 0.5 - 0.75), Color("#596367"))

	var door_y := -size.y * 0.5 + 1.2
	_visual_box(building, Vector3(1.35, 2.25, 0.14), Vector3(-size.x * 0.16, door_y, -size.z * 0.5 - 0.12), Color("#35434a"))
	_visual_box(building, Vector3(size.x * 0.72, 0.42, 0.26), Vector3(0.0, -size.y * 0.5 + 2.55, -size.z * 0.5 - 0.14), Color("#65777b"))

	# Ground-floor shopfronts add scale and recognizable street-level detail.
	var shop_y := -size.y * 0.5 + 1.78
	for shop_side in [-1.0, 1.0]:
		var shop_x: float = shop_side * size.x * 0.25
		_visual_box(building, Vector3(size.x * 0.30, 1.82, 0.13), Vector3(shop_x, shop_y, -size.z * 0.5 - 0.10), Color("#29424d"))
		_visual_box(building, Vector3(size.x * 0.27, 1.58, 0.035), Vector3(shop_x, shop_y, -size.z * 0.5 - 0.19), Color("#426777"))
		_visual_box(building, Vector3(size.x * 0.32, 0.12, 0.26), Vector3(shop_x, shop_y + 1.02, -size.z * 0.5 - 0.23), Color("#4d5960"))
	_visual_box(building, Vector3(size.x * 0.82, 0.48, 0.24), Vector3(0.0, -size.y * 0.5 + 3.15, -size.z * 0.5 - 0.16), Color("#475c62"))
	_visual_box(building, Vector3(size.x * 0.86, 0.10, 0.34), Vector3(0.0, -size.y * 0.5 + 2.87, -size.z * 0.5 - 0.18), Color("#b28c56"))

	if rng.randf() > 0.45:
		var rooftop_size := Vector3(rng.randf_range(2.0, 3.2), rng.randf_range(1.2, 2.0), rng.randf_range(2.0, 3.2))
		_visual_box(building, rooftop_size, Vector3(size.x * 0.22, size.y * 0.5 + rooftop_size.y * 0.5, size.z * 0.18), color.darkened(0.22))
	if downtown and rng.randf() > 0.5:
		_visual_box(building, Vector3(size.x * 0.52, 0.3, 0.28), Vector3(0.0, size.y * 0.5 - 1.0, -size.z * 0.5 - 0.16), Color("#344c57"))

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
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			var center := Vector3((x - 2) * GRID_SPACING, 0.0, (z - 2) * GRID_SPACING)
			for stripe in range(6):
				var offset := -6.0 + stripe * 2.4
				crosswalk_z_transforms.append(Transform3D(Basis(), center + Vector3(offset, 0.09, -12.2)))
				crosswalk_z_transforms.append(Transform3D(Basis(), center + Vector3(offset, 0.09, 12.2)))
				crosswalk_x_transforms.append(Transform3D(Basis(), center + Vector3(-12.2, 0.09, offset)))
				crosswalk_x_transforms.append(Transform3D(Basis(), center + Vector3(12.2, 0.09, offset)))
			_add_traffic_pole(center + Vector3(-10.0, 0.0, -10.0), true)
			_add_traffic_pole(center + Vector3(10.0, 0.0, 10.0), false)

func _add_traffic_pole(position: Vector3, horizontal: bool) -> void:
	_box(self, Vector3(0.16, 4.2, 0.16), position + Vector3(0.0, 2.1, 0.0), Color("#333b42"))
	var lamp := LIGHT_VISUAL.new()
	add_child(lamp)
	lamp.position = position + Vector3(0.0, 3.35, 0.0)
	lamp.setup(traffic_controller, horizontal)

func _build_batched_details() -> void:
	_add_multimesh_batch(Vector3(5.5, 0.025, 0.18), road_mark_x_transforms, Color("#d9d8c7"))
	_add_multimesh_batch(Vector3(0.18, 0.025, 5.5), road_mark_z_transforms, Color("#d9d8c7"))
	_add_multimesh_batch(Vector3(0.95, 0.035, 11.0), crosswalk_z_transforms, Color("#e6e4d8"))
	_add_multimesh_batch(Vector3(11.0, 0.035, 0.95), crosswalk_x_transforms, Color("#e6e4d8"))
	_add_multimesh_batch(Vector3(1.55, 1.62, 0.12), window_frame_transforms, Color("#414b50"), 0.7)
	_add_multimesh_batch(Vector3(1.24, 1.32, 0.1), window_glass_transforms, Color("#557785"), 0.28)

func _add_multimesh_batch(mesh_size: Vector3, transforms: Array[Transform3D], color: Color, roughness: float = 0.88) -> void:
	if transforms.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = mesh_size
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for index in range(transforms.size()):
		multi.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multi
	instance.material_override = _material(color, roughness)
	add_child(instance)
