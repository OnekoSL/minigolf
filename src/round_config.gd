class_name RoundConfig
extends Resource

enum GameMode { COURSE_SOLO, COURSE_LOCAL, PRACTICE, FREE_PLAY }
enum ContentOrigin { OFFICIAL, CUSTOM }

@export var mode := GameMode.COURSE_SOLO
@export var content_origin := ContentOrigin.OFFICIAL
@export var course_id := &""
@export var players: Array[PlayerProfile] = []
@export var hole_ids: Array[StringName] = []


func validate(hole_catalog: HoleCatalog, course_catalog: CourseCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	var course: CourseDefinition = course_catalog.get_course(course_id) if course_catalog != null else null
	if is_course_mode():
		if course == null:
			errors.append(I18n.text("TEXT_ROUND_REFERS_TO_UNKNOWN_COURSE") % course_id)
		elif hole_ids != course.hole_ids:
			errors.append(I18n.text("TEXT_COURSE_ROUND_MUST_CONTAIN_THE_FULL_ORDERED_HOLE_SEQUENCE"))
		elif String(course.course_id).begins_with("custom_") != (content_origin == ContentOrigin.CUSTOM):
			errors.append(I18n.text("TEXT_COURSE_ORIGIN_DOES_NOT_MATCH_THE_CATALOG"))
	var valid_player_count := false
	match mode:
		GameMode.COURSE_SOLO, GameMode.PRACTICE:
			valid_player_count = players.size() == 1
		GameMode.COURSE_LOCAL:
			valid_player_count = players.size() >= 2 and players.size() <= 4
		GameMode.FREE_PLAY:
			valid_player_count = players.size() >= 1 and players.size() <= 4
	if not valid_player_count:
		errors.append(I18n.text("TEXT_INVALID_PLAYER_COUNT_FOR_MODE") % mode)
	if hole_ids.is_empty() or hole_ids.size() > 9:
		errors.append(I18n.text("TEXT_A_ROUND_REQUIRES_1_TO_9_HOLES"))
	if mode == GameMode.PRACTICE and hole_ids.size() != 1:
		errors.append(I18n.text("TEXT_PRACTICE_CONSISTS_OF_EXACTLY_ONE_HOLE"))
	var used_palettes: Dictionary = {}
	for player in players:
		if player == null:
			errors.append(I18n.text("TEXT_ROUND_CONTAINS_AN_EMPTY_PLAYER"))
			continue
		if used_palettes.has(player.palette_id):
			errors.append(I18n.text("TEXT_PLAYER_COLORS_MUST_BE_UNIQUE"))
		used_palettes[player.palette_id] = true
		if player.golfer_id not in GolferDefinition.IDS:
			errors.append(I18n.text("TEXT_PLAYER_REFERS_TO_AN_UNKNOWN_GOLFER"))
		var definition := player.get_golfer_definition()
		if definition.golfer_id != player.golfer_id:
			errors.append(I18n.text("TEXT_PLAYER_PROFILE_AND_GOLFER_DO_NOT_MATCH"))
		errors.append_array(definition.validate())
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id) if hole_catalog != null else null
		if hole == null:
			errors.append(I18n.text("TEXT_ROUND_CONTAINS_UNKNOWN_HOLE") % hole_id)
		elif mode != GameMode.PRACTICE and not hole.is_course_hole() and not (is_course_mode() and course != null and course.allow_technical_holes and hole_ids == course.hole_ids):
			errors.append(I18n.text("TEXT_TECHNICAL_HOLES_ARE_ONLY_ALLOWED_IN_PRACTICE"))
	return errors


func is_best_eligible(hole_catalog: HoleCatalog, course_catalog: CourseCatalog) -> bool:
	return not has_test_player() and is_course_mode() and validate(hole_catalog, course_catalog).is_empty()


func has_test_player() -> bool:
	return players.any(func(player: PlayerProfile): return player != null and player.golfer_id == &"don")


func allows_restart() -> bool:
	return mode in [GameMode.PRACTICE, GameMode.FREE_PLAY]


func is_course_mode() -> bool:
	return mode in [GameMode.COURSE_SOLO, GameMode.COURSE_LOCAL]
