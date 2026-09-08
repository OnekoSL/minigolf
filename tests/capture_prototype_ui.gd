extends Node

const OUTPUT := "res://.godot/prototype-polish"

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var catalog := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"prototype_course_03")
	for index in range(9):
		var definition := catalog.get_hole(course.hole_ids[index])
		var main := PrototypeMain.new()
		main.configure_attempt(definition, PlayerProfile.create(1,"SPIELER 1",0), true,index+1,9,0,false)
		get_tree().root.add_child(main)
		await get_tree().process_frame
		await get_tree().process_frame
		await _save("spiel-%02d" % (index+1))
		if definition.camera_center_bounds.size != Vector2.ZERO:
			main.course_camera.set_process(false)
			main.course_camera.global_position = definition.camera_center_bounds.end
			await get_tree().process_frame
			await _save("spiel-%02d-ziel" % (index+1))
		main.queue_free()
		await get_tree().process_frame
	var app := GameApp.new()
	get_tree().root.add_child(app)
	await get_tree().process_frame
	var config := RoundConfig.new()
	config.course_id = course.course_id
	config.mode = RoundConfig.GameMode.COURSE_SOLO
	config.players = [PlayerProfile.create(1,"SPIELER 1",0)]
	config.hole_ids = course.hole_ids.duplicate()
	config.best_eligible = true
	app.session = RoundSession.new()
	app.session.configure(config,catalog)
	app.session.scores[0] = [4,2,5,3,2,3,5,4,3]
	app._show_scorecard(true,false)
	await _save("endtabelle-solo")
	config.mode = RoundConfig.GameMode.COURSE_LOCAL
	config.players = [PlayerProfile.create(1,"ALEXANDER123",0), PlayerProfile.create(2,"BEATRIX",1),PlayerProfile.create(3,"CHARLIE",2),PlayerProfile.create(4,"DOROTHEA",3)]
	app.session = RoundSession.new()
	app.session.configure(config,catalog)
	app.session.scores[0] = [4,3,4,3,3,3,5,4,4]
	app.session.scores[1] = [4,2,4,3,2,3,5,4,3]
	app.session.scores[2] = [4,3,4,3,3,3,5,4,4]
	app.session.scores[3] = [8,4,4,3,3,3,5,4,4]
	app.session.capped[3][0] = true
	app._show_scorecard(true,false)
	await _save("endtabelle-hotseat")
	app._show_scorecard(false,true)
	await _save("zwischenstand")
	config.mode = RoundConfig.GameMode.PRACTICE
	config.best_eligible = false
	config.players = [PlayerProfile.create(1,"SPIELER 1",0)]
	config.hole_ids = [&"prototype_04"]
	app.session = RoundSession.new()
	app.session.configure(config,catalog)
	app.session.scores[0] = [3]
	app._show_scorecard(true,false)
	await _save("endtabelle-uebung")
	app.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _save(stem: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print(stem,": ",error_string(get_viewport().get_texture().get_image().save_png(OUTPUT+"/"+stem+".png")))
