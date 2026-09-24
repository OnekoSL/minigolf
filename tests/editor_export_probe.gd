extends Node

# Packaged test entry point; copied into an isolated export project by the probe script.
var failures := 0
var checks := 0
var app: GameApp


func _ready() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	print("%s %s" % ["OK" if condition else "FEHLER", message])
	if not condition:
		failures += 1


func _run() -> void:
	app = GameApp.new()
	get_tree().root.add_child(app)
	await get_tree().process_frame
	var verify := "--verify" in OS.get_cmdline_user_args()
	var manager := get_node("/root/SettingsManager")
	if verify:
		_check(manager.current.language == "it" and manager.current.effects_volume == 40, "Export: Neustart lädt Sprache und Lautstärke")
	for locale in GameSettings.LANGUAGES:
		TranslationServer.set_locale(locale)
		_check(I18n.text("SETTINGS_TITLE") != "SETTINGS_TITLE" and I18n.content_name(app.course_catalog.courses[0]) != "", "Export: Übersetzungskatalog %s verfügbar" % locale)
	if not verify:
		manager.begin()
		manager.draft.language = "it"
		manager.draft.effects_volume = 40
		manager.preview()
		_check(manager.commit() == OK, "Export: Einstellungen gespeichert")
	# Keep existing probe assertions and fixtures independent of user language.
	TranslationServer.set_locale("de")
	app._show_editor(verify)
	await get_tree().process_frame
	var ui := app.editor
	var store := ui.store
	_check(get_tree().root.content_scale_size == Vector2i(1280, 720), "Export enthält hochauflösenden Ingame-Editor")
	if not verify:
		ui.document.begin()
		ui.document.hole.display_name = "Standalone-Probe"
		ui.document.hole.hole_position = Vector2(328, 280)
		ui.document.commit()
		ui.canvas.set_tool("wall", 6)
		ui.canvas._press(Vector2(400, 96), false)
		ui.canvas._drag(Vector2(480, 96))
		ui.canvas._release(Vector2(480, 96))
		ui._save()
		_check(not ui.document.dirty() and store.holes.size() == 1, "Bahn im eigenständigen Programm gebaut und gespeichert")
		var course := CourseDefinition.new()
		course.course_id = EditorCodec.new_id()
		course.display_name = "Standalone-Kurs"
		course.hole_ids = [ui.document.hole.hole_id, ui.document.hole.hole_id]
		_check(store.save_course(course), "Eigener Kurs gespeichert")
		_check(store.export_course(course, "user://standalone-course.json"), "Kurs mit allen Bahnen exportiert")
		_check(store.import_file("user://standalone-course.json"), "Exportdatei mit neuen Kennungen importiert")
		await _capture("standalone-editor.png")
	else:
		_check(store.holes.size() == 2 and store.courses.size() == 2, "Neustart lädt gespeicherte und importierte Inhalte")
		if store.holes.size() != 2 or store.courses.size() != 2:
			_finish()
			return
		ui._open_document(EditorDocument.new(store.holes[0]))
		var before := ui.document.text()
		await get_tree().process_frame
		ui._test()
		await get_tree().process_frame
		var playtest: EditorPlaytest
		for child in app.get_children():
			if child is EditorPlaytest:
				playtest = child
		_check(playtest != null and get_tree().root.content_scale_size == Vector2i(640, 360), "Testspiel verwendet normale Spielauflösung")
		if playtest != null:
			for _frame in range(20):
				await get_tree().process_frame
			await _capture("standalone-testspiel.png")
			playtest._close()
			await get_tree().process_frame
		_check(ui.document.text() == before and get_tree().root.content_scale_size == Vector2i(1280, 720), "Testspiel kehrt ohne Entwurfsänderungen zum Editor zurück")
		var course := store.courses[0]
		var players: Array[PlayerProfile] = [PlayerProfile.create(1, "EXE TEST", 0)]
		app._start_custom_content(course, players)
		for hole_index in range(2):
			for _frame in range(20):
				await get_tree().process_frame
			var game := app.gameplay
			game.shot_controller.cursor_position = game.hole.get_hole_position()
			game.shot_controller._locked_power = inverse_lerp(game.shot_controller.minimum_ball_speed, game.shot_controller.maximum_ball_speed, 155)
			game.shot_controller._locked_accuracy = 0
			game.shot_controller.state = ShotController.ShotState.ARMED
			game.shot_controller.action_released()
			for _frame in range(500):
				await get_tree().physics_frame
				if app.current_screen in [GameApp.ScreenState.SCORECARD, GameApp.ScreenState.FINAL]:
					break
			_check(app.session.scores[0][hole_index] == 1, "Export: eigene Bahn %d mit echter Physik eingelocht" % (hole_index + 1))
			if hole_index == 0:
				app._continue_after_hole()
		_check(app.session.is_complete() and app.session.get_player_total(0) == 2, "Eigener Kurs vollständig gespielt")
		_check(app.best_store.get_best(app._active_best_score_key()) == 2, "Eigener Bestwert unter passendem Bahnstand gespeichert")
		await _capture("standalone-scorecard.png")
	_finish()


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for _frame in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_tree().root.get_texture().get_image().save_png("user://" + name)


func _finish() -> void:
	print("Export-Editor: %d Checks, %d Fehler" % [checks, failures])
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)
