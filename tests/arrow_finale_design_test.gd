extends RefCounted

const FIELD_RECTS := [
	Rect2(264, 248, 32, 64), Rect2(328, 248, 32, 64),
	Rect2(552, 88, 16, 64), Rect2(600, 88, 16, 64),
	Rect2(696, 152, 16, 64), Rect2(760, 152, 16, 64),
	Rect2(952, 56, 32, 64), Rect2(1016, 56, 32, 64),
]
const FIELD_DIRECTIONS := [2, 1, 0, 5, 6, 4, 3, 7]


static func run(host: Node, check: Callable) -> void:
	print("\n[Armageddon: acht verpflichtende Gefaelleabschnitte]")
	var definition := LegacyCourseFixtures.holes().get_hole(&"arrow_armageddon_09")
	check.call(definition.validate().is_empty(), "Armageddon: neuer Zickzack-Grundriss ist kataloggueltig")
	check.call(definition.walls.is_empty() and definition.wall_tiles.is_empty(), "Armageddon: die geschlossene Kontur fuehrt den Weg ohne lose Innenhindernisse")
	check.call(definition.arrow_tiles.size() == 48, "Armageddon: 48 Zellen bilden acht kurze, getrennte Vollbreitenfelder")
	for index in range(FIELD_RECTS.size()):
		var field: Rect2 = FIELD_RECTS[index]
		var cells := definition.arrow_tiles.filter(func(tile): return field.encloses(tile.get_rect()))
		check.call(cells.size() == int(field.get_area() / 256) and cells.all(func(tile):
			return tile.direction == FIELD_DIRECTIONS[index] and tile.slope_grade == (1 if index % 2 == 0 else 2)
		), "Armageddon: Abschnitt %d hat seine eigene Richtung und Blau/Rot-Stufe" % (index + 1))
		check.call(_cuts_entire_floor(definition, field), "Armageddon: Abschnitt %d sperrt jeden neutralen Start-Ziel-Weg am kontinuierlichen Querschnitt" % (index + 1))
	# A dosed four-shot route, with a final putt adapted to the real resting
	# position. These are actual ball launches, not teleported waypoints.
	for angle in [-8.5, -8.0, -7.5]:
		for third_speed in [376.0, 380.0, 384.0]:
			check.call(await _play(host, definition, angle, third_speed),
				"Armageddon: PAR4 mit erstem Winkel %.1f und drittem Tempo %.0f durchquert alle acht Abschnitte" % [angle, third_speed])


static func _cuts_entire_floor(definition: HoleDefinition, field: Rect2) -> bool:
	# A turn may open beside one edge of a field. One fully closed cut
	# through its interior suffices; test both ends and the middle.
	for x in [field.position.x + 1.0, field.get_center().x, field.end.x - 1.0]:
		if _cut_at_x(definition, field, x): return true
	return false


static func _cut_at_x(definition: HoleDefinition, field: Rect2, x: float) -> bool:
	# This is an analytic cut, not a raster-path search: every continuous
	# start/goal path must cross this x. Intersect ALL outline edges, then
	# cover every possible ball-centre interval. The conservative 7px bound
	# leaves more candidates than a diagonal-wall clearance would permit.
	if not definition.tee_position.x < x or not x < definition.hole_position.x:
		return false
	var crossings: Array[float] = []
	var points := definition.lane_outline.get_floor_points()
	for index in range(points.size()):
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		if (a.x <= x and b.x > x) or (b.x <= x and a.x > x):
			crossings.append(lerpf(a.y, b.y, (x - a.x) / (b.x - a.x)))
	crossings.sort()
	if crossings.is_empty() or crossings.size() % 2 != 0:
		return false
	var clearance := PrototypeBall.RADIUS + definition.lane_outline.wall_thickness * 0.5
	for index in range(0, crossings.size(), 2):
		var low := crossings[index] + clearance
		var high := crossings[index + 1] - clearance
		if low <= high and (low < field.position.y or high >= field.end.y):
			return false
	return true


static func _play(host: Node, definition: HoleDefinition, first_angle: float, third_speed: float) -> bool:
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	host.get_tree().root.add_child(runtime)
	await host.get_tree().physics_frame
	var ball := PrototypeBall.new()
	host.get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.configure_environment(runtime.zones, definition.hole_position)
	ball.position = definition.tee_position
	var result := {"holed": false}
	ball.holed.connect(func(_n): result["holed"] = true)
	var seen := {}
	var legal := true
	var shots := [[first_angle, 340.0], [10.7, 200.0], [-6.4, third_speed], [definition.hole_position, 0.0]]
	for index in range(shots.size()):
		var aim = shots[index][0]
		var speed: float = shots[index][1]
		if speed == 0.0:
			speed = maxf(78.0, sqrt(240.0 * ball.position.distance_to(definition.hole_position)) + 10.0)
		legal = legal and speed >= 78.0 and speed <= 420.0 and not ball.moving
		var direction: Vector2 = ball.position.direction_to(aim) if aim is Vector2 else Vector2.from_angle(deg_to_rad(aim))
		ball.launch(direction, speed, index + 1)
		for _step in range(1800):
			ball._physics_process(1.0 / 60.0)
			legal = legal and definition.lane_outline.contains_point(ball.position)
			for field_index in range(FIELD_RECTS.size()):
				if FIELD_RECTS[field_index].has_point(ball.position): seen[field_index] = true
			if not ball.moving: break
		if ball.position.distance_to(definition.hole_position) < 0.001:
			await host.get_tree().create_timer(0.4).timeout
			break
	var completed: bool = result["holed"] and legal and seen.size() == 8 and ball.current_stroke_count <= definition.par
	if not completed: print("  Armageddon-Reserve ", first_angle, " / ", third_speed, " endet ", ball.position, " gesehen=", seen, " legal=", legal)
	ball.free()
	runtime.free()
	return completed
