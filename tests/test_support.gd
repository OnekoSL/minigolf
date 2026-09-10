extends RefCounted

var host: Node
var check: Callable


func _init(test_host: Node, test_check: Callable) -> void:
	host = test_host
	check = test_check


func get_tree() -> SceneTree:
	return host.get_tree()


func _check(condition: bool, description: String) -> void:
	check.call(condition, description)


func _simulate_hole_snapshot(hole_id: StringName, target: Vector2, speed: float, steps: int) -> Dictionary:
	var runtime := _instantiate_hole(hole_id)
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position(), runtime.get_tunnels())
	ball.launch(ball.position.direction_to(target), speed, 1)
	for _step in range(steps):
		if not ball.moving:
			break
		ball._physics_process(1.0 / 60.0)
	var result := {"position": ball.position, "velocity": ball.velocity}
	ball.free()
	runtime.free()
	return result


func _simulate_hole_route(hole_id: StringName, shots: Array, obstacle_mode := &"") -> bool:
	var runtime := _instantiate_hole(hole_id)
	await get_tree().physics_frame
	for obstacle in runtime.obstacle_nodes:
		obstacle.set_physics_process(false)
		if obstacle_mode == &"reference_open" and obstacle is RotatingObstacle:
			obstacle.rotation = 0.0
		elif obstacle_mode == &"gates_open" and obstacle is TimedSlidingGate:
			obstacle.position = obstacle.closed_position + obstacle.open_offset
		elif obstacle_mode == &"labyrinth_geometry":
			if obstacle is RotatingObstacle:
				obstacle.rotation = 0.0
				obstacle.collision_layer = 0
			elif obstacle is TimedSlidingGate:
				obstacle.position = obstacle.closed_position + obstacle.open_offset
				obstacle.collision_layer = 0
			elif obstacle is SeesawObstacle:
				obstacle.left_end_blocker.collision_layer = 0
				obstacle.right_end_blocker.collision_layer = 0
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position(), runtime.get_tunnels())
	var result := {"holed": false}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	for index in range(shots.size()):
		var aim = shots[index][0]
		var speed: float = shots[index][1]
		var direction := Vector2.ZERO
		if typeof(aim) == TYPE_FLOAT or typeof(aim) == TYPE_INT:
			direction = Vector2.from_angle(deg_to_rad(float(aim)))
		else:
			var target: Vector2 = aim
			direction = ball.position.direction_to(target)
		ball.launch(direction, speed, index + 1)
		for _step in range(1800):
			if obstacle_mode == &"seesaw_weight" or obstacle_mode == &"labyrinth_geometry":
				for obstacle in runtime.obstacle_nodes:
					if obstacle is SeesawObstacle:
						var weighted_x := obstacle.to_local(ball.global_position).x if obstacle.contains_global_point(ball.global_position) else INF
						obstacle.advance_tilt(1.0 / 60.0, weighted_x)
						obstacle.sync_end_blockers(true)
			ball._physics_process(1.0 / 60.0)
			if not ball.moving:
				break
		if not ball.visible:
			await get_tree().create_timer(0.65).timeout
		if ball.position.distance_to(runtime.get_hole_position()) <= PrototypeBall.HOLE_RADIUS:
			await get_tree().create_timer(0.4).timeout
		if result["holed"]:
			break
	var completed: bool = result["holed"]
	if not completed:
		print("  Route %s endete bei %s mit Tempo %.1f" % [hole_id, ball.position, ball.velocity.length()])
	ball.free()
	runtime.free()
	return completed


func _instantiate_hole(hole_id: StringName) -> HoleRuntime:
	var catalog := HoleCatalog.load_default()
	var definition := catalog.get_hole(hole_id)
	assert(definition != null, "Unbekannte Bahn-ID: %s" % hole_id)
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	get_tree().root.add_child(runtime)
	return runtime


