extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Zirkus: aktive Routen und Elefantentransport]")
	var catalog := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"zirkus_course")
	check.call(course != null and course.hole_ids.size() == 9 and course.get_total_par(catalog) == 29, "Zirkus: neun Bahnen, PAR 29")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/circus_routes.json"))
	for entry in entries:
		var variants := [[&"allrounder",0.0,1.0],[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],
			[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]]
		for variant in variants:
			var result := await LiveRouteRunner.play(host,catalog.get_hole(StringName(entry.id)),WorldRouteFixtures.route(entry,variant[0],variant[1],variant[2]),variant[0])
			check.call(result.within_par and result.contact_delays.all(func(t): return t == 6), "%s: aktive PAR-Route %s, Winkel %.1f, Kraft %.2f" % [entry.id,variant[0],variant[1],variant[2]])
			if entry.id == "zirkus_05" and variant == [&"allrounder",0.0,1.0]:
				check.call(result.holed and result.strokes == 1, "Mittige Aufnahme an der Spitze erlaubt weiterhin ein Ass")
			if not result.within_par: print("ZIRKUS ROUTENLUECKE ",JSON.stringify(result))
	# Real long route with trunk and tail active, never using the intake.
	var normal: Array[RouteShot] = [RouteShot.new(Vector2(600,280),300,240),RouteShot.new(Vector2(1000,280),300),RouteShot.new(Vector2(960,72),220),RouteShot.new(Vector2(220,56),420)]
	var result := await LiveRouteRunner.play(host,catalog.get_hole(&"zirkus_05"),normal)
	check.call(result.within_par and result.trace.size() == 4 and result.trace[1].position[0] > 900 and result.trace[2].position[1] < 90, "Elefant: normale Umrundung ohne Abkuerzung mit aktiven Sperren in PAR")
	await _test_elephant(host,check,catalog.get_hole(&"zirkus_05"))
	await load("res://tests/elephant_gap_test.gd").run(host,check)


static func _test_elephant(host: Node, check: Callable, definition: HoleDefinition) -> void:
	var game := (load("res://scenes/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
	game.configure_attempt(definition,PlayerProfile.create(1,"TEST",0),true,1,9,0,true)
	host.add_child(game)
	await host.get_tree().physics_frame
	var elephant := game.hole.obstacle_nodes[0] as ElephantObstacle
	var ball := game.ball
	var outcome := {"finished":false,"capped":false,"count":0}
	game.attempt_finished.connect(func(count, capped): outcome.finished = true; outcome.capped = capped; outcome.count = count)
	ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(0,-14)))
	ball.current_stroke_count = 1
	ball.moving = true
	ball.velocity = Vector2.RIGHT * 100
	elephant.advance_motion(0.5)
	check.call(ball.is_tunnel_sequence_active(), "Elefant saugt auch einen rollenden Ball im Spalt an der Spitze auf")
	game.restart_hole()
	ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(-20,-14)))
	check.call(not elephant.try_capture_resting_ball(ball), "Knapp verfehlte Aufnahme bleibt normal spielbar")
	for phase in [0.0,0.5,1.0,2.0,3.0,3.5,4.0,5.0]:
		elephant.reset_motion()
		elephant.advance_motion(maxf(phase,0.001))
		# Inspect the shared physical rectangles in open and shut end states.
		if phase == 2.0:
			check.call(is_equal_approx(elephant.trunk.position.y,112), "Abgesenkter Ruessel schliesst den gesamten unteren Korridor")
		if phase == 5.0:
			check.call(elephant.trunk.position.y + 32 < 248 - elephant.position.y - PrototypeBall.RADIUS, "Gehobener Ruessel gibt die gesamte Ballbreite frei")
	# Sideways placement changes the real exit trajectory deterministically.
	var velocities: Array[Vector2] = []
	for attempt in range(2):
		game.restart_hole()
		ball.current_stroke_count = 1
		ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(6,-14)))
		ball._finish_stopped()
		for tick in range(500):
			await host.get_tree().physics_frame
			if not ball.is_tunnel_sequence_active(): break
		velocities.append(ball.velocity)
		check.call(ball.velocity.x < 0 and absf(ball.velocity.y) > 10 and ball.collision_mask == 2 and definition.lane_outline.contains_point(ball.position), "Seitliche Ablage erzeugt eine freie, schraege Ausstossbahn")
	check.call(velocities[0].is_equal_approx(velocities[1]), "Gleiche Ablage ergibt denselben Ausstoss ohne Zufall")
	# A pending swing must be cancelled when a settled ball is claimed.
	for state in [ShotController.ShotState.POWER,ShotController.ShotState.ACCURACY,ShotController.ShotState.ARMED,ShotController.ShotState.SWINGING]:
		game.restart_hole()
		ball.current_stroke_count = 1
		ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(0,-14)))
		game.shot_controller._set_state(state)
		ball._finish_stopped()
		check.call(ball.is_tunnel_sequence_active() and game.shot_controller.state == ShotController.ShotState.BALL_MOVING, "Aufnahme bricht Schlagvorbereitung %d ohne Zusatzschlag ab" % state)
		game.shot_controller.action_released()
		check.call(game.strokes == 0, "Loslassen nach Aufnahme startet keinen verspaeteten Schlag")
	game.restart_hole()
	game.strokes = game.get_stroke_limit()
	ball.current_stroke_count = game.strokes
	ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(0,-14)))
	ball._finish_stopped()
	check.call(ball.is_tunnel_sequence_active() and not game._attempt_reported, "Letzter erlaubter Schlag beginnt Aufnahme vor der Limitwertung")
	var elapsed_before := elephant.elapsed
	var position_before := ball.position
	host.get_tree().paused = true
	for tick in range(10): await host.get_tree().physics_frame
	check.call(elephant.elapsed == elapsed_before and ball.position == position_before, "Pause friert Reservierung, Ball und Elefant gemeinsam ein")
	host.get_tree().paused = false
	for tick in range(800):
		await host.get_tree().physics_frame
		if outcome.finished: break
	check.call(outcome.finished and not outcome.capped and outcome.count == game.get_stroke_limit(), "Letzter Schlag endet nach dem Ausstoss regulaer im Loch")
	game.restart_hole()
	ball.current_stroke_count = 1
	ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(0,-14)))
	ball._finish_stopped()
	game.restart_hole()
	for tick in range(400): await host.get_tree().physics_frame
	check.call(not ball.is_tunnel_sequence_active() and ball.position == definition.tee_position and ball.collision_mask == 2 and ball.scale == Vector2.ONE, "Neustart verwirft wartenden Transport dauerhaft und stellt Ballkollision wieder her")
	ball.current_stroke_count = 1
	ball.reset_to(elephant.to_global(elephant.intake_position + Vector2(0,-14)))
	ball._finish_stopped()
	game.switch_test_hole()
	for tick in range(400): await host.get_tree().physics_frame
	check.call(not ball.is_tunnel_sequence_active() and ball.position == game.hole.get_tee_position(), "Bahnwechsel verwirft Aufnahme und alte Elefantenreferenzen")
	game.queue_free()
	await host.get_tree().process_frame
