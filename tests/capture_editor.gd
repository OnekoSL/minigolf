extends Node

var ui: EditorUI


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/editor-captures")
	ui = EditorUI.new()
	ui.store = CustomContentStore.new("user://editor_capture_scratch")
	add_child(ui)
	await _capture("01-editor")
	var source := HoleCatalog.load_default()
	for hole in source.holes:
		if hole.is_course_hole() and not hole.cannons.is_empty():
			ui._open_document(EditorDocument.new(hole, true))
			ui.document.selection = [String(ui.document.hole.cannons[0].get_meta("editor_id"))]
			ui._refresh()
			break
	await _capture("02-mechanisms")
	ui._save()
	ui.show_library()
	await _capture("03-library")
	ui._edit_course(null)
	ui._append_course_hole(0)
	await _capture("04-course")
	for child in ui.get_children():
		if child is ConfirmationDialog:
			child.queue_free()
	await get_tree().process_frame
	var longest: HoleDefinition
	for hole in source.holes:
		if hole.is_course_hole() and (longest == null or hole.course_rect.size.length_squared() > longest.course_rect.size.length_squared()):
			longest = hole
	ui._open_document(EditorDocument.new(longest, true))
	await _capture("05-long-course")
	ui.canvas.zoom = 2.5
	ui.canvas.pan = ui.canvas.size * 0.5 - longest.tee_position * ui.canvas.zoom
	ui.canvas._update_transform()
	await _capture("06-zoom")
	ui._open_document(EditorDocument.new())
	ui._tool("tunnel")
	ui.canvas._press(Vector2(320, 208), false)
	ui.canvas._release(Vector2(320, 208))
	ui.canvas._press(Vector2(416, 208), false)
	ui.canvas._drag(Vector2(496, 144))
	ui.canvas._release(Vector2(496, 144))
	await _capture("07-tunnel-move")
	ui.queue_free()
	await get_tree().process_frame
	for name in DirAccess.get_files_at("user://editor_capture_scratch"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://editor_capture_scratch/" + name))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://editor_capture_scratch"))
	get_tree().quit()


func _capture(label: String) -> void:
	for _frame in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://.godot/editor-captures/%s.png" % label)
