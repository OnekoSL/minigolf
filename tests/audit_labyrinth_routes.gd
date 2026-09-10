extends Node

const OUTPUT := "res://.godot/labyrinth-live/audit.json"
const INITIAL_WAITS := [0, 30, 60, 90, 120, 150]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var holes := HoleCatalog.load_default()
	var course := CourseCatalog.load_default().get_course(&"labyrinth_nine_course")
	var results: Array[Dictionary] = []
	DirAccess.make_dir_recursive_absolute(OUTPUT.get_base_dir())
	for hole_id in course.hole_ids:
		for wait_ticks in INITIAL_WAITS:
			var result := await LiveRouteRunner.play(self, holes.get_hole(hole_id), LabyrinthRoutes.live_route(hole_id, wait_ticks))
			result["initial_wait_ticks"] = wait_ticks
			if result.holed:
				var repeated := await LiveRouteRunner.play(self, holes.get_hole(hole_id), LabyrinthRoutes.live_route(hole_id, wait_ticks))
				result["repeat_confirmed"] = repeated.holed and load("res://tests/labyrinth_live_test.gd").same_stops(result, repeated)
			results.append(result)
			print("LIVE %s wait=%d holed=%s strokes=%d position=%s reason=%s" % [hole_id, wait_ticks, result.holed, result.strokes, result.position, result.reason])
			var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
			file.store_string(JSON.stringify(results, "\t"))
			file.close()
	print("Labyrinth-Untersuchung: ", OUTPUT)
	get_tree().quit()
