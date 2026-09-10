extends RefCounted

const TEST_DIR := "res://.godot/cleanup-tests"


static func run(host: Node, check: Callable) -> void:
	print("\n[Eingabesperren, Kursfreigabe und Speicherfehler]")
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_test_round_validation(check)
	_test_storage(check)
	_test_calibration(check)
	await _test_menu(host, check)
	await _test_best_submission(host, check)


static func _course_config(course: CourseDefinition) -> RoundConfig:
	var config := RoundConfig.new()
	config.course_id = course.course_id
	config.players = [PlayerProfile.create(1, "TEST", 0)]
	config.hole_ids = course.hole_ids.duplicate()
	return config


static func _test_round_validation(check: Callable) -> void:
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	for course in courses.courses:
		var valid := _course_config(course)
		check.call(valid.is_best_eligible(holes, courses) and not valid.allows_restart(), "%s: Vollstaendige offizielle Runde ist bestwertberechtigt und sperrt Lochneustarts" % course.course_id)
	var course := courses.courses[0]
	var config := _course_config(course)
	config.hole_ids.resize(1)
	check.call(not config.validate(holes, courses).is_empty(), "Verkuerzte Kursrunde wird abgelehnt")
	config.hole_ids = course.hole_ids.duplicate()
	config.hole_ids.reverse()
	check.call(not config.is_best_eligible(holes, courses), "Vertauschte Lochfolge ist nicht bestwertberechtigt")
	config.hole_ids = courses.courses[1].hole_ids.duplicate()
	check.call(not config.is_best_eligible(holes, courses), "Fremde Lochfolge ist nicht bestwertberechtigt")
	config = _course_config(course)
	config.course_id = &"unknown_course"
	check.call(not config.is_best_eligible(holes, courses), "Unbekannter Kurs ist nicht bestwertberechtigt")
	config = _course_config(course)
	config.hole_ids[0] = &"reference_gate_lane"
	check.call(not config.validate(holes, courses).is_empty(), "Technische Bahn darf nicht in einen anderen Kurs eingeschleust werden")
	for mode in [RoundConfig.GameMode.FREE_PLAY, RoundConfig.GameMode.PRACTICE]:
		config = _course_config(course)
		config.mode = mode
		config.hole_ids.resize(1)
		check.call(config.validate(holes, courses).is_empty() and not config.is_best_eligible(holes, courses), "Modus %d bleibt ohne Kursbestwert" % mode)


static func _test_storage(check: Callable) -> void:
	var path := TEST_DIR + "/best.cfg"
	DirAccess.remove_absolute(path)
	var store := BestScoreStore.new(path)
	var result := store.submit(&"course_v1", 20)
	check.call(result.error == OK and result.updated and result.best_score == 20, "Fehlende Bestwertdatei wird erfolgreich angelegt")
	result = store.submit(&"course_v1", 21)
	check.call(result.error == OK and not result.updated and result.best_score == 20, "Schlechteres Ergebnis meldet unveraenderten Bestwert")
	result = store.submit(&"course_v2", 19)
	check.call(result.updated and store.get_best(&"course_v1") == 20, "Neue Revision erhaelt bestehende Bestwerte")
	var original := "[course_best]\ncourse_v1=20\n[broken\n"
	_write(path, original)
	result = store.submit(&"course_v2", 1)
	check.call(result.error != OK and not result.updated and FileAccess.get_file_as_string(path) == original, "Beschaedigte Bestwertdatei wird nicht ueberschrieben")
	DirAccess.remove_absolute(path)
	store.storage_path = TEST_DIR + "/missing-parent/best.cfg"
	result = store.submit(&"course_v1", 19)
	check.call(result.error != OK and not result.updated and result.best_score == -1, "Schreibfehler wird ohne vorgetaeuschten Bestwert zurueckgegeben")


static func _test_calibration(check: Callable) -> void:
	var support: Node = load("res://src/controller_support.gd").new()
	support.user_mapping_path = TEST_DIR + "/mapping.cfg"
	DirAccess.remove_absolute(support.user_mapping_path)
	check.call(support._save_user_profile("first", {"shot_button": 0}) == OK, "Neue Kalibrierdatei wird gespeichert")
	check.call(support._save_user_profile("second", {"shot_button": 1}) == OK, "Weiteres Controllerprofil wird gespeichert")
	var saved := ConfigFile.new()
	saved.load(support.user_mapping_path)
	check.call(saved.get_value("first", "shot_button") == 0, "Weitere Kalibrierung erhaelt das vorhandene Profil")
	var original := "[first]\nshot_button=0\n[broken\n"
	_write(support.user_mapping_path, original)
	check.call(support._save_user_profile("second", {"shot_button": 2}) != OK and FileAccess.get_file_as_string(support.user_mapping_path) == original, "Beschaedigte Kalibrierdatei bleibt unveraendert")
	DirAccess.remove_absolute(support.user_mapping_path)
	support.user_mapping_path = TEST_DIR + "/missing-parent/mapping.cfg"
	support.active_device_guid = "test-guid"
	support._calibration_profile = {"shot_button": 3}
	support._calibration_step = 7
	var finished := {"count": 0}
	support.calibration_finished.connect(func(_guid): finished.count += 1)
	support._advance_calibration()
	check.call(finished.count == 0 and support._profiles["test-guid"].shot_button == 3, "Speicherfehler behaelt Sitzungsprofil und sendet kein Erfolgssignal")
	check.call("Speichern fehlgeschlagen" in support.get_diagnostics_text() and not support.is_calibrating(), "Diagnose zeigt den Speicherfehler auch nach Kalibrierende")
	support.user_mapping_path = TEST_DIR + "/mapping.cfg"
	support._calibration_step = 7
	support._advance_calibration()
	check.call(finished.count == 1 and "Kalibrierung gespeichert" in support.get_diagnostics_text(), "Erfolgreicher neuer Versuch meldet gespeichertes Profil")
	DirAccess.remove_absolute(support.user_mapping_path)
	support.free()


static func _test_menu(host: Node, check: Callable) -> void:
	var app := GameApp.new()
	host.get_tree().root.add_child(app)
	await host.get_tree().process_frame
	app.set_process(false)
	var support := host.get_node("/root/ControllerSupport")
	var was_focused: bool = support.focused
	support.focused = true
	var calls := {"count": 0}
	app._build_screen("TEST", "")
	var button := app._add_option_button("TEST", Rect2(220, 150, 200, 30), func(): calls.count += 1)
	await host.get_tree().process_frame
	_click(host, button)
	check.call(calls.count == 0, "Echter Mausklick umgeht die Eingabesperre nicht")
	app._menu_input_locked = false
	support.focused = false
	_click(host, button)
	check.call(calls.count == 0, "Mausaktion bleibt bei Fokusverlust gesperrt")
	support.focused = true
	app.diagnostics_visible = true
	_click(host, button)
	check.call(calls.count == 0, "Mausaktion bleibt bei offener Diagnose gesperrt")
	app.diagnostics_visible = false
	support._calibration_step = 0
	_click(host, button)
	check.call(calls.count == 0, "Mausaktion bleibt waehrend Kalibrierung gesperrt")
	support._calibration_step = -1
	_click(host, button)
	check.call(calls.count == 1, "Freigegebener Mausklick aktiviert genau eine Aktion")
	var second := app._add_option_button("ZWEITER", Rect2(220, 200, 200, 30), func(): calls.count += 10)
	app.selected_option = 0
	_click(host, second)
	check.call(calls.count == 11, "Maus aktiviert den angeklickten Button auch bei abweichender Tastaturauswahl")
	app._build_screen("NEU", "")
	app._add_option_button("NEU", Rect2(220, 150, 200, 30), func(): calls.count += 10)
	app._menu_input_locked = false
	button.pressed.emit()
	check.call(calls.count == 11, "Verspaetetes Signal eines alten Buttons aktiviert keine neue Aktion")
	Input.action_press("menu_confirm")
	app._arm_input_gate()
	app._process(0.2)
	check.call(app._menu_input_locked, "Gehaltene Bestaetigung haelt den neuen Bildschirm gesperrt")
	Input.action_release("menu_confirm")
	app._process(0.1)
	check.call(not app._menu_input_locked, "Neutrale Eingabe gibt den neuen Bildschirm wieder frei")
	support.focused = was_focused
	app.free()
	await host.get_tree().process_frame


static func _test_best_submission(host: Node, check: Callable) -> void:
	var app := GameApp.new()
	host.get_tree().root.add_child(app)
	await host.get_tree().process_frame
	var course := app.course_catalog.courses[0]
	var config := _course_config(course)
	config.hole_ids.resize(1)
	app.session = RoundSession.new()
	app.session.configure(config, app.hole_catalog)
	app.session.record_current_score(1, false)
	var path := TEST_DIR + "/submission.cfg"
	DirAccess.remove_absolute(path)
	app.best_store = BestScoreStore.new(path)
	app._update_best_score()
	check.call(not FileAccess.file_exists(path), "Verkuerzte abgeschlossene Runde schreibt keinen offiziellen Bestwert")
	for mode in [RoundConfig.GameMode.PRACTICE, RoundConfig.GameMode.FREE_PLAY]:
		config.mode = mode
		app._update_best_score()
		check.call(not FileAccess.file_exists(path), "Abgeschlossener Modus %d schreibt keinen Kursbestwert" % mode)
	config = _course_config(course)
	app.session.configure(config, app.hole_catalog)
	app._update_best_score()
	check.call(not FileAccess.file_exists(path), "Unvollstaendige offizielle Runde schreibt keinen Bestwert")
	for index in range(config.hole_ids.size()):
		app.session.record_current_score(2, false)
		if index + 1 < config.hole_ids.size():
			app.session.advance_hole()
	app._update_best_score()
	check.call(app.best_store.get_best(course.get_best_score_key()) == 18, "Vollstaendige offizielle Runde speichert unter dem Revisionsschluessel")
	app.best_store.storage_path = TEST_DIR + "/missing-parent/submission.cfg"
	app._update_best_score()
	check.call("NICHT GESPEICHERT" in app._scorecard_subtitle(true), "Endtabelle benennt den fehlgeschlagenen Speichervorgang")
	DirAccess.remove_absolute(path)
	app.free()
	await host.get_tree().process_frame


static func _click(host: Node, button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = button.get_global_rect().get_center()
	event.global_position = event.position
	event.pressed = true
	host.get_viewport().push_input(event, true)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	host.get_viewport().push_input(event, true)


static func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()
