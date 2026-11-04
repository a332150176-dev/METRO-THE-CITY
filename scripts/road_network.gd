extends RefCounted
class_name RoadNetwork

const GRID_SIZE: int = 9
const SPACING: float = 76.0
const TURN_RADIUS: float = 7.0

func intersection_position(id: int) -> Vector3:
	var cell := Vector2i(id % GRID_SIZE, int(id / GRID_SIZE))
	var center_offset := float(GRID_SIZE - 1) * 0.5
	return Vector3((float(cell.x) - center_offset) * SPACING, 0.0, (float(cell.y) - center_offset) * SPACING)

func all_intersections() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for id in range(GRID_SIZE * GRID_SIZE):
		result.append(intersection_position(id))
	return result

func shortest_path(start_id: int, goal_id: int) -> Array[int]:
	var last_id := GRID_SIZE * GRID_SIZE - 1
	var start := clampi(start_id, 0, last_id)
	var goal := clampi(goal_id, 0, last_id)
	var queue: Array[int] = [start]
	var previous: Dictionary = {start: -1}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == goal:
			break
		var cell := Vector2i(current % GRID_SIZE, int(current / GRID_SIZE))
		var candidates: Array[Vector2i] = [
			cell + Vector2i(1, 0), cell + Vector2i(-1, 0),
			cell + Vector2i(0, 1), cell + Vector2i(0, -1)
		]
		for next_cell in candidates:
			if next_cell.x < 0 or next_cell.x >= GRID_SIZE or next_cell.y < 0 or next_cell.y >= GRID_SIZE:
				continue
			var next_id: int = next_cell.y * GRID_SIZE + next_cell.x
			if previous.has(next_id):
				continue
			previous[next_id] = current
			queue.append(next_id)
	var path: Array[int] = []
	if not previous.has(goal):
		return path
	var cursor: int = goal
	while cursor != -1:
		path.push_front(cursor)
		cursor = int(previous[cursor])
	return path

func _right_of(direction: Vector3) -> Vector3:
	return Vector3(direction.z, 0.0, -direction.x).normalized()

func build_route(start_id: int, goal_id: int, lane_offset: float = 3.1) -> PackedVector3Array:
	var ids := shortest_path(start_id, goal_id)
	var route := PackedVector3Array()
	if ids.size() < 2:
		route.append(intersection_position(start_id))
		return route

	var first_direction := (intersection_position(ids[1]) - intersection_position(ids[0])).normalized()
	route.append(intersection_position(ids[0]) + _right_of(first_direction) * lane_offset)

	for i in range(1, ids.size() - 1):
		var center := intersection_position(ids[i])
		var incoming := (center - intersection_position(ids[i - 1])).normalized()
		var outgoing := (intersection_position(ids[i + 1]) - center).normalized()
		var entry := center - incoming * TURN_RADIUS + _right_of(incoming) * lane_offset
		var exit := center + outgoing * TURN_RADIUS + _right_of(outgoing) * lane_offset
		if route.is_empty() or route[route.size() - 1].distance_to(entry) > 0.5:
			route.append(entry)
		var control_a := entry + incoming * (TURN_RADIUS * 0.72)
		var control_b := exit - outgoing * (TURN_RADIUS * 0.72)
		for step in range(1, 9):
			var t := float(step) / 8.0
			var one_minus := 1.0 - t
			var point := one_minus * one_minus * one_minus * entry
			point += 3.0 * one_minus * one_minus * t * control_a
			point += 3.0 * one_minus * t * t * control_b
			point += t * t * t * exit
			route.append(point)

	var last_direction := (intersection_position(ids[ids.size() - 1]) - intersection_position(ids[ids.size() - 2])).normalized()
	var finish := intersection_position(goal_id) + _right_of(last_direction) * lane_offset
	if route[route.size() - 1].distance_to(finish) > 0.5:
		route.append(finish)
	return route

func nearest_intersection(position: Vector3) -> Dictionary:
	var best_id := 0
	var best_distance := INF
	for id in range(GRID_SIZE * GRID_SIZE):
		var point := intersection_position(id)
		var distance := Vector2(position.x, position.z).distance_to(Vector2(point.x, point.z))
		if distance < best_distance:
			best_distance = distance
			best_id = id
	return {"id": best_id, "distance": best_distance, "position": intersection_position(best_id)}
