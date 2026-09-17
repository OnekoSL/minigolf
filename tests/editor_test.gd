extends RefCounted


static func run(host: Node, check: Callable) -> void:
	var document := EditorDocument.new()
	check.call(document.blocking_issues().is_empty(), "Editor: neue Rechteckbahn ist gültig")
	var codec := EditorCodec.new()
	var source := HoleCatalog.load_default()
	var roundtrip_count := 0
	for hole in source.holes:
		if not hole.is_course_hole():
			continue
		var encoded: Dictionary = EditorCodec.encode(hole)
		var decoded := codec.decode(JSON.parse_string(JSON.stringify(encoded)), "hole") as HoleDefinition
		check.call(decoded != null, "Editor: Vorlage %s lässt sich laden (%s)" % [hole.hole_id, codec.error])
		if decoded != null:
			check.call(JSON.stringify(EditorCodec.encode(decoded)) == JSON.stringify(encoded), "Editor: sämtliche Eigenschaften von %s bleiben erhalten" % hole.hole_id)
			roundtrip_count += 1
	check.call(roundtrip_count > 90, "Editor: vollständiger regulärer Vorlagenbestand geprüft")
	var before := document.text()
	document.begin()
	document.hole.par = 4
	document.hole.tee_position += Vector2(16, 0)
	document.commit()
	document.undo()
	check.call(document.text() == before, "Editor: zusammenhängende Änderung rückgängig")
	document.redo()
	check.call(document.hole.par == 4, "Editor: Änderung wiederhergestellt")
	document.begin()
	document.hole.display_name = "Abbruch"
	document.cancel()
	check.call(document.hole.display_name == "Meine Bahn", "Editor: Escape verwirft laufende Änderung")
	var template := source.holes[0]
	var original: Dictionary = EditorCodec.encode(template)
	var copied := EditorDocument.new(template, true)
	copied.hole.tee_position += Vector2(16, 16)
	check.call(JSON.stringify(EditorCodec.encode(template)) == JSON.stringify(original), "Editor: Vorlage wird nicht verändert")
	check.call(copied.hole.hole_id != template.hole_id, "Editor: Vorlage erhält unabhängige Identität")
	var trigger := TriggerDefinition.new()
	trigger.trigger_id = &"switch_test"
	trigger.position = Vector2(280, 160)
	var cannon := CannonDefinition.new()
	cannon.mechanism_id = &"cannon_test"
	cannon.position = Vector2(320, 160)
	cannon.landing_position = Vector2(480, 160)
	document.hole.triggers.append(trigger)
	document.hole.cannons.append(cannon)
	document.ensure_ids()
	document.link(trigger, cannon)
	document.selection = [String(trigger.get_meta("editor_id")), String(cannon.get_meta("editor_id"))]
	document.duplicate_selection()
	check.call(document.hole.triggers.size() == 2 and document.hole.cannons.size() == 2, "Editor: verbundene Gruppe dupliziert")
	check.call(document.hole.cannons[1].required_trigger_id == document.hole.triggers[1].trigger_id and document.hole.triggers[1].target_ids == [document.hole.cannons[1].mechanism_id], "Editor: Kopieverknüpfung zeigt auf die Kopien")
	document.selection = [String(document.hole.cannons[1].get_meta("editor_id"))]
	document.delete_selection()
	check.call(document.hole.triggers[1].target_ids.is_empty(), "Editor: Löschen entfernt Verbindungsreferenz")
	document.undo()
	check.call(document.hole.triggers[1].target_ids.size() == 1, "Editor: Rückgängig stellt Verbindungen wieder her")
	var bad: Dictionary = EditorCodec.encode(document.hole)
	bad.fields["script"] = "res://evil.gd"
	check.call(codec.decode(bad) == null, "Editor: Import lehnt ausführbare Eigenschaften ab")
	bad = EditorCodec.encode(document.hole)
	bad.fields.tee_position = ["falsch", 42]
	check.call(codec.decode(bad) == null, "Editor: falsche Koordinatentypen werden abgelehnt")
	bad = EditorCodec.encode(document.hole)
	bad.fields.lane_outline = EditorCodec.encode(CannonDefinition.new())
	check.call(codec.decode(bad) == null, "Editor: falsche Ressource in Kontur wird abgelehnt")
	bad = EditorCodec.encode(document.hole)
	bad.fields.walls = [EditorCodec.encode(TunnelDefinition.new())]
	check.call(codec.decode(bad) == null, "Editor: falscher Bauteiltyp in typisierter Liste wird abgelehnt")
	_geometry(check)
	await _storage(host, check)
	await _runtime(host, check)
	await _mechanism_states(host, check)
	await _ui(host, check)
	await _playtest(host, check)
	await _custom_round(host, check)


static func _storage(_host: Node, check: Callable) -> void:
	var path := "user://editor_tests/" + EditorCodec.new_id("run_")
	var store := CustomContentStore.new(path)
	var document := EditorDocument.new()
	check.call(store.save_hole(document.hole), "Editor: neue Bahn speichern")
	var course := CourseDefinition.new()
	course.course_id = EditorCodec.new_id()
	course.display_name = "Testkurs"
	course.hole_ids = [document.hole.hole_id, document.hole.hole_id]
	check.call(store.save_course(course), "Editor: Kurs mit Wiederholung speichern")
	var key := store.best_key(course)
	document.hole.display_name = "Anderer Name"
	document.hole.theme = load("res://data/themes/baustelle.tres")
	store.save_hole(document.hole)
	check.call(store.best_key(course) == key, "Editor: Gestaltung und Name erhalten Bestwertschlüssel")
	document.hole.par += 1
	store.save_hole(document.hole)
	check.call(store.best_key(course) != key, "Editor: PAR-Änderung trennt Bestwerte")
	check.call(not store.delete_hole(document.hole.hole_id), "Editor: verwendete Bahn kann nicht gelöscht werden")
	var reloaded := CustomContentStore.new(path)
	check.call(reloaded.load_library() and reloaded.holes.size() == 1 and reloaded.courses.size() == 1, "Editor: Neustart lädt Bibliothek")
	check.call(store.export_course(course, path.path_join("export.json")), "Editor: Kurs inklusive Bahnen exportiert")
	check.call(reloaded.import_file(path.path_join("export.json")), "Editor: Kursdatei importiert")
	check.call(reloaded.holes.size() == 2 and reloaded.courses.size() == 2 and reloaded.holes[1].hole_id != reloaded.holes[0].hole_id, "Editor: Import bekommt eigene Kennungen")
	check.call(reloaded.courses[1].hole_ids == [reloaded.holes[1].hole_id, reloaded.holes[1].hole_id], "Editor: Import erhält Reihenfolge und Wiederholungen")
	document.hole.lane_outline.points.clear()
	check.call(store.save_hole(document.hole), "Editor: unvollständiger Entwurf speicherbar")
	check.call(store.playable_catalog().holes.is_empty(), "Editor: Entwurf nicht spielbar")
	var corrupt := FileAccess.open(path.path_join("library.json"), FileAccess.WRITE)
	corrupt.store_string("broken")
	corrupt.close()
	check.call(not reloaded.load_library() and not reloaded.save_hole(EditorDocument.new().hole), "Editor: beschädigte Bibliothek wird nicht überschrieben")
	check.call(FileAccess.get_file_as_string(path.path_join("library.json")) == "broken", "Editor: beschädigte Originaldatei bleibt erhalten")
	var blocker := FileAccess.open(path.path_join("blocker"), FileAccess.WRITE)
	blocker.store_string("x")
	blocker.close()
	var denied := CustomContentStore.new(path.path_join("blocker/child"))
	check.call(not denied.save_hole(EditorDocument.new().hole) and denied.holes.is_empty(), "Editor: Schreibfehler wird gemeldet und Speicherzustand zurückgerollt")
	_cleanup(path)


static func _runtime(host: Node, check: Callable) -> void:
	var document := EditorDocument.new()
	var obstacle := ObstacleDefinition.new()
	obstacle.position = Vector2(400, 180)
	obstacle.obstacle_type = ObstacleDefinition.ObstacleType.SLIDING_GATE
	document.hole.obstacles.append(obstacle)
	var game := PrototypeMain.new()
	game.configure_attempt(document.hole, PlayerProfile.create(1, "Test", 0), true, 1, 1, 0, false)
	host.add_child(game)
	game.set_input_enabled(false)
	check.call(game.hole.definition == document.hole, "Editor: Spielstart verwendet ungespeicherte Definition direkt")
	game.shot_controller._locked_power = 0.5
	game.shot_controller._locked_accuracy = 0
	game.shot_controller.state = ShotController.ShotState.ARMED
	game.shot_controller.action_released()
	var state := EditorTestState.capture(game)
	var gate: TimedSlidingGate = game.hole.obstacle_nodes[0]
	var old_position := gate.position
	var old_clock := gate.elapsed_seconds
	gate.advance_motion(0.8)
	game.ball.start_mechanism_transport(Vector2(230, 280), Vector2(400, 200), Vector2(100, 0), 0.2, 0.6)
	game.strokes = 5
	state.restore(game)
	check.call(gate.position == old_position and gate.elapsed_seconds == old_clock, "Editor: Schlagwiederholung stellt Torstellung und Uhr wieder her")
	check.call(not game.ball.is_tunnel_sequence_active() and game.strokes == 0, "Editor: Schlagwiederholung stellt Balltransport und Schlagzahl wieder her")
	check.call(game.shot_controller.state == ShotController.ShotState.SWINGING and game.shot_controller._swing_elapsed == 0, "Editor: Schlagwiederholung startet synchronen Abschwung")
	game.queue_free()
	await host.get_tree().process_frame


static func _ui(host: Node, check: Callable) -> void:
	var ui := EditorUI.new()
	var path := "user://editor_tests/" + EditorCodec.new_id("ui_")
	ui.store = CustomContentStore.new(path)
	host.add_child(ui)
	await host.get_tree().process_frame
	check.call(ui.canvas != null and ui.canvas.runtime != null, "Editor: Oberfläche zeigt gültige neue Bahn")
	var before := ui.document.hole.arrow_tiles.size()
	ui.canvas.set_tool("arrow")
	ui.canvas._press(Vector2(256, 144), false)
	ui.canvas._drag(Vector2(320, 144))
	ui.canvas._release(Vector2(320, 144))
	check.call(ui.document.hole.arrow_tiles.size() >= before + 5, "Editor: Ziehen malt lückenlose Pfeilreihe")
	ui.document.undo()
	check.call(ui.document.hole.arrow_tiles.size() == before, "Editor: gesamte Pinselbewegung ist ein Rückgängig-Schritt")
	ui.canvas.set_tool("arrow_rect")
	ui.canvas._press(Vector2(256, 144), false)
	ui.canvas._release(Vector2(304, 176))
	check.call(ui.document.hole.arrow_tiles.size() == 12, "Editor: Rechteckwerkzeug füllt ein ganzes Pfeilfeld")
	ui.document.undo()
	ui.canvas.set_tool("boundary_arc")
	ui.canvas._press(Vector2(400, 24), false)
	ui.canvas._release(Vector2(400, 24))
	var arc := ui.document.hole.lane_outline.boundary_arcs[0]
	check.call(ui.document.boundary_edge(arc) == 0, "Editor: Außenbogen ist an genau einer Konturkante verankert")
	ui.document.set_boundary_bulge(arc, 48)
	check.call(ui.document.boundary_edge(arc) == 0 and absf(ui.document.boundary_bulge(arc) - 48) < 0.001, "Editor: Bogenänderung erhält beide Anker")
	ui.document.undo()
	ui.canvas.set_tool("tunnel")
	ui.canvas._press(Vector2(320, 208), false)
	ui.canvas._release(Vector2(320, 208))
	check.call(ui.canvas.tool == "select", "Editor: Tunnelplatzierung wechselt automatisch zum Verschieben")
	ui.canvas._press(Vector2(416, 208), false)
	ui.canvas._drag(Vector2(480, 240))
	ui.canvas._release(Vector2(480, 240))
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(320, 208) and ui.document.hole.tunnels[0].endpoint_b == Vector2(480, 240), "Editor: Ziehpunkt verschiebt nur den gewählten Tunnelendpunkt")
	check.call(ui.document.hole.tunnels.size() == 1, "Editor: unmittelbares Ziehen nach Tunnelplatzierung erzeugt kein weiteres Paar")
	ui.canvas._press(Vector2(400, 224), false)
	ui.canvas._drag(Vector2(416, 240))
	ui.canvas._drag(Vector2(448, 256))
	ui.canvas._release(Vector2(448, 256))
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(368, 240) and ui.document.hole.tunnels[0].endpoint_b == Vector2(528, 272), "Editor: mittlerer Tunnelgriff verschiebt beide Enden gemeinsam")
	ui.document.undo()
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(320, 208) and ui.document.hole.tunnels[0].endpoint_b == Vector2(480, 240), "Editor: gemeinsame Tunnelbewegung ist ein Rückgängig-Schritt")
	ui.document.redo()
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(368, 240) and ui.document.hole.tunnels[0].endpoint_b == Vector2(528, 272), "Editor: Wiederholen stellt beide Tunnelenden wieder her")
	ui.canvas._press(Vector2(448, 256), false)
	ui.canvas._drag(Vector2(416, 224))
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	ui.canvas._gui_input(escape)
	ui.canvas._release(Vector2(416, 224))
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(368, 240) and ui.document.hole.tunnels[0].endpoint_b == Vector2(528, 272), "Editor: Escape bricht gemeinsame Tunnelbewegung vollständig ab")
	ui.document.undo()
	ui.document.undo()
	ui.document.undo()
	ui.canvas.set_tool("tunnel")
	ui.canvas._press(Vector2(320, 208), false)
	ui.canvas._drag(Vector2(352, 224))
	ui.canvas._release(Vector2(352, 224))
	check.call(ui.document.hole.tunnels[0].endpoint_a == Vector2(352, 224) and ui.document.hole.tunnels[0].endpoint_b == Vector2(448, 224), "Editor: Ziehen beim Setzen platziert das ganze Tunnelpaar")
	ui.document.undo()
	ui._write_recovery()
	check.call(FileAccess.file_exists(path.path_join("recovery.json")), "Editor: ungespeicherter Entwurf erhält getrennte Wiederherstellungsdatei")
	ui._save()
	check.call(not FileAccess.file_exists(path.path_join("recovery.json")), "Editor: explizites Speichern entfernt die veraltete Wiederherstellung")
	ui.show_library()
	check.call(ui._library_list.item_count == 1, "Editor: gespeicherte Bahn in Bibliothek sichtbar")
	ui.queue_free()
	await host.get_tree().process_frame
	host.get_window().content_scale_size = Vector2i(640, 360)
	_cleanup(path)


static func _mechanism_states(host: Node, check: Callable) -> void:
	var hole := EditorDocument.new().hole
	hole.course_rect.size = Vector2(1440, 800)
	hole.lane_outline.points = PackedVector2Array([Vector2(184, 24), Vector2(1608, 24), Vector2(1608, 808), Vector2(184, 808)])
	hole.camera_center_bounds = Rect2(Vector2(320, 180), Vector2(984, 464))
	for kind in range(5):
		var obstacle := ObstacleDefinition.new()
		obstacle.obstacle_type = kind
		obstacle.position = Vector2(350 + kind * 240, 420)
		obstacle.seconds_per_revolution = 16
		hole.obstacles.append(obstacle)
	var cannon := CannonDefinition.new()
	cannon.mechanism_id = &"capture"
	cannon.required_trigger_id = &"enable"
	cannon.position = Vector2(500, 160)
	cannon.landing_position = Vector2(600, 160)
	hole.cannons.append(cannon)
	var trigger := TriggerDefinition.new()
	trigger.trigger_id = &"enable"
	trigger.target_ids = [&"capture"]
	trigger.position = Vector2(300, 160)
	hole.triggers.append(trigger)
	var game := PrototypeMain.new()
	game.configure_attempt(hole, PlayerProfile.create(1, "Test", 0), true, 1, 1, 0, false)
	host.add_child(game)
	game.set_input_enabled(false)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for node in [game.ball, game.hole, game.shot_controller]:
		node.process_mode = Node.PROCESS_MODE_DISABLED
	var state := EditorTestState.capture(game)
	var seesaw: SeesawObstacle = game.hole.obstacle_nodes[2]
	var elephant: ElephantObstacle = game.hole.obstacle_nodes[4]
	var rotation_before: float = game.hole.obstacle_nodes[0].rotation
	game.hole.obstacle_nodes[0].rotation += 1
	game.hole.obstacle_nodes[1].advance_motion(0.8)
	seesaw.advance_tilt(0.3, 40)
	game.hole.obstacle_nodes[3].rotation += 1
	elephant.advance_motion(0.6)
	game.hole.trigger_nodes[0].activate()
	game.ball.launch(Vector2.RIGHT, 100, 1)
	game.ball.start_cannon_sequence(&"capture", Vector2(500, 160), Vector2(600, 160), 0.2, 0.12, 0.55, 34, Vector2(55, 0))
	check.call(game.ball.is_cannon_sequence_active(), "Editor: Zustandsprüfung startet eine echte Kanonensequenz")
	state.restore(game)
	check.call(game.hole.obstacle_nodes[0].rotation == rotation_before and game.hole.obstacle_nodes[3].rotation == 0, "Editor: Rotor und Zahnrad werden zurückgestellt")
	check.call(seesaw.tilt == seesaw.preferred_tilt and seesaw.left_end_collision.disabled == not seesaw.is_left_end_blocking(), "Editor: Wippenneigung und Kollisionssperren werden gemeinsam restauriert")
	check.call(elephant.elapsed == 0 and elephant.passenger == null and elephant.trunk.elapsed_seconds == 0, "Editor: Elefant und beide Gliedmaßen werden zurückgestellt")
	check.call(not game.hole.trigger_nodes[0].is_activated and not game.hole.cannon_nodes[0].is_enabled and not game.ball.is_cannon_sequence_active(), "Editor: Schalter, Kanonensperre und Flugzustand werden restauriert")
	game.ball.current_stroke_count = 1
	game.ball.start_mechanism_transport(Vector2(300, 160), Vector2(400, 160), Vector2(100, 0), 0.0, 0.6)
	game.ball.advance_tunnel_sequence(0.1)
	var transported := EditorTestState.capture(game)
	game.ball.advance_tunnel_sequence(0.2)
	transported.restore(game)
	check.call(game.ball.is_tunnel_sequence_active() and is_equal_approx(game.ball._tunnel_elapsed, 0.1), "Editor: laufender Transport erhält seinen vollständigen Zwischenstand")
	state.restore(game)
	seesaw.advance_tilt(0.2, 40)
	state.restore(game)
	check.call(seesaw.tilt == seesaw.preferred_tilt, "Editor: Zustand kann mehrfach wiederhergestellt werden")
	game.queue_free()
	await host.get_tree().process_frame


static func _playtest(host: Node, check: Callable) -> void:
	var previous_mode := host.process_mode
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	var test := EditorPlaytest.new()
	test.definition = EditorDocument.new().hole
	host.add_child(test)
	check.call(not test.game.input_enabled and host.get_tree().paused, "Editor: Teststart wartet auf neutrale Eingabe ohne Mechanikvorlauf")
	for _frame in range(20):
		await host.get_tree().process_frame
	check.call(test.game.input_enabled and not host.get_tree().paused, "Editor: neutrale Eingabe gibt Testspiel frei")
	test.game.shot_controller._locked_power = 0.25
	test.game.shot_controller._locked_accuracy = 0
	test.game.shot_controller.state = ShotController.ShotState.ARMED
	test.game.shot_controller.action_released()
	check.call(test.snapshot != null, "Editor: Abschwung zeichnet vollständigen Testzustand auf")
	for _frame in range(35):
		await host.get_tree().physics_frame
	check.call(test.game.strokes == 1 and test.trace.get_point_count() > 0, "Editor: Testschlag läuft über echte Physik und zeichnet Spur")
	await test._repeat()
	check.call(test.game.strokes == 0 and test.game.shot_controller.state == ShotController.ShotState.SWINGING, "Editor: Wiederholung beginnt vor dem Ballkontakt")
	for _frame in range(35):
		await host.get_tree().physics_frame
	check.call(test.game.strokes == 1, "Editor: wiederholter Abschwung zählt genau einen Schlag")
	test._toggle_pause()
	var before := test.game.ball.position
	for _frame in range(20):
		await host.get_tree().process_frame
	check.call(test.game.ball.position == before, "Editor: Pause friert Ballphysik ein")
	test._toggle_pause()
	for _frame in range(20):
		await host.get_tree().process_frame
	test._place_mode()
	check.call(test.placing and host.get_tree().paused and not test.game.input_enabled, "Editor: Ballplatzierung pausiert und sperrt Schlageingabe")
	check.call(test.can_place(Vector2(400, 240)) and not test.can_place(Vector2(184, 24)), "Editor: Ballplatzierung berücksichtigt Ballradius und echte Kollision")
	test._close()
	check.call(not host.get_tree().paused, "Editor: Verlassen des Tests hebt die globale Pause auf")
	test.queue_free()
	await host.get_tree().process_frame
	host.process_mode = previous_mode


static func _custom_round(host: Node, check: Callable) -> void:
	var app := GameApp.new()
	host.add_child(app)
	var hole := EditorDocument.new().hole
	var course := CourseDefinition.new()
	course.course_id = EditorCodec.new_id()
	course.display_name = "Eigener Rundentest"
	course.hole_ids = [hole.hole_id, hole.hole_id]
	app.hole_catalog.holes.append(hole)
	app.course_catalog.courses.append(course)
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	config.content_origin = RoundConfig.ContentOrigin.CUSTOM
	config.course_id = course.course_id
	config.hole_ids = course.hole_ids.duplicate()
	config.players = [PlayerProfile.create(1, "Eins", 0), PlayerProfile.create(2, "Zwei", 1)]
	check.call(config.validate(app.hole_catalog, app.course_catalog).is_empty(), "Editor: eigener Kurs ist mit zwei Spielern gültig")
	config.content_origin = RoundConfig.ContentOrigin.OFFICIAL
	check.call(not config.validate(app.hole_catalog, app.course_catalog).is_empty(), "Editor: eigene Kurse können sich nicht als offizielle Kurse ausgeben")
	config.content_origin = RoundConfig.ContentOrigin.CUSTOM
	app._start_round(config)
	check.call(app.gameplay.hole.definition.hole_id == hole.hole_id and app.best_store.storage_path == "user://custom_content/progress.cfg", "Editor: eigener Kurs nutzt eigene Bahn und getrennte Bestwerte")
	app._on_attempt_finished(2, false)
	check.call(app.session.current_player_index == 1, "Editor: eigener Kurs wechselt im Hotseat zum zweiten Spieler")
	app.session.record_current_score(3, false)
	app.session.advance_hole()
	app.session.record_current_score(1, false)
	app.session.record_current_score(2, false)
	var path := "user://editor_tests/" + EditorCodec.new_id("scores_")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
	app.best_store = BestScoreStore.new(path.path_join("progress.cfg"))
	app._update_best_score()
	check.call(app.best_store.get_best(app._active_best_score_key()) == 3, "Editor: vollständige eigene Runde speichert den besseren Gesamtwert")
	var key := app._active_best_score_key()
	hole.tee_position += Vector2(16, 0)
	check.call(app._active_best_score_key() != key, "Editor: geometrische Änderung trennt Kurswertung")
	app.queue_free()
	await host.get_tree().process_frame
	_cleanup(path)


static func _cleanup(path: String) -> void:
	# Only the freshly generated, isolated test directory is removed.
	for name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _geometry(check: Callable) -> void:
	var document := EditorDocument.new()
	var arc := WallDefinition.new()
	arc.wall_type = WallDefinition.WallType.ARC
	arc.center = Vector2(400, 160)
	arc.radius = 32
	arc.rotation_degrees = 90
	arc.thickness = 4
	document.hole.walls.append(arc)
	var points := EditorDocument.arc_points(arc)
	check.call(points[0].is_equal_approx(Vector2(400, 192)), "Editor: Bogenhilfen berücksichtigen Mittelpunkt und Drehung")
	check.call(not document.clear_position(Vector2(400, 192)), "Editor: Ballplatzierung erkennt versetzte und gedrehte Bogenkollision")
	document.begin()
	arc.arc_segments = 0
	document.commit()
	check.call(not document.blocking_issues().is_empty(), "Editor: ungültige Bogensegmentierung wird vor dem Geometriebau abgefangen")
	check.call(EditorDocument.arc_points(arc).is_empty(), "Editor: ungültiger Bogen bleibt auch als Vorschau ohne ungültige Koordinaten bearbeitbar")
	document.undo()
	document.redo()
	check.call(document.hole.walls[0].arc_segments == 0, "Editor: Rückgängig/Wiederholen kann auch ungültige Zwischenstände wiederherstellen")
	document.undo()
	var gate := ObstacleDefinition.new()
	gate.obstacle_type = ObstacleDefinition.ObstacleType.SLIDING_GATE
	gate.position = Vector2(400, 160)
	gate.open_offset = Vector2(0, -300)
	document.hole.obstacles.append(gate)
	document.ensure_ids()
	var hints := document.issues().filter(func(issue: Dictionary): return issue.get("severity") == "warning")
	check.call(not hints.is_empty() and hints[0].id == gate.get_meta("editor_id"), "Editor: außerhalb liegender Torweg liefert anklickbaren Hinweis")
	check.call(document.blocking_issues().is_empty(), "Editor: ausgeblendeter Torweg ist ein Hinweis, kein falscher Spielbarkeitsbeweis")
