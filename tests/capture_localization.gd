extends Node

var root: Window

var app: GameApp
var directory := "res://.godot/localization"
var failures := 0


func _ready() -> void:
	call_deferred("run")


func run() -> void:
	root = get_tree().root
	root.gui_embed_subwindows = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	app = GameApp.new()
	root.add_child(app)
	await get_tree().process_frame
	root.size = Vector2i(1280, 720)
	var manager := root.get_node("SettingsManager")
	for locale in GameSettings.LANGUAGES:
		manager.saved = GameSettings.new()
		manager.saved.language = locale
		manager.apply(manager.saved)
		app._show_title()
		await capture(locale + "-title")
		app._show_settings(false)
		for page in range(4):
			app.settings_menu.page = page
			app.settings_menu.show()
			await capture(locale + "-settings-" + str(page))
		app.settings_menu.cancel()
		app._show_mode()
		await capture(locale + "-modes")
		app.working_players = [PlayerProfile.create(1, "Élodie", 0)]
		app._show_course_select()
		await capture(locale + "-courses")
		var config := RoundConfig.new()
		config.mode = RoundConfig.GameMode.COURSE_SOLO
		config.course_id = app.course_catalog.courses[0].course_id
		config.players = app.working_players.duplicate()
		config.hole_ids = app.course_catalog.courses[0].hole_ids.duplicate()
		app._start_round(config)
		await get_tree().process_frame
		await capture(locale + "-hud")
		app._show_pause()
		app._show_scorecard(false, true)
		await capture(locale + "-scores")
		app._leave_to_menu()
		app._show_editor(false)
		await capture(locale + "-editor")
		app.editor._file_dialog(true, func(_path: String): pass)
		var file_dialog: FileDialog
		for child in app.editor.get_children():
			if child is FileDialog:
				file_dialog = child
		file_dialog.current_dir = ProjectSettings.globalize_path("res://data/i18n")
		await capture(locale + "-files")
		file_dialog.hide()
		file_dialog.queue_free()
		app.editor._close()
		await get_tree().process_frame
	print("Localization captures: %d Fehler, %s" % [failures, directory])
	get_tree().quit(0 if failures == 0 else 1)


func capture(name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(directory.path_join(name + ".png"))
	if error != OK:
		failures += 1
