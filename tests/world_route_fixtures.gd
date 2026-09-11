class_name WorldRouteFixtures
extends RefCounted


static func route(entry: Dictionary, golfer := &"allrounder", angle_offset := 0.0, power_factor := 1.0) -> Array[RouteShot]:
	var source: Array = entry.shots
	if golfer != &"allrounder":
		var alternatives: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golfer_routes.json"))
		for alternative in alternatives:
			if alternative.hole_id == entry.id and alternative.golfer == String(golfer) and entry.id not in ["arrow_armageddon_09","classic_nine_04","classic_nine_06"]:
				source = alternative.shots
	var shots: Array[RouteShot] = []
	for data in source:
		var shot := RouteShot.new(Vector2(data.target[0],data.target[1]),data.speed,int(data.get("wait",0)))
		if data.angle != null: shot.angle_degrees = data.angle
		shots.append(shot)
	if not shots.is_empty():
		var first := shots[0]
		var hole := HoleCatalog.load_default().get_hole(StringName(entry.id))
		if is_nan(first.angle_degrees):
			first.target = hole.tee_position+(first.target-hole.tee_position).rotated(deg_to_rad(angle_offset))
		else:
			first.angle_degrees += angle_offset
		first.speed = clampf(first.speed*power_factor,ShotController.MINIMUM_BALL_SPEED,GolferDefinition.get_golfer(golfer).get_maximum_ball_speed())
	return shots
