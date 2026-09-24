extends RefCounted


static func run(host: Node, check: Callable) -> void:
	print("\n[Mehrsprachigkeit und Einstellungen]")
	var manager := host.get_node("/root/SettingsManager")
	var old_store: SettingsStore = manager.store
	var old_saved: GameSettings = manager.saved.copy()
	var old_current: GameSettings = manager.current.copy()
	var directory := "user://settings-test-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var path := directory.path_join("settings.cfg")
	var store := SettingsStore.new(path)
	manager.store = store
	manager.saved = store.read()
	manager.apply(manager.saved)
	check.call(manager.current.language == "de" and manager.current.master_volume == 100, "Einstellungen: erster Start verwendet Deutsch und volle Lautstärke")
	manager.begin()
	manager.draft.language = "fr"
	manager.draft.master_volume = 35
	manager.draft.effects_volume = 0
	manager.preview()
	check.call(TranslationServer.get_locale() == "fr" and AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "Vorschau wirkt auf Sprache und Effektbus")
	check.call(not FileAccess.file_exists(path), "Vorschau schreibt keine Einstellungen")
	manager.cancel()
	check.call(TranslationServer.get_locale() == "de" and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")), "Abbrechen stellt Sprache und Ton wieder her")
	manager.begin()
	manager.draft.language = "es"
	manager.draft.master_volume = 65
	manager.preview()
	check.call(manager.commit() == OK, "Übernehmen speichert Einstellungen")
	var loaded := SettingsStore.new(path).read()
	check.call(loaded.language == "es" and loaded.master_volume == 65, "Neustart lädt gespeicherte Auswahl")
	manager.begin()
	manager.draft.effects_volume = 45
	manager.preview()
	check.call(manager.commit() == OK and store.read().effects_volume == 45, "Erneutes Übernehmen ersetzt eine vorhandene Einstellungsdatei")
	manager.begin()
	manager.draft.fullscreen = not manager.current.fullscreen
	manager.preview()
	check.call(manager.display_previous != null and manager.commit() == ERR_BUSY, "Anzeigewechsel benötigt Bestätigung vor Speicherung")
	manager._process(15.1)
	check.call(manager.display_previous == null and manager.current.fullscreen == manager.saved.fullscreen, "Anzeige kehrt nach 15 Sekunden automatisch zurück")
	manager.draft.vsync = not manager.saved.vsync
	manager.preview()
	manager.confirm_display()
	manager.cancel()
	check.call(manager.current.vsync == manager.saved.vsync, "Auch bestätigte Anzeigevorschau wird beim Abbrechen verworfen")
	var config := ConfigFile.new()
	config.set_value("settings", "language", "unknown")
	config.set_value("settings", "master_volume", 999)
	config.set_value("settings", "fullscreen", "false")
	config.set_value("settings", "effects_volume", 25)
	config.save(path)
	loaded = store.read()
	check.call(loaded.language == "de" and loaded.master_volume == 100 and not loaded.fullscreen and loaded.effects_volume == 25, "Ungültige Einzelwerte fallen auf Standard zurück; gültige bleiben erhalten")
	var corrupt := "[settings\nthis file is deliberately broken"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(corrupt)
	file.close()
	loaded = store.read()
	check.call(store.load_error != OK and loaded.language == "de" and store.write(loaded) != OK and FileAccess.get_file_as_string(path) == corrupt, "Beschädigte Einstellungen werden nicht überschrieben")
	manager.store = SettingsStore.new(directory.path_join("missing/settings.cfg"))
	manager.begin()
	manager.draft.language = "it"
	manager.preview()
	check.call(manager.commit() != OK and manager.saved.language == "es" and manager.current.language == "it", "Speicherfehler erhält bisherigen Speicherstand und bearbeitbare Vorschau")
	manager.cancel()
	manager.store = SettingsStore.new(directory.path_join("valid.cfg"))
	manager.saved = GameSettings.new()
	manager.apply(manager.saved)
	await _test_catalogs(host, check)
	await _test_menu(host, check)
	await _test_live_editor(host, check)
	manager.cancel()
	manager.store = old_store
	manager.saved = old_saved
	manager.apply(old_current)


static func _test_catalogs(host: Node, check: Callable) -> void:
	var german := load("res://data/i18n/de.po") as Translation
	var keys := german.get_message_list()
	var placeholders := RegEx.new()
	placeholders.compile("%(?:[-+0-9.]*[sdf]|%)")
	var holes := HoleCatalog.load_default()
	var courses := CourseCatalog.load_default()
	var custom := HoleDefinition.new()
	custom.hole_id = &"custom_i18n_test"
	custom.display_name = "SETTINGS_TITLE Äéñ"
	for locale in GameSettings.LANGUAGES:
		TranslationServer.set_locale(locale)
		var catalog := load("res://data/i18n/%s.po" % locale) as Translation
		var complete := catalog.get_message_list().size() == keys.size()
		var valid_placeholders := true
		for key in keys:
			var value := String(catalog.get_message(key))
			complete = complete and not value.is_empty()
			var expected: Array[String] = []
			var actual: Array[String] = []
			for token in placeholders.search_all(german.get_message(key)):
				expected.append(token.get_string())
			for token in placeholders.search_all(value):
				actual.append(token.get_string())
			valid_placeholders = valid_placeholders and expected == actual
		check.call(complete and valid_placeholders, "%s: vollständiger Katalog und identische Formatparameter" % locale)
		var names_complete := true
		for hole in holes.holes:
			names_complete = names_complete and not catalog.get_message("HOLE_" + String(hole.hole_id).to_upper()).is_empty()
		for course in courses.courses:
			names_complete = names_complete and not catalog.get_message("COURSE_" + String(course.course_id).to_upper()).is_empty()
		check.call(names_complete, "%s: alle aktiven offiziellen Inhaltsnamen vorhanden" % locale)
		check.call(I18n.content_name(custom) == custom.display_name, "%s: eigene Namen werden nicht übersetzt" % locale)
		var document := EditorDocument.new()
		var tile := WallTileDefinition.new()
		tile.grid_cell = Vector2i(-100, -100)
		document.hole.wall_tiles.append(tile)
		document.ensure_ids()
		var id := String(tile.get_meta("editor_id"))
		var issues := document.issues()
		check.call(issues.any(func(issue: Dictionary): return issue.id == id and issue.has("key")), "%s: Editorfehler markiert sprachunabhängig den Wandbaustein" % locale)
		check.call(issues.all(func(issue: Dictionary): return issue.has("key") and issue.has("parameters")), "%s: Alle Editorhinweise enthalten Schlüssel und Parameter" % locale)
		var wall := WallDefinition.new()
		wall.arc_segments = 256
		document.hole.walls.append(wall)
		document.ensure_ids()
		var limits := document.issues()
		check.call(limits.size() == 1 and limits[0].id == String(wall.get_meta("editor_id")) and limits[0].has("key"), "%s: Geometriegrenze markiert den betroffenen Bogen" % locale)
		var label := MenuWidgets.label("SETTINGS_TITLE", Vector2.ZERO, Vector2(200, 20), 12, Color.WHITE)
		host.add_child(label)
		check.call(label.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED and label.text == "SETTINGS_TITLE", "%s: Benutzernamen bleiben auch bei identischem Übersetzungsschlüssel wörtlich" % locale)
		label.queue_free()
	TranslationServer.set_locale("pt")
	check.call(I18n.text("SETTINGS_TITLE") == "EINSTELLUNGEN", "Nicht unterstützte Sprache verwendet deutschen Rückfall")
	TranslationServer.set_locale("de")
	await host.get_tree().process_frame


static func _test_menu(host: Node, check: Callable) -> void:
	var manager := host.get_node("/root/SettingsManager")
	var app := GameApp.new()
	host.add_child(app)
	await host.get_tree().process_frame
	app._show_settings(false)
	check.call(app.current_screen == GameApp.ScreenState.SETTINGS and app._menu_input_locked, "Einstellungen sind vom Titel erreichbar und sperren gehaltene Eingaben")
	var old_button: Button = app.option_buttons[1]
	app._invoke_option(1)
	check.call(manager.draft.language == "de", "Gehaltene Bestätigung ändert keine Sprache")
	app._menu_input_locked = false
	app._select_option(1)
	app._move_selection(Vector2.RIGHT)
	check.call(manager.current.language == "en" and app.selected_option == 1, "Rechts ändert Sprache; Auswahl bleibt auf derselben Zeile")
	app._menu_input_locked = false
	old_button.pressed.emit()
	check.call(manager.current.language == "en", "Veraltete Menüsignale ändern keine Werte")
	app._go_back()
	check.call(app.current_screen == GameApp.ScreenState.TITLE and manager.current.language == "de", "Zurück verwirft Vorschau und kehrt zum Titel zurück")
	app._show_settings(false)
	app._menu_input_locked = false
	var input := host.get_node("/root/ControllerSupport")
	var old_focus: bool = input.focused
	input.focused = false
	app._invoke_option(1)
	check.call(manager.current.language == "de", "Fokusverlust sperrt Einstellungsaktionen")
	input.focused = old_focus
	var previous_id: int = input.active_device_id
	var previous_guid: String = input.active_device_guid
	var previous_mapping_path: String = input.user_mapping_path
	input.active_device_id = 42
	input.active_device_guid = "settings_test_controller"
	input.user_mapping_path = manager.store.storage_path + ".controller"
	app.settings_menu.page = 3
	app.settings_menu._calibrate()
	check.call(input.is_calibrating() and not app.diagnostics_visible, "Kalibrierung startet im Setup ohne blockierendes Diagnosefenster")
	input.active_device_id = -1
	app._on_controller_changed(-1, "", "")
	check.call(not input.is_calibrating() and not app.settings_menu.calibration_visible, "Controllertrennung beendet Kalibrierung und erhält das Setup")
	input.active_device_id = previous_id
	input.active_device_guid = previous_guid
	input.user_mapping_path = previous_mapping_path
	var valid_store: SettingsStore = manager.store
	manager.store = SettingsStore.new(valid_store.storage_path.path_join("missing/settings.cfg"))
	app.settings_menu._adjust("language", 1)
	app.settings_menu._commit()
	check.call(app.current_screen == GameApp.ScreenState.SETTINGS and not app.settings_menu.error_message.is_empty(), "Speicherfehler bleibt im Menü sichtbar; Entwurf bleibt erhalten")
	app.settings_menu._adjust("language", 1)
	check.call(app.screen_root.get_children().any(func(node: Node): return node is Label and node.text == I18n.text("SETTINGS_SAVE_ERROR")), "Sichtbarer Speicherfehler folgt der Sprachvorschau")
	app.settings_menu.cancel()
	manager.store = valid_store
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.PRACTICE
	config.players = [PlayerProfile.create(1, "Élodie", 0)]
	config.hole_ids = [app.course_catalog.courses[0].hole_ids[0]]
	app._start_round(config)
	await host.get_tree().process_frame
	app._show_pause()
	var game := app.gameplay
	var ball_position := game.ball.global_position
	app._show_settings(true)
	manager.draft.language = "fr"
	manager.preview()
	await host.get_tree().process_frame
	check.call(host.get_tree().paused and app.gameplay == game and game.ball.global_position == ball_position, "Sprachvorschau erhält pausierte Runde und Ballposition")
	check.call(game.hud.course_label.text == I18n.content_name(game.hole.definition) and game.hud.round_label.text.begins_with("TROU"), "Bereits sichtbares HUD aktualisiert Sprache auch während Pause")
	app.settings_menu._commit()
	check.call(app.current_screen == GameApp.ScreenState.PAUSE and host.get_tree().paused, "Übernehmen kehrt zur angehaltenen Runde zurück")
	app._resume_game()
	check.call(app._menu_input_locked and not game.input_enabled, "Fortsetzen erhält Eingabeschranke")
	app._leave_to_menu()
	app.queue_free()
	await host.get_tree().process_frame


static func _test_live_editor(host: Node, check: Callable) -> void:
	TranslationServer.set_locale("de")
	var editor := EditorUI.new()
	editor.store = CustomContentStore.new("user://i18n-editor-%d" % Time.get_ticks_usec())
	host.add_child(editor)
	await host.get_tree().process_frame
	editor.document.begin()
	editor.document.hole.display_name = "SETTINGS_TITLE éñ"
	editor.document.commit()
	editor.canvas.set_tool("wall", 7)
	editor.canvas.zoom = 0.65
	editor.canvas.pan = Vector2(17, 42)
	var original := editor.document
	var before := original.text()
	var undo_count := original.undo_stack.size()
	var dialog := ConfirmationDialog.new()
	I18n.bind(dialog, "title", "TEXT_PLAYERS_FOR", ["Élodie"])
	editor.add_child(dialog)
	TranslationServer.set_locale("it")
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	check.call(editor.document == original and original.text() == before and original.undo_stack.size() == undo_count, "Sprachwechsel erhält Editorentwurf und Undo-Verlauf")
	check.call(editor.canvas.tool == "wall" and editor.canvas.variant == 7 and is_equal_approx(editor.canvas.zoom, 0.65) and editor.canvas.pan == Vector2(17, 42) and editor.title_label.text == original.hole.display_name + " *", "Editor behält Werkzeug, Variante und unveränderten eigenen Namen")
	check.call(dialog.title == "Giocatori per «Élodie»", "Offene Dialogtitel übersetzen sich mit unveränderten Nutzernamen")
	editor._close()
	editor.queue_free()
	await host.get_tree().process_frame
	TranslationServer.set_locale("de")
