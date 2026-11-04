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
	var route: PackedVector3Array = game.road_network.build_route(0, 8)
	if route.size() < 5:
		push_error("Smoke test: 3x3 route generation failed")
		quit(1)
		return
	if game.get_node_or_null("ProceduralCity") == null:
		push_error("Smoke test: procedural city is missing")
		quit(1)
		return
	var traffic := game.get_node_or_null("CityTraffic")
	if traffic == null or traffic.cars.size() < 9 or traffic.pedestrians.size() < 18:
		push_error("Smoke test: traffic or pedestrian population did not initialize")
		quit(1)
		return
	if game.get_node_or_null("GameHUD") == null:
		push_error("Smoke test: game HUD is missing")
		quit(1)
		return

	print("METRO smoke test passed: scene, city, 3x3 route, traffic and pedestrians")
	quit(0)
