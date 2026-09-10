class_name LabyrinthRoutes
extends RefCounted


static func geometry_routes() -> Dictionary:
	return {
		&"labyrinth_nine_01": [[Vector2(384, 300), 224.0], [Vector2(608, 64), 284.0], [Vector2(832, 300), 284.0], [Vector2(1056, 64), 284.0], [Vector2(1088, 176), 170.0]],
		&"labyrinth_nine_02": [[Vector2(432, 64), 242.0], [Vector2(624, 300), 274.0], [Vector2(832, 176), 245.0], [Vector2(1040, 64), 242.0], [Vector2(1088, 176), 174.0]],
		&"labyrinth_nine_03": [[Vector2(384, 312), 224.0], [Vector2(456, 300), 135.0], [Vector2(456, 144), 220.0], [Vector2(608, 64), 180.0], [Vector2(816, 300), 275.0], [Vector2(960, 64), 258.0], [Vector2(1024, 64), 124.0], [Vector2(1088, 176), 176.0]],
		&"labyrinth_nine_04": [[Vector2(352, 304), 210.0], [Vector2(520, 40), 300.0], [Vector2(680, 304), 278.0], [Vector2(840, 40), 278.0], [Vector2(1000, 304), 278.0], [Vector2(1088, 176), 197.0]],
		&"labyrinth_nine_05": [[Vector2(560, 232), 286.0], [Vector2(752, 144), 225.0], [Vector2(944, 232), 225.0], [Vector2(1088, 176), 192.0]],
		&"labyrinth_nine_06": [[Vector2(432, 300), 245.0], [Vector2(552, 292), 200.0], [Vector2(592, 176), 130.0], [Vector2(864, 64), 300.0], [Vector2(1080, 300), 300.0], [Vector2(1088, 176), 185.0]],
		&"labyrinth_nine_07": [[Vector2(400, 64), 227.0], [Vector2(576, 300), 270.0], [Vector2(752, 40), 278.0], [Vector2(928, 300), 270.0], [Vector2(960, 176), 180.0], [Vector2(1088, 176), 224.0]],
		&"labyrinth_nine_08": [[Vector2(368, 304), 217.0], [Vector2(384, 48), 270.0], [Vector2(536, 48), 210.0], [Vector2(688, 176), 220.0], [Vector2(848, 304), 224.0], [Vector2(1008, 40), 286.0], [Vector2(1088, 176), 187.0]],
		&"labyrinth_nine_09": [[Vector2(352, 304), 210.0], [Vector2(504, 40), 294.0], [Vector2(648, 304), 282.0], [Vector2(792, 40), 282.0], [Vector2(936, 304), 266.0], [Vector2(1064, 20), 340.0], [Vector2(1088, 176), 90.0]],
	}


static func live_route(hole_id: StringName, initial_wait := 0) -> Array[RouteShot]:
	var result: Array[RouteShot] = []
	for entry in geometry_routes()[hole_id]:
		var target: Vector2 = entry[0]
		# The old geometry-only ninth route aimed above the legal cursor bounds.
		if hole_id == &"labyrinth_nine_09" and target.y < 23.0:
			target.y = 23.0
		result.append(RouteShot.new(target, entry[1], initial_wait if result.is_empty() else 0))
	return result
