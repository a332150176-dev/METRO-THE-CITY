extends Node3D
class_name StoreSystem

signal store_state_changed(is_inside: bool)
signal status_changed(message: String)

const SHOP_CENTER := Vector3(-52.0, 0.0, -52.0)
const SHOP_HALF_SIZE := 7.2
const INTERACTION_RANGE := 3.2

var player: PlayerController
var inside_store: bool = false
var selected_product_id: String = ""
var roof: MeshInstance3D
var interior_root: Node3D
var left_door: MeshInstance3D
var right_door: MeshInstance3D
var products: Array[Dictionary] = []
var product_models: Dictionary = {}

var door_outside_position: Vector3:
	get:
		return SHOP_CENTER + Vector3(0.0, 0.15, -8.6)

var door_inside_position: Vector3:
	get:
		return SHOP_CENTER + Vector3(0.0, 0.15, -5.7)

var checkout_position: Vector3:
	get:
		return SHOP_CENTER + Vector3(0.0, 0.15, 5.0)

func _ready() -> void:
	_create_catalog()
	_load_product_models()
	_build_store()

func configure(player_node: PlayerController) -> void:
	player = player_node

func get_door_position() -> Vector3:
	return SHOP_CENTER + Vector3(0.0, 0.15, -7.2)

func get_product_position(product_id: String) -> Vector3:
	for product in products:
		if str(product["id"]) == product_id:
			return product["position"]
	return SHOP_CENTER

func get_checkout_position() -> Vector3:
	return checkout_position

func get_action_label() -> String:
	if player == null or not is_instance_valid(player):
		return ""
	if inside_store:
		if _distance_to(player.global_position, door_inside_position) <= INTERACTION_RANGE:
			return "יציאה מהחנות"
		if _distance_to(player.global_position, checkout_position) <= INTERACTION_RANGE:
			return "תשלום בקופה" if not selected_product_id.is_empty() else "קופה"
		if not _nearest_product().is_empty():
			return "בחירת מוצר"
		return "בתוך החנות"
	if _distance_to(player.global_position, get_door_position()) <= 4.0:
		return "כניסה לחנות"
	return ""

func try_interact() -> bool:
	if player == null or not is_instance_valid(player):
		return false

	if not inside_store:
		if _distance_to(player.global_position, get_door_position()) > 4.0:
			return false
		_enter_store()
		return true

	if _distance_to(player.global_position, door_inside_position) <= INTERACTION_RANGE:
		_exit_store()
		return true

	var nearby_product := _nearest_product()
	if not nearby_product.is_empty():
		selected_product_id = str(nearby_product["id"])
		status_changed.emit("נבחר: %s. גש לקופה כדי לשלם." % str(nearby_product["name"]))
		return true

	if _distance_to(player.global_position, checkout_position) <= INTERACTION_RANGE:
		_purchase_selected_product()
		return true

	status_changed.emit("אפשר לבחור מוצר ליד המדפים, לשלם בקופה או לצאת דרך הדלת.")
	return true

func _create_catalog() -> void:
	products = [
		{"id": "water", "name": "מים מינרליים", "price": 8, "position": SHOP_CENTER + Vector3(-5.1, 0.15, -2.8), "color": Color("#64b8d8"), "model": "soda-bottle"},
		{"id": "soda", "name": "משקה קל", "price": 12, "position": SHOP_CENTER + Vector3(5.1, 0.15, -2.8), "color": Color("#d66a45"), "model": "soda-can"},
		{"id": "snack", "name": "חטיף", "price": 15, "position": SHOP_CENTER + Vector3(-5.1, 0.15, 2.4), "color": Color("#d5b24b"), "model": "candy-bar-wrapper"},
		{"id": "sandwich", "name": "כריך", "price": 25, "position": SHOP_CENTER + Vector3(5.1, 0.15, 2.4), "color": Color("#8baf78"), "model": "sandwich"}
	]

func _build_store() -> void:
	var wall_color := Color("#c7b9a5")
	var floor_color := Color("#a7a39a")
	var trim_color := Color("#354f5b")
	_add_static_box(self, Vector3(14.4, 0.3, 14.4), SHOP_CENTER + Vector3(0.0, 0.0, 0.0), floor_color)

	# Exterior shell. The front wall has a wide, walkable doorway.
	_add_static_box(self, Vector3(14.4, 6.0, 0.4), SHOP_CENTER + Vector3(0.0, 3.15, 7.0), wall_color)
	_add_static_box(self, Vector3(0.4, 6.0, 14.4), SHOP_CENTER + Vector3(-7.0, 3.15, 0.0), wall_color)
	_add_static_box(self, Vector3(0.4, 6.0, 14.4), SHOP_CENTER + Vector3(7.0, 3.15, 0.0), wall_color)
	_add_static_box(self, Vector3(4.9, 6.0, 0.4), SHOP_CENTER + Vector3(-4.75, 3.15, -7.0), wall_color)
	_add_static_box(self, Vector3(4.9, 6.0, 0.4), SHOP_CENTER + Vector3(4.75, 3.15, -7.0), wall_color)
	_add_static_box(self, Vector3(4.2, 0.7, 0.4), SHOP_CENTER + Vector3(0.0, 5.8, -7.0), wall_color)

	roof = _add_visual_box(self, Vector3(14.8, 0.3, 14.8), SHOP_CENTER + Vector3(0.0, 6.25, 0.0), Color("#777d7c"))
	_add_visual_box(self, Vector3(14.8, 0.28, 1.25), SHOP_CENTER + Vector3(0.0, 4.35, -7.55), Color("#287b91"))
	_add_visual_box(self, Vector3(14.8, 0.18, 0.25), SHOP_CENTER + Vector3(0.0, 3.62, -7.7), trim_color)
	_add_visual_box(self, Vector3(5.0, 0.12, 0.35), SHOP_CENTER + Vector3(-4.4, 2.1, -7.38), Color("#496777"))
	_add_visual_box(self, Vector3(5.0, 0.12, 0.35), SHOP_CENTER + Vector3(4.4, 2.1, -7.38), Color("#496777"))

	left_door = _add_visual_box(self, Vector3(1.15, 3.8, 0.12), SHOP_CENTER + Vector3(-0.62, 2.05, -7.15), Color("#6f9ba8"))
	right_door = _add_visual_box(self, Vector3(1.15, 3.8, 0.12), SHOP_CENTER + Vector3(0.62, 2.05, -7.15), Color("#6f9ba8"))
	var glass_material := StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.43, 0.68, 0.76, 0.48)
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.roughness = 0.18
	left_door.material_override = glass_material
	right_door.material_override = glass_material

	var sign := Label3D.new()
	sign.text = "MINI MARKET"
	sign.font_size = 54
	sign.pixel_size = 0.012
	sign.position = SHOP_CENTER + Vector3(0.0, 4.8, -7.78)
	sign.modulate = Color("#fff1cf")
	add_child(sign)

	var hebrew_sign := Label3D.new()
	hebrew_sign.text = "מינימרקט"
	hebrew_sign.font_size = 34
	hebrew_sign.pixel_size = 0.012
	hebrew_sign.position = SHOP_CENTER + Vector3(0.0, 3.95, -7.78)
	hebrew_sign.modulate = Color("#f4f0e8")
	add_child(hebrew_sign)

	_build_interior(trim_color)
	_set_doors_open(false)

func _build_interior(trim_color: Color) -> void:
	interior_root = Node3D.new()
	interior_root.name = "StoreInterior"
	add_child(interior_root)
	interior_root.visible = false
	_add_visual_box(interior_root, Vector3(13.8, 0.06, 13.8), SHOP_CENTER + Vector3(0.0, 0.19, 0.0), Color("#c9c2b4"))
	_add_visual_box(self, Vector3(13.5, 0.12, 0.16), SHOP_CENTER + Vector3(0.0, 0.38, 6.55), trim_color)
	_add_visual_box(self, Vector3(0.16, 0.12, 13.2), SHOP_CENTER + Vector3(-6.55, 0.38, 0.0), trim_color)
	_add_visual_box(self, Vector3(0.16, 0.12, 13.2), SHOP_CENTER + Vector3(6.55, 0.38, 0.0), trim_color)

	_build_rack(interior_root, SHOP_CENTER + Vector3(-5.1, 0.0, -2.0), Color("#8c7657"))
	_build_rack(SHOP_CENTER + Vector3(5.1, 0.0, -2.0), Color("#8c7657"))
	_build_rack(SHOP_CENTER + Vector3(-5.1, 0.0, 3.2), Color("#8c7657"))
	_build_rack(SHOP_CENTER + Vector3(5.1, 0.0, 3.2), Color("#8c7657"))

	# Stock is modeled as small, varied packages rather than empty display shelves.
	for product in products:
		_add_product_stock(product, interior_root)

	_add_static_box(interior_root, Vector3(5.2, 1.05, 1.1), SHOP_CENTER + Vector3(0.0, 0.78, 5.4), Color("#6b5541"))
	_add_visual_box(self, Vector3(1.5, 0.18, 0.72), SHOP_CENTER + Vector3(0.0, 1.42, 5.35), Color("#2a3036"))
	_add_visual_box(self, Vector3(0.48, 0.16, 0.4), SHOP_CENTER + Vector3(-0.55, 1.6, 5.32), Color("#7eb6b5"))
	_add_visual_box(self, Vector3(0.34, 0.38, 0.28), SHOP_CENTER + Vector3(1.1, 1.75, 5.32), Color("#bdc5c6"))
	var counter_label := Label3D.new()
	counter_label.text = "קופה"
	counter_label.font_size = 38
	counter_label.pixel_size = 0.012
	counter_label.position = SHOP_CENTER + Vector3(0.0, 2.15, 5.35)
	counter_label.modulate = Color("#27343b")
	add_child(counter_label)

	_add_visual_box(self, Vector3(0.12, 3.2, 0.12), SHOP_CENTER + Vector3(-6.4, 1.6, -6.0), Color("#d8c69e"))
	_add_visual_box(self, Vector3(0.12, 3.2, 0.12), SHOP_CENTER + Vector3(6.4, 1.6, -6.0), Color("#d8c69e"))
	_add_visual_box(self, Vector3(12.8, 0.16, 0.22), SHOP_CENTER + Vector3(0.0, 3.2, -6.0), Color("#d8c69e"))

func _build_rack(parent: Node3D, center: Vector3, frame_color: Color) -> void:
	for x_offset in [-0.52, 0.52]:
		for z_offset in [-3.05, 3.05]:
			_add_static_box(parent, Vector3(0.1, 2.0, 0.1), center + Vector3(x_offset, 1.0, z_offset), frame_color)
	for shelf_height in [0.45, 1.05, 1.65]:
		_add_static_box(self, Vector3(1.2, 0.12, 6.3), center + Vector3(0.0, shelf_height, 0.0), Color("#a58b68"))
	_add_visual_box(parent, Vector3(1.28, 0.08, 6.4), center + Vector3(0.0, 2.05, 0.0), Color("#4f5c5d"))

func _add_product_stock(product: Dictionary, parent: Node3D) -> void:
	var center: Vector3 = product["position"]
	var model_name := str(product.get("model", ""))
	var packed_model := product_models.get(model_name) as PackedScene
	for row in range(3):
		for column in range(4):
			var offset := Vector3((float(column) - 1.5) * 0.22, 0.66 + float(row) * 0.52, (float(column % 2) - 0.5) * 0.42)
			if packed_model != null:
				var stock_item := packed_model.instantiate() as Node3D
				if stock_item != null:
					stock_item.name = "Stock_%s_%d_%d" % [model_name, row, column]
					var item_scale := 0.58
					if model_name == "soda-bottle" or model_name == "soda-can" or model_name == "carton":
						item_scale = 0.48
					stock_item.scale = Vector3.ONE * item_scale
					stock_item.position = center + offset
					stock_item.rotation.y = float((row + column) % 4) * PI * 0.5
					parent.add_child(stock_item)
					continue
			var fallback := _add_visual_box(parent, Vector3(0.15, 0.28, 0.19), center + offset, product["color"])

func _load_product_models() -> void:
	product_models.clear()
	for model_name in ["soda-bottle", "soda-can", "sandwich", "candy-bar-wrapper", "burger", "carton", "bread"]:
		var asset_path := "res://assets/products/%s.glb.b64" % model_name
		if not FileAccess.file_exists(asset_path):
			continue
		var encoded := FileAccess.get_file_as_string(asset_path).strip_edges()
		if encoded.is_empty():
			continue
		var binary := Marshalls.base64_to_raw(encoded)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var parse_error := document.append_from_buffer(binary, "res://assets/products/", state, 0)
		if parse_error != OK:
			push_warning("Could not load store product %s: %s" % [model_name, error_string(parse_error)])
			continue
		var model_scene := document.generate_scene(state)
		if model_scene == null:
			continue
		var packed := PackedScene.new()
		var pack_error := packed.pack(model_scene)
		if pack_error == OK:
			product_models[model_name] = packed
		else:
			push_warning("Could not pack store product %s: %s" % [model_name, error_string(pack_error)])
		model_scene.free()

func _add_static_box(parent: Node3D, box_size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var body := StaticBody3D.new()
	body.position = position
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	body.add_child(mesh_instance)
	return mesh_instance

func _add_visual_box(parent: Node3D, box_size: Vector3, position: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box_size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.78
	return material

func _distance_to(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _nearest_product() -> Dictionary:
	if player == null:
		return {}
	var closest_distance := 2.6
	var closest: Dictionary = {}
	for product in products:
		var product_position: Vector3 = product["position"]
		var distance := _distance_to(player.global_position, product_position)
		if distance < closest_distance:
			closest_distance = distance
			closest = product
	return closest

func _purchase_selected_product() -> void:
	if selected_product_id.is_empty():
		status_changed.emit("בחר מוצר ליד אחד המדפים לפני התשלום.")
		return
	for product in products:
		if str(product["id"]) != selected_product_id:
			continue
		var price := int(product["price"])
		var name := str(product["name"])
		var game_state := get_node_or_null("/root/GameState")
		if game_state == null:
			status_changed.emit("שמירת המשחק אינה זמינה כרגע.")
			return
		var purchased := bool(game_state.call("purchase_item", selected_product_id, price))
		if purchased:
			var count := int(game_state.call("item_count", selected_product_id))
			var balance := int(game_state.get("money"))
			status_changed.emit("נרכש %s | יחידות בתיק: %d | יתרה: ₪%d" % [name, count, balance])
			selected_product_id = ""
		else:
			status_changed.emit("אין מספיק כסף עבור %s (₪%d)." % [name, price])
		return

func _enter_store() -> void:
	inside_store = true
	selected_product_id = ""
	roof.visible = false
	interior_root.visible = true
	_set_doors_open(true)
	player.global_position = door_inside_position
	player.velocity = Vector3.ZERO
	player.rotation.y = PI
	store_state_changed.emit(true)
	status_changed.emit("ברוך הבא למינימרקט. בחר מוצר ליד המדפים וגש לקופה.")

func _exit_store() -> void:
	inside_store = false
	selected_product_id = ""
	roof.visible = true
	interior_root.visible = false
	_set_doors_open(false)
	player.global_position = door_outside_position
	player.velocity = Vector3.ZERO
	player.rotation.y = 0.0
	store_state_changed.emit(false)
	status_changed.emit("יצאת מהמינימרקט.")

func _set_doors_open(open: bool) -> void:
	if left_door == null or right_door == null:
		return
	var left_target := SHOP_CENTER + Vector3(-2.7 if open else -0.62, 2.05, -7.15)
	var right_target := SHOP_CENTER + Vector3(2.7 if open else 0.62, 2.05, -7.15)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_door, "position", left_target, 0.22)
	tween.tween_property(right_door, "position", right_target, 0.22)
