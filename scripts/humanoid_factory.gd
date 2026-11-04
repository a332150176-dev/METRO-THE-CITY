extends Node
class_name HumanoidFactory

const HIGH_DETAIL_CHARACTER_PATH := "res://assets/visual_upgrade/lagos_player.glb"

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
var high_detail_character_scene: PackedScene

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

	var high_detail_resource := load(HIGH_DETAIL_CHARACTER_PATH)
	if high_detail_resource is PackedScene:
		high_detail_character_scene = high_detail_resource as PackedScene
	else:
		load_errors.append("missing or invalid high-detail character: " + HIGH_DETAIL_CHARACTER_PATH)

func assets_ready() -> bool:
	if high_detail_character_scene != null:
		return true
	return packed_scenes.has("body") and packed_scenes.has("hair") and packed_scenes.has("top") and packed_scenes.has("bottom") and packed_scenes.has("boots") and packed_scenes.has("movement")

func create_character(character_id: String = "noam", custom_shirt_color: String = "") -> Node3D:
	if high_detail_character_scene != null:
		var high_detail_character := _create_high_detail_character(character_id, custom_shirt_color)
		if high_detail_character != null:
			return high_detail_character
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
	_apply_character_colors(body_instance, character_id, custom_shirt_color)
	_hide_covered_skin(body_instance)

	var animation_source: Node = (packed_scenes["movement"] as PackedScene).instantiate()
	_clear_scene_owners(animation_source)
	var source_player := _find_animation_player(animation_source)
	if source_player != null:
		if packed_scenes.has("general"):
			var general_source: Node = (packed_scenes["general"] as PackedScene).instantiate()
			_clear_scene_owners(general_source)
			var general_player := _find_animation_player(general_source)
			if general_player != null:
				_merge_animation_libraries(source_player, general_player)
			general_source.free()
		source_player.owner = null
		source_player.reparent(body_instance)
		source_player.name = "CharacterAnimationPlayer"
		source_player.root_node = NodePath("..")
		for locomotion_name in ["Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B"]:
			if source_player.has_animation(locomotion_name):
				var locomotion_clip := source_player.get_animation(locomotion_name) as Animation
				if locomotion_clip != null:
					locomotion_clip.loop_mode = Animation.LOOP_LINEAR
		if not source_player.has_animation("Idle_A"):
			var default_library := source_player.get_animation_library("") as AnimationLibrary
			if default_library == null:
				default_library = AnimationLibrary.new()
				var library_error := source_player.add_animation_library("", default_library)
				if library_error != OK:
					push_warning("Could not create idle animation library: %s" % error_string(library_error))
			if default_library != null:
				var idle_clip := Animation.new()
				idle_clip.length = 3.2
				idle_clip.loop_mode = Animation.LOOP_LINEAR
				var idle_error := default_library.add_animation("Idle_A", idle_clip)
				if idle_error != OK:
					push_warning("Could not add procedural idle animation: %s" % error_string(idle_error))
		animation_source.free()
	else:
		animation_source.free()

	var result := Node3D.new()
	result.name = "RiggedCharacterModel"
	result.add_child(body_instance)
	body_instance.scale = Vector3.ONE * 0.82
	result.set_meta("character_id", character_id)
	return result

func _create_high_detail_character(character_id: String, custom_shirt_color: String) -> Node3D:
	var model := high_detail_character_scene.instantiate() as Node3D
	if model == null:
		return null
	model.name = "HighDetailHumanoid"

	var animation_player := _find_animation_player(model)
	if animation_player == null:
		model.free()
		return null
	animation_player.name = "CharacterAnimationPlayer"

	var default_library := animation_player.get_animation_library("") as AnimationLibrary
	if default_library == null:
		default_library = AnimationLibrary.new()
		var library_error := animation_player.add_animation_library("", default_library)
		if library_error != OK:
			push_warning("Could not create high-detail character animation library: %s" % error_string(library_error))
			model.free()
			return null

	var animation_aliases := {
		"Idle_A": "HumanArmature|Man_Idle",
		"Walking_A": "HumanArmature|Man_Walk",
		"Running_A": "HumanArmature|Man_Run"
	}
	for alias_value in animation_aliases.keys():
		var alias_name := str(alias_value)
		var source_name := str(animation_aliases[alias_value])
		if animation_player.has_animation(alias_name):
			continue
		if not animation_player.has_animation(source_name):
			push_warning("High-detail character is missing animation: " + source_name)
			continue
		var source_clip := animation_player.get_animation(source_name) as Animation
		if source_clip == null:
			continue
		var clip_copy := source_clip.duplicate(true) as Animation
		if clip_copy == null:
			continue
		clip_copy.loop_mode = Animation.LOOP_LINEAR
		var add_error := default_library.add_animation(alias_name, clip_copy)
		if add_error != OK:
			push_warning("Could not add high-detail animation %s: %s" % [alias_name, error_string(add_error)])

	_apply_high_detail_colors(model, character_id, custom_shirt_color)
	# Quaternius' source character faces +Z; the game camera and movement use -Z.
	model.rotation.y = PI
	model.scale = Vector3.ONE * 0.95

	var result := Node3D.new()
	result.name = "RiggedCharacterModel"
	result.add_child(model)
	result.set_meta("character_id", character_id)
	result.set_meta("visual_quality", "high_detail")
	return result

func _apply_high_detail_colors(model_root: Node3D, character_id: String, custom_shirt_color: String) -> void:
	var lookup_id := "noam" if character_id == "pedestrian" else character_id
	var character := CharacterCatalog.get_character(lookup_id)
	var hair_colors := {
		"noam": Color("#30241e"),
		"lior": Color("#4a3025"),
		"amit": Color("#211e1b")
	}
	var palette := {
		"skin": character["skin"],
		"hair": hair_colors.get(lookup_id, Color("#30241e")),
		"shirt": character["shirt"],
		"pants": character["pants"],
		"shoes": Color("#25282d"),
		"socks": Color("#25282d")
	}
	if not custom_shirt_color.is_empty():
		palette["shirt"] = Color(custom_shirt_color)

	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(model_root, meshes)
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source_material := mesh_instance.mesh.surface_get_material(surface_index) as StandardMaterial3D
			if source_material == null:
				continue
			var material_key := source_material.resource_name.to_lower()
			var tint: Color
			var should_tint := true
			if material_key.contains("shirt"):
				tint = palette["shirt"]
			elif material_key.contains("pants"):
				tint = palette["pants"]
			elif material_key.contains("skin"):
				tint = palette["skin"]
			elif material_key.contains("hair"):
				tint = palette["hair"]
			elif material_key.contains("shoe") or material_key.contains("sock"):
				tint = palette["shoes"]
			else:
				should_tint = false
			if not should_tint:
				continue
			var material_copy := source_material.duplicate() as StandardMaterial3D
			if material_copy == null:
				continue
			material_copy.albedo_color = tint
			mesh_instance.set_surface_override_material(surface_index, material_copy)

func _merge_animation_libraries(target: AnimationPlayer, source: AnimationPlayer) -> void:
	var target_library := target.get_animation_library("") as AnimationLibrary
	if target_library == null:
		target_library = AnimationLibrary.new()
		var add_error := target.add_animation_library("", target_library)
		if add_error != OK:
			push_warning("Could not create default humanoid animation library: %s" % error_string(add_error))
			return
	for library_name in source.get_animation_library_list():
		var source_library := source.get_animation_library(library_name) as AnimationLibrary
		if source_library == null:
			continue
		for animation_name in source_library.get_animation_list():
			var clip_name := str(animation_name)
			if target.has_animation(clip_name):
				continue
			var source_clip := source_library.get_animation(clip_name)
			if source_clip == null:
				continue
			var clip_copy := source_clip.duplicate(true) as Animation
			if clip_copy == null:
				continue
			var add_clip_error := target_library.add_animation(clip_name, clip_copy)
			if add_clip_error != OK:
				push_warning("Could not merge humanoid animation %s: %s" % [clip_name, error_string(add_clip_error)])

func _attach_part(body_root: Node3D, body_skeleton: Skeleton3D, part_key: String) -> void:
	if not packed_scenes.has(part_key):
		return
	var part_root: Node = (packed_scenes[part_key] as PackedScene).instantiate()
	if part_root == null:
		return
	_clear_scene_owners(part_root)
	var part_skeleton := _find_skeleton(part_root)
	if part_skeleton == null:
		part_root.free()
		return
	var meshes: Array[MeshInstance3D] = []
	_collect_skinned_meshes(part_skeleton, meshes)
	for mesh_instance in meshes:
		part_skeleton.remove_child(mesh_instance)
		mesh_instance.owner = null
		body_root.add_child(mesh_instance)
		mesh_instance.skeleton = mesh_instance.get_path_to(body_skeleton)
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	part_root.free()

func _clear_scene_owners(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		_clear_scene_owners(child)

func _apply_character_colors(body_root: Node3D, character_id: String, custom_shirt_color: String = "") -> void:
	var character := CharacterCatalog.get_character(character_id)
	var hair_colors := {
		"noam": Color("#30241e"),
		"lior": Color("#4a3025"),
		"amit": Color("#211e1b")
	}
	var palette := {
		"skin": character["skin"],
		"hair": hair_colors.get(character_id, Color("#30241e")),
		"shirt": character["shirt"],
		"trousers": character["pants"],
		"boots": Color("#252b30")
	}
	if character_id != "pedestrian" and not custom_shirt_color.is_empty():
		palette["shirt"] = Color(custom_shirt_color)
	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(body_root, meshes)
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source_material := mesh_instance.mesh.surface_get_material(surface_index)
			if source_material == null:
				continue
			var material_key := source_material.resource_name.to_lower()
			if not palette.has(material_key):
				continue
			var tinted := source_material.duplicate() as StandardMaterial3D
			if tinted == null:
				continue
			tinted.albedo_color = palette[material_key]
			mesh_instance.set_surface_override_material(surface_index, tinted)

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
		if mesh_instance.mesh != null and mesh_instance.skin != null:
			output.append(mesh_instance)
	for child in node.get_children():
		_collect_skinned_meshes(child, output)
