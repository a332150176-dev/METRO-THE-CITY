extends Node

signal money_changed(value: int)
signal reputation_changed(value: int)
signal mission_changed(index: int)

var money: int = 0
var reputation: int = 0
var selected_character: String = "noam"
var mission_index: int = 0
var campaign_started: bool = false

func add_reward(amount: int, reputation_points: int = 1) -> void:
	money += maxi(0, amount)
	reputation += maxi(0, reputation_points)
	money_changed.emit(money)
	reputation_changed.emit(reputation)

func set_character(character_id: String) -> void:
	selected_character = character_id

func advance_mission() -> void:
	mission_index += 1
	mission_changed.emit(mission_index)

func reset_campaign() -> void:
	mission_index = 0
	campaign_started = false
