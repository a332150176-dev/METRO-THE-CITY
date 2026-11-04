extends Node3D

const CITY_SCRIPT := preload("res://scripts/city_builder.gd")
const NETWORK_SCRIPT := preload("res://scripts/road_network.gd")
const SIGNAL_SCRIPT := preload("res://scripts/traffic_controller.gd")
const TRAFFIC_SCRIPT := preload("res://scripts/traffic_manager.gd")
const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")
const HUD_SCRIPT := preload("res://scripts/game_hud.gd")
const MISSION_SCRIPT := preload("res://scripts/mission_manager.gd")

var road_network: RoadNetwork
var traffic_controller: TrafficController
var player: PlayerController
var hud: GameHUD
var mission_manager: MissionManager

func _ready() -> void:
	_ensure_input_actions()
	_build_environment()
	road_network = NETWORK_SCRIPT.new()

	traffic_controller = SIGNAL_SCRIPT.new()
	traffic_controller.name = "TrafficController"
	add_child(traffic_controller)

	var city: CityBuilder = CITY_SCRIPT.new()
	city.name = "ProceduralCity"
	add_child(city)
	city.build_city(traffic_controller)

	var traffic: TrafficManager = TRAFFIC_SCRIPT.new()
	traffic.name = "CityTraffic"
	add_child(traffic)
	traffic.configure(road_network, traffic_controller)

	hud = HUD_SCRIPT.new()
	hud.name = "GameHUD"
	add_child(hud)
	hud.character_selected.connect(_start_game)
	hud.show_character_selection()
	GameState.money_changed.connect(hud.set_money)

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#38658c")
	sky_material.sky_horizon_color = Color("#b9c9cf")
	sky_material.ground_bottom_color = Color("#313b42")
	sky_material.ground_horizon_color = Color("#8a999a")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#9ab2c4")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-53.0, -32.0, 0.0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

func _start_game(character_id: String) -> void:
	if player != null:
		return
	player = PLAYER_SCRIPT.new()
	player.name = "Player"
	add_child(player)
	player.configure(character_id)
	player.global_position = Vector3(-65.0, 0.15, -65.0)

	hud.show_gameplay()
	player.set_joystick_source(hud.get_joystick())
	hud.sprint_toggled.connect(player.set_sprinting)
	hud.interaction_pressed.connect(_on_interaction)

	mission_manager = MISSION_SCRIPT.new()
	mission_manager.name = "CampaignMissions"
	add_child(mission_manager)
	mission_manager.mission_updated.connect(hud.set_mission)
	mission_manager.setup(player)
	GameState.campaign_started = true

func _on_interaction() -> void:
	if player == null:
		return
	player.request_interaction()

func _ensure_input_actions() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)

func _add_key_action(action: String, key: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
