extends "res://tests/test_support.gd"


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
	await _test_short_putts()


func _test_short_putts() -> void:
	print("\n[Kurze Schlaege von 1 bis 10 dm]")
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.configure_environment([], Vector2(10000, 10000))
	var controller := ShotController.new()
	get_tree().root.add_child(controller)
	controller.set_process(false)
	var meter := PowerDistanceMeter.new()
	controller.shot_committed.connect(func(direction: Vector2, speed: float, _accuracy: float):
		ball.launch(direction, speed, 1)
	)
	for distance_dm in range(1, 11):
		var previous_position := Vector2.ZERO
		for attempt in range(2):
			ball.position = Vector2(250, 180)
			ball.moving = false
			controller.configure(ball, Rect2(176, 16, 448, 328))
			controller.action_pressed()
			controller.power_value = meter.power_for_distance_dm(float(distance_dm))
			controller.action_pressed()
			controller.accuracy_value = 0.0
			controller.action_pressed()
			controller.action_released()
			controller.advance_swing(controller.swing_contact_delay)
			for step in range(180):
				if not ball.moving:
					break
				ball._physics_process(1.0 / 60.0)
			var actual_dm := (ball.position.x - 250.0) / 3.2
			_check(not ball.moving and absf(actual_dm - distance_dm) < 0.3, "%d dm: Echter Schlag rollt bis zur angezeigten Weite aus (%.2f dm)" % [distance_dm, actual_dm])
			if attempt == 1:
				_check(ball.position.is_equal_approx(previous_position), "%d dm: Kurzer Schlag bleibt reproduzierbar" % distance_dm)
			previous_position = ball.position
	meter.free()
	controller.free()
	ball.free()


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
	_check(not PrototypeBall.should_settle_static_wall_contact(Vector2(100, 0), Vector2.LEFT, 1), "Kraeftiger erster Bandentreffer prallt weiterhin ab")
	_check(PrototypeBall.should_settle_static_wall_contact(Vector2(20, 0), Vector2.LEFT, 1), "Schwacher Bandentreffer darf an der Wand ausrollen")
	_check(PrototypeBall.should_settle_static_wall_contact(Vector2(105, 0), Vector2.LEFT, 2), "Wiederholter Gefaelleruecklauf wird an derselben Wand beruhigt")
	_check(PrototypeBall.remove_inward_wall_velocity(Vector2(20, 12), Vector2.LEFT).is_equal_approx(Vector2(0, 12)), "Ruhelage entfernt nur die Bewegung in die Wand")
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


func _test_tunnel_pair() -> void:
	print("\n[Verborgene Tunnelloecher]")
	var tunnel := TunnelDefinition.new()
	tunnel.endpoint_a = Vector2(48, 100)
	tunnel.endpoint_b = Vector2(160, 100)
	_check(tunnel.validate("Testtunnel").is_empty(), "Zwei getrennte Loecher bilden ein gueltiges Tunnelpaar")
	_check(tunnel.get_other_endpoint(tunnel.endpoint_b) == tunnel.endpoint_a, "Beide Loecher verweisen wechselseitig aufeinander")
	var invalid := TunnelDefinition.new()
	invalid.endpoint_a = Vector2(48, 100)
	invalid.endpoint_b = Vector2(56, 100)
	_check(not invalid.validate("Zu kurzer Testtunnel").is_empty(), "Ueberlappende Tunnelloecher werden abgelehnt")

	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = Vector2(40, 100)
	ball.configure_environment([], Vector2(1000, 1000), [tunnel])
	ball.launch(Vector2.RIGHT, 120.0, 1)
	ball._physics_process(1.0 / 60.0)
	_check(ball.is_tunnel_sequence_active(), "Ein rollender Ball wird vom unmarkierten Tunnelloch aufgenommen")
	ball.advance_tunnel_sequence(PrototypeBall.TUNNEL_DURATION)
	_check(not ball.is_tunnel_sequence_active(), "Der Ball erscheint nach kurzer Einzugsanimation am Partnerloch")
	_check(ball.position.is_equal_approx(Vector2(173, 100)), "Der Ball verlaesst das Partnerloch ausserhalb des erneuten Aufnahmebereichs")
	_check(ball.velocity.is_equal_approx(Vector2(120, 0)), "Der Tunnel erhaelt Richtung und Geschwindigkeit des Balls")
	ball.queue_free()
	await get_tree().process_frame

	var reverse_ball := PrototypeBall.new()
	get_tree().root.add_child(reverse_ball)
	reverse_ball.set_physics_process(false)
	reverse_ball.position = Vector2(168, 100)
	reverse_ball.configure_environment([], Vector2(1000, 1000), [tunnel])
	reverse_ball.launch(Vector2.LEFT, 120.0, 1)
	reverse_ball._physics_process(1.0 / 60.0)
	reverse_ball.advance_tunnel_sequence(PrototypeBall.TUNNEL_DURATION)
	_check(reverse_ball.position.is_equal_approx(Vector2(35, 100)), "Dasselbe Tunnelpaar funktioniert auch in Gegenrichtung")
	_check(reverse_ball.velocity.is_equal_approx(Vector2(-120, 0)), "Auch rueckwaerts bleibt die Austrittsrichtung erhalten")
	reverse_ball.queue_free()
	await get_tree().process_frame


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


func _test_atomic_arrow_dynamics() -> void:
	print("\n[Atomare Pfeilkraefte]")
	var default_tile := ArrowTileDefinition.new()
	_check(is_equal_approx(default_tile.deceleration, 30.0), "Atomare Pfeilbloecke verwenden nur 30 px/s2 Rollwiderstand")
	var grade_names := ["flach", "mittel", "steil"]
	var expected_downhill := [30.0, 60.0, 120.0]
	var expected_uphill_braking := [90.0, 120.0, 180.0]
	for grade in range(3):
		var tile := ArrowTileDefinition.new()
		tile.direction = SurfaceZone.SlopeDirection.RIGHT
		tile.slope_grade = grade
		var zone := tile.instantiate_zone()
		var data := zone.get_surface_data()
		var acceleration := data.acceleration
		var resistance := data.deceleration
		var downhill := PrototypeBall.apply_deceleration(
			PrototypeBall.apply_surface_acceleration(Vector2.ZERO, acceleration, 1.0),
			resistance,
			1.0
		)
		var uphill_start := Vector2.LEFT * 300.0
		var uphill := PrototypeBall.apply_deceleration(
			PrototypeBall.apply_surface_acceleration(uphill_start, acceleration, 1.0),
			resistance,
			1.0
		)
		var uphill_braking := uphill_start.length() - uphill.length()
		_check(
			is_equal_approx(downhill.x, expected_downhill[grade])
			and is_equal_approx(uphill_braking, expected_uphill_braking[grade]),
			"Pfeilstufe %s beschleunigt bergab und bremst bergauf mit abgestufter Kraft" % grade_names[grade]
		)
		zone.free()


func _test_slope_wall_settling() -> void:
	print("\n[Gefaelle an Begrenzungswand]")
	var slope := SurfaceZone.new()
	slope.configure_slope(
		Rect2(0, 0, 128, 64),
		SurfaceZone.SlopeDirection.RIGHT,
		SurfaceZone.STEEP_SLOPE_ACCELERATION,
		50.0,
		105.0,
		105.0,
		12.0
	)
	get_tree().root.add_child(slope)
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 0
	wall.position = Vector2(108, 32)
	var wall_collision := CollisionShape2D.new()
	var wall_shape := RectangleShape2D.new()
	wall_shape.size = Vector2(8, 64)
	wall_collision.shape = wall_shape
	wall.add_child(wall_collision)
	get_tree().root.add_child(wall)
	var ball := PrototypeBall.new()
	ball.position = Vector2(48, 32)
	get_tree().root.add_child(ball)
	await get_tree().physics_frame
	var slope_zones: Array[SurfaceZone] = [slope]
	ball.configure_environment(slope_zones, Vector2(-1000, -1000))
	var wall_hits := {"count": 0}
	ball.wall_hit.connect(func(_intensity, _position, _normal, _kind): wall_hits["count"] += 1)
	ball.launch(Vector2.RIGHT, 120.0, 1)
	for _step in range(240):
		await get_tree().physics_frame
		if not ball.moving:
			break
	_check(int(wall_hits["count"]) >= 2, "Testball erreicht dieselbe Gefaellewand wiederholt")
	_check(not ball.moving and ball.position.x < wall.position.x, "Wiederholter Ruecklauf kommt an der Wand zur Ruhe")
	ball.queue_free()
	wall.queue_free()
	slope.queue_free()
	await get_tree().process_frame


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
	_check(surface_data.acceleration.normalized().is_equal_approx(Vector2.RIGHT), "Flaechendrehung veraendert die Welt-Pfeilrichtung nicht")
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

