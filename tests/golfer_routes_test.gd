extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Golfer: legale Routen bei geringerer Reichweite]")
	var fixtures: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golfer_routes.json"))
	for fixture in fixtures:
		var shots: Array[RouteShot] = []
		for entry in fixture.shots:
			var shot := RouteShot.new(Vector2(entry.target[0], entry.target[1]), entry.speed)
			if entry.angle != null:
				shot.angle_degrees = entry.angle
			shots.append(shot)
		var hole := LegacyCourseFixtures.holes().get_hole(StringName(fixture.hole_id))
		var result := await LiveRouteRunner.play(host, hole, shots, StringName(fixture.golfer))
		check.call(result.holed and result.within_limit, "%s: %s mit legalen Kraeften und echten Kontakten eingelocht" % [fixture.golfer, fixture.hole_id])
		check.call(result.contact_delays.all(func(ticks): return ticks == 6), "Jeder Routenschlag startet nach sechs Physikticks")
	var hole := LegacyCourseFixtures.holes().get_hole(&"labyrinth_nine_05")
	var result := await LiveRouteRunner.play(host, hole, LabyrinthRoutes.live_route(hole.hole_id, 150), &"mara")
	check.call(result.holed and result.within_par, "Mara bewaeltigt Diagonalfalle mit aktiven Hindernissen innerhalb PAR")
