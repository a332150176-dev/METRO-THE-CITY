extends SceneTree

func _initialize() -> void:
	call_deferred("_run_smoke_test")

func _run_smoke_test() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Smoke test: main scene could not be loaded")
		quit(1)
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	if game.road_network == null:
		push_error("Smoke test: road network was not initialized")
		quit(1)
		return
	var route: PackedVector3Array = game.road_network.build_route(0, 48)
	if route.size() < 5:
		push_error("Smoke test: 7x7 route generation failed")
		quit(1)
		return
	if game.road_network.all_intersections().size() != 49:
		push_error("Smoke test: expanded city does not contain 49 intersections")
		quit(1)
		return
	var city_node := game.get_node_or_null("ProceduralCity")
	if city_node == null:
		push_error("Smoke test: procedural city is missing")
		quit(1)
		return
	var authored_models: Array = city_node.get("suburban_meshes")
	if authored_models.size() < 8:
		push_error("Smoke test: authored suburban building models did not load")
		quit(1)
		return
	var downtown_models: Array = city_node.get("downtown_meshes")
	if downtown_models.size() < 5:
		push_error("Smoke test: five downtown skyscraper models did not load")
		quit(1)
		return
	var traffic := game.get_node_or_null("CityTraffic")
	if traffic == null or traffic.cars.size() < 12 or traffic.pedestrians.size() < 24:
		push_error("Smoke test: traffic or pedestrian population did not initialize")
		quit(1)
		return
	if traffic.vehicle_scenes.size() < 8:
		push_error("Smoke test: all eight authored vehicle models did not load")
		quit(1)
		return
	var first_car := traffic.cars[0] as TrafficCar
	if first_car.get_node_or_null("VehicleVisual/AuthoredVehicleModel") == null:
		push_error("Smoke test: traffic car is not using its authored 3D model")
		quit(1)
		return
	if first_car.wheel_meshes.size() < 4:
		push_error("Smoke test: authored vehicle wheel meshes were not found")
		quit(1)
		return
	if game.get_node_or_null("GameHUD") == null:
		push_error("Smoke test: game HUD is missing")
		quit(1)
		return

	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		push_error("Smoke test: GameState autoload is missing")
		quit(1)
		return
	game_state.set_shirt_color(Color("#b64d3b"))
	if game_state.custom_shirt_color != "#b64d3b":
		push_error("Smoke test: character customization did not persist")
		quit(1)
		return
	game_state.clear_shirt_color()

	game.hud._start_selected_character()
	await process_frame
	if game.player == null or game.mission_manager == null:
		push_error("Smoke test: character selection did not start the campaign")
		quit(1)
		return

	var wanted := game.get_node_or_null("WantedSystem") as WantedSystem
	if wanted == null:
		push_error("Smoke test: wanted system was not initialized")
		quit(1)
		return
	wanted.report_vehicle_theft()
	await process_frame
	if wanted.wanted_level != 1 or traffic.police_units.size() != 1:
		push_error("Smoke test: vehicle theft did not dispatch a police unit")
		quit(1)
		return
	var police_car := traffic.police_units[0]
	if police_car.pursuit_target != game.player or police_car.vehicle_type != "police":
		push_error("Smoke test: police unit did not start pursuing the player")
		quit(1)
		return

	game.player.request_jump()
	if not game.player.jump_requested:
		push_error("Smoke test: jump action was not registered")
		quit(1)
		return

	if game.hud.minimap == null:
		push_error("Smoke test: navigation mini-map is missing")
		quit(1)
		return

	var test_car: TrafficCar = traffic.cars[0]
	test_car.enter_vehicle(game.player, game.hud.get_joystick())
	if not test_car.player_driving:
		push_error("Smoke test: player could not enter a vehicle")
		quit(1)
		return
	game.mission_manager.vehicle = test_car
	test_car.global_position = Vector3(0.0, 0.0, 0.0)
	await process_frame
	if game.mission_manager.current_index < 1:
		push_error("Smoke test: mission did not complete while driving")
		quit(1)
		return
	test_car.exit_vehicle()
	if test_car.player_driving or not game.player.visible:
		push_error("Smoke test: player could not exit a vehicle")
		quit(1)
		return

	var store := game.get_node_or_null("InteractiveStores") as StoreSystem
	if store == null:
		push_error("Smoke test: interactive minimarket was not created")
		quit(1)
		return
	if store.product_models.size() < 7:
		push_error("Smoke test: authored food and drink models did not load")
		quit(1)
		return
	store.configure(game.player)
	game_state.add_reward(50, 0)
	game.player.global_position = store.get_door_position()
	if not store.try_interact() or not store.inside_store:
		push_error("Smoke test: player could not enter the minimarket")
		quit(1)
		return
	game.player.global_position = store.get_product_position("water")
	if not store.try_interact():
		push_error("Smoke test: product shelf interaction failed")
		quit(1)
		return
	game.player.global_position = store.get_checkout_position()
	if not store.try_interact() or game_state.item_count("water") < 1:
		push_error("Smoke test: checkout did not save a purchased item")
		quit(1)
		return
	game.player.global_position = store.door_inside_position
	if not store.try_interact() or store.inside_store:
		push_error("Smoke test: player could not exit the minimarket")
		quit(1)
		return

	print("METRO smoke test passed: 7x7 city, eight textured suburban buildings, five textured skyscrapers, eight authored vehicles, police wanted response, traffic, campaign, vehicles, interactive store with 3D products, checkout and persistent inventory")
	quit(0)
