extends Node

var output: Array = []
var failures: Array[String] = []
var filter := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		filter = argument
	call_deferred("_run")


func _run() -> void:
	var catalog := HoleCatalog.load_default()
	var plans: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/world_blueprints.json"))
	var known := _known()
	known.erase("classic_nine_06")
	for plan in plans:
		if not filter.is_empty() and filter not in plan.id and filter not in plan.key:
			continue
		var hole := catalog.get_hole(StringName(plan.id))
		# Discovery may use the maximum legal round length. Production PAR is
		# recorded only after the resulting route has actually been played.
		var probe := hole.duplicate(true) as HoleDefinition
		probe.par = 12
		var route: Array[RouteShot] = []
		var result: Dictionary = {}
		if known.has(String(hole.hole_id)):
			for shot in known[String(hole.hole_id)]:
				var s := RouteShot.new(shot[0] if shot[0] is Vector2 else Vector2.ZERO,shot[1],shot[2] if shot.size()>2 else 0)
				if not shot[0] is Vector2: s.angle_degrees = float(shot[0])
				route.append(s)
			result = await LiveRouteRunner.play(self,probe,route)
		else:
			var position := hole.tee_position
			for entry in plan.waypoints:
				var aim := Vector2(entry[0],entry[1])
				var destination := aim
				var is_transfer := false
				for tunnel in hole.tunnels:
					if aim == tunnel.endpoint_a:
						destination = tunnel.endpoint_b+position.direction_to(aim)*45
						is_transfer = true
				for cannon in hole.cannons:
					if aim == cannon.position:
						destination = cannon.landing_position+Vector2(8,0)
						is_transfer = true
				var base := sqrt(240*position.distance_to(aim))+1.0
				if aim == hole.hole_position: base = sqrt(240*position.distance_to(aim)+3600)
				var best_score := INF
				var best_shot: RouteShot
				var best_result: Dictionary
				var waits := [0] if hole.obstacles.is_empty() else [0,30,60,90,120,180,240]
				for wait in waits:
					for factor in [1.0,0.85,1.15,0.7,1.3,0.55,1.5]:
						var speed := clampf(base*factor,28,380)
						var shot := RouteShot.new(aim,speed,wait)
						var attempt := route.duplicate()
						attempt.append(shot)
						var trial := await LiveRouteRunner.play(self,probe,attempt)
						var stop := Vector2(trial.position[0],trial.position[1])
						var score := stop.distance_to(destination)
						if trial.reason.begins_with("Gefahr") or trial.reason.contains("1800"): score += 10000
						if trial.holed: score = -1000
						if score < best_score:
							best_score = score
							best_shot = shot
							best_result = trial
						if best_score < (24 if is_transfer else 9): break
					if best_score < (24 if is_transfer else 9): break
				if best_shot == null: break
				route.append(best_shot)
				result = best_result
				position = Vector2(result.position[0],result.position[1])
				if result.holed: break
		# A short final putt is a legitimate part of a safe route, not a teleport.
		for extra in range(2):
			if result.get("holed",false) or result.is_empty(): break
			var position := Vector2(result.position[0],result.position[1])
			var speed := clampf(sqrt(240*position.distance_to(hole.hole_position)+2500),28,380)
			route.append(RouteShot.new(hole.hole_position,speed))
			result = await LiveRouteRunner.play(self,probe,route)
		var shots: Array = []
		for shot in route:
			shots.append({"target":[shot.target.x,shot.target.y],"angle":null if is_nan(shot.angle_degrees) else shot.angle_degrees,"speed":shot.speed,"wait":shot.wait_ticks})
		output.append({"id":String(hole.hole_id),"key":plan.key,"shots":shots,"result":result})
		print("%s %s: %s, %d Schlaege; %s" % [plan.key,hole.hole_id,"OK" if result.get("holed",false) else "OFFEN",result.get("strokes",0),str(result.get("position",[]))])
		if not result.get("holed",false): failures.append(String(hole.hole_id))
		var file := FileAccess.open("res://tmp/worlds/routes-%s.json" % (filter if not filter.is_empty() else "all"),FileAccess.WRITE)
		file.store_string(JSON.stringify(output,"\t")+"\n")
	print("OFFEN: ",failures)
	get_tree().quit(0 if failures.is_empty() else 1)


func _known() -> Dictionary:
	return {
		"classic_nine_01": [[0.0,292.0]],
		"classic_nine_02": [[-12.0,408.0]],
		"classic_nine_03": [[-36.0,250.0],[Vector2(575,74),180.0]],
		"classic_nine_04": [[0.0,282.0]],
		"classic_nine_05": [[-32.35,387.5]],
		"classic_nine_06": [[-24.0,280.0],[Vector2(575,72),115.0]],
		"classic_nine_07": [[Vector2(600,270),300.0],[Vector2(850,100),270.0],[Vector2(960,280),240.0]],
		"classic_nine_08": [[-24.0,420.0],[-28.5,340.0],[Vector2(960,72),185.0]],
		"classic_nine_09": [[Vector2(600,280),300.0],[Vector2(1000,280),300.0],[Vector2(960,72),220.0],[Vector2(220,56),420.0]],
		"prototype_04": [[Vector2(368,280),230.0],[Vector2(544,280),268.0],[Vector2(552,88),220.0]],
		"prototype_05": [[Vector2(568,176),262.0],[Vector2(840,176),230.0],[Vector2(936,176),146.0]],
		"prototype_06": [[Vector2(264,264),228.0],[Vector2(552,264),262.0],[Vector2(552,88),162.0]],
		"prototype_07": [[Vector2(416,112),274.0],[Vector2(416,272),260.0],[Vector2(784,272),270.0],[Vector2(784,120),190.0],[Vector2(1064,120),256.0]],
		"prototype_08": [[Vector2(275,264),204.0],[Vector2(408,344),192.0],[Vector2(552,264),198.0],[Vector2(552,88),202.0]],
		"arrow_armageddon_01": [[Vector2(490,180),250.0],[Vector2(580,100),180.0]],
		"arrow_armageddon_02": [[Vector2(575,70),420.0],[Vector2(575,70),135.0]],
		"arrow_armageddon_03": [[Vector2(475,165),290.0],[Vector2(580,180),130.0]],
		"arrow_armageddon_04": [[Vector2(350,235),245.0],[Vector2(580,180),110.0],[Vector2(580,180),78.0]],
		"arrow_armageddon_05": [[Vector2(395,180),230.0],[Vector2(575,95),225.0],[Vector2(575,70),100.0]],
		"arrow_armageddon_06": [[-2.0,360.0],[-180.0,280.0],[-156.0,370.0]],
		"arrow_armageddon_07": [[Vector2(430,235),180.0],[Vector2(740,160),200.0],[Vector2(880,130),160.0],[Vector2(960,70),100.0]],
		"arrow_armageddon_08": [[Vector2(540,176),280.0],[Vector2(800,176),360.0],[Vector2(900,260),180.0],[Vector2(960,286),140.0]],
		"reference_01": [[Vector2(480,250),245.0],[Vector2(710,242),310.0],[Vector2(850,120),285.0],[Vector2(1090,65),210.0]],
		"classic_diamond_02": [[Vector2(380,280),200.0],[Vector2(540,240),215.0],[Vector2(575,70),265.0]],
		"double_gate_03": [[Vector2(410,173),225.0],[Vector2(735,173),280.0],[Vector2(850,70),190.0],[Vector2(960,70),160.0]],
		"cannon_workshop_04": [[Vector2(380,280),196.0],[Vector2(590,265),238.0],[Vector2(1045,260),243.0],[Vector2(1090,70),218.0]],
	}
