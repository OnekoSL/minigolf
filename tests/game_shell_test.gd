extends "res://tests/test_support.gd"


func _test_game_shell() -> void:
	print("\n[Spielrahmen und Rundentabelle]")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	_check(courses != null, "Kurskatalog wird als typisierte Resource geladen")
	_check(courses.validate(holes).is_empty(), "Kurskatalog verweist nur auf gueltige echte Loecher")
	var course := courses.get_course(&"prototype_course_03")
	_check(course != null and course.hole_ids.size() == 9, "Prototypkurs verbindet neun echte Kursbahnen")
	_check(course.get_total_par(holes) == 33, "Vollstaendiger Prototypkurs besitzt Gesamt-Par 33")
	_check(not course.allow_technical_holes, "Prototypkurs benoetigt keine Freigabe fuer Techniklabore")
	var classic_course := courses.get_course(&"classic_nine_course")
	var arrow_course := courses.get_course(&"arrow_armageddon_course")
	var reference_course := courses.get_course(&"reference_lanes_course")
	var labyrinth_course := courses.get_course(&"labyrinth_nine_course")
	_check(courses.courses.size() == 5 and courses.courses[0] == classic_course and courses.courses[1] == arrow_course and courses.courses[2] == reference_course and courses.courses[3] == labyrinth_course and courses.courses[4] == course, "Kursauswahl ordnet Klassische Neun, Pfeil-Armageddon, Referenzbahnen, Labyrinth-Neun und Prototypkurs")
	_check(classic_course != null and classic_course.hole_ids.size() == 9 and classic_course.get_total_par(holes) == 19, "Neun-Loch-Kurs ist vollstaendig im Spielrahmen registriert")
	_check(arrow_course != null and arrow_course.hole_ids.size() == 9 and arrow_course.get_total_par(holes) == 27, "Pfeil-Armageddon ist vollstaendig im Spielrahmen registriert")
	_check(reference_course != null and reference_course.hole_ids == [&"reference_gate_lane", &"reference_gate_bumpers", &"reference_gate_rotor", &"reference_gate_slider", &"reference_gate_seesaw", &"reference_gate_hill", &"reference_angle_lane", &"reference_mos_lane", &"reference_gate_hill_hole"], "Referenzkurs enthaelt neun Bahnen und endet mit dem Huegelloch")
	_check(reference_course != null and reference_course.get_total_par(holes) == 18 and reference_course.allow_technical_holes, "Referenzkurs besitzt Gesamt-Par 18 und erlaubt technische Bahnen")
	_check(labyrinth_course != null and labyrinth_course.hole_ids.size() == 9 and labyrinth_course.get_total_par(holes) == 50, "Labyrinth-Neun ist vollstaendig im Spielrahmen registriert")
	var course_holes := 0
	var technical_holes := 0
	for hole in holes.holes:
		if hole.is_course_hole():
			course_holes += 1
		else:
			technical_holes += 1
	_check(course_holes == 36 and technical_holes == 14, "Katalog trennt sechsunddreissig Kurs- und vierzehn Technikbahnen")

	var first := PlayerProfile.create(1, "", 0)
	var second := PlayerProfile.create(2, "ZWOELFZEICHENPLUS", 1)
	_check(first.player_name == "SPIELER 1", "Leerer Name erhaelt den Spielernamen als Ersatz")
	_check(second.player_name.length() == 12, "Spielername wird auf zwoelf Zeichen begrenzt")
	_check(first.get_color() != second.get_color(), "Farbvarianten unterscheiden Spieler auch im HUD")

	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.FREE_PLAY
	config.course_id = course.course_id
	config.players = [first, second]
	config.hole_ids = course.hole_ids.slice(0, 3)
	_check(config.validate(holes, courses).is_empty(), "Zwei-Spieler-Kurskonfiguration ist gueltig")
	_check(config.allows_restart() and not config.is_course_mode(), "Verkuerzte Testrunde verwendet freies Spiel")
	var prototype_config := RoundConfig.new()
	prototype_config.mode = RoundConfig.GameMode.COURSE_LOCAL
	prototype_config.course_id = course.course_id
	prototype_config.players = [first, second]
	prototype_config.hole_ids = course.hole_ids.duplicate()
	_check(prototype_config.validate(holes, courses).is_empty(), "Prototypkurs akzeptiert alle neun ausgearbeiteten Kursbahnen")
	prototype_config.hole_ids.append(&"allround_test")
	_check(not prototype_config.validate(holes, courses).is_empty(), "Technische Bahnen bleiben ohne Kursfreigabe gesperrt")
	var invalid_solo := RoundConfig.new()
	invalid_solo.mode = RoundConfig.GameMode.COURSE_SOLO
	invalid_solo.players = [first, second]
	invalid_solo.hole_ids = course.hole_ids.duplicate()
	_check(not invalid_solo.validate(holes, courses).is_empty(), "Einzelkurs lehnt mehrere Spieler ab")
	var duplicate_color := RoundConfig.new()
	duplicate_color.mode = RoundConfig.GameMode.FREE_PLAY
	duplicate_color.players = [first, PlayerProfile.create(2, "B", 0)]
	duplicate_color.hole_ids = [&"reference_01"]
	_check(not duplicate_color.validate(holes, courses).is_empty(), "Doppelte Spielerfarben werden abgelehnt")
	var free_config := RoundConfig.new()
	free_config.mode = RoundConfig.GameMode.FREE_PLAY
	free_config.players = [first]
	free_config.hole_ids = [&"reference_01", &"reference_01", &"double_gate_03"]
	_check(free_config.validate(holes, courses).is_empty(), "Freies Spiel erlaubt geordnete Lochwiederholungen")
	_check(free_config.allows_restart() and not free_config.is_course_mode(), "Freies Spiel erlaubt schnellen Lochneustart")
	_check(
		RoundSession.stroke_limit_for_par(1) == 8
			and RoundSession.stroke_limit_for_par(5) == 8
			and RoundSession.stroke_limit_for_par(6) == 9
			and RoundSession.stroke_limit_for_par(7) == 10,
		"Schlaglimit ist mindestens acht und steigt oberhalb von Par 5 auf Par plus drei"
	)
	var long_config := RoundConfig.new()
	long_config.mode = RoundConfig.GameMode.FREE_PLAY
	long_config.course_id = labyrinth_course.course_id
	long_config.players = [first]
	long_config.hole_ids = [&"labyrinth_nine_08"]

	var round := RoundSession.new()
	round.configure(config, holes)
	_check(round.current_player_index == 0 and round.current_hole_index == 0, "Runde startet bei Spieler eins und Loch eins")
	_check(round.record_current_score(4, false) == RoundSession.AdvanceResult.NEXT_PLAYER, "Nach komplettem Loch folgt der naechste Spieler")
	_check(round.current_player_index == 1 and round.current_hole_index == 0, "Spielerwechsel bleibt am selben Loch")
	_check(round.record_current_score(8, true) == RoundSession.AdvanceResult.HOLE_COMPLETE, "Nach letztem Spieler erscheint die Lochtabelle")
	_check(round.scores[1][0] == 8 and round.capped[1][0], "Schlaglimit wird als 8 mit MAX-Markierung gespeichert")
	var long_round := RoundSession.new()
	long_round.configure(long_config, holes)
	long_round.record_current_score(12, true)
	_check(long_round.get_current_stroke_limit() == 10 and long_round.scores[0][0] == 10 and long_round.capped[0][0], "PAR-7-Ergebnisse werden erst bei zehn Schlaegen mit MAX gewertet")
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
	four_config.mode = RoundConfig.GameMode.FREE_PLAY
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

	var test_path := "res://.godot/putt_pixel_best_score_test.cfg"
	var absolute_test_path := ProjectSettings.globalize_path(test_path)
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_test_path)
	var store := BestScoreStore.new(test_path)
	_check(store.get_best(course.course_id) == -1, "Fehlender Bestwert wird fehlerfrei geladen")
	_check(store.submit(course.course_id, 14).best_score == 14, "Erster Kursbestwert wird gespeichert")
	_check(store.submit(course.course_id, 16).best_score == 14, "Schlechteres Ergebnis ueberschreibt den Bestwert nicht")
	_check(store.submit(course.course_id, 10).best_score == 10 and store.get_best(course.course_id) == 10, "Besseres Ergebnis aktualisiert den Bestwert")
	_check(store.submit(arrow_course.course_id, 27).best_score == 27 and store.get_best(course.course_id) == 10, "Alter Pfeil-Armageddon-Bestwert bleibt vom klassischen Kurs getrennt")
	_check(store.submit(&"arrow_armageddon_course_v2", 24).best_score == 24, "Pfeil-Armageddon-Bestwert der Revision 2 bleibt erhalten")
	_check(store.submit(&"arrow_armageddon_course_v3", 25).best_score == 25, "Pfeil-Armageddon-Bestwert der Revision 3 bleibt erhalten")
	_check(store.submit(&"arrow_armageddon_course_v4", 26).best_score == 26, "Pfeil-Armageddon-Bestwert der Revision 4 bleibt erhalten")
	_check(
		arrow_course.best_score_revision == 6
			and arrow_course.get_best_score_key() == &"arrow_armageddon_course_v6"
			and store.get_best(arrow_course.get_best_score_key()) == -1
			and store.get_best(arrow_course.course_id) == 27
			and store.get_best(&"arrow_armageddon_course_v2") == 24
			and store.get_best(&"arrow_armageddon_course_v3") == 25
			and store.get_best(&"arrow_armageddon_course_v4") == 26,
		"Pfeil-Armageddon Revision 6 uebernimmt keine aelteren Kursbestwerte"
	)
	_check(store.submit(classic_course.course_id, 18).best_score == 18, "Alter Klassik-Bestwert bleibt unter seinem bisherigen Schluessel erhalten")
	_check(store.submit(&"classic_nine_course_v2", 17).best_score == 17, "Klassik-Bestwert der Revision 2 bleibt unter seinem Revisionsschluessel erhalten")
	_check(store.submit(&"classic_nine_course_v3", 19).best_score == 19, "Klassik-Bestwert der Revision 3 bleibt unter seinem Revisionsschluessel erhalten")
	_check(store.submit(&"classic_nine_course_v4", 19).best_score == 19, "Klassik-Bestwert der Revision 4 bleibt unter seinem Revisionsschluessel erhalten")
	_check(store.submit(&"classic_nine_course_v5", 19).best_score == 19, "Klassik-Bestwert der Revision 5 bleibt unter seinem Revisionsschluessel erhalten")
	_check(store.submit(&"classic_nine_course_v6", 19).best_score == 19, "Klassik-Bestwert der Revision 6 bleibt unter seinem Revisionsschluessel erhalten")
	_check(
		classic_course.best_score_revision == 8
			and classic_course.get_best_score_key() == &"classic_nine_course_v8"
			and store.get_best(classic_course.get_best_score_key()) == -1
			and store.get_best(classic_course.course_id) == 18
			and store.get_best(&"classic_nine_course_v2") == 17
			and store.get_best(&"classic_nine_course_v3") == 19
			and store.get_best(&"classic_nine_course_v4") == 19
			and store.get_best(&"classic_nine_course_v5") == 19
			and store.get_best(&"classic_nine_course_v6") == 19,
		"Klassische Neun Revision 8 uebernimmt keine aelteren Bestwerte"
	)
	_check(
		course.best_score_revision == 4
			and course.get_best_score_key() == &"prototype_course_03_v4"
			and store.get_best(course.get_best_score_key()) == -1
			and store.get_best(course.course_id) == 10,
		"Prototypkurs Revision 4 uebernimmt keinen alten Kursbestwert"
	)
	_check(
		reference_course.best_score_revision == 2
			and reference_course.get_best_score_key() == &"reference_lanes_course_v2"
			and labyrinth_course.best_score_revision == 2
			and labyrinth_course.get_best_score_key() == &"labyrinth_nine_course_v2",
		"Referenz- und Labyrinthkurs trennen Bestwerte fuer den erweiterten Kraftbereich"
	)
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
	_check(app.option_buttons.size() == 6 and "KLASSISCHE NEUN" in app.option_buttons[0].text and "PFEIL-ARMAGEDDON" in app.option_buttons[1].text and "REFERENZBAHNEN" in app.option_buttons[2].text, "Erste Kursseite zeigt den neuen Referenzkurs direkt an")
	_check(app.option_buttons[3].disabled and not app.option_buttons[5].disabled, "Fuenf Kurse aktivieren die zweite Kursseite")
	app._change_course_page(1)
	_check(app.course_select_page == 1 and app.option_buttons.size() == 5 and "LABYRINTH-NEUN" in app.option_buttons[0].text and "PROTOTYPKURS" in app.option_buttons[1].text, "Zweite Kursseite enthaelt Labyrinth-Neun und Prototypkurs")
	var extra_course := classic_course.duplicate(true) as CourseDefinition
	extra_course.course_id = &"course_page_test"
	extra_course.display_name = "SEITENTEST"
	app.course_catalog = app.course_catalog.duplicate(true) as CourseCatalog
	app.course_catalog.courses.append(extra_course)
	app._show_course_select()
	_check(app.course_select_page == 1 and app.option_buttons.size() == 6 and "LABYRINTH-NEUN" in app.option_buttons[0].text and "PROTOTYPKURS" in app.option_buttons[1].text and "SEITENTEST" in app.option_buttons[2].text, "Kursnavigation erreicht weitere datengetriebene Eintraege")
	app.course_catalog = courses
	app.course_select_page = 0
	app.hole_select_page = 0
	app._show_hole_select()
	_check(app.option_buttons.size() == 8 and app.option_buttons[5].disabled and not app.option_buttons[7].disabled, "Uebung zeigt fuenf Bahnen mit Seitennavigation")
	app._change_hole_page(1)
	_check(app.hole_select_page == 1 and app.option_buttons.size() == 8, "Uebungsseite wechselt controllerfreundlich weiter")
	app.free_select_page = 7
	app._show_free_builder()
	_check(app.free_select_page == 7 and app.option_buttons.size() == 6, "Freies Spiel erreicht die letzte Seite aller sechsunddreissig Kursbahnen")
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
	app._start_round(long_config)
	_check(app.gameplay.get_stroke_limit() == 10 and "0/10" in app.gameplay.hud.stroke_label.text, "PAR-7-Gameplay zeigt das dynamische Maximum von zehn Schlaegen")
	app.gameplay.strokes = 9
	app.gameplay._on_ball_stopped(app.gameplay.ball.position)
	_check(app.current_screen == GameApp.ScreenState.GAMEPLAY, "Eine PAR-7-Bahn bleibt nach dem neunten Schlag aktiv")
	app.gameplay.strokes = 10
	app.gameplay._on_ball_stopped(app.gameplay.ball.position)
	await get_tree().create_timer(0.60).timeout
	_check(app.current_screen == GameApp.ScreenState.FINAL and app.session.scores[0][0] == 10 and app.session.capped[0][0], "Eine PAR-7-Bahn endet nach dem zehnten Schlag mit MAX-Markierung")
	var nine_config := RoundConfig.new()
	nine_config.mode = RoundConfig.GameMode.COURSE_SOLO
	nine_config.course_id = classic_course.course_id
	nine_config.players = [first]
	nine_config.hole_ids = classic_course.hole_ids.duplicate()
	var nine_round := RoundSession.new()
	nine_round.configure(nine_config, holes)
	var par_scores := [1, 2, 2, 1, 1, 2, 3, 3, 4]
	for hole_index in range(9):
		nine_round.record_current_score(par_scores[hole_index], false)
		if hole_index < 8:
			nine_round.advance_hole()
	_check(nine_round.is_complete() and nine_round.get_player_total(0) == 19 and nine_round.get_player_difference(0) == 0, "Neun-Loch-Tabelle summiert Par 19 korrekt")
	var arrow_config := RoundConfig.new()
	arrow_config.mode = RoundConfig.GameMode.COURSE_SOLO
	arrow_config.course_id = arrow_course.course_id
	arrow_config.players = [first]
	arrow_config.hole_ids = arrow_course.hole_ids.duplicate()
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


func _test_repeated_hole_switch_input() -> void:
	print("\n[Bahnwechsel-Eingabe]")
	var scene := load("res://scenes/prototype_main.tscn") as PackedScene
	var main := scene.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.shot_controller.state = ShotController.ShotState.SWINGING
	main._update_controller_status(-1, "Kein Controller", "")
	_check(main.shot_controller.state == ShotController.ShotState.AIMING and main.strokes == 0, "Controllertrennung bricht SWINGING ohne Schlagverlust ab")
	for index in range(45):
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


func _test_distance_scale() -> void:
	print("\n[Entfernungsskala]")
	var meter := PowerDistanceMeter.new()
	_check(meter.distance_dm_for_power(0.0) == 1, "Mindestkraft wird als ein Dezimeter angezeigt")
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
