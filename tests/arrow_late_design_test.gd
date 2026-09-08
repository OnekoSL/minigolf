extends RefCounted

# A continuous vertical cut separates tee and cup in these left-to-right holes.
# Covering every floor interval at that cut proves a required field cannot be
# bypassed, including sub-pixel neutral strips that a flood-fill could miss.
static func run(host: Node, check: Callable) -> void:
	print("\n[Staffel und Gegenstrom: verpflichtende Gefaelle]")
	var staffel: HoleDefinition = load("res://data/holes/arrow_armageddon_07.tres")
	var gegenstrom: HoleDefinition = load("res://data/holes/arrow_armageddon_08.tres")
	var fields: Array[Rect2] = [
		Rect2(280, 248, 64, 64), Rect2(424, 200, 64, 64),
		Rect2(600, 152, 64, 64), Rect2(776, 104, 64, 64),
	]
	var directions := [SurfaceZone.SlopeDirection.RIGHT, SurfaceZone.SlopeDirection.UP_RIGHT,
		SurfaceZone.SlopeDirection.RIGHT, SurfaceZone.SlopeDirection.UP_RIGHT]
	var grades := [SurfaceZone.SlopeGrade.SHALLOW, SurfaceZone.SlopeGrade.MEDIUM,
		SurfaceZone.SlopeGrade.MEDIUM, SurfaceZone.SlopeGrade.STEEP]
	check.call(staffel.validate().is_empty() and gegenstrom.validate().is_empty(), "Staffel und Gegenstrom bestehen die Ressourcenvalidierung")
	check.call(staffel.arrow_tiles.size() == 64 and staffel.surfaces.is_empty(), "Staffel verwendet ausschliesslich vier atomare 4x4-Pfeilfelder")
	for index in range(fields.size()):
		var rectangles: Array[Rect2] = []
		var correct := true
		for tile in staffel.arrow_tiles:
			if fields[index].encloses(tile.get_rect()):
				rectangles.append(tile.get_rect())
				correct = correct and tile.direction == directions[index] and tile.slope_grade == grades[index]
		check.call(rectangles.size() == 16 and correct, "Staffelfeld %d besitzt genau 16 Zellen in der vorgesehenen Richtung und Staerke" % (index + 1))
		check.call(_cut_is_covered(staffel, fields[index].get_center().x, rectangles), "Staffelfeld %d sperrt den gesamten kontinuierlichen Bahnquerschnitt ohne neutralen Randweg" % (index + 1))

	var water_count := 0
	var barrier_rects: Array[Rect2] = []
	for surface in gegenstrom.surfaces:
		water_count += int(surface.surface_type == SurfaceZone.SurfaceType.WATER)
		barrier_rects.append(surface.rect)
	var red_count := 0
	var red_directions_correct := true
	var expected_red := [SurfaceZone.SlopeDirection.DOWN, SurfaceZone.SlopeDirection.DOWN_LEFT,
		SurfaceZone.SlopeDirection.UP_LEFT, SurfaceZone.SlopeDirection.UP]
	for tile in gegenstrom.arrow_tiles:
		if tile.slope_grade != SurfaceZone.SlopeGrade.STEEP:
			continue
		red_count += 1
		barrier_rects.append(tile.get_rect())
		var row := int((tile.get_rect().position.y - 144.0) / 16.0)
		red_directions_correct = red_directions_correct and row >= 0 and row < 4 and tile.direction == expected_red[row]
	check.call(water_count == 2 and gegenstrom.surfaces.size() == 2, "Gegenstrom behaelt exakt zwei Wasserbecken")
	check.call(red_count == 48 and red_directions_correct, "Aeussere rote Reihen zeigen vom Wasser weg; mittlere Reihen bleiben schraeg links gegen Festhaengen")
	check.call(_cut_is_covered(gegenstrom, 656.0, barrier_rects), "Zwischen oberer und unterer Aussenwand bleibt nur der rote Kanal als wasserfreier Uebergang")
	check.call(not Geometry2D.is_point_in_polygon(Vector2(656, 286), gegenstrom.lane_outline.get_floor_points()), "Die nachgewiesene neutrale Unterwasser-Umgehung bei y286 liegt nicht mehr auf der Bahn")

	var routes := [
		[[Vector2(430, 235), 180.0], [Vector2(740, 160), 200.0], [Vector2(880, 130), 160.0], [Vector2(960, 70), 100.0]],
		[[Vector2(540, 176), 280.0], [Vector2(800, 176), 360.0], [Vector2(900, 260), 180.0], [Vector2(960, 286), 140.0]],
	]
	for index in range(2):
		var definition := staffel if index == 0 else gegenstrom
		var runtime := HoleRuntime.new()
		runtime.configure(definition)
		host.get_tree().root.add_child(runtime)
		var ball := PrototypeBall.new()
		host.get_tree().root.add_child(ball)
		ball.configure_environment(runtime.zones, definition.hole_position)
		var signals := {"holed": false, "water": false}
		ball.holed.connect(func(_strokes): signals.holed = true)
		ball.hazard_entered.connect(func(_kind): signals.water = true)
		await host.get_tree().physics_frame
		ball.set_physics_process(false)
		for factor in [1.0, 0.99, 1.01]:
			var result := await _route(host, ball, definition, routes[index], factor, signals)
			check.call(result.holed and not result.water and result.legal and result.shots <= definition.par, "%s: dosierte PAR4-Route locht tatsaechlich ein, auch mit %.0f Prozent Schlagstaerke" % [definition.display_name, factor * 100.0])
		if index == 1:
			signals.water = false
			var weak := _shot(ball, Vector2(540, 176), Vector2(800, 176), 160.0)
			check.call(weak.max_x > 600.0 and weak.max_x < 752.0 and weak.end.x < 540.0 and not weak.moving and not signals.water, "Ein zu schwacher legaler Schlag dringt in Rot ein, stoppt und rollt wasserfrei zurueck")
			signals.water = false
			var strong := _shot(ball, Vector2(540, 176), Vector2(800, 176), 320.0)
			check.call(strong.end.x > 752.0 and not strong.moving and not signals.water, "Ein ausreichend starker legaler Schlag ueberwindet den roten Gegenstrom wasserfrei")
			signals.water = false
			var seam := _shot(ball, Vector2(656, 176), Vector2(800, 176), 30.0)
			check.call(seam.end.x < 560.0 and not seam.moving and not signals.water, "Ein langsamer Ball auf der mittleren Pfeilnaht verlaesst das Feld nach links statt festzuhaengen")
		ball.free()
		runtime.free()
		await host.get_tree().physics_frame


static func _cut_is_covered(definition: HoleDefinition, x: float, rectangles: Array[Rect2]) -> bool:
	if not definition.tee_position.x < x or not x < definition.hole_position.x:
		return false
	var floor_points := definition.lane_outline.get_floor_points()
	var crossings: Array[float] = []
	for index in range(floor_points.size()):
		var start := floor_points[index]
		var end := floor_points[(index + 1) % floor_points.size()]
		if (start.x <= x and x < end.x) or (end.x <= x and x < start.x):
			crossings.append(lerpf(start.y, end.y, (x - start.x) / (end.x - start.x)))
	crossings.sort()
	if crossings.is_empty() or crossings.size() % 2 != 0:
		return false
	var intervals: Array[Vector2] = []
	for rect in rectangles:
		if rect.position.x <= x and x < rect.end.x:
			intervals.append(Vector2(rect.position.y, rect.end.y))
	intervals.sort_custom(func(a: Vector2, b: Vector2): return a.x < b.x)
	for index in range(0, crossings.size(), 2):
		var covered_to := crossings[index]
		for interval in intervals:
			if interval.x > covered_to + 0.00001:
				break
			covered_to = maxf(covered_to, interval.y)
		if covered_to < crossings[index + 1] - 0.00001:
			return false
	return true


static func _route(host: Node, ball: PrototypeBall, definition: HoleDefinition, shots: Array, factor: float, signals: Dictionary) -> Dictionary:
	signals.holed = false
	signals.water = false
	var point := definition.tee_position
	var count := 0
	var legal := true
	for shot in shots:
		var speed: float = shot[1] * factor
		legal = legal and speed >= 78.0 and speed <= 420.0
		var result := _shot(ball, point, shot[0], speed)
		point = result.end
		count += 1
		if signals.water or result.moving:
			break
		if point.distance_to(definition.hole_position) < 0.001:
			await host.get_tree().create_timer(0.45).timeout
			break
	return {"holed": signals.holed, "water": signals.water, "legal": legal, "shots": count}


static func _shot(ball: PrototypeBall, start: Vector2, target: Vector2, speed: float) -> Dictionary:
	ball.reset_to(start)
	ball.launch(start.direction_to(target), speed, 1)
	var max_x := start.x
	for _tick in range(1800):
		ball._physics_process(1.0 / 60.0)
		max_x = maxf(max_x, ball.position.x)
		if not ball.moving:
			break
	return {"end": ball.position, "moving": ball.moving, "max_x": max_x}
