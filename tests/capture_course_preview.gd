extends Node


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/course-preview")
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	get_tree().root.add_child(app)
	await get_tree().process_frame
	for index in range(app.course_catalog.courses.size()):
		app.course_select_page = index/app.COURSES_PER_PAGE
		app._show_course_select()
		app._select_option(index%app.COURSES_PER_PAGE)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var path := "res://.godot/course-preview/%s.png" % app.course_preview.course_id
		var result := get_viewport().get_texture().get_image().save_png(path)
		if result != OK:
			get_tree().quit(1)
			return
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit()
