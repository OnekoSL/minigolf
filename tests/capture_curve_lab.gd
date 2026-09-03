extends Node


func _ready() -> void:
	await get_tree().process_frame
	var main := get_parent().get_node("PrototypeMain") as PrototypeMain
	for _index in range(7):
		main.switch_test_hole()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var result := get_viewport().get_texture().get_image().save_png("res://.godot/curve-lab.png")
	print("Curve lab screenshot: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)
