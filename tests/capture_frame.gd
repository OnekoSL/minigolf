extends Node


func _ready() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png("res://.godot/prototype-screenshot.png")
	print("Screenshot: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)

