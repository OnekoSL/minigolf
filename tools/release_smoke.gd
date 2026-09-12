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
	_check(ProjectSettings.get_setting("application/config/version")=="0.3.0","Version 0.3.0 im ausgelieferten Paket")
	_check(FileAccess.file_exists("res://config/controller_mappings.cfg"),"Controllerprofile im Paket enthalten")
	_check(not ResourceLoader.exists("res://tests/run_tests.gd") and not ResourceLoader.exists("res://tools/release_smoke.gd"),"Entwicklertests und Buildwerkzeuge nicht ausgeliefert")
	print("USER_DIR ",OS.get_user_data_dir())
	_check(OS.get_user_data_dir().replace("\\","/").ends_with("Godot/app_userdata/Putt & Pixel - Spielrahmen-Prototyp"),"Bisheriger Speicherordner bleibt erhalten")
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	root.add_child(app)
	await get_tree().process_frame
	_check(root.title=="Putt & Pixel 0.3.0","Release-Fenstertitel")
	_check(app.hole_catalog.validate().is_empty() and app.course_catalog.validate(app.hole_catalog).is_empty(),"Exportierte Bahn- und Kursdaten sind gueltig")
	_check(app.course_catalog.courses.size()==8,"Acht exportierte Kurse")
	await _capture("titel")
	for index in range(app.course_catalog.courses.size()):
		var course := app.course_catalog.courses[index]
		app.course_select_page = index/app.COURSES_PER_PAGE
		app._show_course_select()
		app._select_option(index%app.COURSES_PER_PAGE)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(app.course_preview.hole_ids.size()==9 and app.course_preview.runtimes.size()==9,"Neun aufgebaute Bahnen in "+course.display_name)
		if index==5: await _capture("uhrwerkfabrik")
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
	app._remove_gameplay()
	app.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("RELEASE: %d Checks, %d Fehler" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
