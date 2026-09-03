class_name RoundConfig
extends Resource

enum GameMode { COURSE_SOLO, COURSE_LOCAL, PRACTICE, FREE_PLAY }

@export var mode := GameMode.COURSE_SOLO
@export var course_id := &""
@export var players: Array[PlayerProfile] = []
@export var hole_ids: Array[StringName] = []
@export var best_eligible := false
@export var allow_technical_holes := false


func validate(hole_catalog: HoleCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
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
	if best_eligible and not is_course_mode():
		errors.append("Nur offizielle Kursmodi duerfen Bestwerte speichern")
	var used_palettes: Dictionary = {}
	for player in players:
		if player == null:
			errors.append("Runde enthaelt einen leeren Spieler")
			continue
		if used_palettes.has(player.palette_id):
			errors.append("Spielerfarben muessen eindeutig sein")
		used_palettes[player.palette_id] = true
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id) if hole_catalog != null else null
		if hole == null:
			errors.append("Runde enthaelt unbekannte Bahn %s" % hole_id)
		elif mode != GameMode.PRACTICE and not hole.is_course_hole() and not (is_course_mode() and allow_technical_holes):
			errors.append("Technische Bahnen sind nur in der Uebung erlaubt")
	return errors


func allows_restart() -> bool:
	return mode in [GameMode.PRACTICE, GameMode.FREE_PLAY]


func is_course_mode() -> bool:
	return mode in [GameMode.COURSE_SOLO, GameMode.COURSE_LOCAL]
