extends Node

signal money_changed(value: int)
signal reputation_changed(value: int)
signal mission_changed(index: int)

const SAVE_PATH: String = "user://metro_save.cfg"

var money: int = 0
var reputation: int = 0
var inventory: Dictionary = {}
var selected_character: String = "noam"
var mission_index: int = 0
var campaign_started: bool = false
var custom_shirt_color: String = ""

func _ready() -> void:
	load_progress()

func add_reward(amount: int, reputation_points: int = 1) -> void:
	money += maxi(0, amount)
	reputation += maxi(0, reputation_points)
	money_changed.emit(money)
	reputation_changed.emit(reputation)
	save_progress()

func purchase_item(item_id: String, price: int) -> bool:
	if item_id.strip_edges().is_empty() or price <= 0 or money < price:
		return false
	money -= price
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	money_changed.emit(money)
	save_progress()
	return true

func item_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))


func set_shirt_color(color: Color) -> void:
	custom_shirt_color = "#" + color.to_html(false).trim_prefix("#")
	save_progress()

func clear_shirt_color() -> void:
	custom_shirt_color = ""
	save_progress()

func set_character(character_id: String) -> void:
	selected_character = character_id
	save_progress()

func advance_mission() -> void:
	mission_index += 1
	mission_changed.emit(mission_index)
	save_progress()

func reset_campaign() -> void:
	mission_index = 0
	campaign_started = false
	save_progress()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "money", money)
	config.set_value("player", "inventory", inventory)
	config.set_value("player", "reputation", reputation)
	config.set_value("player", "character", selected_character)
	config.set_value("player", "custom_shirt_color", custom_shirt_color)
	config.set_value("campaign", "mission_index", mission_index)
	config.set_value("campaign", "started", campaign_started)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save METRO progress: %s" % error_string(error))

func load_progress() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return
	money = maxi(0, int(config.get_value("player", "money", 0)))
	var saved_inventory: Variant = config.get_value("player", "inventory", {})
	inventory = saved_inventory if saved_inventory is Dictionary else {}
	reputation = maxi(0, int(config.get_value("player", "reputation", 0)))
	selected_character = str(config.get_value("player", "character", "noam"))
	custom_shirt_color = str(config.get_value("player", "custom_shirt_color", ""))
	if not custom_shirt_color.is_empty() and not custom_shirt_color.begins_with("#"):
		custom_shirt_color = "#" + custom_shirt_color
	if not ["noam", "lior", "amit"].has(selected_character):
		selected_character = "noam"
	mission_index = maxi(0, int(config.get_value("campaign", "mission_index", 0)))
	campaign_started = bool(config.get_value("campaign", "started", false))
	money_changed.emit(money)
	reputation_changed.emit(reputation)
	mission_changed.emit(mission_index)
