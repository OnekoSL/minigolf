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
	await _test_rotated_surface_zones()
	await _test_hole_catalog()
	await _test_reference_hole()
	await _test_classic_diamond_hole()
	await _test_double_gate_hole()
	await _test_cannon_workshop()
	await _test_classic_nine_course()
	await _test_arrow_armageddon_course()
	await _test_slope_test_hole()
	await _test_flow_test_hole()
	await _test_scroll_test_hole()
	await _test_curve_lab()
	await _test_repeated_hole_switch_input()
	_test_distance_scale()
	await _test_feedback_systems()
	await _test_game_shell()
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


func _test_rotated_surface_zones() -> void:
	print("\n[Gedrehte Pfeilflaechen]")
	var definition := SurfaceDefinition.new()
	definition.rect = Rect2(280, 120, 160, 48)
	definition.rotation_degrees = 45.0
	definition.surface_type = SurfaceZone.SurfaceType.SLOPE
	definition.slope_direction = SurfaceZone.SlopeDirection.RIGHT
	definition.slope_strength = 90.0
	definition.deceleration = 120.0
	var zone := definition.instantiate_zone()
	get_tree().root.add_child(zone)
	await get_tree().process_frame
	_check(is_equal_approx(rad_to_deg(zone.rotation), 45.0), "Drehwinkel wird auf Darstellung und Kollision uebertragen")
	var collision := zone.get_child(0) as CollisionShape2D
	_check(collision != null and collision.shape is RectangleShape2D and collision.shape.size == Vector2(160, 48), "Gedrehte Flaeche verwendet ihre rechteckige Originalgroesse")
	_check(zone.contains_global_point(Vector2(360, 144)), "Lokale Punktpruefung erkennt die Mitte einer gedrehten Flaeche")
	_check(zone.contains_global_point(zone.to_global(Vector2(70, 0))), "Lokale Punktpruefung folgt der gedrehten Laengsachse")
	_check(not zone.contains_global_point(Vector2(290, 190)), "Punkte ausserhalb der gedrehten Kontur werden abgelehnt")
	var surface_data := zone.get_surface_data()
	_check(Vector2(surface_data["acceleration"]).normalized().is_equal_approx(Vector2.RIGHT), "Flaechendrehung veraendert die Welt-Pfeilrichtung nicht")
	var valid_hole := HoleDefinition.new()
	valid_hole.hole_id = &"rotation_test"
	valid_hole.course_rect = Rect2(176, 16, 448, 328)
	valid_hole.tee_position = Vector2(220, 180)
	valid_hole.hole_position = Vector2(580, 180)
	valid_hole.camera_center_bounds = Rect2(320, 180, 0, 0)
	valid_hole.surfaces = [definition]
	_check(valid_hole.validate().is_empty(), "Gedrehte Flaeche innerhalb der Bahn besteht die Eckvalidierung")
	var outside := definition.duplicate(true) as SurfaceDefinition
	outside.rect = Rect2(580, 20, 80, 40)
	outside.rotation_degrees = 45.0
	valid_hole.surfaces = [outside]
	_check(not valid_hole.validate().is_empty(), "Gedrehte Ecken ausserhalb der Bahn werden abgelehnt")
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
		"restart_hole", "switch_test_hole", "toggle_diagnostics", "pause", "menu_confirm", "menu_back"
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
	_check(audio.players.size() == 12, "Retro-Audio erzeugt alle Ereignisklaenge ohne externe Dateien")
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


func _test_curve_lab() -> void:
	print("\n[Kurven-Labor]")
	var arc := WallDefinition.new()
	arc.wall_type = WallDefinition.WallType.ARC
	arc.radius = 64.0
	arc.thickness = 8.0
	arc.arc_start_degrees = 20.0
	arc.arc_sweep_degrees = 140.0
	arc.arc_segments = 20
	_check(arc.validate("Testbogen").is_empty(), "Gueltiger Kreisbogen besteht die Wandvalidierung")
	_check(arc.get_arc_polygon().size() == 42, "Bogen erzeugt eine geschlossene Kontur aus festen Segmenten")
	_check(arc.get_arc_centerline().size() == 21, "Darstellung und Kollision verwenden dieselbe Bogenaufloesung")
	var invalid_arc := WallDefinition.new()
	invalid_arc.wall_type = WallDefinition.WallType.ARC
	invalid_arc.radius = 4.0
	invalid_arc.thickness = 8.0
	_check(not invalid_arc.validate("Enger Bogen").is_empty(), "Zu enger Bogenradius wird abgelehnt")

	var test_hole := _instantiate_hole(&"curve_lab")
	await get_tree().process_frame
	var circles := 0
	var arcs := 0
	for wall in test_hole.definition.walls:
		if wall.wall_type == WallDefinition.WallType.CIRCLE:
			circles += 1
		elif wall.wall_type == WallDefinition.WallType.ARC:
			arcs += 1
	_check(test_hole.definition.category == HoleDefinition.HoleCategory.TECHNICAL, "Kurven-Labor bleibt eine technische Testbahn")
	_check(circles == 3 and arcs == 4, "Kurven-Labor kombiniert drei Kreise und vier Kreisboegen")
	_check(test_hole.definition.surfaces.is_empty() and test_hole.definition.obstacles.is_empty(), "Kurventest isoliert die neue Wandgeometrie")
	var circle_collisions := 0
	var arc_collisions := 0
	for child in test_hole.get_children():
		if child is not StaticBody2D:
			continue
		for collision in child.get_children():
			if collision is CollisionShape2D and collision.shape is CircleShape2D:
				circle_collisions += 1
			elif collision is CollisionPolygon2D:
				arc_collisions += 1
	_check(circle_collisions == circles, "Runde Bumper verwenden echte Kreiskollisionen")
	_check(arc_collisions == arcs, "Kreisboegen werden als zusammenhaengende Kollisionsbaender erzeugt")

	var ball := PrototypeBall.new()
	ball.position = Vector2(340, 180)
	get_tree().root.add_child(ball)
	await get_tree().physics_frame
	ball.launch(Vector2.RIGHT, 240.0, 1)
	var bounced := false
	for _step in range(45):
		await get_tree().physics_frame
		if ball.velocity.x < 0.0:
			bounced = true
			break
	_check(bounced, "Zentraler Kreisbumper reflektiert einen realen Ballkontakt")
	ball.queue_free()
	var arc_ball := PrototypeBall.new()
	get_tree().root.add_child(arc_ball)
	await get_tree().physics_frame
	var first_arc_hit := await _simulate_arc_hit(arc_ball)
	var second_arc_hit := await _simulate_arc_hit(arc_ball)
	_check(bool(first_arc_hit.get("hit", false)), "Unterer Kreisbogen reflektiert einen realen Ballkontakt")
	_check(
		Vector2(first_arc_hit.get("position", Vector2.ZERO)).distance_to(Vector2(second_arc_hit.get("position", Vector2.ZERO))) <= 0.1,
		"Identischer Bogentreffer bleibt bis auf 0,1 Pixel reproduzierbar"
	)
	_check(
		Vector2(first_arc_hit.get("velocity", Vector2.ZERO)).distance_to(Vector2(second_arc_hit.get("velocity", Vector2.ZERO))) <= 0.1,
		"Bogenreflexion liefert reproduzierbare Geschwindigkeit"
	)
	arc_ball.queue_free()
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
	for index in range(27):
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
	_check(catalog.holes.size() == 27, "Katalog enthaelt zweiundzwanzig echte Loecher und fuenf Testbahnen")
	_check(catalog.validate().is_empty(), "Alle Bahndefinitionen bestehen die Datenvalidierung")
	var found_ids: Dictionary = {}
	for definition in catalog.holes:
		found_ids[definition.hole_id] = true
		var runtime := HoleRuntime.new()
		runtime.configure(definition)
		get_tree().root.add_child(runtime)
		_check(runtime.zones.size() == definition.surfaces.size(), "%s erzeugt alle Flaechen" % definition.hole_id)
		_check(runtime.obstacle_nodes.size() == definition.obstacles.size(), "%s erzeugt alle Hindernisse" % definition.hole_id)
		_check(runtime.trigger_nodes.size() == definition.triggers.size(), "%s erzeugt alle Trigger" % definition.hole_id)
		_check(runtime.cannon_nodes.size() == definition.cannons.size(), "%s erzeugt alle Kanonen" % definition.hole_id)
		_check(runtime.overlay != null, "%s erzeugt eine sichtbare Bahnebene" % definition.hole_id)
		if not runtime.zones.is_empty():
			_check(runtime.overlay.get_index() > runtime.zones[-1].get_index(), "%s zeichnet Banden ueber den Flaechen" % definition.hole_id)
		runtime.queue_free()
	_check(found_ids.size() == 27, "Alle Bahn-IDs sind eindeutig")
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


func _test_cannon_workshop() -> void:
	print("\n[Loch 04: Die Kanonenwerkstatt]")
	var runtime := _instantiate_hole(&"cannon_workshop_04")
	await get_tree().physics_frame
	var definition := runtime.definition
	_check(definition.display_name == "DIE KANONENWERKSTATT", "Abenteuerbahn besitzt den festgelegten Namen")
	_check(definition.par == 4, "Kanonenwerkstatt ist Par 4")
	_check(definition.course_rect == Rect2(176, 16, 960, 328), "Kanonenwerkstatt besitzt den zweibildschirmbreiten Bahnraum")
	_check(definition.camera_center_bounds == Rect2(320, 180, 504, 0), "Kanonenwerkstatt scrollt nur horizontal")
	_check(definition.triggers.size() == 1 and definition.cannons.size() == 2, "Ein Schalter steuert genau zwei Kanonen")
	_check(definition.cannons[0].capture_size == Vector2(36, 24), "Sichere Kanone besitzt die breite Einfahrt")
	_check(definition.cannons[1].capture_size == Vector2(18, 14), "Riskante Kanone besitzt die schmale Einfahrt")
	var trigger := runtime.trigger_nodes[0]
	var safe := runtime.cannon_nodes[0]
	var risk := runtime.cannon_nodes[1]
	_check(not trigger.is_activated and not safe.is_enabled and not risk.is_enabled, "Schalter und Kanonen starten verriegelt")
	trigger.activate()
	await get_tree().physics_frame
	_check(trigger.is_activated and safe.is_enabled and risk.is_enabled, "Ein Schalter entriegelt beide Kanonen dauerhaft")
	trigger.activate()
	_check(trigger.is_activated, "Erneuter Kontakt veraendert den dauerhaften Schalterzustand nicht")
	runtime.reset_mechanisms()
	await get_tree().physics_frame
	_check(not trigger.is_activated and not safe.is_enabled and not risk.is_enabled, "Mechanismusreset verriegelt Schalter und Kanonen")

	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = safe.position - safe.entry_direction * 4.0
	ball.velocity = safe.entry_direction * 100.0
	ball.moving = true
	_check(not safe.can_capture_ball(ball), "Verriegelte Kanone nimmt keinen Ball auf")
	trigger.activate()
	await get_tree().physics_frame
	_check(safe.can_capture_ball(ball), "Entriegelte Kanone akzeptiert die vorgesehene Einflugrichtung")
	ball.velocity = -safe.entry_direction * 100.0
	_check(not safe.can_capture_ball(ball), "Kanone lehnt eine Einfahrt von hinten ab")
	ball.velocity = safe.entry_direction * 100.0
	var phases := {&"cannon_load": 0, &"cannon_fire": 0, &"cannon_land": 0}
	ball.cannon_feedback.connect(func(kind, _id, _position, _direction): phases[kind] = int(phases.get(kind, 0)) + 1)
	var stroke_before := ball.current_stroke_count
	safe._on_body_entered(ball)
	_check(ball.is_cannon_sequence_active() and ball.collision_mask == 0, "Kanonenaufnahme beendet die Bodenphysik atomar")
	ball.advance_cannon_sequence(0.19)
	_check(ball.is_cannon_sequence_active() and int(phases[&"cannon_fire"]) == 0, "Vor der Zuendpause wird noch nicht gefeuert")
	ball.advance_cannon_sequence(0.20)
	_check(int(phases[&"cannon_fire"]) == 1 and ball.is_cannon_sequence_active(), "Kanone feuert nach Aufnahme und Zuendpause genau einmal")
	_check(ball.global_position.x > safe.global_position.x and ball.collision_mask == 0, "Bogenflug passiert die Maschinenwand ohne Bodenkollision")
	ball.advance_cannon_sequence(1.0)
	_check(ball.global_position.is_equal_approx(safe.landing_position) and ball.velocity.is_equal_approx(safe.landing_velocity), "Kanone landet reproduzierbar mit definierter Restgeschwindigkeit")
	_check(not ball.is_cannon_sequence_active() and ball.collision_mask == 2 and int(phases[&"cannon_land"]) == 1, "Landung stellt die normale Ballphysik wieder her")
	_check(ball.current_stroke_count == stroke_before, "Kanonenaufnahme und Flug zaehlen keinen zusaetzlichen Schlag")
	var first_landing := ball.global_position
	var first_velocity := ball.velocity
	safe.reset_state()
	safe.set_enabled(true)
	ball.reset_to(safe.position - safe.entry_direction * 4.0)
	ball.velocity = safe.entry_direction * 100.0
	ball.moving = true
	safe._on_body_entered(ball)
	ball.advance_cannon_sequence(2.0)
	_check(ball.global_position.distance_to(first_landing) <= 0.1 and ball.velocity.distance_to(first_velocity) <= 0.1, "Identischer Kanoneneintritt reproduziert Landung und Resttempo bis auf 0,1 Pixel")
	ball.reset_to(Vector2(500, 200))
	ball.velocity = Vector2.RIGHT * 100.0
	ball.moving = true
	ball.start_cannon_sequence(&"reset_test", Vector2(520, 200), Vector2(800, 200), 0.2, 0.12, 0.55, 34.0, Vector2.RIGHT * 55.0)
	ball.reset_to(Vector2(220, 286))
	_check(not ball.is_cannon_sequence_active() and ball.collision_mask == 2 and not ball.moving, "Neustart bricht einen Kanonenflug sicher ab")
	ball.free()
	runtime.free()
	var invalid_target := definition.duplicate(true) as HoleDefinition
	invalid_target.triggers[0].target_ids.append(&"missing_cannon")
	_check(not invalid_target.validate().is_empty(), "Bahnvalidierung lehnt unbekannte Triggerziele ab")
	var invalid_requirement := definition.duplicate(true) as HoleDefinition
	invalid_requirement.cannons[0].required_trigger_id = &"missing_switch"
	_check(not invalid_requirement.validate().is_empty(), "Bahnvalidierung lehnt unbekannte Pflichttrigger ab")

	var safe_completed := await _simulate_cannon_route(false)
	_check(safe_completed, "Breite Kanonenroute beendet die Werkstatt reproduzierbar in vier Schlaegen")
	var risk_completed := await _simulate_cannon_route(true)
	_check(risk_completed, "Schmale Kanonenroute beendet die Werkstatt reproduzierbar in drei Schlaegen")


func _test_classic_nine_course() -> void:
	print("\n[Kurs: Klassische Neun]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	var course := courses.get_course(&"classic_nine_course")
	_check(course != null, "Klassische Neun wird als eigener Kurs geladen")
	if course == null:
		return
	_check(course.hole_ids.size() == 9, "Klassische Neun enthaelt neun geordnete Bahnen")
	_check(course.get_total_par(holes) == 18, "Klassische Neun besitzt Gesamt-Par 18")
	var par_counts := {1: 0, 2: 0, 3: 0}
	var compact_count := 0
	var wide_count := 0
	var slope_count := 0
	var circle_count := 0
	var arc_count := 0
	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		_check(definition != null and definition.is_course_hole(), "%s ist eine gueltige Kursbahn" % hole_id)
		if definition == null:
			continue
		par_counts[definition.par] = int(par_counts.get(definition.par, 0)) + 1
		_check(definition.obstacles.is_empty(), "%s besitzt keine beweglichen Hindernisse" % hole_id)
		if definition.course_rect == Rect2(176, 16, 448, 328) and definition.camera_center_bounds.size == Vector2.ZERO:
			compact_count += 1
		elif definition.course_rect == Rect2(176, 16, 832, 328) and definition.camera_center_bounds == Rect2(320, 180, 376, 0):
			wide_count += 1
		for surface in definition.surfaces:
			_check(surface.surface_type == SurfaceZone.SurfaceType.SLOPE, "%s verwendet weder Sand noch Wasser" % hole_id)
			_check(is_equal_approx(surface.deceleration, 120.0) and is_equal_approx(surface.slope_strength, 24.0), "%s besitzt nur eine schwache Pfeilzone" % hole_id)
			_check(surface.minimum_flow_speed == 0.0 and surface.maximum_flow_speed == 0.0, "%s verwendet keine automatische Flussfuehrung" % hole_id)
			slope_count += 1
		for wall in definition.walls:
			if wall.wall_type == WallDefinition.WallType.CIRCLE:
				circle_count += 1
			elif wall.wall_type == WallDefinition.WallType.ARC:
				arc_count += 1
	_check(par_counts == {1: 3, 2: 3, 3: 3}, "Par-Verteilung besteht aus dreimal eins, zwei und drei")
	_check(compact_count == 6 and wide_count == 3, "Sechs Bahnen sind kompakt und drei scrollen horizontal")
	_check(slope_count == 3, "Genau drei Bahnen besitzen je einen kleinen Pfeilbereich")
	_check(circle_count == 8 and arc_count == 11, "Kurs kombiniert acht Kreisbumper und elf Kreisbogenwaende")

	var routes := {
		&"classic_nine_01": [[Vector2(320, 180), 292.0]],
		&"classic_nine_02": [[Vector2(295.3766, 220.2858), 348.0]],
		&"classic_nine_03": [[Vector2(303.99, 231.56), 396.0]],
		&"classic_nine_04": [[Vector2(201.2061, 263.1596), 340.0], [Vector2(468.6949, 172.4086), 340.0]],
		&"classic_nine_05": [[Vector2(235.0753, 272.8571), 340.0], [Vector2(584.5403, 58.6901), 180.0]],
		&"classic_nine_06": [[Vector2(204.6791, 273.1443), 420.0], [Vector2(520.4238, 47.6587), 180.0]],
		&"classic_nine_07": [[Vector2(240, 286), 420.0], [Vector2(965.4721, 267.2545), 260.0], [Vector2(986.6935, 68.7469), 180.0]],
		&"classic_nine_08": [[Vector2(470, 320), 248.0], [Vector2(760, 80), 300.0], [Vector2(960, 72), 244.0]],
		&"classic_nine_09": [[Vector2(238.7939, 279.1596), 380.0], [Vector2(808.3391, 78.3043), 340.0], [Vector2(944.7792, 72.1226), 180.0]],
	}
	for hole_id in course.hole_ids:
		var completed := await _simulate_hole_route(hole_id, routes[hole_id])
		_check(completed, "%s endet reproduzierbar innerhalb seines Pars" % hole_id)


func _test_arrow_armageddon_course() -> void:
	print("\n[Kurs: Pfeil-Armageddon]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	var course := courses.get_course(&"arrow_armageddon_course")
	_check(course != null, "Pfeil-Armageddon wird als eigener Kurs geladen")
	if course == null:
		return
	_check(course.hole_ids.size() == 9, "Pfeil-Armageddon enthaelt neun geordnete Bahnen")
	_check(course.get_total_par(holes) == 27, "Pfeil-Armageddon besitzt Gesamt-Par 27")
	var par_counts := {2: 0, 3: 0, 4: 0}
	var compact_count := 0
	var wide_count := 0
	var long_count := 0
	var gentle_count := 0
	var strong_count := 0
	var flow_count := 0
	var sand_count := 0
	var water_count := 0
	var rotated_count := 0
	var directions: Dictionary = {}
	for hole_id in course.hole_ids:
		var definition := holes.get_hole(hole_id)
		_check(definition != null and definition.is_course_hole(), "%s ist eine gueltige Kursbahn" % hole_id)
		if definition == null:
			continue
		par_counts[definition.par] = int(par_counts.get(definition.par, 0)) + 1
		_check(definition.obstacles.is_empty() and definition.triggers.is_empty() and definition.cannons.is_empty(), "%s besitzt keine zeitabhaengige Mechanik" % hole_id)
		if definition.course_rect == Rect2(176, 16, 448, 328) and definition.camera_center_bounds.size == Vector2.ZERO:
			compact_count += 1
		elif definition.course_rect == Rect2(176, 16, 832, 328) and definition.camera_center_bounds == Rect2(320, 180, 376, 0):
			wide_count += 1
		elif definition.course_rect == Rect2(176, 16, 960, 328) and definition.camera_center_bounds == Rect2(320, 180, 504, 0):
			long_count += 1
		for surface in definition.surfaces:
			if not is_zero_approx(surface.rotation_degrees):
				rotated_count += 1
			match surface.surface_type:
				SurfaceZone.SurfaceType.SAND:
					sand_count += 1
				SurfaceZone.SurfaceType.WATER:
					water_count += 1
				SurfaceZone.SurfaceType.SLOPE:
					directions[surface.slope_direction] = true
					if surface.minimum_flow_speed > 0.0:
						flow_count += 1
						_check(surface.slope_strength == 150.0 and surface.deceleration == 50.0 and surface.maximum_flow_speed == 105.0 and surface.flow_alignment_rate == 12.0 and surface.flow_centering_strength == 10.0, "%s verwendet die festgelegte Foerderflaeche" % hole_id)
					elif surface.slope_strength == 150.0:
						strong_count += 1
						_check(surface.deceleration == 50.0, "%s verwendet die festgelegte starke Pfeilflaeche" % hole_id)
					else:
						gentle_count += 1
						_check(surface.slope_strength == 90.0 and surface.deceleration == 120.0, "%s verwendet das festgelegte sanfte Gefaelle" % hole_id)
	_check(par_counts == {2: 3, 3: 3, 4: 3}, "Par-Verteilung besteht aus dreimal zwei, drei und vier")
	_check(compact_count == 5 and wide_count == 3 and long_count == 1, "Fuenf Bahnen sind kompakt und vier scrollen horizontal")
	_check(gentle_count == 4 and strong_count == 13 and flow_count == 20, "Die drei Wirkungsstufen steigern sich ueber den Kurs")
	_check(sand_count == 1 and water_count == 2, "Nur eine Sand- und zwei Wasserflaechen ergaenzen die Pfeile")
	_check(directions.size() == 8, "Der Kurs verwendet alle acht Pfeilrichtungen")
	_check(rotated_count >= 12, "Diagonale Korridore verwenden echte gedrehte Flaechen")

	var first_snapshot := await _simulate_hole_snapshot(&"arrow_armageddon_07", Vector2(430, 235), 300.0, 180)
	var second_snapshot := await _simulate_hole_snapshot(&"arrow_armageddon_07", Vector2(430, 235), 300.0, 180)
	_check(Vector2(first_snapshot["position"]).distance_to(Vector2(second_snapshot["position"])) <= 0.1, "Identische Foerderfahrt reproduziert die Position bis auf 0,1 Pixel")
	_check(Vector2(first_snapshot["velocity"]).distance_to(Vector2(second_snapshot["velocity"])) <= 0.1, "Identische Foerderfahrt reproduziert das Tempo bis auf 0,1 Pixel")

	var routes := {
		&"arrow_armageddon_01": [[Vector2(490, 180), 250.0], [Vector2(580, 100), 140.0]],
		&"arrow_armageddon_02": [[Vector2(470, 135), 310.0], [Vector2(575, 70), 65.0]],
		&"arrow_armageddon_03": [[Vector2(475, 165), 290.0], [Vector2(580, 180), 60.0]],
		&"arrow_armageddon_04": [[Vector2(350, 235), 245.0], [Vector2(580, 180), 110.0], [Vector2(580, 180), 120.0]],
		&"arrow_armageddon_05": [[Vector2(395, 180), 230.0], [Vector2(400, 80), 160.0], [Vector2(575, 70), 210.0]],
		&"arrow_armageddon_06": [[Vector2(430, 235), 300.0], [Vector2(990, 175), 120.0], [Vector2(960, 100), 180.0]],
		&"arrow_armageddon_07": [[Vector2(430, 235), 300.0], [Vector2(720, 220), 300.0], [Vector2(960, 70), 65.0], [Vector2(960, 70), 120.0]],
		&"arrow_armageddon_08": [[Vector2(410, 120), 280.0], [Vector2(650, 220), 340.0], [Vector2(860, 250), 280.0], [Vector2(960, 286), 110.0]],
		&"arrow_armageddon_09": [[Vector2(430, 235), 300.0], [Vector2(600, 75), 190.0], [Vector2(800, 50), 320.0], [Vector2(1090, 70), 230.0]],
	}
	for hole_id in course.hole_ids:
		var completed := await _simulate_hole_route(hole_id, routes[hole_id])
		_check(completed, "%s endet reproduzierbar innerhalb seines Pars" % hole_id)


func _simulate_hole_snapshot(hole_id: StringName, target: Vector2, speed: float, steps: int) -> Dictionary:
	var runtime := _instantiate_hole(hole_id)
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position())
	ball.launch(ball.position.direction_to(target), speed, 1)
	for _step in range(steps):
		if not ball.moving:
			break
		ball._physics_process(1.0 / 60.0)
	var result := {"position": ball.position, "velocity": ball.velocity}
	ball.free()
	runtime.free()
	return result


func _simulate_reference_route(shots: Array) -> bool:
	return await _simulate_hole_route(&"reference_01", shots, &"reference_open")


func _simulate_cannon_route(use_risk_cannon: bool) -> bool:
	var runtime := _instantiate_hole(&"cannon_workshop_04")
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position())
	var result := {"holed": false}
	ball.holed.connect(func(_strokes): result["holed"] = true)
	var shots := [
		[Vector2(380, 280), 196.0],
		[Vector2(590, 105) if use_risk_cannon else Vector2(590, 265), 268.0 if use_risk_cannon else 238.0],
	]
	if use_risk_cannon:
		shots.append([Vector2(1090, 70), 158.0])
	else:
		shots.append([Vector2(1045, 260), 243.0])
		shots.append([Vector2(1090, 70), 218.0])
	for shot_index in range(shots.size()):
		var target: Vector2 = shots[shot_index][0]
		var speed: float = shots[shot_index][1]
		ball.launch(ball.position.direction_to(target), speed, shot_index + 1)
		for _step in range(1800):
			ball._physics_process(1.0 / 60.0)
			var trigger := runtime.trigger_nodes[0]
			var trigger_rect := Rect2(trigger.global_position - trigger.switch_size * 0.5, trigger.switch_size).grow(PrototypeBall.RADIUS)
			if not trigger.is_activated and trigger_rect.has_point(ball.global_position):
				trigger.activate()
			for cannon in runtime.cannon_nodes:
				var capture_rect := Rect2(cannon.global_position - cannon.capture_size * 0.5, cannon.capture_size).grow(PrototypeBall.RADIUS)
				if capture_rect.has_point(ball.global_position):
					cannon._on_body_entered(ball)
			if not ball.moving:
				break
		await get_tree().physics_frame
		if ball.position.distance_to(runtime.get_hole_position()) <= PrototypeBall.HOLE_RADIUS:
			await get_tree().create_timer(0.4).timeout
		if result["holed"]:
			break
	var completed: bool = result["holed"]
	if not completed:
		print("  Kanonenroute %s endete bei %s mit Tempo %.1f" % ["riskant" if use_risk_cannon else "sicher", ball.position, ball.velocity.length()])
	ball.free()
	runtime.free()
	return completed


func _simulate_arc_hit(ball: PrototypeBall) -> Dictionary:
	ball.reset_to(Vector2(400, 225))
	ball.launch(Vector2.DOWN, 240.0, 1)
	for _step in range(45):
		await get_tree().physics_frame
		if ball.velocity.y < 0.0:
			return {"hit": true, "position": ball.position, "velocity": ball.velocity}
	return {"hit": false, "position": ball.position, "velocity": ball.velocity}


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


func _test_game_shell() -> void:
	print("\n[Spielrahmen und Rundentabelle]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	_check(courses != null, "Kurskatalog wird als typisierte Resource geladen")
	_check(courses.validate(holes).is_empty(), "Kurskatalog verweist nur auf gueltige echte Loecher")
	var course := courses.get_course(&"prototype_course_03")
	_check(course != null and course.hole_ids.size() == 9, "Prototypkurs verbindet vier echte und fuenf technische Bahnen")
	_check(course.get_total_par(holes) == 38, "Vollstaendiger Prototypkurs besitzt Gesamt-Par 38")
	_check(course.allow_technical_holes, "Prototypkurs erlaubt seine kuratierten Testbahnen ausdruecklich")
	var classic_course := courses.get_course(&"classic_nine_course")
	var arrow_course := courses.get_course(&"arrow_armageddon_course")
	_check(courses.courses.size() == 3 and courses.courses[0] == classic_course and courses.courses[1] == arrow_course and courses.courses[2] == course, "Kursauswahl ordnet Klassische Neun, Pfeil-Armageddon und Prototypkurs")
	_check(classic_course != null and classic_course.hole_ids.size() == 9 and classic_course.get_total_par(holes) == 18, "Neun-Loch-Kurs ist vollstaendig im Spielrahmen registriert")
	_check(arrow_course != null and arrow_course.hole_ids.size() == 9 and arrow_course.get_total_par(holes) == 27, "Pfeil-Armageddon ist vollstaendig im Spielrahmen registriert")
	var course_holes := 0
	var technical_holes := 0
	for hole in holes.holes:
		if hole.is_course_hole():
			course_holes += 1
		else:
			technical_holes += 1
	_check(course_holes == 22 and technical_holes == 5, "Katalog trennt zweiundzwanzig Kurs- und fuenf Technikbahnen")

	var first := PlayerProfile.create(1, "", 0)
	var second := PlayerProfile.create(2, "ZWOELFZEICHENPLUS", 1)
	_check(first.player_name == "SPIELER 1", "Leerer Name erhaelt den Spielernamen als Ersatz")
	_check(second.player_name.length() == 12, "Spielername wird auf zwoelf Zeichen begrenzt")
	_check(first.get_color() != second.get_color(), "Farbvarianten unterscheiden Spieler auch im HUD")

	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	config.course_id = course.course_id
	config.players = [first, second]
	config.hole_ids = course.hole_ids.slice(0, 3)
	config.best_eligible = true
	_check(config.validate(holes).is_empty(), "Zwei-Spieler-Kurskonfiguration ist gueltig")
	_check(not config.allows_restart() and config.is_course_mode(), "Gewerteter Kurs verhindert Lochneustarts")
	var prototype_config := RoundConfig.new()
	prototype_config.mode = RoundConfig.GameMode.COURSE_LOCAL
	prototype_config.course_id = course.course_id
	prototype_config.players = [first, second]
	prototype_config.hole_ids = course.hole_ids.duplicate()
	prototype_config.best_eligible = true
	prototype_config.allow_technical_holes = course.allow_technical_holes
	_check(prototype_config.validate(holes).is_empty(), "Kuratierter Prototypkurs akzeptiert alle fuenf technischen Bahnen")
	prototype_config.allow_technical_holes = false
	_check(not prototype_config.validate(holes).is_empty(), "Technische Bahnen bleiben ohne Kursfreigabe gesperrt")
	var invalid_solo := RoundConfig.new()
	invalid_solo.mode = RoundConfig.GameMode.COURSE_SOLO
	invalid_solo.players = [first, second]
	invalid_solo.hole_ids = course.hole_ids.duplicate()
	_check(not invalid_solo.validate(holes).is_empty(), "Einzelkurs lehnt mehrere Spieler ab")
	var duplicate_color := RoundConfig.new()
	duplicate_color.mode = RoundConfig.GameMode.FREE_PLAY
	duplicate_color.players = [first, PlayerProfile.create(2, "B", 0)]
	duplicate_color.hole_ids = [&"reference_01"]
	_check(not duplicate_color.validate(holes).is_empty(), "Doppelte Spielerfarben werden abgelehnt")
	var free_config := RoundConfig.new()
	free_config.mode = RoundConfig.GameMode.FREE_PLAY
	free_config.players = [first]
	free_config.hole_ids = [&"reference_01", &"reference_01", &"double_gate_03"]
	_check(free_config.validate(holes).is_empty(), "Freies Spiel erlaubt geordnete Lochwiederholungen")
	_check(free_config.allows_restart() and not free_config.is_course_mode(), "Freies Spiel erlaubt schnellen Lochneustart")

	var round := RoundSession.new()
	round.configure(config, holes)
	_check(round.current_player_index == 0 and round.current_hole_index == 0, "Runde startet bei Spieler eins und Loch eins")
	_check(round.record_current_score(4, false) == RoundSession.AdvanceResult.NEXT_PLAYER, "Nach komplettem Loch folgt der naechste Spieler")
	_check(round.current_player_index == 1 and round.current_hole_index == 0, "Spielerwechsel bleibt am selben Loch")
	_check(round.record_current_score(8, true) == RoundSession.AdvanceResult.HOLE_COMPLETE, "Nach letztem Spieler erscheint die Lochtabelle")
	_check(round.scores[1][0] == 8 and round.capped[1][0], "Schlaglimit wird als 8 mit MAX-Markierung gespeichert")
	_check(round.advance_hole() and round.current_player_index == 0 and round.current_hole_index == 1, "Weiter setzt Spieler und Loch korrekt fort")
	round.record_current_score(3, false)
	round.record_current_score(3, false)
	round.advance_hole()
	round.record_current_score(4, false)
	_check(round.record_current_score(1, false) == RoundSession.AdvanceResult.ROUND_COMPLETE, "Letztes Ergebnis beendet die komplette Runde")
	_check(round.is_complete(), "Alle Tabellenfelder sind nach Rundenende gefuellt")
	_check(round.get_player_total(0) == 11 and round.get_player_difference(0) == 0, "Gesamtschlaege und Par-Differenz werden korrekt berechnet")
	_check(round.get_competition_rank(0) == 1 and round.get_competition_rank(1) == 2, "Endtabelle sortiert nach Gesamtschlaegen")

	var tied := RoundSession.new()
	tied.configure(config, holes)
	for hole_index in range(3):
		tied.scores[0][hole_index] = [4, 3, 4][hole_index]
		tied.scores[1][hole_index] = [4, 3, 4][hole_index]
	_check(tied.get_competition_rank(0) == 1 and tied.get_competition_rank(1) == 1, "Gleichstand teilt sich denselben Rang")
	var four_config := RoundConfig.new()
	four_config.mode = RoundConfig.GameMode.COURSE_LOCAL
	four_config.course_id = course.course_id
	four_config.players = [
		PlayerProfile.create(1, "A", 0), PlayerProfile.create(2, "B", 1),
		PlayerProfile.create(3, "C", 2), PlayerProfile.create(4, "D", 3),
	]
	four_config.hole_ids = course.hole_ids.slice(0, 3)
	var four_round := RoundSession.new()
	four_round.configure(four_config, holes)
	var four_scores := [[4, 4, 5, 6], [3, 3, 4, 5], [4, 4, 4, 4]]
	for hole_index in range(3):
		for player_index in range(4):
			four_round.record_current_score(four_scores[hole_index][player_index], false)
		if hole_index < 2:
			four_round.advance_hole()
	_check(four_round.is_complete(), "Vier Spieler absolvieren alle drei Kursloecher lochweise")
	_check(four_round.get_competition_rank(0) == 1 and four_round.get_competition_rank(1) == 1, "Vierer-Runde behaelt gemeinsame Spitzenraenge")
	_check(four_round.get_competition_rank(2) == 3 and four_round.get_competition_rank(3) == 4, "Nach Gleichstand werden die folgenden Raenge uebersprungen")

	var test_path := "user://putt_pixel_best_score_test.cfg"
	var absolute_test_path := ProjectSettings.globalize_path(test_path)
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_test_path)
	var store := BestScoreStore.new(test_path)
	_check(store.get_best(course.course_id) == -1, "Fehlender Bestwert wird fehlerfrei geladen")
	_check(store.submit(course.course_id, 14) == 14, "Erster Kursbestwert wird gespeichert")
	_check(store.submit(course.course_id, 16) == 14, "Schlechteres Ergebnis ueberschreibt den Bestwert nicht")
	_check(store.submit(course.course_id, 10) == 10 and store.get_best(course.course_id) == 10, "Besseres Ergebnis aktualisiert den Bestwert")
	_check(store.submit(arrow_course.course_id, 27) == 27 and store.get_best(course.course_id) == 10, "Pfeil-Armageddon speichert einen getrennten Kursbestwert")
	DirAccess.remove_absolute(absolute_test_path)

	var app_scene := load("res://scenes/game_app.tscn") as PackedScene
	var app := app_scene.instantiate() as GameApp
	get_tree().root.add_child(app)
	await get_tree().process_frame
	_check(app.current_screen == GameApp.ScreenState.TITLE, "App startet auf dem Titelbild statt direkt auf der Bahn")
	app._show_mode()
	app._go_back()
	_check(app.current_screen == GameApp.ScreenState.TITLE, "Kreisweg fuehrt von der Moduswahl zum Titel zurueck")
	app._select_mode(RoundConfig.GameMode.COURSE_SOLO)
	_check(app.current_screen == GameApp.ScreenState.PLAYER_NAME and app.desired_player_count == 1, "Einzelkurs fuehrt in die Ein-Spieler-Eingabe")
	app._select_mode(RoundConfig.GameMode.COURSE_LOCAL)
	_check(app.current_screen == GameApp.ScreenState.PLAYER_COUNT, "Lokaler Mehrspieler fragt die Spielerzahl ab")
	app._select_mode(RoundConfig.GameMode.PRACTICE)
	_check(app.current_screen == GameApp.ScreenState.PLAYER_NAME, "Uebung besitzt einen vollstaendigen Spielerpfad")
	app._select_mode(RoundConfig.GameMode.FREE_PLAY)
	_check(app.current_screen == GameApp.ScreenState.PLAYER_COUNT, "Freies Spiel besitzt einen eigenen Mehrspielerpfad")
	app._show_course_select()
	_check(app.option_buttons.size() == 6 and "KLASSISCHE NEUN" in app.option_buttons[0].text and "PFEIL-ARMAGEDDON" in app.option_buttons[1].text and "PROTOTYPKURS" in app.option_buttons[2].text, "Kursauswahl erzeugt drei Kurskarten aus den Daten")
	_check(app.option_buttons[3].disabled and app.option_buttons[5].disabled, "Drei Kurse passen ohne Ueberlappung auf die erste Kursseite")
	var extra_course := classic_course.duplicate(true) as CourseDefinition
	extra_course.course_id = &"course_page_test"
	extra_course.display_name = "SEITENTEST"
	app.course_catalog = app.course_catalog.duplicate(true) as CourseCatalog
	app.course_catalog.courses.append(extra_course)
	app._show_course_select()
	_check(not app.option_buttons[5].disabled, "Ein vierter Kurs aktiviert die Naechste-Seite")
	app._change_course_page(1)
	_check(app.course_select_page == 1 and app.option_buttons.size() == 4 and "SEITENTEST" in app.option_buttons[0].text, "Kursnavigation erreicht weitere datengetriebene Seiten")
	app.course_catalog = courses
	app.course_select_page = 0
	app.hole_select_page = 0
	app._show_hole_select()
	_check(app.option_buttons.size() == 8 and app.option_buttons[5].disabled and not app.option_buttons[7].disabled, "Uebung zeigt fuenf Bahnen mit Seitennavigation")
	app._change_hole_page(1)
	_check(app.hole_select_page == 1 and app.option_buttons.size() == 8, "Uebungsseite wechselt controllerfreundlich weiter")
	app.free_select_page = 4
	app._show_free_builder()
	_check(app.free_select_page == 4 and app.option_buttons.size() == 7, "Freies Spiel erreicht die letzte Seite aller zweiundzwanzig Kursbahnen")
	app.free_hole_ids = [&"reference_01", &"classic_diamond_02", &"reference_01"]
	_check(app._free_sequence_text() == "FOLGE: 1-2-1", "Freie Auswahl bewahrt Reihenfolge und Wiederholung")
	var practice_config := RoundConfig.new()
	practice_config.mode = RoundConfig.GameMode.PRACTICE
	practice_config.players = [first]
	practice_config.hole_ids = [&"classic_diamond_02"]
	app._start_round(practice_config)
	_check(app.current_screen == GameApp.ScreenState.GAMEPLAY and app.gameplay != null, "Rundenkonfiguration startet den wiederverwendbaren Gameplay-Bildschirm")
	_check(not app.gameplay.input_enabled, "Gameplay bleibt waehrend der Eingabeuebergabe zunaechst gesperrt")
	await get_tree().create_timer(0.10).timeout
	_check(app.gameplay.input_enabled, "Neutrale Eingabe gibt Gameplay nach dem Wechsel frei")
	app.gameplay.strokes = 8
	app.gameplay._on_ball_stopped(app.gameplay.ball.position)
	await get_tree().create_timer(0.60).timeout
	_check(app.current_screen == GameApp.ScreenState.FINAL, "Achter nicht eingelochter Schlag fuehrt zur Endtabelle")
	_check(app.session.scores[0][0] == 8 and app.session.capped[0][0], "Gameplay meldet das Schlaglimit an die Rundentabelle")
	var nine_config := RoundConfig.new()
	nine_config.mode = RoundConfig.GameMode.COURSE_SOLO
	nine_config.course_id = classic_course.course_id
	nine_config.players = [first]
	nine_config.hole_ids = classic_course.hole_ids.duplicate()
	nine_config.best_eligible = true
	var nine_round := RoundSession.new()
	nine_round.configure(nine_config, holes)
	var par_scores := [1, 1, 1, 2, 2, 2, 3, 3, 3]
	for hole_index in range(9):
		nine_round.record_current_score(par_scores[hole_index], false)
		if hole_index < 8:
			nine_round.advance_hole()
	_check(nine_round.is_complete() and nine_round.get_player_total(0) == 18 and nine_round.get_player_difference(0) == 0, "Neun-Loch-Tabelle summiert Par 18 korrekt")
	var arrow_config := RoundConfig.new()
	arrow_config.mode = RoundConfig.GameMode.COURSE_SOLO
	arrow_config.course_id = arrow_course.course_id
	arrow_config.players = [first]
	arrow_config.hole_ids = arrow_course.hole_ids.duplicate()
	arrow_config.best_eligible = true
	var arrow_round := RoundSession.new()
	arrow_round.configure(arrow_config, holes)
	var arrow_par_scores := [2, 2, 2, 3, 3, 3, 4, 4, 4]
	for hole_index in range(9):
		arrow_round.record_current_score(arrow_par_scores[hole_index], false)
		if hole_index < 8:
			arrow_round.advance_hole()
	_check(arrow_round.is_complete() and arrow_round.get_player_total(0) == 27 and arrow_round.get_player_difference(0) == 0, "Pfeil-Armageddon-Tabelle summiert Par 27 korrekt")
	app.queue_free()
	await get_tree().process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("  OK  ", description)
	else:
		failures += 1
		push_error("  FEHLER  " + description)
