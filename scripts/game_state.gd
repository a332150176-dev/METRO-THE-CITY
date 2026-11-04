extends Node

signal money_changed(value: int)
signal reputation_changed(value: int)
signal mission_changed(index: int)

const SAVE_PATH: String = "user://metro_save.cfg"

var money: int = 0
var reputation: int = 0
var selected_character: String = "noam"
var mission_index: int = 0
var campaign_started: bool = false

func _ready() -> void:
	load_progress()

func add_reward(amount: int, reputation_points: int = 1) -> void:
	money += maxi(0, amount)
	reputation += maxi(0, reputation_points)
	money_changed.emit(money)
	reputation_changed.emit(reputation)
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
	config.set_value("player", "reputation", reputation)
	config.set_value("player", "character", selected_character)
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
	reputation = maxi(0, int(config.get_value("player", "reputation", 0)))
	selected_character = str(config.get_value("player", "character", "noam"))
	if not ["noam", "lior", "amit"].has(selected_character):
		selected_character = "noam"
	mission_index = maxi(0, int(config.get_value("campaign", "mission_index", 0)))
	campaign_started = bool(config.get_value("campaign", "started", false))
	money_changed.emit(money)
	reputation_changed.emit(reputation)
	mission_changed.emit(mission_index)
