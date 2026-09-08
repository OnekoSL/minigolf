extends RefCounted

# Regression checks for the three introductory arrow holes. The mandatory
# field proof merges exact intervals across a separator in the actual outline.
# Routes use the real ball and collider geometry; no flow or collision bypass.

static func run(host: Node, check: Callable) -> void:
	var routes := {
		&"arrow_armageddon_01": [
			[[Vector2(490, 180), 250.0], [Vector2(580, 100), 180.0]],
			[[-4.0, 310.0]],
		],
		&"arrow_armageddon_02": [
			[[Vector2(575, 70), 420.0], [Vector2(575, 70), 135.0]],
			[[-26.0, 380.0]],
		],
		&"arrow_armageddon_03": [
			[[Vector2(475, 165), 290.0], [Vector2(580, 180), 130.0]],
			[[-36.0, 330.0]],
		],
	}
	for hole_id in routes:
		var definition: HoleDefinition = load("res://data/holes/%s.tres" % hole_id)
		var hole_check := func(condition: bool, label: String) -> void:
			check.call(condition, "%s: %s" % [hole_id, label])
		_geometry(definition, hole_check)
		for index in range(routes[hole_id].size()):
			var shots: Array = routes[hole_id][index]
			hole_check.call(shots.size() <= definition.par, "Reference route fits PAR")
			var valid_input := shots.all(func(shot): return float(shot[1]) >= 78.0 and float(shot[1]) <= 420.0)
			hole_check.call(valid_input, "Every shot is in the legal 78-420 speed range")
			if valid_input:
				var holed := await _route(host, definition, shots)
				hole_check.call(holed, "PAR/risk route %d emits the real holed signal" % (index + 1))
		if hole_id == &"arrow_armageddon_03":
			await _cross_slope_contacts(host, definition, hole_check)


static func _geometry(definition: HoleDefinition, check: Callable) -> void:
	check.call(definition.validate().is_empty(), "Catalogue validation: %s" % definition.validate())
	check.call(definition.par == 2, "Keep PAR2")
	check.call(definition.lane_outline.use_normalized_walls and is_equal_approx(definition.lane_outline.wall_thickness, 4.0), "4px normalized outline")
	check.call(definition.lane_outline.boundary_arcs.is_empty(), "Separator proof requires straight outline segments")
	check.call(definition.walls.is_empty() and definition.wall_tiles.is_empty(), "No free/interior walls")
	check.call(definition.surfaces.is_empty() and definition.obstacles.is_empty() and definition.triggers.is_empty() and definition.cannons.is_empty(), "Pure arrow teaching holes")
	for tile in definition.arrow_tiles:
		check.call(tile.cell_size == 16 and tile.slope_grade == SurfaceZone.SlopeGrade.SHALLOW, "16px shallow cell")
		check.call(is_equal_approx(tile.deceleration, 30.0), "30px/s2 rolling resistance")
		check.call(is_zero_approx(tile.minimum_flow_speed) and is_zero_approx(tile.maximum_flow_speed) and is_zero_approx(tile.flow_alignment_rate) and is_zero_approx(tile.flow_centering_strength), "No flow assistance")
	var cuts: Array[float] = []
	match definition.hole_id:
		&"arrow_armageddon_01":
			check.call(definition.arrow_tiles.size() == 28, "24 core cells and 4 exit cells")
			cuts = [344.0]
		&"arrow_armageddon_02":
			check.call(definition.arrow_tiles.size() == 36, "36 diagonal stair cells")
			cuts = [344.0]
		&"arrow_armageddon_03":
			check.call(definition.arrow_tiles.size() == 84, "Two 6x7 cross-slope fields")
			cuts = [352.0, 480.0]
	var polygon: PackedVector2Array = definition.lane_outline.points
	for cut_x in cuts:
		check.call(definition.tee_position.x < cut_x and definition.hole_position.x > cut_x, "Separator lies between tee and cup")
		# Derive the playable cross-section from the actual resource, not
		# hard-coded widths. A diagonal wall excludes 7*sqrt2 in y;
		# a horizontal wall excludes radius5+half-wall2 = 7.
		var crossings: Array[Vector2] = []
		for index in range(polygon.size()):
			var a: Vector2 = polygon[index]
			var b: Vector2 = polygon[(index + 1) % polygon.size()]
			if cut_x > minf(a.x, b.x) and cut_x < maxf(a.x, b.x):
				var edge := b - a
				var y := a.y + (cut_x - a.x) * edge.y / edge.x
				var exclusion := (PrototypeBall.RADIUS + definition.lane_outline.wall_thickness * 0.5) * edge.length() / absf(edge.x)
				crossings.append(Vector2(y, exclusion))
		crossings.sort_custom(func(a, b): return a.x < b.x)
		check.call(crossings.size() == 2, "Exactly one playable channel at the separator")
		if crossings.size() != 2:
			continue
		var ball_min := crossings[0].x + crossings[0].y
		var ball_max := crossings[1].x - crossings[1].y
		check.call(ball_max > ball_min, "Positive ball clearance")
		# Merge the exact arrow intervals at a separator between tee and
		# cup. This is a continuous cut proof, not a coarse raster flood fill.
		var intervals: Array[Vector2] = []
		for tile in definition.arrow_tiles:
			var rect: Rect2 = tile.get_rect()
			if cut_x >= rect.position.x and cut_x < rect.end.x:
				intervals.append(Vector2(rect.position.y, rect.end.y))
		intervals.sort_custom(func(a, b): return a.x < b.x)
		var covered_until := ball_min
		for interval in intervals:
			if interval.y < covered_until:
				continue
			check.call(interval.x <= covered_until, "No neutral gap at mandatory cross-section")
			covered_until = maxf(covered_until, interval.y)
		check.call(covered_until >= ball_max, "Whole cross-section covered")
		print("MANDATORY_CUT ", definition.hole_id, " x=", cut_x, " ball_center_y=", Vector2(ball_min, ball_max), " covered_through=", covered_until)


static func _route(host: Node, definition: HoleDefinition, shots: Array) -> bool:
	var tree := host.get_tree()
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	tree.root.add_child(runtime)
	await tree.physics_frame
	var ball := PrototypeBall.new()
	tree.root.add_child(ball)
	ball.set_physics_process(false)
	ball.reset_to(definition.tee_position)
	ball.configure_environment(runtime.zones, runtime.get_hole_position(), runtime.get_tunnels())
	await tree.physics_frame
	var result := {"holed": false}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	for index in range(shots.size()):
		var direction: Vector2
		if shots[index][0] is Vector2:
			direction = ball.position.direction_to(shots[index][0])
		else:
			direction = Vector2.from_angle(deg_to_rad(float(shots[index][0])))
		ball.launch(direction, float(shots[index][1]), index + 1)
		for _step in range(1800):
			ball._physics_process(1.0 / 60.0)
			if not ball.moving:
				break
		if ball.position.distance_to(definition.hole_position) <= PrototypeBall.HOLE_RADIUS:
			await tree.create_timer(0.4).timeout
		if result["holed"]:
			break
	var completed: bool = result["holed"]
	if not completed:
		print("INTRO_ROUTE_FAILED ", definition.hole_id, " ", shots, " endpoint=", ball.position, " velocity=", ball.velocity)
	ball.free()
	runtime.free()
	await tree.physics_frame
	return completed


static func _cross_slope_contacts(host: Node, definition: HoleDefinition, check: Callable) -> void:
	var tree := host.get_tree()
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	tree.root.add_child(runtime)
	await tree.physics_frame
	var ball := PrototypeBall.new()
	tree.root.add_child(ball)
	ball.set_physics_process(false)
	ball.configure_environment(runtime.zones, runtime.get_hole_position(), runtime.get_tunnels())
	await tree.physics_frame
	for origin in [Vector2(352, 176), Vector2(480, 176)]:
		for direction in [Vector2.UP, Vector2.DOWN]:
			for speed in [78.0, 420.0]:
				ball.reset_to(origin)
				ball.launch(direction, speed, 1)
				for _step in range(1800):
					ball._physics_process(1.0 / 60.0)
					if not ball.moving:
						break
				var label := "Cross-slope/wall contact at %s dir%s speed%s" % [origin, direction, speed]
				check.call(not ball.moving, label + " reaches a playable rest state within 30 seconds")
				check.call(definition.lane_outline.contains_point(ball.position), label + " stays inside the course")
				if not ball.moving:
					var stopped_at := ball.position
					ball.launch(Vector2.RIGHT, 180.0, 2)
					for _step in range(1800):
						ball._physics_process(1.0 / 60.0)
						if not ball.moving:
							break
					check.call(ball.position.x > stopped_at.x + 16.0, label + " can be played onward after stopping")
	ball.free()
	runtime.free()
	await tree.physics_frame
