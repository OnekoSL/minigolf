extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Golferprofile und Auswahl]")
	check.call(PlayerProfile.create(1, "ALT", 0).golfer_id == &"allrounder", "Alte Spieleraufrufe erhalten den Allrounder")
	var maxima := [230, 195, 287, 218]
	var power_times := [4.0, 5.2, 3.2, 4.0]
	var accuracy_times := [2.4, 2.4, 2.4, 1.8]
	var maximum_errors := [8.0, 8.0, 10.0, 4.0]
	var scene := load("res://scenes/prototype_main.tscn") as PackedScene
	for index in range(4):
		var id := GolferDefinition.IDS[index]
		var definition := GolferDefinition.get_golfer(id)
		check.call(definition.validate().is_empty(), "%s: vollstaendiges Golferprofil" % id)
		var main := scene.instantiate() as PrototypeMain
		main.attempt_profile = PlayerProfile.create(1, "TEST", index, id)
		host.add_child(main)
		main.set_process(false)
		main.ball.set_physics_process(false)
		var shot := main.shot_controller
		shot.set_process(false)
		var meter := main.hud.power_bar
		check.call(main.hud.golfer.golfer_id == id and main.hud.golfer._sprite.texture == definition.atlas and main.hud.golfer_title.text == "P1  " + definition.display_name, "%s: Spielstart verbindet Atlas und Titel" % id)
		check.call(meter.distance_dm_for_power(0.0) == 1 and meter.distance_dm_for_power(1.0) == maxima[index], "%s: Skala reicht von 1 dm bis zum Profilmaximum" % id)
		for dm in [1, 5, 10, 50, 100]:
			check.call(meter.distance_dm_for_power(meter.power_for_distance_dm(dm)) == dm, "%s: %d-dm-Strich stimmt mit Schlagkraft ueberein" % [id, dm])
		check.call(is_equal_approx(shot.power_at_time(power_times[index] / 2.0), 1.0) and is_equal_approx(shot.power_at_time(power_times[index]), 0.0), "%s: Kraftzyklus besitzt vereinbarte Dauer" % id)
		check.call(is_equal_approx(shot.accuracy_at_time(accuracy_times[index] / 4.0), 0.0) and is_equal_approx(shot.accuracy_at_time(accuracy_times[index]), -1.0), "%s: Genauigkeitszyklus besitzt vereinbarte Dauer" % id)
		var window := 0.025 if id == &"nika" else 0.05
		check.call(shot.accuracy_to_angle(window) == 0.0 and shot.accuracy_to_angle(window + 0.001) > 0.0, "%s: Perfektfenster besitzt wirksame Grenze" % id)
		check.call(is_equal_approx(rad_to_deg(shot.accuracy_to_angle(1.0)), maximum_errors[index]) and is_equal_approx(rad_to_deg(shot.accuracy_to_angle(-1.0)), -maximum_errors[index]), "%s: maximale Richtungsabweichung" % id)
		for power in [0.0, 0.5, 1.0]:
			main.restart_hole()
			shot.action_pressed()
			shot.power_value = power
			shot.action_pressed()
			shot.action_pressed()
			shot.action_released()
			shot.advance_swing(0.099)
			check.call(not main.ball.moving and main.strokes == 0, "%s: kein vorzeitiger Kontakt" % id)
			shot.advance_swing(0.001)
			var expected := lerpf(ShotController.MINIMUM_BALL_SPEED, definition.get_maximum_ball_speed(), power)
			check.call(is_equal_approx(main.ball.velocity.length(), expected) and main.strokes == 1, "%s: echte Startgeschwindigkeit bei Kraft %.1f" % [id, power])
		main.queue_free()
		await host.get_tree().process_frame
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	host.add_child(app)
	app.set_process(false)
	app._select_mode(RoundConfig.GameMode.COURSE_LOCAL)
	app._choose_player_count(2)
	app._confirm_player_name()
	check.call(app.current_screen == GameApp.ScreenState.PLAYER_GOLFER and app.option_buttons.size() == 4, "Nach dem Namen stehen alle vier Golfer zur Auswahl")
	app._invoke_option(2)
	check.call(app.current_screen == GameApp.ScreenState.PLAYER_GOLFER, "Eingabesperre verhindert Folgeaktion im Golfermenue")
	app._move_selection(Vector2.DOWN)
	check.call(app.golfer_preview.golfer_id == &"mara", "Controller-Navigation aktualisiert die animierte Vorschau")
	var stale := app.option_buttons[2]
	app._confirm_player_golfer(&"nika")
	app._go_back()
	check.call(app.golfer_preview.golfer_id == &"nika" and app.selected_option == 3, "Zurueck aus der Farbe erhaelt die Golferwahl")
	app._menu_input_locked = false
	stale.pressed.emit()
	check.call(app.current_screen == GameApp.ScreenState.PLAYER_GOLFER, "Verspaetetes Signal eines alten Menues kann keine Figur waehlen")
	app._confirm_player_golfer(&"mara")
	app._confirm_player_color(0)
	app._confirm_player_name()
	app._confirm_player_golfer(&"mara")
	check.call(app.option_buttons[0].disabled, "Bereits vergebene Farbe bleibt gesperrt")
	app._confirm_player_color(1)
	check.call(app.working_players.size() == 2 and app.working_players.all(func(player): return player.golfer_id == &"mara"), "Zwei Spieler duerfen dieselbe Figur mit eigenen Farben waehlen")
	app.queue_free()
	await host.get_tree().process_frame
