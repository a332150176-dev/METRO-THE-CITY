extends CanvasLayer
class_name GameHUD

signal character_selected(character_id: String)
signal interaction_pressed
signal jump_pressed
signal sprint_toggled(enabled: bool)

var joystick: TouchJoystick
var overlay: ColorRect
var mission_label: Label
var mission_detail: Label
var money_label: Label
var reputation_label: Label
var selected_character: String = "noam"
var sprint_button: Button
var action_button: Button
var minimap: CityMiniMap

func show_character_selection() -> void:
	selected_character = GameState.selected_character
	overlay = ColorRect.new()
	overlay.color = Color(0.015, 0.035, 0.065, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-245.0, -245.0)
	panel.size = Vector2(490.0, 490.0)
	overlay.add_child(panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "METRO: THE CITY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "בחר את הדמות שלך"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	layout.add_child(subtitle)

	for id in CharacterCatalog.ids():
		var character_id: String = str(id)
		var data := CharacterCatalog.get_character(character_id)
		var button := Button.new()
		button.text = "%s  —  %s" % [data["name"], data["subtitle"]]
		button.custom_minimum_size = Vector2(0.0, 42.0)
		button.pressed.connect(func(): _select_character(character_id))
		layout.add_child(button)

	var start_button := Button.new()
	start_button.text = "כניסה לעיר"
	start_button.custom_minimum_size = Vector2(0.0, 48.0)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.pressed.connect(_start_selected_character)
	layout.add_child(start_button)

func _select_character(character_id: String) -> void:
	selected_character = character_id

func _start_selected_character() -> void:
	GameState.set_character(selected_character)
	if overlay != null:
		overlay.queue_free()
		overlay = null
	character_selected.emit(selected_character)

func show_gameplay() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := Label.new()
	title.text = "METRO  /  THE CITY"
	title.position = Vector2(26.0, 18.0)
	title.add_theme_font_size_override("font_size", 19)
	root.add_child(title)

	minimap = CityMiniMap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.position = Vector2(-188.0, 18.0)
	minimap.size = Vector2(168.0, 168.0)
	root.add_child(minimap)

	mission_label = Label.new()
	mission_label.position = Vector2(26.0, 52.0)
	mission_label.size = Vector2(480.0, 34.0)
	mission_label.add_theme_font_size_override("font_size", 22)
	root.add_child(mission_label)

	mission_detail = Label.new()
	mission_detail.position = Vector2(26.0, 88.0)
	mission_detail.size = Vector2(520.0, 50.0)
	mission_detail.add_theme_font_size_override("font_size", 16)
	root.add_child(mission_detail)

	money_label = Label.new()
	money_label.position = Vector2(26.0, 142.0)
	money_label.text = "₪ 0"
	money_label.add_theme_font_size_override("font_size", 20)
	root.add_child(money_label)

	reputation_label = Label.new()
	reputation_label.position = Vector2(26.0, 170.0)
	reputation_label.text = "מוניטין: %d" % GameState.reputation
	reputation_label.add_theme_font_size_override("font_size", 17)
	root.add_child(reputation_label)

	joystick = TouchJoystick.new()
	joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	joystick.position = Vector2(24.0, -190.0)
	joystick.size = Vector2(170.0, 170.0)
	root.add_child(joystick)

	sprint_button = Button.new()
	sprint_button.text = "ריצה"
	sprint_button.toggle_mode = true
	sprint_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	sprint_button.position = Vector2(-150.0, -125.0)
	sprint_button.size = Vector2(122.0, 64.0)
	sprint_button.toggled.connect(func(enabled: bool): sprint_toggled.emit(enabled))
	root.add_child(sprint_button)

	action_button = Button.new()
	action_button.text = "פעולה"
	action_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_button.position = Vector2(-150.0, -205.0)
	action_button.size = Vector2(122.0, 64.0)
	action_button.pressed.connect(func(): interaction_pressed.emit())
	root.add_child(action_button)

func get_joystick() -> TouchJoystick:
	return joystick

func set_mission(title: String, description: String, reward: int, index: int) -> void:
	if mission_label == null:
		return
	if reward > 0:
		mission_label.text = "%02d  |  %s" % [index + 1, title]
		mission_detail.text = "%s   •   פרס: ₪%d" % [description, reward]
	else:
		mission_label.text = title
		mission_detail.text = description

func set_money(value: int) -> void:
	if money_label != null:
		money_label.text = "₪ %d" % value


func set_reputation(value: int) -> void:
	if reputation_label != null:
		reputation_label.text = "מוניטין: %d" % value


func set_action_label(value: String) -> void:
	if action_button != null and action_button.text != value:
		action_button.text = value


func set_navigation_sources(player_node: PlayerController, mission_node: MissionManager) -> void:
	if minimap != null:
		minimap.set_sources(player_node, mission_node)
