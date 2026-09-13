extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Saeulenhof: Hindernisse und Bandenroute]")
	var hole := HoleCatalog.load_default().get_hole(&"tempelruinen_02")
	check.call(hole.walls.size() == 10 and hole.walls.all(func(w): return w.wall_type == WallDefinition.WallType.CIRCLE),
		"Saeulenhof besitzt zehn massive Kreissaeulen")
	for center in [Vector2(280,176),Vector2(496,176)]:
		var pattern := true
		for offset in [Vector2.ZERO,Vector2(-64,-64),Vector2(64,-64),Vector2(-64,64),Vector2(64,64)]:
			pattern = pattern and hole.walls.any(func(w): return w.center.is_equal_approx(center+offset))
		check.call(pattern,"Kammer bei %s zeigt die symmetrische Wuerfel-Fuenf" % center)
	var entry_blocked := hole.walls.any(func(w): return Geometry2D.get_closest_point_to_segment(w.center,hole.tee_position,hole.tunnels[0].endpoint_a).distance_to(w.center) < w.radius + PrototypeBall.RADIUS)
	check.call(entry_blocked,"Die mittlere Saeule sperrt auch die Direktlinie zum Tunneleingang")
	var exit := hole.tunnels[0].endpoint_b
	var blocked := hole.walls.any(func(w): return Geometry2D.get_closest_point_to_segment(w.center,exit,hole.hole_position).distance_to(w.center) < w.radius + PrototypeBall.RADIUS)
	check.call(blocked,"Eine Saeule sperrt die direkte Linie vom Tunnelausgang zum Zielloch")
	var clear := true
	for wall in hole.walls:
		for point in [hole.tee_position,hole.hole_position,hole.tunnels[0].endpoint_a,exit]:
			clear = clear and point.distance_to(wall.center) > wall.radius + 13.0 + PrototypeBall.RADIUS
	check.call(clear,"Abschlag, Ziel und beide Tunnelauslaeufe bleiben mit Ballradius frei")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	for entry in entries:
		if entry.id != "tempelruinen_02": continue
		for test_case in [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]:
			var route := WorldRouteFixtures.route(entry,test_case[0],test_case[1],test_case[2])
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t == 6),
				"Saeulenhof PAR 2: %s, Winkel %+.1f, Kraft %.2f" % test_case)
			if not result.within_par: print(JSON.stringify(result))
		for variation in [Vector2(-0.3,1),Vector2(0.3,1),Vector2(0,0.99),Vector2(0,1.01)]:
			var route := WorldRouteFixtures.route(entry)
			var stop := Vector2(442.4,130.3)
			route[1].target = stop + (route[1].target-stop).rotated(deg_to_rad(variation.x))
			route[1].speed *= variation.y
			var result := await LiveRouteRunner.play(host,hole,route)
			check.call(result.within_par,"Zielputt vertraegt Winkel %+.1f, Kraft %.2f" % [variation.x,variation.y])
