extends Node

var failures := 0
var checks := 0


func _ready() -> void:
	call_deferred("_run_all")


func _run_all() -> void:
	print("Putt & Pixel - Headless-Tests")
	await _test_shot_state_machine()
	_test_ball_math()
	await _test_hazard_reset()
	await _test_rotating_obstacle_wakes_ball()
	await _test_timed_gate()
	_test_slope_directions()
	await _test_hole_catalog()
	await _test_reference_hole()
	await _test_classic_diamond_hole()
	await _test_double_gate_hole()
	await _test_slope_test_hole()
	await _test_flow_test_hole()
	await _test_scroll_test_hole()
	await _test_repeated_hole_switch_input()
	_test_distance_scale()
	await _test_feedback_systems()
	_test_controller_support()
	print("\nErgebnis: %d Checks, %d Fehler" % [checks, failures])
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)


func _test_shot_state_machine() -> void:
	print("\n[Schlagsystem]")
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.position = Vector2(220, 305)
	var controller := ShotController.new()
	get_tree().root.add_child(controller)
	await get_tree().process_frame
	controller.configure(ball, Rect2(176, 16, 448, 328))

	_check(controller.state == ShotController.ShotState.AIMING, "startet in AIMING")
	_check(is_equal_approx(controller.power_cycle_seconds, 4.0), "Kraftbalken laeuft mit halbierter Geschwindigkeit")
	_check(is_equal_approx(controller.accuracy_cycle_seconds, 2.4), "Genauigkeitsbalken laeuft mit halbierter Geschwindigkeit")
	controller.action_pressed()
	_check(controller.state == ShotController.ShotState.POWER, "erster Druck startet POWER")
	controller.advance_meter(0.5)
	_check(controller.power_value > controller.minimum_power, "Kraftbalken bewegt sich")
	controller.action_pressed()
	_check(controller.state == ShotController.ShotState.ACCURACY, "zweiter Druck startet ACCURACY")
	controller.advance_meter(0.3)
	controller.action_pressed()
	_check(controller.state == ShotController.ShotState.ARMED, "dritter Druck aktiviert ARMED")
	var committed := {"value": false}
	controller.shot_committed.connect(func(_direction, _speed, _accuracy):
		committed["value"] = true
		ball.moving = true
	)
	controller.action_released()
	_check(controller.state == ShotController.ShotState.SWINGING, "Loslassen startet den sichtbaren Abschwung")
	_check(not committed["value"], "Vor dem Kontaktzeitpunkt wird kein Schlag ausgeloest")
	controller.advance_swing(controller.swing_contact_delay * 0.5)
	_check(not committed["value"], "Ball bleibt waehrend der ersten Abschwunghaelfte liegen")
	controller.advance_swing(controller.swing_contact_delay * 0.5)
	_check(controller.state == ShotController.ShotState.BALL_MOVING, "Kontaktzeitpunkt startet die Ballbewegung")
	_check(committed["value"], "shot_committed wird am Kontaktzeitpunkt ausgeloest")
	committed["value"] = false
	ball.moving = false
	controller.state = ShotController.ShotState.ARMED
	controller.action_released()
	_check(controller.state == ShotController.ShotState.SWINGING, "Neuer Abschwung kann vorbereitet werden")
	controller.cancel_shot()
	controller.advance_swing(controller.swing_contact_delay * 2.0)
	_check(controller.state == ShotController.ShotState.AIMING, "Abbruch waehrend SWINGING kehrt zum Zielen zurueck")
	_check(not committed["value"], "Abgebrochener Abschwung loest keinen verspaeteten Schlag aus")
	controller.state = ShotController.ShotState.ARMED
	controller.action_released()
	controller._on_focus_changed(false)
	controller.advance_swing(controller.swing_contact_delay * 2.0)
	_check(controller.state == ShotController.ShotState.AIMING and not committed["value"], "Fokusverlust bricht den Abschwung ohne Schlag ab")

	for cancellable_state in [
		ShotController.ShotState.POWER,
		ShotController.ShotState.ACCURACY,
		ShotController.ShotState.ARMED,
		ShotController.ShotState.SWINGING,
	]:
		controller.state = cancellable_state
		controller.cancel_shot()
		_check(controller.state == ShotController.ShotState.AIMING, "Abbruch aus Zustand %d" % cancellable_state)

	controller.state = ShotController.ShotState.ACCURACY
	controller.action_released()
	_check(controller.state == ShotController.ShotState.ACCURACY, "Loslassen vor ARMED fuehrt keinen Schlag aus")
	controller.state = ShotController.ShotState.BALL_MOVING
	ball.moving = false
	controller._process(1.0 / 60.0)
	_check(controller.state == ShotController.ShotState.AIMING, "Verwaister BALL_MOVING-Zustand gibt die Zielsteuerung wieder frei")
	_check(is_zero_approx(controller.accuracy_to_angle(0.04)), "Perfektfenster erzeugt keinen Fehler")
	_check(absf(controller.accuracy_to_angle(1.0) - deg_to_rad(8.0)) < 0.0001, "Maximalfehler betraegt acht Grad")
	controller.queue_free()
	ball.queue_free()
	await get_tree().process_frame


func _test_ball_math() -> void:
	print("\n[Ballphysik]")
	var start := Vector2(200, 0)
	var grass := PrototypeBall.apply_deceleration(start, 120.0, 1.0 / 60.0)
	var sand := PrototypeBall.apply_deceleration(start, 260.0, 1.0 / 60.0)
	_check(grass.length() < start.length(), "Gruen bremst monoton")
	_check(sand.length() < grass.length(), "Sand bremst staerker als Gruen")

	var bounce := PrototypeBall.calculate_bounce(Vector2(100, 40), Vector2(-1, 0), 0.82)
	_check(bounce.x < 0.0 and bounce.y > 0.0, "Bandenreflexion spiegelt die Normalkomponente")
	_check(absf(bounce.length() - Vector2(100, 40).length() * 0.82) < 0.01, "Rueckprallfaktor wird angewendet")
	var paddle_hit := PrototypeBall.resolve_moving_surface_collision(
		Vector2.ZERO, Vector2.DOWN, Vector2(0, 90), 0.82
	)
	_check(paddle_hit.y > 160.0, "rotierendes Hindernis uebertraegt seinen Bewegungsimpuls")
	var moving_ball_hit := PrototypeBall.resolve_moving_surface_collision(
		Vector2(0, -40), Vector2.DOWN, Vector2(0, 90), 0.82
	)
	_check(moving_ball_hit.y > paddle_hit.y, "Gegenbewegung verstaerkt den konsequenten Abprall")
	var reinforced_hit := PrototypeBall.resolve_rotating_obstacle_collision(
		Vector2.ZERO, Vector2.DOWN, Vector2(0, 20), 0.82, 1.25, 55.0
	)
	_check(reinforced_hit.y >= 55.0, "Dreherkontakt liefert einen sichtbaren Mindestimpuls")

	var run_a := _simulate_friction(Vector2(315, -20), 120.0, 180)
	var run_b := _simulate_friction(Vector2(315, -20), 120.0, 180)
	_check(run_a.is_equal_approx(run_b), "identischer Schlag ist reproduzierbar")
	_check(PrototypeBall.can_capture_hole(6.9, 120.0), "Ball bis zur neuen Lochgeschwindigkeit wird aufgenommen")
	_check(not PrototypeBall.can_capture_hole(6.9, 120.1), "zu schneller Ball wird nicht aufgenommen")
	var stuck_ball := PrototypeBall.new()
	get_tree().root.add_child(stuck_ball)
	stuck_ball.set_physics_process(false)
	stuck_ball.moving = true
	stuck_ball.velocity = Vector2(90.0, 0.0)
	var stuck_stopped := {"value": false}
	stuck_ball.stopped.connect(func(_position): stuck_stopped["value"] = true)
	for _step in range(ceili(PrototypeBall.STUCK_SETTLE_TIME * 60.0) + 1):
		stuck_ball._stuck_time += 1.0 / 60.0
		if stuck_ball._stuck_time >= PrototypeBall.STUCK_SETTLE_TIME:
			stuck_ball._finish_stopped()
			break
	_check(stuck_stopped["value"] and not stuck_ball.moving, "Festliegender Ball gibt die Steuerung nach kurzer Zeit wieder frei")
	stuck_ball.free()
func _simulate_friction(initial: Vector2, deceleration: float, steps: int) -> Vector2:
	var value := initial
	for _index in range(steps):
		value = PrototypeBall.apply_deceleration(value, deceleration, 1.0 / 60.0)
	return value


func _test_slope_directions() -> void:
	print("\n[Gefaellerichtungen]")
	var expected_directions: Array[Vector2] = [
		Vector2.UP,
		Vector2(1.0, -1.0).normalized(),
		Vector2.RIGHT,
		Vector2(1.0, 1.0).normalized(),
		Vector2.DOWN,
		Vector2(-1.0, 1.0).normalized(),
		Vector2.LEFT,
		Vector2(-1.0, -1.0).normalized(),
	]
	var names: Array[String] = [
		"oben", "oben rechts", "rechts", "unten rechts",
		"unten", "unten links", "links", "oben links",
	]
	for index in range(expected_directions.size()):
		var direction := SurfaceZone.direction_vector(index as SurfaceZone.SlopeDirection)
		var expected := expected_directions[index]
		_check(direction.is_equal_approx(expected), "Pfeilrichtung %s ist korrekt" % names[index])
		var before := Vector2(120.0, 80.0)
		var after := PrototypeBall.apply_surface_acceleration(
			before,
			direction * SurfaceZone.DEFAULT_SLOPE_ACCELERATION,
			1.0 / 60.0
		)
		var impulse := after - before
		_check(
			impulse.normalized().is_equal_approx(expected) and is_equal_approx(
				impulse.length(), SurfaceZone.DEFAULT_SLOPE_ACCELERATION / 60.0
			),
			"Ballbeschleunigung %s hat Richtung und normierte Staerke" % names[index]
		)
		var zone := SurfaceZone.new()
		zone.configure_slope(Rect2(-50.0, -50.0, 100.0, 100.0), index as SurfaceZone.SlopeDirection)
		get_tree().root.add_child(zone)
		var ball := PrototypeBall.new()
		get_tree().root.add_child(ball)
		ball.set_physics_process(false)
		ball.position = Vector2.ZERO
		var configured_zones: Array[SurfaceZone] = [zone]
		ball.configure_environment(configured_zones, Vector2(1000.0, 1000.0))
		ball.moving = true
		ball.velocity = before
		ball._physics_process(1.0 / 60.0)
		var expected_velocity := PrototypeBall.apply_deceleration(
			before + expected * SurfaceZone.DEFAULT_SLOPE_ACCELERATION / 60.0,
			120.0,
			1.0 / 60.0
		)
		_check(
			ball.velocity.is_equal_approx(expected_velocity),
			"Echte Gefaellezone beschleunigt den Ball %s" % names[index]
		)
		ball.free()
		zone.free()


func _test_hazard_reset() -> void:
	print("\n[Wasser]")
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	await get_tree().process_frame
	ball.global_position = Vector2(220, 305)
	var result := {"hazard_seen": false, "stop_position": Vector2.ZERO}
	ball.hazard_entered.connect(func(_kind): result["hazard_seen"] = true)
	ball.stopped.connect(func(at_position): result["stop_position"] = at_position)
	ball.launch(Vector2.RIGHT, 100.0, 1)
	ball.global_position = Vector2(360, 150)
	ball._enter_hazard("Wasser")
	await get_tree().create_timer(0.65).timeout
	_check(result["hazard_seen"], "Wassersignal wird ausgeloest")
	_check(Vector2(result["stop_position"]).distance_to(Vector2(220, 305)) < 0.1, "Ball kehrt zur Position vor dem Schlag zurueck")
	ball.queue_free()
	await get_tree().process_frame


func _test_controller_support() -> void:
	print("\n[Controller]")
	for action in [
		"aim_left", "aim_right", "aim_up", "aim_down", "shot_action", "shot_cancel",
		"restart_hole", "switch_test_hole", "toggle_diagnostics", "pause"
	]:
		_check(InputMap.has_action(action), "Input-Aktion %s existiert" % action)

	var parsed := ControllerSupport.parse_mapping_lines("# Kommentar\n\nGUID,Name,a:b0\n")
	_check(parsed.size() == 1 and parsed[0] == "GUID,Name,a:b0", "Mappingdatei ignoriert Kommentare und Leerzeilen")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	var old_focus: bool = ControllerSupport.focused
	ControllerSupport.focused = false
	_check(not ControllerSupport.event_is_pressed(key, &"shot_action"), "Eingabe wird ohne Fensterfokus ignoriert")
	ControllerSupport.focused = old_focus


func _test_distance_scale() -> void:
	print("\n[Entfernungsskala]")
	var meter := PowerDistanceMeter.new()
	_check(meter.distance_dm_for_power(0.0) == 5, "Mindestkraft wird in ganzen Dezimetern angezeigt")
	_check(meter.distance_dm_for_power(1.0) == 230, "Maximalkraft wird in ganzen Dezimetern angezeigt")
	meter.free()


func _test_feedback_systems() -> void:
	print("\n[Spielgefuehl-Feedback]")
	var silent := PrototypeAudio.roll_profile(-1, 120.0, false)
	_check(not bool(silent["audible"]), "Rollton verstummt sobald der Ball nicht mehr rollt")
	var grass := PrototypeAudio.roll_profile(-1, 180.0, true)
	var sand := PrototypeAudio.roll_profile(SurfaceZone.SurfaceType.SAND, 180.0, true)
	var slope := PrototypeAudio.roll_profile(SurfaceZone.SurfaceType.SLOPE, 180.0, true)
	_check(grass["profile"] == &"grass", "Gruen verwendet das weiche Rollprofil")
	_check(sand["profile"] == &"sand" and float(sand["pitch_scale"]) < float(grass["pitch_scale"]), "Sand rollt tiefer und koerniger")
	_check(slope["profile"] == &"slope" and float(slope["pitch_scale"]) > float(grass["pitch_scale"]), "Gefaelle besitzt ein etwas helleres Rollprofil")
	var audio := PrototypeAudio.new()
	get_tree().root.add_child(audio)
	await get_tree().process_frame
	_check(audio.players.size() == 8, "Retro-Audio erzeugt alle Ereignisklaenge ohne externe Dateien")
	_check(audio.roll_streams.size() == 3, "Retro-Audio erzeugt drei Materialschleifen")
	audio.update_roll(180.0, SurfaceZone.SurfaceType.SAND, true)
	_check(audio.current_roll_profile == &"sand", "Laufendes Audio wechselt auf das erkannte Material")
	audio.update_roll(0.0, SurfaceZone.SurfaceType.SAND, false)
	_check(audio.current_roll_profile == &"", "Stillstand beendet die Materialschleife")
	audio.free()
	var effects := FeedbackEffects.new()
	get_tree().root.add_child(effects)
	effects.spawn_wall(Vector2.ZERO, Vector2.UP, 80.0, &"wall")
	_check(effects.particles.is_empty(), "Leichte Bandenkontakte bleiben visuell ruhig")
	effects.spawn_wall(Vector2.ZERO, Vector2.UP, 300.0, &"wall")
	_check(effects.particles.size() == 4, "Kraeftige Bande erzeugt wenige kurze Splitter")
	effects.spawn_wall(Vector2.ZERO, Vector2.UP, 300.0, &"gate")
	_check(effects.particles.size() == 8 and effects.particles[-1]["color"] == Color("#8ed7e5"), "Torkontakt besitzt eigene kalte Splitterfarbe")
	effects.spawn_water(Vector2.ZERO)
	_check(effects.rings.size() == 2, "Wasser erzeugt zwei auslaufende Ringe")
	effects.spawn_perfect(Vector2.ZERO)
	_check(effects.particles.size() == 12, "Perfekter Treffer erzeugt einen kurzen Vierpunkt-Glanz")
	effects.free()


func _test_slope_test_hole() -> void:
	print("\n[Gefaelle-Testloch]")
	var test_hole := _instantiate_hole(&"slope_lab")
	await get_tree().process_frame
	_check(test_hole.zones.size() == 8, "Testloch enthaelt acht Gefaellezonen")
	var found_directions: Dictionary = {}
	for zone in test_hole.zones:
		found_directions[zone.slope_direction] = true
	_check(found_directions.size() == 8, "Testloch zeigt jede Gefaellerichtung genau einmal")
	test_hole.queue_free()
	await get_tree().process_frame


func _test_flow_test_hole() -> void:
	print("\n[U-Flussbahn]")
	var test_hole := _instantiate_hole(&"flow_test")
	await get_tree().process_frame
	_check(test_hole.zones.size() == 5, "U-Bahn besteht aus fuenf lueckenlosen Richtungssegmenten")
	var required_directions := {
		SurfaceZone.SlopeDirection.DOWN: true,
		SurfaceZone.SlopeDirection.DOWN_RIGHT: true,
		SurfaceZone.SlopeDirection.RIGHT: true,
		SurfaceZone.SlopeDirection.UP_RIGHT: true,
		SurfaceZone.SlopeDirection.UP: true,
	}
	for zone in test_hole.zones:
		required_directions.erase(zone.slope_direction)
	_check(required_directions.is_empty(), "U-Bahn besitzt beide Kurven und alle drei Geraden")
	var flow_zone: SurfaceZone = test_hole.zones[0]
	var assisted := PrototypeBall.apply_flow_assist(
		Vector2.ZERO, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(
		assisted.is_equal_approx(Vector2.DOWN * flow_zone.minimum_flow_speed),
		"Flussbahn setzt einen bewegten, fast stehenden Ball wieder auf Mindesttempo"
	)
	var fast_sideways := PrototypeBall.apply_flow_assist(
		Vector2.RIGHT * 420.0, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(
		fast_sideways.length() < 420.0 and fast_sideways.length() > flow_zone.maximum_flow_speed,
		"Flussbahn reduziert zu schnelle Einfahrten allmaehlich statt sofort"
	)
	_check(fast_sideways.y > 0.0, "Flussbahn richtet seitliche Einfahrten zum naechsten Segment aus")
	var opposing := PrototypeBall.apply_flow_assist(
		Vector2.UP * 120.0, Vector2.DOWN, flow_zone.minimum_flow_speed,
		flow_zone.maximum_flow_speed, flow_zone.flow_alignment_rate, 1.0 / 60.0
	)
	_check(opposing.is_equal_approx(Vector2.UP * 120.0), "Flussbahn ueberschreibt einen Schlag gegen die Pfeilrichtung nicht")
	var reverse_ball := PrototypeBall.new()
	get_tree().root.add_child(reverse_ball)
	reverse_ball.set_physics_process(false)
	reverse_ball.position = test_hole.get_tee_position()
	reverse_ball.configure_environment(test_hole.zones, test_hole.get_hole_position())
	reverse_ball.launch(Vector2.UP, 120.0, 1)
	for _step in range(5):
		reverse_ball._physics_process(1.0 / 60.0)
	_check(
		reverse_ball.position.y < test_hole.get_tee_position().y and reverse_ball.velocity.y < 0.0,
		"Ball kann am U-Bahn-Abschlag sichtbar nach oben gespielt werden"
	)
	reverse_ball.free()
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = test_hole.get_tee_position()
	ball.configure_environment(test_hole.zones, test_hole.get_hole_position())
	var completed := {"value": false}
	ball.holed.connect(func(_strokes): completed["value"] = true)
	ball.launch(Vector2.RIGHT, 60.0, 1)
	for _step in range(1200):
		ball._physics_process(1.0 / 60.0)
		if completed["value"] or not ball.moving:
			break
	if not completed["value"] and ball.position.is_equal_approx(test_hole.get_hole_position()):
		await get_tree().create_timer(0.4).timeout
	_check(
		completed["value"],
		"Ball durchlaeuft die komplette U-Bahn ohne weiteren Schlag (Position %s, Tempo %.1f)" % [
			ball.position, ball.velocity.length()
		]
	)
	ball.free()
	test_hole.queue_free()
	await get_tree().process_frame


func _test_scroll_test_hole() -> void:
	print("\n[Scroll-Testbahn]")
	var test_hole := _instantiate_hole(&"scroll_test")
	await get_tree().process_frame
	_check(test_hole.get_course_rect().size.x > 640.0, "Scrollbahn ist breiter als der interne Bildschirm")
	_check(test_hole.get_course_rect().size.y > 360.0, "Scrollbahn ist hoeher als der interne Bildschirm")
	var bounds := test_hole.get_camera_center_bounds()
	_check(bounds.size.x > 0.0 and bounds.size.y > 0.0, "Scrollbahn erlaubt horizontale und vertikale Kamerafahrt")
	_check(bounds.end.is_equal_approx(Vector2(952.0, 532.0)), "Kameragrenze schliesst rechte und untere Aussenwand vollstaendig ein")
	_check(
		CourseCamera.clamp_to_bounds(Vector2(-1000, -1000), bounds).is_equal_approx(bounds.position),
		"Kamera zeigt am Bahnanfang nicht ueber den Rand hinaus"
	)
	_check(
		CourseCamera.clamp_to_bounds(Vector2(9999, 9999), bounds).is_equal_approx(bounds.end),
		"Kamera zeigt am Bahnende nicht ueber den Rand hinaus"
	)
	var deadzone := Rect2(220.0, 52.0, 360.0, 256.0)
	var resting_camera := CourseCamera.position_for_deadzone(
		Vector2(320, 180), Vector2(500, 180), bounds, Vector2(640, 360), deadzone
	)
	_check(resting_camera.is_equal_approx(Vector2(320, 180)), "Zielkreuz innerhalb des Ruhebereichs bewegt die Kamera nicht")
	var shifted_camera := CourseCamera.position_for_deadzone(
		Vector2(320, 180), Vector2(620, 180), bounds, Vector2(640, 360), deadzone
	)
	_check(shifted_camera.is_equal_approx(Vector2(360, 180)), "Zielkreuz am rechten Rand schiebt die Kamera nur um den Ueberstand")
	var lookahead := CourseCamera.lookahead_for_velocity(Vector2(600, 0), 0.12, 48.0)
	_check(lookahead.is_equal_approx(Vector2(48, 0)), "Ballvorlauf folgt der Bewegungsrichtung und bleibt auf 48 Pixel begrenzt")
	var gentle_lookahead := CourseCamera.lookahead_for_velocity(Vector2(100, -50), 0.12, 48.0)
	_check(gentle_lookahead.is_equal_approx(Vector2(12, -6)), "Ballvorlauf skaliert bei langsamem Rollen weich mit dem Tempo")
	var no_impact := CourseCamera.impact_for_collision(Vector2.LEFT, 100.0, 220.0, 520.0, 2.0)
	_check(no_impact == Vector2.ZERO, "Leichte Bandenkontakte bewegen die Kamera nicht")
	var maximum_impact := CourseCamera.impact_for_collision(Vector2.LEFT, 520.0, 220.0, 520.0, 2.0)
	_check(maximum_impact.is_equal_approx(Vector2(-2, 0)), "Kameraimpuls bleibt auf zwei interne Pixel begrenzt")
	var camera := CourseCamera.new()
	var target := Node2D.new()
	get_tree().root.add_child(target)
	get_tree().root.add_child(camera)
	target.position = test_hole.get_tee_position()
	camera.configure(target, bounds)
	camera.add_impact(Vector2.LEFT, 520.0)
	camera._process(camera.impact_decay_seconds)
	_check(camera.impact_offset.is_zero_approx(), "Kameraimpuls klingt innerhalb von 0,12 Sekunden vollstaendig aus")
	camera.set_focus_position(test_hole.get_hole_position())
	camera.snap_to_target()
	_check(camera.position.is_equal_approx(bounds.end.round()), "Zielkreuz fuehrt die Kamera pixelgenau zur rechten unteren Scrollgrenze")
	camera.queue_free()
	target.queue_free()
	test_hole.queue_free()
	await get_tree().process_frame


func _test_repeated_hole_switch_input() -> void:
	print("\n[Bahnwechsel-Eingabe]")
	var scene := load("res://scenes/prototype_main.tscn") as PackedScene
	var main := scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.shot_controller.state = ShotController.ShotState.SWINGING
	main._update_controller_status(-1, "Kein Controller", "")
	_check(main.shot_controller.state == ShotController.ShotState.AIMING and main.strokes == 0, "Controllertrennung bricht SWINGING ohne Schlagverlust ab")
	for index in range(7):
		main.switch_test_hole()
		_check(
			main.shot_controller.state == ShotController.ShotState.AIMING,
			"Bahnwechsel %d setzt das Schlagsystem sicher auf Zielen" % (index + 1)
		)
		var before: Vector2 = main.shot_controller.cursor_position
		main.shot_controller.advance_aim(Vector2.RIGHT, 0.1)
		_check(
			main.shot_controller.cursor_position.x > before.x,
			"Stickbewegung funktioniert direkt nach Bahnwechsel %d" % (index + 1)
		)
	main.queue_free()
	await get_tree().process_frame


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


func _test_hole_catalog() -> void:
	print("\n[Datengetriebener Bahnkatalog]")
	var catalog := HoleCatalog.load_default()
	_check(catalog != null, "Lochkatalog wird als typisierte Resource geladen")
	if catalog == null:
		return
	_check(catalog.holes.size() == 7, "Katalog enthaelt drei echte Loecher und vier Testbahnen")
	_check(catalog.validate().is_empty(), "Alle Bahndefinitionen bestehen die Datenvalidierung")
	var found_ids: Dictionary = {}
	for definition in catalog.holes:
		found_ids[definition.hole_id] = true
		var runtime := HoleRuntime.new()
		runtime.configure(definition)
		get_tree().root.add_child(runtime)
		_check(runtime.zones.size() == definition.surfaces.size(), "%s erzeugt alle Flaechen" % definition.hole_id)
		_check(runtime.obstacle_nodes.size() == definition.obstacles.size(), "%s erzeugt alle Hindernisse" % definition.hole_id)
		_check(runtime.overlay != null, "%s erzeugt eine sichtbare Bahnebene" % definition.hole_id)
		if not runtime.zones.is_empty():
			_check(runtime.overlay.get_index() > runtime.zones[-1].get_index(), "%s zeichnet Banden ueber den Flaechen" % definition.hole_id)
		runtime.queue_free()
	_check(found_ids.size() == 7, "Alle Bahn-IDs sind eindeutig")
	await get_tree().process_frame


func _test_reference_hole() -> void:
	print("\n[Referenzloch 01]")
	var test_hole := _instantiate_hole(&"reference_01")
	await get_tree().process_frame
	var definition := test_hole.definition
	_check(definition.display_name == "S-KURVE AN DER MUEHLE", "Referenzloch besitzt den festgelegten Namen")
	_check(definition.par == 4, "Referenzloch ist Par 4")
	_check(definition.course_rect == Rect2(176, 16, 960, 328), "Referenzloch ist zwei Spielfenster breit")
	_check(definition.camera_center_bounds == Rect2(320, 180, 504, 0), "Referenzloch scrollt nur horizontal bis zur kompletten Aussenwand")
	var surface_types: Dictionary = {}
	for surface in definition.surfaces:
		surface_types[surface.surface_type] = true
	_check(surface_types.has(SurfaceZone.SurfaceType.WATER), "Referenzloch enthaelt die Wassertrennung")
	_check(surface_types.has(SurfaceZone.SurfaceType.SAND), "Referenzloch enthaelt den sicheren Sandweg")
	_check(surface_types.has(SurfaceZone.SurfaceType.SLOPE), "Referenzloch enthaelt das Gefaelle zum Schlussabschnitt")
	var angled_walls := 0
	for wall in definition.walls:
		if not is_zero_approx(wall.rotation_degrees):
			angled_walls += 1
	_check(angled_walls == 2, "Zwei schräge Leitbanden formen die S-Kurve")
	_check(definition.obstacles.size() == 1, "Riskanter Weg enthaelt genau eine Windmuehle")
	var windmill := definition.obstacles[0]
	_check(is_equal_approx(windmill.seconds_per_revolution, 2.4), "Windmuehle behaelt die getestete Umlaufzeit")
	_check(is_equal_approx(windmill.impulse_multiplier, 1.25), "Windmuehle behaelt den getesteten Impulsfaktor")
	test_hole.queue_free()
	await get_tree().process_frame
	var safe_completed := await _simulate_reference_route([
		[Vector2(440, 285), 235.0],
		[Vector2(705, 285), 335.0],
		[Vector2(940, 125), 330.0],
		[Vector2(1090, 65), 100.0],
	])
	_check(safe_completed, "Reproduzierbarer Sicherheitsweg beendet das Loch in vier Schlaegen")
	var risk_completed := await _simulate_reference_route([
		[Vector2(450, 80), 272.0],
		[Vector2(1090, 65), 392.0],
	])
	_check(risk_completed, "Reproduzierbarer Risikoweg beendet das Loch bei offener Muehle in zwei Schlaegen")


func _test_classic_diamond_hole() -> void:
	print("\n[Loch 02: Die Diamantenlinie]")
	var test_hole := _instantiate_hole(&"classic_diamond_02")
	await get_tree().process_frame
	var definition := test_hole.definition
	_check(definition.display_name == "DIE DIAMANTENLINIE", "Geometrische Bahn besitzt den festgelegten Namen")
	_check(definition.par == 3, "Diamantenlinie ist Par 3")
	_check(definition.course_rect == Rect2(176, 16, 448, 328), "Diamantenlinie passt vollstaendig auf einen Bildschirm")
	_check(definition.camera_center_bounds.size == Vector2.ZERO, "Geometrische Bahn benoetigt kein Scrolling")
	_check(definition.surfaces.is_empty() and definition.obstacles.is_empty(), "Diamantenlinie besteht ausschliesslich aus Geometrie")
	var diamond_walls := 0
	for wall in definition.walls:
		if not is_zero_approx(wall.rotation_degrees):
			diamond_walls += 1
	_check(diamond_walls == 4, "Vier schräge Banden bilden den geschlossenen Diamanten")
	test_hole.free()
	var safe_completed := await _simulate_hole_route(&"classic_diamond_02", [
		[Vector2(350, 286), 180.0],
		[Vector2(520, 286), 205.0],
		[Vector2(575, 70), 232.0],
	])
	_check(safe_completed, "Breiter unterer Weg beendet die Diamantenlinie in hoechstens drei Schlaegen")
	var precision_completed := await _simulate_hole_route(&"classic_diamond_02", [
		[Vector2(285, 90), 225.0],
		[Vector2(575, 70), 265.0],
	])
	_check(precision_completed, "Praeziser oberer Weg beendet die Diamantenlinie in zwei Schlaegen")


func _test_double_gate_hole() -> void:
	print("\n[Loch 03: Das Doppeltor]")
	var test_hole := _instantiate_hole(&"double_gate_03")
	await get_tree().process_frame
	var definition := test_hole.definition
	_check(definition.display_name == "DAS DOPPELTOR", "Mechanische Bahn besitzt den festgelegten Namen")
	_check(definition.par == 4, "Doppeltor ist Par 4")
	_check(definition.course_rect == Rect2(176, 16, 832, 328), "Doppeltor besitzt den festgelegten breiten Bahnraum")
	_check(definition.camera_center_bounds == Rect2(320, 180, 376, 0), "Doppeltor scrollt nur horizontal bis zur Aussenwand")
	_check(definition.obstacles.size() == 2, "Doppeltor enthaelt genau zwei zeitgesteuerte Tore")
	var valid_gate_data := true
	for obstacle in definition.obstacles:
		valid_gate_data = valid_gate_data and obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE
		valid_gate_data = valid_gate_data and obstacle.gate_size == Vector2(10, 86)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.cycle_seconds, 2.8)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.transition_seconds, 0.25)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.open_hold_seconds, 1.0)
	_check(valid_gate_data, "Beide Tore behalten Groesse und festgelegte Timingwerte")
	var first_gate := test_hole.obstacle_nodes[0] as TimedSlidingGate
	var second_gate := test_hole.obstacle_nodes[1] as TimedSlidingGate
	first_gate.set_physics_process(false)
	second_gate.set_physics_process(false)
	test_hole.reset_obstacles()
	var first_closed := first_gate.closed_position
	var second_closed := second_gate.closed_position
	first_gate.advance_motion(1.60)
	second_gate.advance_motion(1.60)
	await get_tree().physics_frame
	_check(
		first_gate.position.is_equal_approx(first_closed + first_gate.open_offset)
		and second_gate.position.is_equal_approx(second_closed + second_gate.open_offset),
		"Beide Tore sind im gemeinsamen Zeitfenster vollstaendig offen"
	)
	test_hole.reset_obstacles()
	_check(first_gate.position.is_equal_approx(first_closed) and second_gate.position.is_equal_approx(second_closed), "Lochneustart setzt beide Torphasen zurueck")
	test_hole.free()
	var route_completed := await _simulate_hole_route(&"double_gate_03", [
		[Vector2(410, 173), 225.0],
		[Vector2(735, 173), 280.0],
		[Vector2(960, 70), 245.0],
	], &"gates_open")
	_check(route_completed, "Reproduzierbarer Timingweg beendet das Doppeltor in hoechstens vier Schlaegen")


func _simulate_reference_route(shots: Array) -> bool:
	return await _simulate_hole_route(&"reference_01", shots, &"reference_open")


func _simulate_hole_route(hole_id: StringName, shots: Array, obstacle_mode := &"") -> bool:
	var runtime := _instantiate_hole(hole_id)
	await get_tree().physics_frame
	for obstacle in runtime.obstacle_nodes:
		obstacle.set_physics_process(false)
		if obstacle_mode == &"reference_open" and obstacle is RotatingObstacle:
			obstacle.rotation = 0.0
		elif obstacle_mode == &"gates_open" and obstacle is TimedSlidingGate:
			obstacle.position = obstacle.closed_position + obstacle.open_offset
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position())
	var result := {"holed": false}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	for index in range(shots.size()):
		var target: Vector2 = shots[index][0]
		var speed: float = shots[index][1]
		ball.launch(ball.position.direction_to(target), speed, index + 1)
		for _step in range(1800):
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


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("  OK  ", description)
	else:
		failures += 1
		push_error("  FEHLER  " + description)
