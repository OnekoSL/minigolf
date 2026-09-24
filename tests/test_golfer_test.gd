extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Frei einstellbarer Testgolfer]")
	var baseline := GolferDefinition.get_golfer(&"don")
	check.call(GolferDefinition.IDS[4] == &"don" and baseline.validate().is_empty(), "Don ist die gueltige fuenfte Figur")
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.add_child(app)
	app.set_process(false)
	app._select_mode(RoundConfig.GameMode.COURSE_LOCAL)
	app._choose_player_count(2)
	app._confirm_player_name()
	app._select_option(4)
	check.call(app.golfer_preview.golfer_id == &"don", "Fuenfter Menueeintrag zeigt Don")
	app._menu_input_locked = false
	app._activate_selected()
	check.call(app.current_screen == GameApp.ScreenState.PLAYER_TEST_STATS, "Don oeffnet eigene Werteauswahl")
	app._invoke_option(1)
	check.call(app.setup_test_golfer.range_factor == 1.0, "Eingabesperre schuetzt Werte nach Bildschirmwechsel")
	app._menu_input_locked = false
	var stale := app.option_buttons[1]
	for index in range(5):
		app._invoke_option(index * 2 + 1)
		var key: StringName = GolferDefinition.TEST_STATS[index]
		check.call(float(app.setup_test_golfer.get(key)) > float(baseline.get(key)), "Plus veraendert Testwert %s" % key)
	app._select_option(0)
	app._move_selection(Vector2.DOWN)
	check.call(app.selected_option == 2, "Controller wechselt zur naechsten Wertezeile")
	app._move_selection(Vector2.RIGHT)
	check.call(app.selected_option == 3, "Controller erreicht Plus-Spalte")
	app._invoke_option(10)
	check.call(app.setup_test_golfer.range_factor == 1.0 and app.setup_test_golfer.maximum_error_degrees == 8.0, "Ben-Werte setzt das Testprofil zurueck")
	for index in range(5):
		var key: StringName = GolferDefinition.TEST_STATS[index]
		app.setup_test_golfer.set(key, GolferDefinition.TEST_MINIMUMS[index])
		app._invoke_option(index * 2)
		check.call(is_equal_approx(float(app.setup_test_golfer.get(key)), GolferDefinition.TEST_MINIMUMS[index]), "Minus haelt Untergrenze von %s" % key)
		app.setup_test_golfer.set(key, GolferDefinition.TEST_MAXIMUMS[index])
		app._invoke_option(index * 2 + 1)
		check.call(is_equal_approx(float(app.setup_test_golfer.get(key)), GolferDefinition.TEST_MAXIMUMS[index]), "Plus haelt Obergrenze von %s" % key)
	app.setup_test_golfer.range_factor = 2.0
	app.setup_test_golfer.power_cycle_seconds = 6.0
	app.setup_test_golfer.accuracy_cycle_seconds = 5.0
	app.setup_test_golfer.perfect_accuracy_window = 0.2
	app.setup_test_golfer.maximum_error_degrees = 0.0
	app._invoke_option(11)
	app._go_back()
	check.call(app.current_screen == GameApp.ScreenState.PLAYER_TEST_STATS and app.setup_test_golfer.range_factor == 2.0, "Zurueck aus Farbe erhaelt freie Werte")
	app._menu_input_locked = false
	stale.pressed.emit()
	check.call(app.setup_test_golfer.range_factor == 2.0, "Altes Werte-Menue kann neue Einstellungen nicht aendern")
	app._go_back()
	check.call(app.selected_option == 4 and app.golfer_stats.definition.range_factor == 2.0, "Zurueck zur Figur zeigt aktuelle Testwerte")
	app._confirm_player_golfer(&"don")
	var editing := app.setup_test_golfer
	app._show_player_color()
	app._confirm_player_color(0)
	var first := app.working_players[0]
	editing.range_factor = 3.0
	check.call(first.get_golfer_definition().range_factor == 2.0, "Bestaetigtes Profil besitzt eigene Werte-Kopie")
	app._confirm_player_name()
	app._confirm_player_golfer(&"don")
	check.call(app.setup_test_golfer.range_factor == 1.0, "Zweiter Don beginnt mit eigenem Standardprofil")
	app._show_player_color()
	app._confirm_player_color(1)
	check.call(app.working_players[1].get_golfer_definition().range_factor == 1.0 and baseline.range_factor == 1.0, "Hotseat-Spieler und gemeinsame Ressource bleiben unabhaengig")
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	var course := app.course_catalog.courses[0]
	config.course_id = course.course_id
	config.hole_ids = course.hole_ids.duplicate()
	config.players = app.working_players.duplicate()
	check.call(config.validate(app.hole_catalog, app.course_catalog).is_empty(), "Testspieler koennen regulaere Kursrunde spielen")
	check.call(not config.is_best_eligible(app.hole_catalog, app.course_catalog), "Testrunden schreiben keine Kursbestwerte")
	first.test_golfer.power_cycle_seconds = NAN
	check.call(not config.validate(app.hole_catalog, app.course_catalog).is_empty(), "Nicht endliche Testwerte werden abgelehnt")
	first.test_golfer.power_cycle_seconds = 6.0
	first.test_golfer.range_factor = 0.0
	check.call(not config.validate(app.hole_catalog, app.course_catalog).is_empty(), "Unspielbare Reichweite wird abgelehnt")
	first.test_golfer.range_factor = 2.0
	await _check_gameplay(host, check, first)
	config.players = [PlayerProfile.create(1, "BEN", 0), PlayerProfile.create(2, "MARA", 1, &"mara")]
	check.call(config.is_best_eligible(app.hole_catalog, app.course_catalog), "Feste Figuren behalten ihre regulaeren Bestwerte")
	app.queue_free()
	await host.get_tree().process_frame


static func _check_gameplay(host: Node, check: Callable, profile: PlayerProfile) -> void:
	for attempt in range(2):
		var main := (load("res://scenes/prototype_main.tscn") as PackedScene).instantiate() as PrototypeMain
		main.attempt_profile = profile
		host.add_child(main)
		main.set_process(false)
		main.ball.set_physics_process(false)
		main.shot_controller.set_process(false)
		var shot := main.shot_controller
		check.call(main.hud.golfer.golfer_id == &"don" and main.hud.power_bar.distance_dm_for_power(1.0) == 459, "Versuch %d: Don und doppelte Reichweite im HUD" % attempt)
		check.call(shot.power_cycle_seconds == 6.0 and shot.accuracy_cycle_seconds == 5.0 and shot.perfect_accuracy_window == 0.2 and shot.accuracy_to_angle(1.0) == 0.0, "Alle freien Timing- und Genauigkeitswerte erreichen das Schlagsystem")
		for restart in range(2):
			main.restart_hole()
			shot.action_pressed()
			shot.power_value = 1.0
			shot.action_pressed()
			shot.accuracy_value = 1.0
			shot.action_pressed()
			shot.action_released()
			shot.advance_swing(0.099)
			check.call(main.strokes == 0 and not main.ball.moving, "Freie Werte erhalten die Kontaktverzoegerung")
			shot.advance_swing(0.001)
			check.call(main.strokes == 1 and is_equal_approx(main.ball.velocity.length(), 420.0 * sqrt(2.0)), "Neustart und weiterer Versuch verwenden die eingestellte echte Ballgeschwindigkeit")
		main.queue_free()
		await host.get_tree().process_frame
