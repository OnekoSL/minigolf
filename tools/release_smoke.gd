extends Node

var failures := 0
var checks := 0
var output := ""
var root: Window


func _ready() -> void:
	root = get_tree().root
	var arguments := OS.get_cmdline_user_args()
	if arguments.size()>0: output = arguments[0]
	call_deferred("_run")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("OK " if ok else "FAIL ",message)


func _capture(name: String) -> void:
	if output.is_empty() or DisplayServer.get_name()=="headless": return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"Release-Aufnahme "+name)


func _run() -> void:
	# Release templates disable external script overrides. Mount the exported
	# EXE with the matching editor engine and a scene override for this audit; launch the
	# actual standalone executable separately with --write-movie/--quit-after.
	_check(ProjectSettings.get_setting("application/config/version")=="0.6.0","Version 0.6.0 im ausgelieferten Paket")
	_check(ProjectSettings.get_setting("application/config/icon")=="res://assets/branding/putt_and_pixel.png" and ResourceLoader.exists("res://assets/branding/putt_and_pixel.png"),"Eigenes Anwendungssymbol im Paket")
	_check(FileAccess.file_exists("res://config/controller_mappings.cfg"),"Controllerprofile im Paket enthalten")
	_check(not ResourceLoader.exists("res://tests/run_tests.gd") and not ResourceLoader.exists("res://tools/release_smoke.gd"),"Entwicklertests und Buildwerkzeuge nicht ausgeliefert")
	print("USER_DIR ",OS.get_user_data_dir())
	_check(OS.get_user_data_dir().replace("\\","/").ends_with("Godot/app_userdata/Putt & Pixel - Spielrahmen-Prototyp"),"Bisheriger Speicherordner bleibt erhalten")
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	root.add_child(app)
	await get_tree().process_frame
	_check(root.title=="Putt & Pixel 0.6.0","Release-Fenstertitel")
	_check(app.hole_catalog.validate().is_empty() and app.course_catalog.validate(app.hole_catalog).is_empty(),"Exportierte Bahn- und Kursdaten sind gueltig")
	_check(app.course_catalog.courses.size()==11 and app.hole_catalog.holes.size()==113,"Elf Kurse und 113 exportierte Bahnen")
	await _capture("titel")
	await _check_settings(app)
	for index in range(app.course_catalog.courses.size()):
		var course := app.course_catalog.courses[index]
		app.course_select_page = index/app.COURSES_PER_PAGE
		app._show_course_select()
		app._select_option(index%app.COURSES_PER_PAGE)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(app.course_preview.hole_ids.size()==9 and app.course_preview.runtimes.size()==9,"Neun aufgebaute Bahnen in "+course.display_name)
		if index==5: await _capture("uhrwerkfabrik")
		if index==8: await _capture("zirkus")
		if index==9: await _capture("baustelle")
		if index==10: await _capture("urban-winter")
	for index in range(GolferDefinition.IDS.size()):
		var config := RoundConfig.new()
		config.mode = RoundConfig.GameMode.PRACTICE
		var player := PlayerProfile.create(1,"RELEASE",index)
		player.golfer_id = GolferDefinition.IDS[index]
		config.players = [player]
		config.hole_ids = [&"labyrinth_nine_08"]
		app._remove_gameplay()
		await get_tree().process_frame
		app._start_round(config)
		await get_tree().process_frame
		_check(app.gameplay != null and app.gameplay.hole.obstacle_nodes[0] is TunnelGear,"Spielstart mit "+String(player.golfer_id))
		_check(is_equal_approx((app.gameplay.hole.obstacle_nodes[0] as TunnelGear).seconds_per_revolution,16),"Zahnradtempo im Release")
		if index==0: await _capture("spiel")
	await _check_new_courses(app)
	app._remove_gameplay()
	await _check_editor(app)
	app.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("RELEASE: %d Checks, %d Fehler" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)


func _check_settings(app: GameApp) -> void:
	_check(SettingsManager.current.language == "de", "Erster Paketstart verwendet Deutsch")
	app._show_settings(false)
	for locale in GameSettings.LANGUAGES:
		var catalog := load("res://data/i18n/%s.po" % locale) as Translation
		_check(catalog != null and catalog.get_message_list().size() == 849, "Vollstaendiger Sprachkatalog im Paket: " + locale)
		SettingsManager.draft.language = locale
		SettingsManager.preview()
		app.settings_menu.page = 2
		app.settings_menu.show()
		await get_tree().process_frame
		_check(TranslationServer.get_locale() == locale and I18n.text("SETTINGS_TITLE") != "SETTINGS_TITLE", "Sprachvorschau im Paket: " + locale)
		await _capture("einstellungen-" + locale)
	app.settings_menu.cancel()
	_check(SettingsManager.current.language == "de" and app.current_screen == GameApp.ScreenState.TITLE, "Abbrechen stellt Paketsprache wieder her")
	app._show_settings(false)
	SettingsManager.draft.language = "fr"
	SettingsManager.preview()
	app.settings_menu._commit()
	_check(SettingsStore.new().read().language == "fr", "Einstellungen lassen sich im Paket speichern und laden")
	app._show_settings(false)
	SettingsManager.draft.language = "de"
	SettingsManager.preview()
	app.settings_menu._commit()


func _check_editor(app: GameApp) -> void:
	app._show_editor(false)
	await get_tree().process_frame
	var ui := app.editor
	_check(root.content_scale_size == Vector2i(1280, 720), "Exportierter Editor verwendet 1280 x 720")
	ui._tool("tunnel")
	ui.canvas._press(Vector2(320, 208), false)
	ui.canvas._release(Vector2(320, 208))
	_check(ui.canvas.tool == "select", "Tunnelplatzierung wechselt zur Auswahl")
	ui.canvas._press(Vector2(416, 208), false)
	ui.canvas._drag(Vector2(480, 240))
	ui.canvas._release(Vector2(480, 240))
	_check(ui.document.hole.tunnels.size() == 1 and ui.document.hole.tunnels[0].endpoint_b == Vector2(480, 240), "Tunnelende im Paket verschiebbar ohne Kopie")
	ui.canvas._press(Vector2(400, 224), false)
	ui.canvas._drag(Vector2(416, 240))
	ui.canvas._release(Vector2(416, 240))
	_check(ui.document.hole.tunnels[0].endpoint_a == Vector2(336, 224) and ui.document.hole.tunnels[0].endpoint_b == Vector2(496, 256), "Paargriff verschiebt beide Enden")
	ui.document.undo()
	_check(ui.document.hole.tunnels[0].endpoint_a == Vector2(320, 208), "Tunnelbewegung im Paket rueckgaengig")
	await _capture("bahneditor")
	var before := ui.document.text()
	ui._test()
	await get_tree().process_frame
	var playtest: EditorPlaytest
	for child in app.get_children():
		if child is EditorPlaytest:
			playtest = child
	_check(playtest != null and root.content_scale_size == Vector2i(640, 360), "Ungespeicherte Bahn startet echtes Testspiel")
	if playtest != null:
		await _capture("editor-testspiel")
		playtest._close()
		await get_tree().process_frame
	_check(ui.document.text() == before and root.content_scale_size == Vector2i(1280, 720), "Testspiel erhaelt Entwurf und Editoransicht")
	ui._save()
	_check(not ui.document.dirty(), "Eigene Bahn aus Release gespeichert")
	var course := CourseDefinition.new()
	course.course_id = EditorCodec.new_id()
	course.display_name = "Releasekurs"
	course.hole_ids = [ui.document.hole.hole_id, ui.document.hole.hole_id]
	_check(ui.store.save_course(course), "Eigener Kurs mit Wiederholung gespeichert")
	_check(ui.store.export_course(course, "user://release-course.json"), "Kurs mit Bahndaten exportiert")
	_check(ui.store.import_file("user://release-course.json"), "Kurs mit neuen Kennungen importiert")
	var reloaded := CustomContentStore.new()
	_check(reloaded.load_library() and reloaded.holes.size() == 2 and reloaded.courses.size() == 2, "Gespeicherte Bibliothek vollstaendig geladen")
	ui.show_library()
	await _capture("eigene-inhalte")


func _check_new_courses(app: GameApp) -> void:
	for course_id in [&"zirkus_course", &"baustelle_course", &"urban_winter_course"]:
		var course := app.course_catalog.get_course(course_id)
		for index in range(course.hole_ids.size()):
			app._remove_gameplay()
			await get_tree().process_frame
			var config := RoundConfig.new()
			config.mode = RoundConfig.GameMode.PRACTICE
			config.players = [PlayerProfile.create(1,"RELEASE",0)]
			config.hole_ids = [course.hole_ids[index]]
			app._start_round(config)
			await get_tree().physics_frame
			var game := app.gameplay
			_check(game.hole.definition.hole_id == course.hole_ids[index],"Neue Kursbahn startet: "+String(course.hole_ids[index]))
			if course_id in [&"baustelle_course", &"urban_winter_course"]:
				_check(game.ball.base_surface == SurfaceZone.SurfaceType.CONCRETE and game.ball._surface_at(game.ball.position).deceleration == 80,"Betonabschlag im exportierten Kurs")
			if course_id == &"urban_winter_course":
				_check(game.hole.zones.all(func(zone): return zone.surface_type == SurfaceZone.SurfaceType.ICE and zone.deceleration == 20),"Eis statt Wasser im exportierten Winterkurs")
			if course_id == &"baustelle_course" and index == 2:
				var pipe := game.hole.definition.pipe_systems[0]
				game.ball.reset_to(pipe.entrance)
				game.ball.launch(Vector2.RIGHT,190,1)
				game.ball._try_pipe_capture()
				game.shot_controller._set_state(ShotController.ShotState.BALL_MOVING)
				_check(game.ball._tunnel_exit_hole == pipe.exits[1],"Tempo-Rohr waehlt den mittleren Ausgang")
				for tick in range(40):
					await get_tree().physics_frame
					if not game.ball.is_tunnel_sequence_active(): break
				_check(not game.ball.is_tunnel_sequence_active() and game.ball.velocity.x > 180 and game.ball.position.distance_to(pipe.exits[1]+Vector2.RIGHT*13) < 7,"Rohr erhaelt das Tempo im freien Auslauf")
				await _capture("rohraustritt")
			if course_id == &"urban_winter_course" and index == 6:
				game.ball.reset_to(Vector2(400,184))
				game.ball.launch(Vector2.RIGHT,80,1)
				game.shot_controller._set_state(ShotController.ShotState.BALL_MOVING)
				for tick in range(12): await get_tree().physics_frame
				_check(game.ball.visible and game.ball.moving and game.ball.position.x > 410 and game.ball.velocity.x > 75 and game.ball.velocity.x < 77,"Eisgleiten ohne Wasserstrafe")
				await _capture("eisgleiten")
				game.restart_hole()
				_check(not game.ball.moving and game.ball.position == game.hole.get_tee_position(),"Neustart verwirft Eisbewegung")
				game.ball.reset_to(game.hole.get_hole_position()-Vector2(24,0))
				game.ball.launch(Vector2.RIGHT,40,1)
				game.shot_controller._set_state(ShotController.ShotState.BALL_MOVING)
				for tick in range(60):
					await get_tree().physics_frame
					if game.ball.position == game.hole.get_hole_position(): break
				_check(game.ball.position == game.hole.get_hole_position(),"Kurzer Eisputt locht im Paket ein")
