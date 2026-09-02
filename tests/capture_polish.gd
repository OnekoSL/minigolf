extends Node


func _ready() -> void:
	await get_tree().process_frame
	var main = get_parent().get_node("PrototypeMain")
	main.shot_controller.set_process(false)
	main.shot_controller.state = ShotController.ShotState.SWINGING
	main.hud.update_game(
		main.strokes,
		main.hole.get_par(),
		0.78,
		0.0,
		ShotController.ShotState.SWINGING,
		42
	)
	main.hud.golfer._state_time = 0.055
	main.hud.play_golfer_reaction("perfect_swing")
	main.feedback_effects.spawn_wall(Vector2(405, 82), Vector2.DOWN, 360.0, &"windmill")
	main.feedback_effects.spawn_water(Vector2(500, 165))
	main.feedback_effects.spawn_perfect(main.ball.global_position)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var result := image.save_png("res://.godot/prototype-polish.png")
	print("Polish screenshot: ", error_string(result))
	get_tree().quit(0 if result == OK else 1)
