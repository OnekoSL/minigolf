extends SceneTree

const OUTPUT := "res://.godot/prototype-polish"


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var catalog := HoleCatalog.load_default()
	var sheet := _viewport(Vector2i(1800, 1200))
	for index in range(9):
		var definition := catalog.get_hole(CourseCatalog.load_default().get_course(&"prototype_course_03").hole_ids[index])
		var origin := Vector2((index % 3) * 600, (index / 3) * 400)
		var scale_factor := minf(560.0 / definition.course_rect.size.x, 332.0 / definition.course_rect.size.y)
		_add_hole(sheet, definition, origin + Vector2(20, 52), scale_factor)
		_add_label(sheet, origin + Vector2(20, 12), "%d  %s | PAR %d" % [index + 1, definition.display_name, definition.par], 22)
		var detail := _viewport(Vector2i(definition.course_rect.size * 3.0) + Vector2i(48, 88))
		_add_hole(detail, definition, Vector2(24, 64), 3.0)
		_add_label(detail, Vector2(24, 16), "%d  %s | PAR %d" % [index + 1, definition.display_name, definition.par], 28)
		await process_frame
		await RenderingServer.frame_post_draw
		var result := detail.get_texture().get_image().save_png("%s/loch-%02d.png" % [OUTPUT, index + 1])
		print("Prototyp-Detail %d: %s" % [index + 1, error_string(result)])
		detail.queue_free()
	await process_frame
	await RenderingServer.frame_post_draw
	var result := sheet.get_texture().get_image().save_png(OUTPUT + "/uebersicht.png")
	print("Prototyp-Gesamtansicht: ", error_string(result))
	quit()


func _viewport(size: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	return viewport


func _add_hole(viewport: SubViewport, definition: HoleDefinition, origin: Vector2, scale_factor: float) -> void:
	var runtime := HoleRuntime.new()
	runtime.configure(definition)
	runtime.scale = Vector2.ONE * scale_factor
	runtime.position = origin - definition.course_rect.position * scale_factor
	viewport.add_child(runtime)


func _add_label(viewport: SubViewport, point: Vector2, title: String, font_size: int) -> void:
	var label := Label.new()
	label.position = point
	label.text = title
	label.add_theme_font_size_override("font_size", font_size)
	viewport.add_child(label)
