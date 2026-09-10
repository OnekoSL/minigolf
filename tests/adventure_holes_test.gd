extends "res://tests/test_support.gd"


func _test_reference_hole() -> void:
	print("\n[Referenzloch 01]")
	var test_hole := _instantiate_hole(&"reference_01")
	await get_tree().process_frame
	var definition := test_hole.definition
	_check(definition.display_name == "S-KURVE AN DER MUEHLE", "Referenzloch besitzt den festgelegten Namen")
	_check(definition.par == 4, "Referenzloch ist Par 4")
	_check(definition.course_rect == Rect2(176, 16, 960, 328), "Referenzloch ist zwei Spielfenster breit")
	_check(definition.camera_center_bounds == Rect2(320, 180, 504, 0), "Referenzloch scrollt nur horizontal bis zur kompletten Aussenwand")
	_check(
		definition.lane_outline != null
			and definition.lane_outline.use_normalized_walls
			and is_equal_approx(definition.lane_outline.wall_thickness, 4.0),
		"Referenzloch verwendet eine geschlossene S-Kontur aus vier Pixel starken Normwaenden"
	)
	_check(definition.walls.is_empty(), "Referenzloch enthaelt keine freien Legacy-Waende")
	var surface_types: Dictionary = {}
	for surface in definition.surfaces:
		surface_types[surface.surface_type] = true
	_check(
		definition.surfaces.size() == 2
			and surface_types.has(SurfaceZone.SurfaceType.WATER)
			and surface_types.has(SurfaceZone.SurfaceType.SAND)
			and not surface_types.has(SurfaceZone.SurfaceType.SLOPE),
		"Referenzloch besitzt genau Wasser und Sand, aber keine Legacy-Gefaelleflaeche"
	)
	var valid_arrows := definition.arrow_tiles.size() == 18
	for arrow in definition.arrow_tiles:
		valid_arrows = valid_arrows \
			and arrow.cell_size == 16 \
			and arrow.direction == SurfaceZone.SlopeDirection.UP_RIGHT \
			and arrow.slope_grade == SurfaceZone.SlopeGrade.MEDIUM \
			and is_equal_approx(arrow.deceleration, 30.0) \
			and is_zero_approx(arrow.minimum_flow_speed) \
			and is_zero_approx(arrow.maximum_flow_speed) \
			and is_zero_approx(arrow.flow_alignment_rate) \
			and is_zero_approx(arrow.flow_centering_strength)
	_check(valid_arrows, "Ein reines blaues 6-x-3-Pfeilfeld ersetzt das alte Gefaelle")
	_check(definition.obstacles.size() == 1, "Riskanter Weg enthaelt genau eine Windmuehle")
	var windmill := definition.obstacles[0]
	_check(is_equal_approx(windmill.seconds_per_revolution, 2.4), "Windmuehle behaelt die getestete Umlaufzeit")
	_check(is_equal_approx(windmill.impulse_multiplier, 1.25), "Windmuehle behaelt den getesteten Impulsfaktor")
	test_hole.queue_free()
	await get_tree().process_frame
	var safe_completed := await _simulate_reference_route([
		[Vector2(480, 250), 245.0],
		[Vector2(710, 242), 310.0],
		[Vector2(850, 120), 285.0],
		[Vector2(1090, 65), 210.0],
	])
	_check(safe_completed, "Reproduzierbarer Sicherheitsweg beendet das Loch in vier Schlaegen")
	var risk_completed := await _simulate_reference_route([
		[Vector2(680, 155), 365.0],
		[Vector2(1090, 65), 255.0],
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
	_check(
		definition.lane_outline != null
			and definition.lane_outline.use_normalized_walls
			and is_equal_approx(definition.lane_outline.wall_thickness, 4.0)
			and definition.walls.is_empty(),
		"Diamantenlinie verwendet nur vier Pixel starke Normwaende"
	)
	var diagonal_counts := {WallTileDefinition.Variant.DIAGONAL_DOWN: 0, WallTileDefinition.Variant.DIAGONAL_UP: 0}
	for wall_tile in definition.wall_tiles:
		diagonal_counts[wall_tile.variant] = int(diagonal_counts.get(wall_tile.variant, 0)) + 1
	_check(
		definition.wall_tiles.size() == 20
			and diagonal_counts[WallTileDefinition.Variant.DIAGONAL_DOWN] == 10
			and diagonal_counts[WallTileDefinition.Variant.DIAGONAL_UP] == 10,
		"Zwanzig Diagonalbausteine bilden eine symmetrische geschlossene Mittelinsel"
	)
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
	_check(
		definition.lane_outline != null
			and definition.lane_outline.use_normalized_walls
			and is_equal_approx(definition.lane_outline.wall_thickness, 4.0)
			and definition.walls.is_empty()
			and definition.surfaces.is_empty(),
		"Doppeltor verwendet ausschliesslich seine geschlossene Normwandkontur"
	)
	_check(definition.obstacles.size() == 2, "Doppeltor enthaelt genau zwei zeitgesteuerte Tore")
	var valid_gate_data := true
	for obstacle in definition.obstacles:
		valid_gate_data = valid_gate_data and obstacle.obstacle_type == ObstacleDefinition.ObstacleType.SLIDING_GATE
		valid_gate_data = valid_gate_data and obstacle.gate_size == Vector2(10, 86)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.cycle_seconds, 2.8)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.transition_seconds, 0.25)
		valid_gate_data = valid_gate_data and is_equal_approx(obstacle.open_hold_seconds, 1.0)
	_check(valid_gate_data, "Beide Tore behalten Groesse und festgelegte Timingwerte")
	var closed_gate_top := definition.obstacles[0].position.y - definition.obstacles[0].gate_size.y * 0.5
	var closed_gate_bottom := definition.obstacles[0].position.y + definition.obstacles[0].gate_size.y * 0.5
	_check(
		closed_gate_top - 120.0 <= PrototypeBall.RADIUS * 2.0
			and 216.0 - closed_gate_bottom <= PrototypeBall.RADIUS * 2.0,
		"Geschlossene Tore lassen oberhalb und unterhalb keinen Ball vorbei"
	)
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
	var safe_completed := await _simulate_hole_route(&"double_gate_03", [
		[Vector2(410, 173), 225.0],
		[Vector2(735, 173), 280.0],
		[Vector2(850, 70), 190.0],
		[Vector2(960, 70), 160.0],
	], &"gates_open")
	_check(safe_completed, "Reproduzierbarer Wartezonenweg beendet das Doppeltor in vier Schlaegen")
	var risk_completed := await _simulate_hole_route(&"double_gate_03", [
		[Vector2(410, 173), 225.0],
		[Vector2(850, 105), 340.0],
		[Vector2(960, 70), 170.0],
	], &"gates_open")
	_check(risk_completed, "Gemeinsames Torfenster ermoeglicht einen reproduzierbaren Dreischlagweg")


func _test_cannon_workshop() -> void:
	print("\n[Loch 04: Die Kanonenwerkstatt]")
	var runtime := _instantiate_hole(&"cannon_workshop_04")
	await get_tree().physics_frame
	var definition := runtime.definition
	_check(definition.display_name == "DIE KANONENWERKSTATT", "Abenteuerbahn besitzt den festgelegten Namen")
	_check(definition.par == 4, "Kanonenwerkstatt ist Par 4")
	_check(definition.course_rect == Rect2(176, 16, 960, 328), "Kanonenwerkstatt besitzt den zweibildschirmbreiten Bahnraum")
	_check(definition.camera_center_bounds == Rect2(320, 180, 504, 0), "Kanonenwerkstatt scrollt nur horizontal")
	_check(
		definition.lane_outline != null
			and definition.lane_outline.use_normalized_walls
			and is_equal_approx(definition.lane_outline.wall_thickness, 4.0)
			and definition.walls.is_empty()
			and definition.surfaces.is_empty(),
		"Kanonenwerkstatt verwendet nur Kontur- und Innenwaende aus Normbausteinen"
	)
	var workshop_cells := {}
	var t_piece_count := 0
	for wall_tile in definition.wall_tiles:
		workshop_cells[wall_tile.grid_cell] = wall_tile.variant
		if wall_tile.variant in [WallTileDefinition.Variant.T_LEFT, WallTileDefinition.Variant.T_RIGHT]:
			t_piece_count += 1
	var machine_barrier_complete := true
	for grid_y in range(2, 20):
		machine_barrier_complete = machine_barrier_complete and workshop_cells.has(Vector2i(42, grid_y))
	_check(machine_barrier_complete and t_piece_count == 3, "Maschinenwand und drei T-Stuecke trennen beide Kanonenwege lueckenlos")
	_check(
		workshop_cells.has(Vector2i(22, 16))
			and not workshop_cells.has(Vector2i(22, 17))
			and workshop_cells.has(Vector2i(22, 18)),
		"Die einzige Oeffnung der Schalterwand liegt genau auf dem Pflichtschalter"
	)
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


func _simulate_reference_route(shots: Array) -> bool:
	return await _simulate_hole_route(&"reference_01", shots, &"reference_open")


func _simulate_cannon_route(use_risk_cannon: bool) -> bool:
	var runtime := _instantiate_hole(&"cannon_workshop_04")
	await get_tree().physics_frame
	var ball := PrototypeBall.new()
	get_tree().root.add_child(ball)
	ball.set_physics_process(false)
	ball.position = runtime.get_tee_position()
	ball.configure_environment(runtime.zones, runtime.get_hole_position(), runtime.get_tunnels())
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


