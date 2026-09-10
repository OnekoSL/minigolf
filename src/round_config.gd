class_name RoundConfig
extends Resource

enum GameMode { COURSE_SOLO, COURSE_LOCAL, PRACTICE, FREE_PLAY }

@export var mode := GameMode.COURSE_SOLO
@export var course_id := &""
@export var players: Array[PlayerProfile] = []
@export var hole_ids: Array[StringName] = []


func validate(hole_catalog: HoleCatalog, course_catalog: CourseCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	var course: CourseDefinition = course_catalog.get_course(course_id) if course_catalog != null else null
	if is_course_mode():
		if course == null:
			errors.append("Runde verweist auf unbekannten Kurs %s" % course_id)
		elif hole_ids != course.hole_ids:
			errors.append("Kursrunde muss die vollstaendige geordnete Lochfolge enthalten")
	var valid_player_count := false
	match mode:
		GameMode.COURSE_SOLO, GameMode.PRACTICE:
			valid_player_count = players.size() == 1
		GameMode.COURSE_LOCAL:
			valid_player_count = players.size() >= 2 and players.size() <= 4
		GameMode.FREE_PLAY:
			valid_player_count = players.size() >= 1 and players.size() <= 4
	if not valid_player_count:
		errors.append("Ungueltige Spielerzahl fuer Modus %d" % mode)
	if hole_ids.is_empty() or hole_ids.size() > 9:
		errors.append("Eine Runde benoetigt 1 bis 9 Loecher")
	if mode == GameMode.PRACTICE and hole_ids.size() != 1:
		errors.append("Uebung besteht aus genau einem Loch")
	var used_palettes: Dictionary = {}
	for player in players:
		if player == null:
			errors.append("Runde enthaelt einen leeren Spieler")
			continue
		if used_palettes.has(player.palette_id):
			errors.append("Spielerfarben muessen eindeutig sein")
		used_palettes[player.palette_id] = true
		if player.golfer_id not in GolferDefinition.IDS:
			errors.append("Spieler verweist auf unbekannten Golfer")
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id) if hole_catalog != null else null
		if hole == null:
			errors.append("Runde enthaelt unbekannte Bahn %s" % hole_id)
		elif mode != GameMode.PRACTICE and not hole.is_course_hole() and not (is_course_mode() and course != null and course.allow_technical_holes and hole_ids == course.hole_ids):
			errors.append("Technische Bahnen sind nur in der Uebung erlaubt")
	return errors


func is_best_eligible(hole_catalog: HoleCatalog, course_catalog: CourseCatalog) -> bool:
	return is_course_mode() and validate(hole_catalog, course_catalog).is_empty()


func allows_restart() -> bool:
	return mode in [GameMode.PRACTICE, GameMode.FREE_PLAY]


func is_course_mode() -> bool:
	return mode in [GameMode.COURSE_SOLO, GameMode.COURSE_LOCAL]
