extends RefCounted


static func run(host: Node, check: Callable, exhaustive := false) -> void:
	print("\n[Acht Welten: aktive PAR-Routen]")
	var entries: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/world_routes.json"))
	var report: Array = []
	for entry in entries:
		var hole := HoleCatalog.load_default().get_hole(StringName(entry.id))
		var cases := [[&"allrounder",0.0,1.0]]
		if exhaustive:
			cases.append_array([[&"mara",0.0,1.0],[&"bruno",0.0,1.0],[&"nika",0.0,1.0],[&"allrounder",-0.3,1.0],[&"allrounder",0.3,1.0],[&"allrounder",0.0,0.99],[&"allrounder",0.0,1.01]])
		for test_case in cases:
			var route: Array[RouteShot] = preload("res://tests/world_route_fixtures.gd").route(entry,test_case[0],test_case[1],test_case[2])
			var result := await LiveRouteRunner.play(host,hole,route,test_case[0])
			var label := "%s %s Winkel %+.1f Kraft %.2f" % [entry.id,test_case[0],test_case[1],test_case[2]]
			check.call(result.within_par and result.contact_delays.all(func(t): return t==6),label+": aktive Route innerhalb PAR und synchroner Abschwung")
			if not result.within_par: print("  ROUTENLUECKE ",label," ",JSON.stringify(result))
			report.append({"id":entry.id,"golfer":String(test_case[0]),"angle":test_case[1],"power":test_case[2],"result":result})
		var file := FileAccess.open("res://tmp/worlds/route-audit.json" if exhaustive else "res://tmp/worlds/route-suite.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t")+"\n")
