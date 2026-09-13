extends Node

const OUTPUT := "res://.godot/urban_winter"


func _ready() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var catalog := HoleCatalog.load_default()
	for course in [CourseCatalog.load_default().get_course(&"urban_winter_course")]:
		var sheet := _viewport(Vector2i(1536,1152))
		for index in range(9):
			var definition := catalog.get_hole(course.hole_ids[index])
			var origin := Vector2((index%3)*512,(index/3)*384)
			var factor := minf(488.0/definition.course_rect.size.x,336.0/definition.course_rect.size.y)
			_add_hole(sheet,definition,origin+Vector2(12,40),factor)
			_add_label(sheet,origin+Vector2(12,8),"%d  %s | PAR %d" % [index+1,definition.display_name,definition.par],17)
			var detail := _viewport(Vector2i(definition.course_rect.size)+Vector2i(24,48))
			_add_hole(detail,definition,Vector2(12,36),1.0)
			_add_label(detail,Vector2(12,8),definition.display_name,16)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			detail.get_texture().get_image().save_png("%s/%s.png" % [OUTPUT,definition.hole_id])
			detail.queue_free()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		sheet.get_texture().get_image().save_png("%s/%s.png" % [OUTPUT,course.course_id])
		print("Aufnahme: ",course.course_id)
		sheet.queue_free()
	var app := (load("res://scenes/game_app.tscn") as PackedScene).instantiate() as GameApp
	get_tree().root.add_child(app)
	await get_tree().process_frame
	for page in [3]:
		app.course_select_page = page
		app._show_course_select()
		app._select_option(1)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_tree().root.get_texture().get_image().save_png("%s/menu-%d.png" % [OUTPUT,page+1])
	for course in [CourseCatalog.load_default().get_course(&"urban_winter_course")]:
		for index in range(9):
			var config := RoundConfig.new()
			config.mode = RoundConfig.GameMode.PRACTICE
			config.players = [PlayerProfile.create(1,"SPIELTEST",0)]
			config.hole_ids = [course.hole_ids[index]]
			app._remove_gameplay()
			await get_tree().process_frame
			app._start_round(config)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_tree().root.get_texture().get_image().save_png("%s/%s-spiel-%d.png" % [OUTPUT,course.course_id,index+1])
			for obstacle_index in range(app.gameplay.hole.obstacle_nodes.size()):
				var obstacle := app.gameplay.hole.obstacle_nodes[obstacle_index] as MovingObstacle
				obstacle.set_physics_process(false)
				# Freeze the body at the requested visual phase without the physics
				# server restoring its previous synchronized transform next frame.
				obstacle.sync_to_physics = false
				app.gameplay.ball.reset_to(obstacle.position + Vector2(-60,0))
				app.gameplay.shot_controller._set_state(ShotController.ShotState.BALL_MOVING)
				app.gameplay._update_camera_focus()
				app.gameplay.course_camera.snap_to_target()
				var phases: Array[float] = [0.0,3.25,4.0]
				if obstacle is RotatingObstacle: phases = [0.0,1.0,2.0]
				for phase in phases:
					obstacle.reset_motion()
					if obstacle is TimedSlidingGate: obstacle.advance_motion(phase)
					elif obstacle is RotatingObstacle: obstacle.rotation = obstacle.start_rotation + phase * TAU / obstacle.seconds_per_revolution
					await get_tree().process_frame
					await RenderingServer.frame_post_draw
					get_tree().root.get_texture().get_image().save_png("%s/hindernis-%d-%d-%.2f.png" % [OUTPUT,index+1,obstacle_index,phase])
			if index in [6,8]:
				app.gameplay.ball.reset_to(app.gameplay.hole.get_hole_position() - Vector2(24,0))
				app.gameplay.shot_controller._set_state(ShotController.ShotState.BALL_MOVING)
				app.gameplay._update_camera_focus()
				app.gameplay.course_camera.snap_to_target()
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_tree().root.get_texture().get_image().save_png("%s/eisziel-%d.png" % [OUTPUT,index+1])
			var bounds := app.gameplay.hole.definition.camera_center_bounds
			if bounds.size != Vector2.ZERO:
				app.gameplay.course_camera.make_current()
				app.gameplay.course_camera.set_process(false)
				app.gameplay.course_camera.set_physics_process(false)
				app.gameplay.course_camera.position = bounds.end
				app.gameplay.course_camera.force_update_scroll()
				await get_tree().process_frame
				await RenderingServer.frame_post_draw
				get_tree().root.get_texture().get_image().save_png("%s/%s-kamera-%d.png" % [OUTPUT,course.course_id,index+1])
	app._remove_gameplay()
	app.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func _viewport(size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	get_tree().root.add_child(viewport)
	return viewport


func _add_hole(viewport: SubViewport, definition: HoleDefinition, origin: Vector2, factor: float) -> void:
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	runtime.scale = Vector2.ONE*factor
	runtime.position = origin-definition.course_rect.position*factor
	viewport.add_child(runtime)


func _add_label(viewport: SubViewport, point: Vector2, title: String, size: int) -> void:
	var label := Label.new()
	label.position = point
	label.text = title
	label.add_theme_font_size_override("font_size",size)
	viewport.add_child(label)
