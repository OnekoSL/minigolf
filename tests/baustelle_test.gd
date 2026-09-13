extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Die Baustelle: Beton, Tempo-Rohre und aktive Routen]")
	var catalog := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"baustelle_course")
	check.call(course != null and course.hole_ids.size() == 9 and course.best_score_revision == 1, "Baustelle hat neun eigene Bahnen und einen neuen Bestwertschluessel")
	await _test_concrete(host, check)
	await _test_pipes(host, check, catalog.get_hole(&"baustelle_03"))
	await _test_lifecycle(host, check, catalog.get_hole(&"baustelle_03"))
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/baustelle_routes.json"))
	for entry in entries:
		var hole := catalog.get_hole(StringName(entry.id))
		check.call(hole.base_surface == SurfaceZone.SurfaceType.CONCRETE and hole.validate().is_empty(), "%s besitzt gueltigen Beton und freie Rohrauslaeufe" % entry.id)
		for golfer in GolferDefinition.IDS:
			for variation in [Vector2(0,1), Vector2(-0.3,1), Vector2(0.3,1), Vector2(0,0.99), Vector2(0,1.01)]:
				var result := await LiveRouteRunner.play(host, hole, WorldRouteFixtures.route(entry, golfer, variation.x, variation.y), golfer)
				check.call(result.within_par and result.contact_delays.all(func(t): return t == 6) and result.pipe_transfers.size() == hole.pipe_systems.size() and result.pipe_transfers.all(func(t): return t.exit == 1), "%s: aktive PAR-Route %s, %.1f Grad / %.2f Kraft" % [entry.id, golfer, variation.x, variation.y])
				if not result.within_par:
					print("BAUSTELLE ROUTENLUECKE ", JSON.stringify(result))
		if hole.pipe_systems.is_empty():
			continue
		# Continuous wall coverage separates each inlet chamber from its exits.
		var x_positions: Array = [344.0]
		if entry.id == "baustelle_08": x_positions = [792.0]
		if entry.id == "baustelle_09": x_positions = [376.0, 728.0]
		for x in x_positions:
			check.call(_closed_partition(hole, x, 232.0 if entry.id == "baustelle_08" else 40.0, 328.0), "%s: Rohrpassage bei x=%.0f durchgehend geschlossen" % [entry.id, x])
	check.call(FileAccess.file_exists("res://tests/baustelle_recovery_routes.json"), "Fehlwegrouten sind Bestandteil der Kursabnahme")
	var recoveries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/baustelle_recovery_routes.json"))
	for entry in recoveries:
		var result := await LiveRouteRunner.play(host, catalog.get_hole(StringName(entry.id)), WorldRouteFixtures.route(entry))
		check.call(result.holed and result.within_limit and result.pipe_transfers.size() > int(entry.pipe) and result.pipe_transfers[int(entry.pipe)].exit == int(entry.exit), "%s Rohr %d Ausgang %d: vollstaendiger Fehlweg bleibt spielbar" % [entry.id, entry.pipe, entry.exit])
		if not result.holed: print("BAUSTELLE FEHLWEG ", JSON.stringify(result))


static func _test_concrete(host: Node, check: Callable) -> void:
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.set_physics_process(false)
	var distances: Array[float] = []
	for ground in [-1, SurfaceZone.SurfaceType.CONCRETE]:
		ball.configure_environment([], Vector2(20000,20000), [], [], ground)
		ball.reset_to(Vector2(3000,3000))
		ball.launch(Vector2.RIGHT, 240, 1)
		check.call(is_equal_approx(ball.velocity.length(),240), "Grundbelag veraendert die Abschlaggeschwindigkeit nicht")
		for tick in range(300): ball._physics_process(1.0/60.0)
		distances.append(ball.position.x - 3000)
	check.call(absf(distances[1]/distances[0] - 1.5) < 0.01 and not ball.moving, "Beton rollt rund 1,5-mal so weit und kommt sicher zur Ruhe")
	var sand := SurfaceDefinition.new()
	sand.rect = Rect2(2900,2900,400,200)
	var zone := sand.instantiate_zone()
	host.add_child(zone)
	ball.configure_environment([zone], Vector2(20000,20000), [], [], SurfaceZone.SurfaceType.CONCRETE)
	check.call(ball._surface_at(Vector2(3000,3000)).deceleration == 260 and ball._surface_at(Vector2(3400,3000)).deceleration == 80, "Sand ersetzt Beton lokal; ausserhalb greift wieder der Grundbelag")
	var meter := PowerDistanceMeter.new()
	for golfer in GolferDefinition.IDS:
		meter.set_golfer(GolferDefinition.get_golfer(golfer))
		for power in [0.0, 0.25, 0.5, 1.0]:
			var speed := lerpf(meter.minimum_ball_speed,meter.maximum_ball_speed,power)
			var expected := roundi(speed*speed/(2.0*120.0)/32.0*10.0)
			check.call(meter.distance_dm_for_power(power) == expected, "%s: Kraftanzeige bleibt bei %.2f auf ebenes Gruen geeicht" % [golfer,power])
	meter.free()
	zone.free()
	ball.free()


static func _test_pipes(host: Node, check: Callable, hole: HoleDefinition) -> void:
	var runtime := HoleRuntime.new()
	runtime.configure(hole)
	host.add_child(runtime)
	var ball := PrototypeBall.new()
	host.add_child(ball)
	ball.set_physics_process(false)
	runtime.configure_ball(ball)
	await host.get_tree().physics_frame
	var pipe := hole.pipe_systems[0]
	for speed in [27.8,139.99,140.0,140.01,259.99,260.0,260.01,520.0]:
		var expected := 0 if speed < 140 else (1 if speed < 260 else 2)
		ball.reset_to(pipe.entrance)
		ball.launch(Vector2.UP,speed,1)
		check.call(ball._try_pipe_capture(), "Rohr nimmt rollenden Ball mit %.2f px/s auf" % speed)
		check.call(ball._tunnel_exit_hole == pipe.exits[expected] and is_equal_approx(ball._tunnel_velocity.length(),speed), "%.2f px/s: richtiger Ausgang und unveraendertes Tempo" % speed)
		for tick in range(36): ball._physics_process(1.0/60.0)
		check.call(not ball.is_tunnel_sequence_active() and ball.position.is_equal_approx(pipe.exits[expected]+Vector2.RIGHT*13) and ball.velocity.is_equal_approx(Vector2.RIGHT*speed) and ball.current_stroke_count == 1, "Transport endet nach 0,6 s in freiem Auslauf ohne Zusatzschlag")
	for speed in [300.0,520.0]:
		ball.reset_to(pipe.entrance - Vector2(10,0))
		ball.launch(Vector2.RIGHT,speed,1)
		for tick in range(3):
			ball._physics_process(1.0/60.0)
			if ball.is_tunnel_sequence_active(): break
		check.call(ball.is_tunnel_sequence_active(), "Teilschritte erfassen schnelle Rohreinfahrt bei %.0f px/s" % speed)
	ball.reset_to(pipe.entrance + Vector2(0,9))
	ball.launch(Vector2.RIGHT,200,1)
	check.call(not ball._try_pipe_capture(), "Knapp verfehlte Rohrmuendung nimmt den Ball nicht auf")
	for outlet in pipe.exits:
		ball.reset_to(outlet)
		ball.launch(Vector2.LEFT,200,1)
		check.call(not ball._try_pipe_capture(), "Ausgaenge nehmen rueckwaerts rollende Baelle nicht auf")
	ball.reset_to(pipe.entrance)
	check.call(not ball._try_pipe_capture(), "Ein ruhender Ball startet keinen automatischen Rohrtransport")
	ball.reset_to(Vector2(320,168))
	ball.launch(Vector2.RIGHT,300,1)
	for tick in range(60):
		ball._physics_process(1.0/60.0)
		if ball.is_tunnel_sequence_active(): break
	check.call(ball.is_tunnel_sequence_active() and ball._tunnel_exit_hole == pipe.exits[1] and ball._tunnel_velocity.length() < 260, "Bandenkontakt reduziert das Eintrittstempo und aendert den Rohrausgang")
	var sand := SurfaceDefinition.new()
	sand.rect = Rect2(216,140,70,56)
	var zone := sand.instantiate_zone()
	host.add_child(zone)
	ball.configure_environment([zone],hole.hole_position,[],[],hole.base_surface,hole.pipe_systems)
	ball.reset_to(Vector2(226,168))
	ball.launch(Vector2.RIGHT,300,1)
	for tick in range(60):
		ball._physics_process(1.0/60.0)
		if ball.is_tunnel_sequence_active(): break
	check.call(ball.is_tunnel_sequence_active() and ball._tunnel_exit_hole == pipe.exits[1] and ball._tunnel_velocity.length() < 260, "Sand vor der Muendung wirkt auf die Rohrwahl, nicht die urspruengliche Schlagstaerke")
	zone.free()
	var invalid := hole.duplicate(true) as HoleDefinition
	invalid.pipe_systems[0].exits[0] = Vector2(344,80)
	check.call(not invalid.validate().is_empty(), "Validator erkennt eine Rohrmuendung in einer Wand")
	invalid = hole.duplicate(true) as HoleDefinition
	invalid.pipe_systems[0].exit_directions[0] = Vector2.ZERO
	check.call(not invalid.validate().is_empty(), "Validator erkennt eine fehlende Austrittsrichtung")
	invalid = hole.duplicate(true) as HoleDefinition
	invalid.pipe_systems[0].exits.resize(2)
	check.call(not invalid.validate().is_empty(), "Validator verlangt genau drei Ausgaenge")
	invalid = hole.duplicate(true) as HoleDefinition
	invalid.pipe_systems[0].exits[0] = Vector2(595,80)
	check.call(not invalid.validate().is_empty(), "Validator erkennt eine freie Muendung mit anschliessend blockiertem Auslauf")
	invalid = hole.duplicate(true) as HoleDefinition
	var second_pipe := PipeSystemDefinition.new()
	second_pipe.entrance = invalid.pipe_systems[0].exits[0] + Vector2(24,0)
	second_pipe.exits = PackedVector2Array([Vector2(240,80),Vector2(240,224),Vector2(240,280)])
	second_pipe.exit_directions = PackedVector2Array([Vector2.RIGHT,Vector2.RIGHT,Vector2.RIGHT])
	invalid.pipe_systems.append(second_pipe)
	check.call(not invalid.validate().is_empty(), "Validator verhindert direkten Wiedereintritt hinter einer Rohrmuendung")
	ball.free()
	runtime.free()


static func _test_lifecycle(host: Node, check: Callable, hole: HoleDefinition) -> void:
	var game := (load("res://scenes/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	game.configure_attempt(hole, PlayerProfile.create(1,"TEST",0), true, 1, 9, 0, true)
	host.add_child(game)
	await host.get_tree().physics_frame
	var ball := game.ball
	var pipe := hole.pipe_systems[0]
	ball.reset_to(pipe.entrance)
	ball.launch(Vector2.RIGHT,190,1)
	ball._try_pipe_capture()
	game.set_external_paused(true)
	host.get_tree().paused = true
	var elapsed := ball._tunnel_elapsed
	for tick in range(40): await host.get_tree().physics_frame
	check.call(ball.is_tunnel_sequence_active() and ball._tunnel_elapsed == elapsed, "Pause friert den Rohrtransport ein")
	host.get_tree().paused = false
	game.set_external_paused(false)
	game.restart_hole()
	for tick in range(45): await host.get_tree().physics_frame
	check.call(not ball.is_tunnel_sequence_active() and not ball.moving and ball.position == hole.tee_position and ball.collision_mask == 2, "Neustart verwirft den Transport ohne spaeten Ausstoss")
	var outcome := {"finished":false,"capped":false}
	game.attempt_finished.connect(func(_count,capped): outcome.finished = true; outcome.capped = capped)
	game.strokes = RoundSession.stroke_limit_for_par(hole.par)
	ball.reset_to(pipe.entrance)
	ball.launch(Vector2.RIGHT,190,game.strokes)
	ball._try_pipe_capture()
	for tick in range(200):
		await host.get_tree().physics_frame
		if outcome.finished: break
	check.call(outcome.finished and not outcome.capped, "Letzter erlaubter Schlag wird erst nach Rohrtransport und Einlochen gewertet")
	game.restart_hole()
	ball.reset_to(pipe.entrance)
	ball.launch(Vector2.RIGHT,190,1)
	ball._try_pipe_capture()
	game.switch_test_hole()
	for tick in range(45): await host.get_tree().physics_frame
	check.call(not ball.is_tunnel_sequence_active() and not ball.moving and ball.position == game.hole.get_tee_position(), "Bahnwechsel verwirft einen laufenden Transport")
	# Switching back to a grass hole replaces both the base material and pipe list.
	game.active_hole_index = game.hole_catalog.holes.size() - 1
	game.switch_test_hole()
	check.call(ball.base_surface == -1 and ball.pipe_systems.is_empty(), "Wechsel von Beton auf Gruen hinterlaesst weder Betonphysik noch alte Rohre")
	game.queue_free()
	await host.get_tree().process_frame


static func _closed_partition(hole: HoleDefinition, x: float, start: float, end: float) -> bool:
	var intervals: Array[Vector2] = []
	for piece in hole.get_normalized_wall_network():
		for segment in piece["segments"]:
			if is_equal_approx(segment[0].x,x) and is_equal_approx(segment[1].x,x):
				intervals.append(Vector2(minf(segment[0].y,segment[1].y),maxf(segment[0].y,segment[1].y)))
	intervals.sort_custom(func(a: Vector2,b: Vector2): return a.x < b.x)
	var covered := start
	for interval in intervals:
		if interval.x > covered + 0.01: return false
		covered = maxf(covered,interval.y)
		if covered >= end: return true
	return false
