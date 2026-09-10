extends "res://tests/test_support.gd"


func _test_rotating_obstacle_wakes_ball() -> void:
	print("\n[Bewegliches Hindernis]")
	var obstacle := RotatingObstacle.new()
	obstacle.position = Vector2(100, 100)
	get_tree().root.add_child(obstacle)
	var ball := PrototypeBall.new()
	ball.position = Vector2(100, 125)
	get_tree().root.add_child(ball)
	var result := {"woken": false, "windmill_feedback": false}
	ball.external_motion_started.connect(func(): result["woken"] = true)
	ball.wall_hit.connect(func(_intensity, _position, _normal, kind):
		if kind == &"windmill":
			result["windmill_feedback"] = true
	)
	await get_tree().create_timer(1.2).timeout
	_check(result["woken"], "Dreher setzt auch einen ruhenden Ball in Bewegung")
	_check(result["windmill_feedback"], "Dreherkontakt meldet Position, Normale und Hindernistyp fuer Feedback")
	obstacle.queue_free()
	ball.queue_free()
	await get_tree().process_frame


func _test_timed_gate() -> void:
	print("\n[Zeitgesteuertes Doppeltor]")
	_check(is_zero_approx(TimedSlidingGate.openness_at_time(0.0, 2.8, 0.25, 1.0)), "Tor startet vollstaendig geschlossen")
	_check(is_equal_approx(TimedSlidingGate.openness_at_time(1.425, 2.8, 0.25, 1.0), 0.5), "Tor oeffnet innerhalb von 0,25 Sekunden linear")
	_check(is_equal_approx(TimedSlidingGate.openness_at_time(1.55, 2.8, 0.25, 1.0), 1.0), "Tor erreicht die vollstaendig offene Position")
	_check(
		is_equal_approx(TimedSlidingGate.openness_at_time(1.55, 2.8, 0.25, 1.0), 1.0)
		and is_equal_approx(TimedSlidingGate.openness_at_time(1.80, 2.8, 0.25, 1.0), 1.0)
		and is_equal_approx(2.30 - 1.55, 0.75),
		"Beide Phasen besitzen ein gemeinsames offenes Zeitfenster von 0,75 Sekunden"
	)
	var gate := TimedSlidingGate.new()
	gate.position = Vector2(300, 180)
	gate.open_offset = Vector2(0, -100)
	gate.set_physics_process(false)
	get_tree().root.add_child(gate)
	await get_tree().process_frame
	var closed := gate.closed_position
	gate.advance_motion(1.60)
	await get_tree().physics_frame
	_check(gate.position.is_equal_approx(closed + gate.open_offset), "Torbewegung erreicht reproduzierbar den offenen Anschlag")
	gate.reset_motion()
	_check(gate.position.is_equal_approx(closed), "Torreset stellt die definierte Ausgangsphase wieder her")
	var test_ball := PrototypeBall.new()
	get_tree().root.add_child(test_ball)
	var feedback := {"kind": &""}
	test_ball.wall_hit.connect(func(_intensity, _position, _normal, kind): feedback["kind"] = kind)
	var moved := test_ball.apply_moving_obstacle_contact(Vector2(120, 0), Vector2.RIGHT, 1.0, 0.0, &"gate")
	_check(moved and test_ball.moving and test_ball.velocity.x > 0.0, "Schliessendes Tor bewegt einen ruhenden Ball aus der Kollision")
	_check(feedback["kind"] == &"gate", "Torkontakt meldet den eigenen Feedbacktyp")
	var closed_bounce := PrototypeBall.resolve_rotating_obstacle_collision(Vector2(140, 0), Vector2.LEFT, Vector2.ZERO, 0.82, 1.0, 0.0)
	_check(closed_bounce.x < 0.0, "Geschlossenes Tor reflektiert den Ball zur Wartezone")
	test_ball.free()
	gate.free()


func _test_seesaw_obstacle() -> void:
	print("\n[Gewichtsgesteuerte Wippe]")
	var seesaw := SeesawObstacle.new()
	seesaw.position = Vector2(300, 180)
	seesaw.response_seconds = 0.35
	get_tree().root.add_child(seesaw)
	await get_tree().process_frame
	seesaw.set_physics_process(false)
	seesaw.reset_motion()
	seesaw.advance_tilt(0.35, -30.0)
	_check(is_equal_approx(seesaw.tilt, -1.0) and seesaw.get_surface_data().acceleration.x < 0.0, "Ballgewicht links senkt die linke Wippenhaelfte")
	_check(seesaw.is_right_end_blocking() and not seesaw.is_left_end_blocking(), "Abgesenkte linke Wippenseite hebt die rechte Sperrkante")
	seesaw.advance_tilt(0.70, 30.0)
	_check(is_equal_approx(seesaw.tilt, 1.0) and seesaw.get_surface_data().acceleration.x > 0.0, "Ballgewicht rechts kippt Gefaelle und Beschleunigung nach rechts")
	_check(seesaw.is_left_end_blocking() and not seesaw.is_right_end_blocking(), "Abgesenkte rechte Wippenseite hebt die linke Sperrkante")
	seesaw.reset_motion()
	_check(is_equal_approx(seesaw.tilt, -1.0) and seesaw.get_surface_data().acceleration.x < 0.0 and seesaw.is_right_end_blocking(), "Wippenreset stellt die linke Vorzugsposition wieder her")
	_check(
		(seesaw.left_end_collision.shape as RectangleShape2D).size.y < (seesaw.right_end_collision.shape as RectangleShape2D).size.y,
		"Abgesenkte Wippenseite wirkt perspektivisch kleiner als die angehobene Seite"
	)
	_check(seesaw.contains_global_point(Vector2(270, 180)) and seesaw.contains_global_point(Vector2(330, 180)) and not seesaw.contains_global_point(Vector2(355, 180)), "Wippe besteht aus zwei befahrbaren Flaechen um den Mittelpunkt")
	seesaw.advance_tilt(0.35, -30.0)
	await get_tree().physics_frame
	var test_ball := PrototypeBall.new()
	get_tree().root.add_child(test_ball)
	await get_tree().physics_frame
	test_ball.set_physics_process(false)
	test_ball.position = Vector2(320, 180)
	var seesaw_zones: Array[SurfaceZone] = [seesaw]
	test_ball.configure_environment(seesaw_zones, Vector2(500, 180))
	var lip_feedback := {"kind": &"", "velocity_x": 0.0}
	test_ball.wall_hit.connect(func(_intensity, _position, _normal, kind):
		lip_feedback["kind"] = kind
		if kind == &"seesaw_lip":
			lip_feedback["velocity_x"] = test_ball.velocity.x
	)
	test_ball.launch(Vector2.RIGHT, 180.0, 1)
	for _step in range(20):
		test_ball._physics_process(1.0 / 60.0)
		if not test_ball.moving:
			break
	_check(test_ball.position.x < 348.0 and lip_feedback["kind"] == &"seesaw_lip" and float(lip_feedback["velocity_x"]) < -1.0, "Hohe Wippenkante wirft einen schnellen Ball mit umgekehrter Geschwindigkeit zurueck")
	seesaw.advance_tilt(0.70, 30.0)
	await get_tree().physics_frame
	test_ball.reset_to(Vector2(320, 180))
	test_ball.launch(Vector2.RIGHT, 180.0, 1)
	for _step in range(20):
		test_ball._physics_process(1.0 / 60.0)
	_check(test_ball.position.x > 354.0, "Abgesenkte Wippenkante gibt den Ausgang frei")
	seesaw.advance_tilt(0.35, 0.0)
	await get_tree().physics_frame
	lip_feedback["kind"] = &""
	test_ball.reset_to(Vector2(300, 100))
	test_ball.launch(Vector2.DOWN, 180.0, 1)
	for _step in range(30):
		test_ball._physics_process(1.0 / 60.0)
	_check(test_ball.position.y < 143.0 and lip_feedback["kind"] == &"seesaw_side", "Ball prallt an den beiden seitlichen Wippenbanden ab")
	seesaw.reset_motion()
	await get_tree().physics_frame
	test_ball.reset_to(Vector2(240, 180))
	test_ball.launch(Vector2.RIGHT, 120.0, 1)
	for _step in range(30):
		test_ball._physics_process(1.0 / 60.0)
	var entered_from_front := test_ball.position.x > 270.0
	test_ball.reset_to(Vector2(360, 180))
	lip_feedback["velocity_x"] = 0.0
	test_ball.launch(Vector2.LEFT, 120.0, 1)
	for _step in range(20):
		test_ball._physics_process(1.0 / 60.0)
	_check(entered_from_front and float(lip_feedback["velocity_x"]) > 1.0 and test_ball.position.x > 350.0, "Nur die abgesenkte Vorderseite erlaubt Einstieg; die hohe Rueckseite reflektiert den Ball")
	test_ball.free()
	seesaw.free()
	await _test_seesaw_dynamic_end_contacts()
	await _test_seesaw_live_end_activation()


func _test_seesaw_dynamic_end_contacts() -> void:
	for rotation_degrees in [0.0, 90.0, 180.0, 270.0]:
		for travel_sign in [-1.0, 1.0]:
			for delta in [1.0 / 60.0, 1.0 / 30.0]:
				for speed in [420.0, 520.0]:
					var result := await _simulate_seesaw_end_contact(rotation_degrees, travel_sign, speed, delta)
					var label := "Wippe %.0f Grad, Richtung %+.0f, Tempo %.0f, %.0f Hz" % [rotation_degrees, travel_sign, speed, 1.0 / delta]
					_check(
						int(result["lip_hits"]) > 0 and float(result["first_lip_velocity"]) < -1.0,
						"%s reflektiert den starken Anspielball am noch angehobenen Ausgang" % label
					)
					_check(
						float(result["maximum_progress"]) < 48.0
							and not bool(result["crossed_closed_exit"])
							and not bool(result["still_moving"]),
						"%s passiert die Ausgangsebene waehrend der gesamten Fahrt nicht" % label
					)
				var slow_result := await _simulate_seesaw_end_contact(rotation_degrees, travel_sign, 170.0, delta)
				_check(
					float(slow_result["maximum_progress"]) > 60.0
						and bool(slow_result["exit_lowered_before_crossing"])
						and not bool(slow_result["crossed_closed_exit"]),
					"Wippe %.0f Grad, Richtung %+.0f, %.0f Hz laesst einen dosierten Ball nach dem gewichtsgesteuerten Absenken ausrollen" % [rotation_degrees, travel_sign, 1.0 / delta]
				)
			for initial_tilt in [-0.1, 0.0, 0.1]:
				var neutral_result := await _simulate_seesaw_end_contact(rotation_degrees, travel_sign, 180.0, 1.0 / 60.0, initial_tilt)
				_check(
					bool(neutral_result["both_neutral_ends_closed"])
						and int(neutral_result["lip_hits"]) > 0
						and float(neutral_result["first_lip_velocity"]) < -1.0
						and float(neutral_result["maximum_progress"]) < 48.0,
					"Wippe %.0f Grad, Richtung %+.0f, Neigung %+.1f haelt beide Stirnseiten geschlossen und reflektiert" % [rotation_degrees, travel_sign, initial_tilt]
				)


func _simulate_seesaw_end_contact(rotation_degrees: float, travel_sign: float, speed: float, delta: float, neutral_tilt := INF) -> Dictionary:
	var seesaw := SeesawObstacle.new()
	seesaw.position = Vector2(300, 180)
	seesaw.rotation_degrees = rotation_degrees
	seesaw.preferred_tilt = -travel_sign
	get_tree().root.add_child(seesaw)
	seesaw.set_physics_process(false)
	seesaw.reset_motion()
	var neutral_contact := not is_inf(neutral_tilt)
	if neutral_contact:
		seesaw.tilt = neutral_tilt
		seesaw.target_tilt = 0.0
	seesaw.sync_end_blockers(true)
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	var starting_progress := 20.0 if neutral_contact else -60.0
	ball.position = seesaw.to_global(Vector2(starting_progress * travel_sign, 0.0))
	var zones: Array[SurfaceZone] = [seesaw]
	ball.configure_environment(zones, Vector2(-2000, -2000))
	var travel_direction := Vector2.RIGHT.rotated(seesaw.global_rotation) * travel_sign
	var result := {
		"lip_hits": 0,
		"first_lip_velocity": 0.0,
		"maximum_progress": starting_progress,
		"crossed_closed_exit": false,
		"exit_lowered_before_crossing": false,
		"both_neutral_ends_closed": seesaw.is_left_end_blocking() and seesaw.is_right_end_blocking(),
		"still_moving": false,
	}
	ball.wall_hit.connect(func(_intensity, _position, _normal, kind):
		if kind == &"seesaw_lip":
			if int(result["lip_hits"]) == 0:
				result["first_lip_velocity"] = ball.velocity.dot(travel_direction)
			result["lip_hits"] = int(result["lip_hits"]) + 1
	)
	await get_tree().physics_frame
	ball.launch(travel_direction, speed, 1)
	var previous_progress := starting_progress
	for _step in range(ceili(8.0 / delta)):
		var weighted_local_x := seesaw.to_local(ball.global_position).x if seesaw.contains_global_point(ball.global_position) else INF
		seesaw.advance_tilt(delta, 0.0 if neutral_contact else weighted_local_x)
		seesaw.sync_end_blockers(true)
		var exit_blocked := seesaw.is_right_end_blocking() if travel_sign > 0.0 else seesaw.is_left_end_blocking()
		if neutral_contact:
			result["both_neutral_ends_closed"] = bool(result["both_neutral_ends_closed"]) and seesaw.is_left_end_blocking() and seesaw.is_right_end_blocking()
		ball._physics_process(delta)
		var progress := seesaw.to_local(ball.global_position).x * travel_sign
		result["maximum_progress"] = maxf(float(result["maximum_progress"]), progress)
		if previous_progress <= seesaw.plank_size.x * 0.5 and progress > seesaw.plank_size.x * 0.5:
			if exit_blocked:
				result["crossed_closed_exit"] = true
			else:
				result["exit_lowered_before_crossing"] = true
		previous_progress = progress
		if not ball.moving:
			break
	result["still_moving"] = ball.moving
	ball.free()
	seesaw.free()
	return result


func _test_seesaw_live_end_activation() -> void:
	var cases: Array[Dictionary] = []
	for rotation_degrees in [0.0, 90.0, 180.0, 270.0]:
		for travel_sign in [-1.0, 1.0]:
			for activation in [&"close_threshold", &"reset"]:
				for lateral_offset in [-16.0, 0.0, 16.0]:
					cases.append(_create_seesaw_live_activation_case(
						rotation_degrees, travel_sign, activation, lateral_offset,
						Vector2(5000.0 + cases.size() * 1000.0, 1000.0)
					))
	# Let the previously open shape become active in the physics server before
	# changing its state immediately ahead of a real physics tick.
	await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	for entry in cases:
		var seesaw: SeesawObstacle = entry["seesaw"]
		var ball: PrototypeBall = entry["ball"]
		seesaw.preferred_tilt = float(entry["travel_sign"])
		if entry["activation"] == &"reset":
			seesaw.reset_motion()
		seesaw.set_physics_process(true)
		ball.set_physics_process(true)
		ball.launch(entry["travel_direction"], 520.0, 1)
	# No manual tilt advance or collision synchronization: the Area and the
	# normal _physics_process callbacks must close the lip before the ball moves.
	for _frame in range(24):
		await get_tree().physics_frame
		await get_tree().process_frame
		for entry in cases:
			var seesaw: SeesawObstacle = entry["seesaw"]
			var ball: PrototypeBall = entry["ball"]
			var progress := seesaw.to_local(ball.global_position).x * float(entry["travel_sign"])
			entry["maximum_progress"] = maxf(float(entry["maximum_progress"]), progress)
	for entry in cases:
		var label := "Live-Wippe %.0f Grad, Richtung %+.0f, %s, seitlich %+.0f" % [entry["rotation_degrees"], entry["travel_sign"], entry["activation"], entry["lateral_offset"]]
		var reflected_once := int(entry["lip_hits"]) == 1 and float(entry["first_lip_velocity"]) < -1.0
		var stayed_outside := float(entry["maximum_progress"]) <= -53.0
		if not reflected_once or not stayed_outside:
			print("  %s: Treffer %d, erste Geschwindigkeit %.2f, maximale Vorwaertsposition %.2f" % [label, entry["lip_hits"], entry["first_lip_velocity"], entry["maximum_progress"]])
		_check(reflected_once and stayed_outside, "%s schliesst rechtzeitig: genau ein Rueckprall, kein Eindringen und kein Doppelkontakt" % label)
		var ball: PrototypeBall = entry["ball"]
		var seesaw: SeesawObstacle = entry["seesaw"]
		ball.free()
		seesaw.free()
	await get_tree().process_frame


func _create_seesaw_live_activation_case(rotation_degrees: float, travel_sign: float, activation: StringName, lateral_offset: float, center: Vector2) -> Dictionary:
	# Deliberately add the ball first: insertion order must not determine whether
	# the seesaw's newly raised end can be crossed for one physics frame.
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	var seesaw := SeesawObstacle.new()
	seesaw.position = center
	seesaw.rotation_degrees = rotation_degrees
	seesaw.preferred_tilt = -travel_sign * (0.21 if activation == &"close_threshold" else 1.0)
	get_tree().root.add_child(seesaw)
	seesaw.set_physics_process(false)
	seesaw.reset_motion()
	ball.position = seesaw.to_global(Vector2(-54.0 * travel_sign, lateral_offset))
	var zones: Array[SurfaceZone] = [seesaw]
	ball.configure_environment(zones, Vector2(-2000, -2000))
	var travel_direction := Vector2.RIGHT.rotated(seesaw.global_rotation) * travel_sign
	var result := {
		"ball": ball, "seesaw": seesaw,
		"rotation_degrees": rotation_degrees, "travel_sign": travel_sign,
		"activation": activation, "lateral_offset": lateral_offset,
		"travel_direction": travel_direction,
		"lip_hits": 0, "first_lip_velocity": 0.0, "maximum_progress": -54.0,
	}
	ball.wall_hit.connect(func(_intensity, _position, _normal, kind):
		if kind == &"seesaw_lip":
			if int(result["lip_hits"]) == 0:
				result["first_lip_velocity"] = ball.velocity.dot(travel_direction)
			result["lip_hits"] = int(result["lip_hits"]) + 1
	)
	return result


func _test_rotated_obstacle_definitions() -> void:
	print("\n[Gedrehte Hindernisse]")
	var obstacle_types := [
		ObstacleDefinition.ObstacleType.ROTATING_BLADE,
		ObstacleDefinition.ObstacleType.SLIDING_GATE,
		ObstacleDefinition.ObstacleType.SEESAW,
	]
	var rotated_nodes: Array[Node2D] = []
	for obstacle_type in obstacle_types:
		var definition := ObstacleDefinition.new()
		definition.obstacle_type = obstacle_type
		definition.position = Vector2(300, 180)
		definition.start_rotation_degrees = 90.0
		var obstacle := definition.instantiate_obstacle()
		get_tree().root.add_child(obstacle)
		rotated_nodes.append(obstacle)
	await get_tree().process_frame
	_check(rotated_nodes.all(func(obstacle): return is_equal_approx(obstacle.rotation, PI * 0.5)), "Rotor, Schiebetor und Wippe lassen sich gemeinsam um 90 Grad platzieren")
	var gate := rotated_nodes[1] as TimedSlidingGate
	_check(gate.open_offset.is_equal_approx(Vector2(100, 0)), "Beim gedrehten Schiebetor dreht sich auch der Oeffnungsweg")
	var seesaw := rotated_nodes[2] as SeesawObstacle
	seesaw.set_physics_process(false)
	seesaw.advance_tilt(0.70, 30.0)
	var slope_acceleration: Vector2 = seesaw.get_surface_data().acceleration
	_check(slope_acceleration.y > 0.0 and absf(slope_acceleration.x) <= 0.01, "Die Gefaellerichtung der Wippe folgt ihrer 90-Grad-Drehung")
	_check(seesaw.contains_global_point(Vector2(300, 220)) and not seesaw.contains_global_point(Vector2(350, 180)), "Die befahrbare Wippenflaeche dreht sich samt Kollision")
	for obstacle in rotated_nodes:
		obstacle.free()


