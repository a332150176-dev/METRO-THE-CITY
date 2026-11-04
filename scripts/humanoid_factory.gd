extends Node
class_name HumanoidFactory

const ASSETS := {
	"body": "body.glb.b64",
	"hair": "hair_short.glb.b64",
	"top": "top_tee.glb.b64",
	"bottom": "bottom_trousers.glb.b64",
	"boots": "boots_low.glb.b64",
	"movement": "movement_basic.glb.b64",
	"general": "general.glb.b64"
}

var packed_scenes: Dictionary = {}
var load_errors: Array[String] = []

func load_assets() -> void:
	packed_scenes.clear()
	load_errors.clear()
	for key_value in ASSETS.keys():
		var key := str(key_value)
		var file_name := str(ASSETS[key])
		var asset_path := "res://assets/humanoid/%s" % file_name
		if not FileAccess.file_exists(asset_path):
			load_errors.append("missing: " + file_name)
			continue
		var encoded := FileAccess.get_file_as_string(asset_path).strip_edges()
		var binary := Marshalls.base64_to_raw(encoded)
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var parse_error := document.append_from_buffer(binary, "res://assets/humanoid/", state, 0)
		if parse_error != OK:
			load_errors.append("parse: %s (%s)" % [file_name, error_string(parse_error)])
			continue
		var imported_scene := document.generate_scene(state)
		if imported_scene == null:
			load_errors.append("scene: " + file_name)
			continue
		var packed := PackedScene.new()
		var pack_error := packed.pack(imported_scene)
		if pack_error == OK:
			packed_scenes[key] = packed
		else:
			load_errors.append("pack: %s (%s)" % [file_name, error_string(pack_error)])
		imported_scene.free()

func assets_ready() -> bool:
	return packed_scenes.has("body") and packed_scenes.has("hair") and packed_scenes.has("top") and packed_scenes.has("bottom") and packed_scenes.has("boots") and packed_scenes.has("movement")

func create_character(character_id: String = "noam") -> Node3D:
	if not assets_ready():
		return null
	var body_instance := packed_scenes["body"].instantiate() as Node3D
	if body_instance == null:
		return null
	body_instance.name = "RiggedHumanoid"

	var skeleton := _find_skeleton(body_instance)
	if skeleton == null:
		body_instance.free()
		return null

	_attach_part(body_instance, skeleton, "hair")
	_attach_part(body_instance, skeleton, "top")
	_attach_part(body_instance, skeleton, "bottom")
	_attach_part(body_instance, skeleton, "boots")
	_hide_covered_skin(body_instance)

	var animation_source := packed_scenes["movement"].instantiate()
	var source_player := _find_animation_player(animation_source)
	if source_player != null:
		source_player.reparent(body_instance)
		source_player.name = "CharacterAnimationPlayer"
		var root_path := source_player.root_node
		if root_path.is_empty():
			source_player.root_node = NodePath("..")
		else:
			source_player.root_node = NodePath("..")
		animation_source.free()
	else:
		animation_source.free()

	var result := Node3D.new()
	result.name = "RiggedCharacterModel"
	result.add_child(body_instance)
	body_instance.scale = Vector3.ONE * 0.82
	result.set_meta("character_id", character_id)
	return result

func _attach_part(body_root: Node3D, body_skeleton: Skeleton3D, part_key: String) -> void:
	if not packed_scenes.has(part_key):
		return
	var part_root := packed_scenes[part_key].instantiate()
	if part_root == null:
		return
	var part_skeleton := _find_skeleton(part_root)
	if part_skeleton == null:
		part_root.free()
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_skinned_meshes(part_skeleton, meshes)
	for mesh_instance in meshes:
		part_skeleton.remove_child(mesh_instance)
		body_root.add_child(mesh_instance)
		mesh_instance.skeleton = mesh_instance.get_path_to(body_skeleton)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	part_root.free()

func _hide_covered_skin(body_root: Node3D) -> void:
	var hidden_names := [
		"skin_torso", "skin_armUpperL", "skin_armUpperR",
		"skin_legUpperL", "skin_legUpperR", "skin_legLowerL",
		"skin_legLowerR", "skin_footL", "skin_footR"
	]
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(body_root, meshes)
	for mesh_instance in meshes:
		if hidden_names.has(str(mesh_instance.name)):
			mesh_instance.visible = false

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_mesh_instances(child, output)

func _collect_skinned_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.skin != null:
			output.append(mesh_instance)
	for child in node.get_children():
		_collect_skinned_meshes(child, output)
