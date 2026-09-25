extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Übung und Tutorial]")
	var old_mode := host.process_mode
	host.process_mode = Node.PROCESS_MODE_ALWAYS
	var catalog := TutorialCatalog.load_default()
	check.call(catalog != null and catalog.lessons.size() == 8 and catalog.validate().is_empty(), "Acht typisierte Lektionen mit gültigen eigenen Bahnen")
	var app := GameApp.new()
	host.add_child(app)
	app._select_mode(RoundConfig.GameMode.PRACTICE)
	var practice := app.practice
	practice.progress.storage_path = "user://practice-test-%d.cfg" % Time.get_ticks_usec()
	practice.progress.read()
	check.call(practice.screen == "hub" and app.session == null, "Übung überspringt die Spieleranlage und erzeugt keine gewertete Runde")
	practice.show_categories()
	check.call(app.option_buttons.size() == 13, "Elf Kurse und Technik-Labore sind erreichbar")
	var count := 0
	for category in range(app.course_catalog.courses.size()):
		practice.category_index = category
		count += practice.category_holes().size()
	check.call(count == 99, "Alle 99 offiziellen Bahnen sind im Training erreichbar")
	practice.category_index = app.course_catalog.courses.size()
	check.call(practice.category_holes().size() == 14, "Alle 14 technischen Bahnen bleiben erreichbar")
	practice.hole_index = 12
	practice.show_holes()
	check.call(practice.hole_page == 1 and practice.hole_index == 12 and practice._grid_count == 5, "Labore behalten die markierte Bahn auf Seite zwei")
	practice.category_index = 0
	practice.start_free(0)
	await _frames(host, 16)
	check.call(practice.game.input_enabled and not host.get_tree().paused, "Übung startet erst nach neutraler Eingabe mit laufender Physik")
	practice.game.strokes = 20
	practice.game._on_ball_stopped(practice.game.ball.position)
	check.call(practice.game.strokes == 20 and not practice.game._attempt_reported, "Training erlaubt mehr als das normale Schlaglimit")
	practice.game.restart_hole()
	await _frames(host, 16)
	var start := practice.game.ball.position
	_prepare(practice, Vector2.RIGHT, 150.0)
	await _frames(host, 6)
	check.call(practice.snapshot != null and practice.game.strokes == 1, "Nur ein echter Ballkontakt übernimmt den wiederholbaren Schlag")
	await _frames(host, 100)
	var stop := practice.game.ball.position
	practice.show_tools()
	await practice.retry()
	check.call(practice.game.ball.position.is_equal_approx(start) and practice.game.strokes == 0 and practice.game.shot_controller.state == ShotController.ShotState.AIMING, "Wiederholen setzt Ball, Schlagzahl und Zielen zurück")
	check.call(not practice.trace.previous.is_empty() and practice.trace.current.is_empty(), "Vorherige Ballspur bleibt beim neuen Versuch erhalten")
	await _frames(host, 16)
	_prepare(practice, Vector2.RIGHT, 150.0)
	await _frames(host, 106)
	check.call(practice.game.ball.position.is_equal_approx(stop), "Gleiche Eingaben nach Wiederholung ergeben denselben Ballstand")
	var saved := practice.snapshot
	practice.game.shot_controller.action_pressed()
	practice.game.shot_controller.cancel_shot()
	check.call(practice.snapshot == saved, "Abgebrochene Vorbereitung bewahrt den letzten Schlag")
	practice.start_lesson(1)
	check.call(host.get_tree().paused and not practice.game.input_enabled, "Lektionsdialog pausiert die Welt")
	practice.next_section()
	check.call(not practice.progress.contains(&"learn_distance"), "Überspringen speichert keinen Erfolg")
	await _routes(host, practice, check)
	for variation in [[-0.3, 1.0], [0.3, 1.0], [0.0, 0.99], [0.0, 1.01]]:
		await _routes(host, practice, check, variation[0], variation[1])
	await _restoration(host, practice, check)
	await _navigation(host, practice, check)
	_storage(check)
	_trace_limits(check)
	practice.close()
	app.queue_free()
	await host.get_tree().process_frame
	host.get_tree().paused = false
	host.process_mode = old_mode


static func _frames(host: Node, count: int) -> void:
	for tick in range(count):
		await host.get_tree().physics_frame
	await host.get_tree().process_frame


static func _prepare(practice: PracticeSession, direction: Vector2, speed: float) -> void:
	var shot := practice.game.shot_controller
	shot.cursor_position = practice.game.ball.position + direction * 32.0
	shot.action_pressed()
	shot.power_value = inverse_lerp(shot.minimum_ball_speed, shot.maximum_ball_speed, speed)
	shot.action_pressed()
	shot.accuracy_value = 0.0
	shot.action_pressed()
	shot.action_released()


static func _routes(host: Node, practice: PracticeSession, check: Callable, angle := 0.0, power := 1.0) -> void:
	var speeds := [300.0, 205.0, 300.0, 335.0, 300.0, 365.0, 245.0, 235.0, 283.0, 300.0, 332.0, 300.0, 300.0, 228.683991532123]
	var flat_index := 0
	for lesson in range(practice.catalog.lessons.size()):
		for part in range(practice.catalog.lessons[lesson].sections.size()):
			practice.start_lesson(lesson, false, part)
			practice.resume()
			await _frames(host, 16)
			var direction := Vector2.RIGHT
			if lesson == 3:
				direction = Vector2(320, -146).normalized()
			direction = direction.rotated(deg_to_rad(angle))
			var shot := practice.game.shot_controller
			if lesson == 2 or (lesson == 6 and part == 0):
				await _frames(host, 150)
				shot.cursor_position = practice.game.ball.position + direction * 32
				shot.action_pressed()
				shot.power_value = inverse_lerp(shot.minimum_ball_speed, shot.maximum_ball_speed, speeds[flat_index] * power)
				shot.action_pressed()
				shot.accuracy_value = 0
				shot.action_pressed()
				await _frames(host, 46)
				shot.action_released()
			elif lesson == 6 and part == 1:
				await _frames(host, 135)
				_prepare(practice, Vector2(224, -24).normalized().rotated(deg_to_rad(angle)), 225.0 * power)
			else:
				_prepare(practice, direction, speeds[flat_index] * power)
			for tick in range(1500):
				await host.get_tree().physics_frame
				if practice.screen == "result" or (tick > 30 and not practice.game.ball.moving and practice.game.ball.position.distance_to(practice.section.hole.hole_position) > PrototypeBall.HOLE_RADIUS):
					break
			await host.get_tree().process_frame
			if (lesson == 7 or (lesson == 6 and part == 1)) and not practice.monitor.completed:
				var final_direction := (practice.section.hole.hole_position - practice.game.ball.position).normalized()
				var final_speed := 192.514013795912 if lesson == 7 else sqrt(240.0 * practice.game.ball.position.distance_to(practice.section.hole.hole_position)) + 4.0
				_prepare(practice, final_direction.rotated(deg_to_rad(angle)), final_speed * power)
				for tick in range(1000):
					await host.get_tree().physics_frame
					if practice.screen == "result" or (tick > 30 and not practice.game.ball.moving and practice.game.ball.position.distance_to(practice.section.hole.hole_position) > PrototypeBall.HOLE_RADIUS):
						break
				await host.get_tree().process_frame
			if not practice.monitor.completed:
				print("ROUTENLÜCKE ", practice.section.section_id, " position=", practice.game.ball.position, " state=", practice.screen, " goal=", practice.monitor.progress)
			check.call(practice.monitor.completed, "Lernroute %s mit %.1f° / %.2f Kraft erfüllt die Aufgabe mit aktiver Spielphysik" % [practice.section.section_id, angle, power])
			flat_index += 1


static func _storage(check: Callable) -> void:
	var store := PracticeProgress.new()
	store.storage_path = "user://practice-store-%d.cfg" % Time.get_ticks_usec()
	store.read()
	store.mark_complete(&"learn_first_putt")
	var again := PracticeProgress.new()
	again.storage_path = store.storage_path
	again.read()
	check.call(again.contains(&"learn_first_putt") and again.error == OK, "Lernfortschritt bleibt nach erneutem Laden erhalten")
	var file := FileAccess.open(store.storage_path, FileAccess.WRITE)
	file.store_string("not a config [")
	file.close()
	again.read()
	again.mark_complete(&"lesson_putt")
	check.call(again.error != OK and again.contains(&"lesson_putt") and FileAccess.get_file_as_string(store.storage_path) == "not a config [", "Beschädigter Fortschritt bleibt unverändert; Lernerfolge bleiben in der Sitzung möglich")
	var failed := PracticeProgress.new()
	failed.storage_path = "user://missing-%d/practice.cfg" % Time.get_ticks_usec()
	failed.read()
	failed.mark_complete(&"learn_first_putt")
	check.call(failed.error != OK and failed.contains(&"learn_first_putt"), "Fehlgeschlagenes Speichern bewahrt Lernfortschritt im Speicher")
	var old_locale := TranslationServer.get_locale()
	for language in GameSettings.LANGUAGES:
		TranslationServer.set_locale(language)
		for lesson in TutorialCatalog.load_default().lessons:
			check.call(I18n.text(lesson.title_key) != String(lesson.title_key), "%s: Lektionsname übersetzt" % language)
			for section in lesson.sections:
				check.call(I18n.text(section.hint_key) != String(section.hint_key) and I18n.content_name(section.hole) != String(section.hole.hole_id), "%s: Lernhinweis und Bahnname verfügbar" % language)
	TranslationServer.set_locale(old_locale)


static func _trace_limits(check: Callable) -> void:
	var trace := PracticeTrace.new()
	for index in range(12020):
		trace.sample(Vector2(index * 2, 0))
	check.call(trace._count == 12000, "Ballspur begrenzt Speicher auf 12000 Punkte")
	trace.break_segment()
	trace.sample(Vector2(200, 300))
	check.call(trace.current.size() == 2 and trace.current[-1].size() == 1, "Ein Transport beginnt einen getrennten Spurabschnitt")
	trace.compare()
	trace.sample(Vector2.ZERO)
	check.call(trace.previous.size() == 2 and trace.current.size() == 1, "Vergleichsspur ist von der aktuellen Bewegung getrennt")
	trace.free()


static func _restoration(host: Node, practice: PracticeSession, check: Callable) -> void:
	# Three different dynamic mechanisms must return to the pre-power clock.
	for lesson in [2, 6, 7]:
		practice.start_lesson(lesson, false, 1 if lesson == 6 else 0)
		practice.resume()
		await _frames(host, 16)
		var obstacle: Node2D = practice.game.hole.obstacle_nodes[0]
		var transform := obstacle.transform
		_prepare(practice, Vector2.RIGHT, 100)
		await _frames(host, 45)
		practice.show_tools()
		await practice.retry()
		check.call(obstacle.transform.is_equal_approx(transform), "Wiederholen restauriert die Hindernisphase von Lektion %d" % lesson)
		check.call(not practice.monitor.progress.passage and not practice.monitor.progress.held, "Wiederholen restauriert die Lernbedingungen statt Erfolg zu erfinden")
		if obstacle is SeesawObstacle:
			check.call(obstacle.left_end_collision.disabled == not obstacle.is_left_end_blocking() and obstacle.right_end_collision.disabled == not obstacle.is_right_end_blocking(), "Wippenkollision und Neigung stimmen nach Wiederholung überein")
		await _frames(host, 16)
		practice.show_tools()
		await practice.retry()
		check.call(obstacle.transform.is_equal_approx(transform), "Mehrfaches Wiederholen erhält denselben Anfangszustand")
	practice.category_index = 0
	practice.start_free(0)
	await _frames(host, 16)
	_prepare(practice, Vector2.RIGHT, 100)
	await _frames(host, 7)
	var tee := practice.game.hole.get_tee_position()
	practice.game.ball._enter_hazard("Wasser")
	practice.show_tools()
	await practice.retry()
	await _frames(host, 60)
	check.call(practice.game.ball.visible and practice.game.ball.position.is_equal_approx(tee) and practice.game.strokes == 0, "Wasser-Rücksetzung kann einen neu versuchten Schlag nicht nachträglich verändern")
	_prepare(practice, Vector2.RIGHT, 100)
	await _frames(host, 7)
	practice.game.ball._capture_hole()
	await _frames(host, 4)
	practice.show_tools()
	await practice.retry()
	await _frames(host, 50)
	check.call(practice.game.ball.scale == Vector2.ONE and practice.game.ball.visible and practice.screen == "play", "Einlochanimation und Abschluss werden bei Wiederholung verworfen")
	for transport in [false, true]:
		_prepare(practice, Vector2.RIGHT, 100)
		await _frames(host, 7)
		if transport:
			practice.game.ball.start_cannon_sequence(&"practice_test", tee, tee + Vector2(240, 0), 0.2, 0.12, 0.55, 34, Vector2(55, 0))
		else:
			practice.game.ball.start_mechanism_transport(tee, tee + Vector2(240, 0), Vector2(80, 0), 0.0, 0.6)
		await _frames(host, 8)
		practice.show_tools()
		await practice.retry()
		await _frames(host, 60)
		check.call(practice.game.ball.position.is_equal_approx(tee) and not practice.game.ball.is_tunnel_sequence_active() and not practice.game.ball.is_cannon_sequence_active(), "Transport/Kanonenflug ist nach Wiederholung vollständig zurückgesetzt")
	# Exercise a production switch and its linked cannon, not just a ball transport.
	var definition := HoleCatalog.load_default().get_hole(&"sternwarte_09")
	practice._start_game(definition, practice.profile)
	practice.resume()
	await _frames(host, 16)
	_prepare(practice, Vector2.RIGHT, 80)
	await _frames(host, 7)
	practice.game.hole.trigger_nodes[0].activate()
	check.call(practice.game.hole.trigger_nodes[0].is_activated, "Test aktiviert einen echten Schalter")
	practice.show_tools()
	await practice.retry()
	check.call(not practice.game.hole.trigger_nodes[0].is_activated and not practice.game.hole.cannon_nodes[0].is_enabled, "Wiederholen restauriert Schalter und Kanonensperre gemeinsam")


static func _navigation(host: Node, practice: PracticeSession, check: Callable) -> void:
	practice.category_index = 0
	practice.start_free(0)
	Input.action_press("menu_confirm")
	await _frames(host, 18)
	check.call(not practice.game.input_enabled and host.get_tree().paused, "Gehaltene Bestätigung lässt nach dem Wechsel weder Ball noch Hindernisse laufen")
	Input.action_release("menu_confirm")
	await _frames(host, 16)
	var menu_event := InputEventKey.new()
	menu_event.keycode = KEY_F2
	menu_event.physical_keycode = KEY_F2
	menu_event.pressed = true
	practice.game._input(menu_event)
	check.call(practice.screen == "tools" and host.get_tree().paused, "F2 öffnet das Trainingsmenü statt eine andere Bahn zu laden")
	await _frames(host, 16)
	practice.resume()
	await _frames(host, 16)
	practice.overlay.menu_button.pressed.emit()
	check.call(practice.screen == "tools", "Sichtbare Mausschaltfläche öffnet dieselben Trainingshilfen")
	practice.resume()
	await _frames(host, 16)
	practice._focus_changed(false)
	check.call(practice.screen == "tools" and not practice.game.input_enabled, "Fokusverlust pausiert das Training")
	practice.resume()
	await _frames(host, 16)
	practice._device_changed(-1, "", "")
	check.call(practice.screen == "tools", "Controllerwechsel pausiert die laufende Übung")
	practice.app._show_settings(true)
	practice.app.settings_menu.calibration_visible = true
	ControllerSupport.calibration_updated.emit("Test")
	ControllerSupport.calibration_finished.emit("test-guid")
	practice.app.settings_menu.calibration_visible = false
	practice.app.settings_menu.cancel()
	practice.resume()
	await _frames(host, 16)
	check.call(not practice.game.diagnostics_visible and practice.game.input_enabled and not host.get_tree().paused, "Kalibrierung in Einstellungen lässt nach Rückkehr keine blockierende Spiel-Diagnose zurück")
	practice.show_tools()
	practice.show_golfers()
	check.call(practice.app.option_buttons.size() == 6, "Alle fünf Golfer stehen im Training zur Auswahl")
	practice.show_don()
	practice.app._adjust_test_stat(0, 1)
	var range_factor := practice.app.setup_test_golfer.range_factor
	practice.app.option_actions[-1].call()
	check.call(practice.profile.golfer_id == &"don" and practice.game.attempt_profile.get_golfer_definition().range_factor == range_factor and practice.snapshot == null, "Don übernimmt seine Werte und beginnt ohne alte Schlagaufzeichnung")
	practice.start_lesson(0)
	check.call(practice.game.attempt_profile.golfer_id == &"allrounder", "Tutorial verwendet auch nach Don wieder Ben")
	practice.next_section()
	check.call(practice.screen == "lessons", "Einzellektion kehrt nach Überspringen zur Übersicht zurück")
	practice.start_lesson(0, true)
	practice.next_section()
	check.call(practice.lesson_index == 1 and practice.basic_course, "Grundkurs führt zur nächsten Lektion")
	# Test prerequisites independently; reaching the cup alone must not satisfy them.
	for lesson in [1, 2, 3, 5, 6, 7]:
		practice.start_lesson(lesson)
		practice.monitor._holed(1)
		check.call(not practice.monitor.completed, "Ohne Voraussetzung kein Lektionsabschluss (%d)" % lesson)
	practice.category_index = 0
	practice.start_free(8)
	practice.next_hole()
	check.call(practice.screen == "holes" and practice.hole_index == 8, "Nach der letzten Kursbahn bleibt die letzte Auswahl markiert")
