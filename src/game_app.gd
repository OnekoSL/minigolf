class_name GameApp
extends Node

enum ScreenState {
	TITLE,
	MODE,
	PLAYER_COUNT,
	PLAYER_NAME,
	PLAYER_COLOR,
	COURSE_SELECT,
	HOLE_SELECT,
	FREE_BUILD,
	GAMEPLAY,
	HANDOFF,
	SCORECARD,
	FINAL,
	PAUSE,
	PAUSE_SCORECARD,
	LEAVE_CONFIRM,
}

const MENU_NAV_THRESHOLD := 0.45
const MENU_REPEAT_DELAY := 0.30
const MENU_REPEAT_RATE := 0.11
const MAX_FREE_HOLES := 9
const COURSES_PER_PAGE := 3
const HOLES_PER_PAGE := 5

var hole_catalog: HoleCatalog
var course_catalog: CourseCatalog
var best_store := BestScoreStore.new()
var session: RoundSession
var gameplay: PrototypeMain

var current_screen := ScreenState.TITLE
var selected_mode := RoundConfig.GameMode.COURSE_SOLO
var desired_player_count := 1
var working_players: Array[PlayerProfile] = []
var setup_player_index := 0
var setup_name := ""
var selected_practice_hole := &"reference_01"
var free_hole_ids: Array[StringName] = []
var course_select_page := 0
var hole_select_page := 0
var free_select_page := 0

var screen_layer: CanvasLayer
var screen_root: Control
var controller_status_label: Label
var diagnostics_panel: Panel
var diagnostics_label: Label
var diagnostics_visible := false
var option_buttons: Array[Button] = []
var option_actions: Array[Callable] = []
var selected_option := 0
var option_columns := 1
var name_value_label: Label

var _menu_input_locked := true
var _neutral_elapsed := 0.0
var _nav_was_active := false
var _nav_repeat_left := 0.0
var _last_attempt_strokes := 0
var _last_attempt_capped := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hole_catalog = HoleCatalog.load_default()
	course_catalog = CourseCatalog.load_default()
	if hole_catalog == null or course_catalog == null:
		push_error("Spielkataloge konnten nicht geladen werden")
		return
	var errors := hole_catalog.validate()
	errors.append_array(course_catalog.validate(hole_catalog))
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		return
	ControllerSupport.active_device_changed.connect(_on_controller_changed)
	ControllerSupport.focus_changed.connect(_on_focus_changed)
	ControllerSupport.calibration_updated.connect(_on_calibration_updated)
	ControllerSupport.calibration_finished.connect(_on_calibration_finished)
	_show_title()


func _process(delta: float) -> void:
	if _menu_input_locked:
		if ControllerSupport.focused and ControllerSupport.menu_controls_are_neutral():
			_neutral_elapsed += delta
			if _neutral_elapsed >= 0.06:
				_menu_input_locked = false
				if current_screen == ScreenState.GAMEPLAY and gameplay != null:
					gameplay.set_input_enabled(true)
		else:
			_neutral_elapsed = 0.0
		return
	if current_screen == ScreenState.GAMEPLAY:
		return
	var aim := ControllerSupport.get_aim_vector()
	var active := aim.length() >= MENU_NAV_THRESHOLD
	if not active:
		_nav_was_active = false
		_nav_repeat_left = 0.0
		return
	if not _nav_was_active:
		_move_selection(aim)
		_nav_was_active = true
		_nav_repeat_left = MENU_REPEAT_DELAY
	else:
		_nav_repeat_left -= delta
		if _nav_repeat_left <= 0.0:
			_move_selection(aim)
			_nav_repeat_left = MENU_REPEAT_RATE


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if current_screen == ScreenState.GAMEPLAY:
		return
	if event.is_action_pressed("toggle_diagnostics", false, true):
		_toggle_diagnostics()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("start_calibration", false, true):
		if ControllerSupport.is_calibrating():
			ControllerSupport.cancel_calibration()
		else:
			ControllerSupport.begin_calibration()
		diagnostics_visible = true
		_refresh_diagnostics()
		get_viewport().set_input_as_handled()
		return
	if _menu_input_locked or diagnostics_visible:
		return
	if current_screen == ScreenState.PLAYER_NAME and event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_BACKSPACE:
			_remove_name_character()
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
			_confirm_player_name()
			get_viewport().set_input_as_handled()
			return
		if event.unicode >= 32 and event.physical_keycode not in [KEY_ENTER, KEY_KP_ENTER]:
			_append_name(String.chr(event.unicode))
			get_viewport().set_input_as_handled()
			return
	if current_screen == ScreenState.PAUSE and event.is_action_pressed("pause", false, true):
		_resume_game()
		get_viewport().set_input_as_handled()
		return
	if ControllerSupport.event_is_pressed(event, &"menu_back"):
		_go_back()
		get_viewport().set_input_as_handled()
		return
	if ControllerSupport.event_is_pressed(event, &"menu_confirm"):
		_activate_selected()
		get_viewport().set_input_as_handled()


func _show_title() -> void:
	current_screen = ScreenState.TITLE
	var root := _build_screen("PUTT & PIXEL", "RETRO MINIGOLF  •  GRUNDPROTOTYP")
	var mark := _label("●", Vector2(296, 82), Vector2(48, 48), 38, Color("#f0c45b"))
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(mark)
	_add_option_button("SPIEL STARTEN", Rect2(205, 190, 230, 38), _show_mode)
	_add_footer("KREUZ / ENTER / KLICK", "F3 DIAGNOSE  •  F4 KALIBRIERUNG")
	_finalize_options()


func _show_mode() -> void:
	current_screen = ScreenState.MODE
	_build_screen("SPIELMODUS", "WAS MOECHTEST DU SPIELEN?")
	_add_option_button("EINZELNER KURS", Rect2(176, 82, 288, 38), func(): _select_mode(RoundConfig.GameMode.COURSE_SOLO))
	_add_option_button("LOKALER MEHRSPIELER", Rect2(176, 126, 288, 38), func(): _select_mode(RoundConfig.GameMode.COURSE_LOCAL))
	_add_option_button("UEBUNG", Rect2(176, 170, 288, 38), func(): _select_mode(RoundConfig.GameMode.PRACTICE))
	_add_option_button("FREIES SPIEL", Rect2(176, 214, 288, 38), func(): _select_mode(RoundConfig.GameMode.FREE_PLAY))
	_add_option_button("ZURUECK", Rect2(246, 278, 148, 30), _show_title)
	_add_footer("STICK / D-PAD  AUSWAEHLEN", "KREUZ BESTAETIGEN  •  KREIS ZURUECK")
	_finalize_options()


func _select_mode(mode: int) -> void:
	selected_mode = mode
	working_players.clear()
	setup_player_index = 0
	course_select_page = 0
	hole_select_page = 0
	free_select_page = 0
	if mode in [RoundConfig.GameMode.COURSE_LOCAL, RoundConfig.GameMode.FREE_PLAY]:
		_show_player_count()
	else:
		desired_player_count = 1
		_show_player_name()


func _show_player_count() -> void:
	current_screen = ScreenState.PLAYER_COUNT
	_build_screen("SPIELERZAHL", "WIE VIELE SPIELER TRETEN AN?")
	var counts := [2, 3, 4] if selected_mode == RoundConfig.GameMode.COURSE_LOCAL else [1, 2, 3, 4]
	var start_x := 320 - counts.size() * 45
	for index in range(counts.size()):
		var count: int = counts[index]
		_add_option_button(str(count), Rect2(start_x + index * 90, 130, 72, 54), func(): _choose_player_count(count))
	option_columns = counts.size()
	_add_option_button("ZURUECK", Rect2(246, 232, 148, 30), _show_mode)
	_add_footer("EIN CONTROLLER WIRD WEITERGEREICHT", "JEDER SPIELER BEENDET DAS LOCH")
	_finalize_options()


func _choose_player_count(count: int) -> void:
	desired_player_count = count
	working_players.clear()
	setup_player_index = 0
	_show_player_name()


func _show_player_name() -> void:
	current_screen = ScreenState.PLAYER_NAME
	if setup_name.is_empty():
		setup_name = "SPIELER %d" % (setup_player_index + 1)
	var root := _build_screen(
		"SPIELER %d/%d" % [setup_player_index + 1, desired_player_count],
		"NAME EINGEBEN  •  MAXIMAL 12 ZEICHEN"
	)
	name_value_label = _label(setup_name, Vector2(66, 62), Vector2(508, 34), 19, Color("#fff1b0"))
	name_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(name_value_label)
	var keys := [
		"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
		"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
		"U", "V", "W", "X", "Y", "Z", "AE", "OE", "UE", "0",
		"1", "2", "3", "4", "5", "6", "7", "8", "9", "LEER",
	]
	for index in range(keys.size()):
		var key: String = keys[index]
		var x := 45 + (index % 10) * 55
		var y := 105 + (index / 10) * 37
		_add_option_button(key, Rect2(x, y, 48, 30), func(): _type_screen_key(key))
	_add_option_button("LOESCHEN", Rect2(155, 263, 148, 32), _remove_name_character)
	_add_option_button("FERTIG", Rect2(337, 263, 148, 32), _confirm_player_name)
	option_columns = 10
	_add_footer("TASTATUR KANN DIREKT SCHREIBEN", "KREIS ZURUECK")
	_finalize_options()


func _type_screen_key(key: String) -> void:
	if key == "LEER":
		_append_name(" ")
	elif key == "AE":
		_append_name("Ä")
	elif key == "OE":
		_append_name("Ö")
	elif key == "UE":
		_append_name("Ü")
	else:
		_append_name(key)


func _append_name(character: String) -> void:
	if setup_name == "SPIELER %d" % (setup_player_index + 1):
		setup_name = ""
	if setup_name.length() >= 12:
		return
	setup_name = (setup_name + character).left(12)
	if name_value_label != null:
		name_value_label.text = setup_name


func _remove_name_character() -> void:
	if not setup_name.is_empty():
		setup_name = setup_name.left(setup_name.length() - 1)
	if name_value_label != null:
		name_value_label.text = setup_name


func _confirm_player_name() -> void:
	setup_name = PlayerProfile.sanitize_name(setup_name, setup_player_index + 1)
	_show_player_color()


func _show_player_color() -> void:
	current_screen = ScreenState.PLAYER_COLOR
	_build_screen(
		"%s" % setup_name,
		"FARBE FUER SPIELER %d WAEHLEN" % (setup_player_index + 1)
	)
	var used: Dictionary = {}
	for player in working_players:
		used[player.palette_id] = true
	for palette in range(4):
		var button := _add_option_button(
			PlayerProfile.PALETTE_NAMES[palette],
			Rect2(76 + palette * 126, 126, 112, 62),
			func(): _confirm_player_color(palette)
		)
		button.disabled = used.has(palette)
		button.add_theme_color_override("font_color", PlayerProfile.PALETTE_COLORS[palette])
	option_columns = 4
	_add_footer("FARBEN SIND NUR KOSMETISCH", "SPIELERNUMMER BLEIBT ZUSAETZLICH SICHTBAR")
	_finalize_options()


func _confirm_player_color(palette: int) -> void:
	working_players.append(PlayerProfile.create(setup_player_index + 1, setup_name, palette))
	setup_player_index += 1
	setup_name = ""
	if setup_player_index < desired_player_count:
		_show_player_name()
	else:
		_show_content_selection()


func _show_content_selection() -> void:
	match selected_mode:
		RoundConfig.GameMode.COURSE_SOLO, RoundConfig.GameMode.COURSE_LOCAL:
			_show_course_select()
		RoundConfig.GameMode.PRACTICE:
			_show_hole_select()
		RoundConfig.GameMode.FREE_PLAY:
			free_hole_ids.clear()
			_show_free_builder()


func _show_course_select() -> void:
	current_screen = ScreenState.COURSE_SELECT
	var page_count := maxi(1, ceili(float(course_catalog.courses.size()) / COURSES_PER_PAGE))
	course_select_page = clampi(course_select_page, 0, page_count - 1)
	_build_screen(
		"KURSAUSWAHL",
		"SEITE %d/%d  •  %d KURSE SIND SPIELBEREIT" % [course_select_page + 1, page_count, course_catalog.courses.size()]
	)
	var card_height := 54.0
	var card_gap := 6.0
	var start_y := 76.0
	var first_index := course_select_page * COURSES_PER_PAGE
	var last_index := mini(first_index + COURSES_PER_PAGE, course_catalog.courses.size())
	for index in range(first_index, last_index):
		var course: CourseDefinition = course_catalog.courses[index]
		var total_par := course.get_total_par(hole_catalog)
		var best := best_store.get_best(course.course_id)
		var best_text := "NOCH KEIN BESTWERT" if best < 0 else "BESTWERT %d (%s)" % [best, _format_difference(best - total_par)]
		_add_option_button(
			"%s\n%d LOECHER  •  PAR %d  •  %s" % [course.display_name, course.hole_ids.size(), total_par, best_text],
			Rect2(112, start_y + (index - first_index) * (card_height + card_gap), 416, card_height),
			func(): _start_course(course)
		)
	var previous := _add_option_button("< VORHERIGE", Rect2(62, 276, 152, 30), func(): _change_course_page(-1))
	previous.disabled = course_select_page <= 0
	_add_option_button("ZURUECK", Rect2(246, 276, 148, 30), _show_mode)
	var next := _add_option_button("NAECHSTE >", Rect2(426, 276, 152, 30), func(): _change_course_page(1))
	next.disabled = course_select_page >= page_count - 1
	_add_footer("3 KURSE PRO SEITE", "GETRENNTE BESTWERTE")
	_finalize_options()


func _change_course_page(direction: int) -> void:
	var page_count := maxi(1, ceili(float(course_catalog.courses.size()) / COURSES_PER_PAGE))
	course_select_page = clampi(course_select_page + direction, 0, page_count - 1)
	_show_course_select()


func _start_course(course: CourseDefinition) -> void:
	var config := RoundConfig.new()
	config.mode = selected_mode
	config.course_id = course.course_id
	config.players = working_players.duplicate()
	config.hole_ids = course.hole_ids.duplicate()
	config.best_eligible = true
	config.allow_technical_holes = course.allow_technical_holes
	_start_round(config)


func _show_hole_select() -> void:
	current_screen = ScreenState.HOLE_SELECT
	var course_holes := _get_course_holes()
	var page_count := maxi(1, ceili(float(course_holes.size()) / HOLES_PER_PAGE))
	hole_select_page = clampi(hole_select_page, 0, page_count - 1)
	_build_screen("UEBUNGSLOCH", "SEITE %d/%d  •  EIN LOCH FREI AUSWAEHLEN" % [hole_select_page + 1, page_count])
	var first_index := hole_select_page * HOLES_PER_PAGE
	var last_index := mini(first_index + HOLES_PER_PAGE, course_holes.size())
	for index in range(first_index, last_index):
		var hole: HoleDefinition = course_holes[index]
		_add_option_button(
			"%d  %s  •  PAR %d" % [index + 1, hole.display_name, hole.par],
			Rect2(106, 76 + (index - first_index) * 37, 428, 32),
			func(): _start_practice(hole.hole_id)
		)
	var previous := _add_option_button("< VORHERIGE", Rect2(62, 276, 152, 30), func(): _change_hole_page(-1))
	previous.disabled = hole_select_page <= 0
	_add_option_button("ZURUECK", Rect2(246, 276, 148, 30), _show_mode)
	var next := _add_option_button("NAECHSTE >", Rect2(426, 276, 152, 30), func(): _change_hole_page(1))
	next.disabled = hole_select_page >= page_count - 1
	_add_footer("5 BAHNEN PRO SEITE", "DREIECK / F2 IM SPIEL: TESTBAHNEN")
	_finalize_options()


func _change_hole_page(direction: int) -> void:
	var page_count := maxi(1, ceili(float(_get_course_holes().size()) / HOLES_PER_PAGE))
	hole_select_page = clampi(hole_select_page + direction, 0, page_count - 1)
	_show_hole_select()


func _start_practice(hole_id: StringName) -> void:
	selected_practice_hole = hole_id
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.PRACTICE
	config.players = working_players.duplicate()
	config.hole_ids = [hole_id]
	config.best_eligible = false
	_start_round(config)


func _show_free_builder() -> void:
	current_screen = ScreenState.FREE_BUILD
	var sequence_text := "NOCH KEIN LOCH" if free_hole_ids.is_empty() else _free_sequence_text()
	var course_holes := _get_course_holes()
	var page_count := maxi(1, ceili(float(course_holes.size()) / HOLES_PER_PAGE))
	free_select_page = clampi(free_select_page, 0, page_count - 1)
	_build_screen("FREIE LOCHFOLGE", "%d/%d  •  SEITE %d/%d  •  %s" % [free_hole_ids.size(), MAX_FREE_HOLES, free_select_page + 1, page_count, sequence_text])
	var first_index := free_select_page * HOLES_PER_PAGE
	var last_index := mini(first_index + HOLES_PER_PAGE, course_holes.size())
	for index in range(first_index, last_index):
		var hole: HoleDefinition = course_holes[index]
		_add_option_button(
			"+ %s" % hole.display_name,
			Rect2(80, 74 + (index - first_index) * 33, 480, 29),
			func(): _append_free_hole(hole.hole_id)
		)
	var remove_button := _add_option_button("LETZTES ENTFERNEN", Rect2(52, 244, 250, 28), _remove_free_hole)
	remove_button.disabled = free_hole_ids.is_empty()
	var start_button := _add_option_button("RUNDE STARTEN", Rect2(338, 244, 250, 28), _start_free_round)
	start_button.disabled = free_hole_ids.is_empty()
	var previous := _add_option_button("< VORHERIGE", Rect2(62, 282, 152, 28), func(): _change_free_page(-1))
	previous.disabled = free_select_page <= 0
	_add_option_button("ZURUECK", Rect2(246, 282, 148, 28), _show_mode)
	var next := _add_option_button("NAECHSTE >", Rect2(426, 282, 152, 28), func(): _change_free_page(1))
	next.disabled = free_select_page >= page_count - 1
	_add_footer("KREUZ FUEGT DIE SICHTBARE BAHN AN", "REIHENFOLGE UND WIEDERHOLUNG FREI")
	_finalize_options()


func _change_free_page(direction: int) -> void:
	var page_count := maxi(1, ceili(float(_get_course_holes().size()) / HOLES_PER_PAGE))
	free_select_page = clampi(free_select_page + direction, 0, page_count - 1)
	_show_free_builder()


func _append_free_hole(hole_id: StringName) -> void:
	if free_hole_ids.size() < MAX_FREE_HOLES:
		free_hole_ids.append(hole_id)
	_show_free_builder()


func _remove_free_hole() -> void:
	if not free_hole_ids.is_empty():
		free_hole_ids.pop_back()
	_show_free_builder()


func _start_free_round() -> void:
	if free_hole_ids.is_empty():
		return
	var config := RoundConfig.new()
	config.mode = RoundConfig.GameMode.FREE_PLAY
	config.players = working_players.duplicate()
	config.hole_ids = free_hole_ids.duplicate()
	config.best_eligible = false
	_start_round(config)


func _start_round(config: RoundConfig) -> void:
	var errors := config.validate(hole_catalog)
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		return
	session = RoundSession.new()
	session.configure(config, hole_catalog)
	_start_current_attempt()


func _start_current_attempt() -> void:
	_clear_screen()
	current_screen = ScreenState.GAMEPLAY
	get_tree().paused = false
	gameplay = PrototypeMain.new()
	gameplay.configure_attempt(
		session.get_current_hole(),
		session.get_current_player(),
		session.config.allows_restart(),
		session.current_hole_index + 1,
		session.config.hole_ids.size(),
		session.get_player_total(session.current_player_index),
		session.config.mode == RoundConfig.GameMode.PRACTICE
	)
	gameplay.attempt_finished.connect(_on_attempt_finished)
	gameplay.pause_requested.connect(_show_pause)
	gameplay.practice_hole_switched.connect(_on_practice_hole_switched)
	add_child(gameplay)
	gameplay.set_input_enabled(false)
	_arm_input_gate()


func _on_attempt_finished(strokes: int, reached_limit: bool) -> void:
	_last_attempt_strokes = strokes
	_last_attempt_capped = reached_limit
	var completed_player := session.current_player_index
	var result := session.record_current_score(strokes, reached_limit)
	_remove_gameplay()
	match result:
		RoundSession.AdvanceResult.NEXT_PLAYER:
			_show_handoff(completed_player)
		RoundSession.AdvanceResult.HOLE_COMPLETE:
			_show_scorecard(false, false)
		RoundSession.AdvanceResult.ROUND_COMPLETE:
			_update_best_score()
			_show_scorecard(true, false)


func _show_handoff(completed_player: int) -> void:
	current_screen = ScreenState.HANDOFF
	var previous := session.config.players[completed_player]
	var next := session.get_current_player()
	_build_screen("SPIELERWECHSEL", "%s: %d SCHLAEGE%s" % [
		previous.player_name,
		_last_attempt_strokes,
		"  •  MAX" if _last_attempt_capped else "",
	])
	var label := _label(
		"CONTROLLER AN\nP%d  %s\nWEITERGEBEN" % [next.player_id, next.player_name],
		Vector2(145, 105), Vector2(350, 92), 20, next.get_color()
	)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	screen_root.add_child(label)
	_add_option_button("BEREIT", Rect2(224, 225, 192, 36), _start_current_attempt)
	_add_footer("ERST NACH DEM LOSLASSEN BESTAETIGEN", "IDENTISCHE HINDERNISPHASE")
	_finalize_options()


func _show_scorecard(final: bool, from_pause: bool) -> void:
	current_screen = ScreenState.PAUSE_SCORECARD if from_pause else (ScreenState.FINAL if final else ScreenState.SCORECARD)
	var title := "ZWISCHENSTAND" if from_pause else ("ENDTABELLE" if final else "ERGEBNISTABELLE")
	_build_screen(title, _scorecard_subtitle(final, from_pause))
	_build_score_table(final)
	if from_pause:
		_add_option_button("ZURUECK ZUR PAUSE", Rect2(220, 302, 200, 30), _show_pause)
	elif final:
		_add_option_button("NOCHMAL", Rect2(52, 302, 160, 30), _rematch)
		_add_option_button("AUSWAHL AENDERN", Rect2(230, 302, 180, 30), _change_selection)
		_add_option_button("HAUPTMENUE", Rect2(428, 302, 160, 30), _leave_to_menu)
		option_columns = 3
	else:
		_add_option_button("WEITER ZUM NAECHSTEN LOCH", Rect2(185, 302, 270, 30), _continue_after_hole)
	_finalize_options()


func _build_score_table(final: bool) -> void:
	var hole_count := session.config.hole_ids.size()
	var hole_width := 32 if hole_count > 6 else 42
	var name_width := 132
	var table_width := name_width + hole_count * hole_width + 96
	var start_x := (640 - table_width) / 2
	var header_y := 72
	_add_table_label("SPIELER", Rect2(start_x, header_y, name_width, 22), Color("#d7edcf"), HORIZONTAL_ALIGNMENT_LEFT)
	for hole_index in range(hole_count):
		_add_table_label(str(hole_index + 1), Rect2(start_x + name_width + hole_index * hole_width, header_y, hole_width, 22), Color("#d7edcf"))
	_add_table_label("SUM", Rect2(start_x + name_width + hole_count * hole_width, header_y, 48, 22), Color("#d7edcf"))
	_add_table_label("+/-", Rect2(start_x + name_width + hole_count * hole_width + 48, header_y, 48, 22), Color("#d7edcf"))
	var par_y := header_y + 24
	_add_table_label("PAR", Rect2(start_x, par_y, name_width, 20), Color("#8fa5b5"), HORIZONTAL_ALIGNMENT_LEFT)
	for hole_index in range(hole_count):
		var hole := hole_catalog.get_hole(session.config.hole_ids[hole_index])
		_add_table_label(str(hole.par), Rect2(start_x + name_width + hole_index * hole_width, par_y, hole_width, 20), Color("#8fa5b5"))
	var total_par := 0
	for hole_id in session.config.hole_ids:
		total_par += hole_catalog.get_hole(hole_id).par
	_add_table_label(str(total_par), Rect2(start_x + name_width + hole_count * hole_width, par_y, 48, 20), Color("#8fa5b5"))
	for player_index in range(session.config.players.size()):
		var y := par_y + 27 + player_index * 38
		var profile := session.config.players[player_index]
		var prefix := "%d. " % session.get_competition_rank(player_index) if final else "P%d " % profile.player_id
		_add_table_label(prefix + profile.player_name, Rect2(start_x, y, name_width, 28), profile.get_color(), HORIZONTAL_ALIGNMENT_LEFT)
		for hole_index in range(hole_count):
			var score: int = session.scores[player_index][hole_index]
			var value := "–" if score < 0 else str(score) + ("*" if session.capped[player_index][hole_index] else "")
			_add_table_label(value, Rect2(start_x + name_width + hole_index * hole_width, y, hole_width, 28), Color("#fff1b0"))
		_add_table_label(str(session.get_player_total(player_index)), Rect2(start_x + name_width + hole_count * hole_width, y, 48, 28), Color.WHITE)
		_add_table_label(_format_difference(session.get_player_difference(player_index)), Rect2(start_x + name_width + hole_count * hole_width + 48, y, 48, 28), Color("#f0c45b"))
	var legend := _label("* MAXIMUM 8", Vector2(start_x, 270), Vector2(180, 18), 9, Color("#8fa5b5"))
	screen_root.add_child(legend)


func _add_table_label(text: String, rect: Rect2, color: Color, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var label := _label(text, rect.position, rect.size, 10, color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_stylebox_override("normal", _panel_style(Color(0.04, 0.07, 0.10, 0.86), Color("#354856"), 1))
	screen_root.add_child(label)


func _scorecard_subtitle(final: bool, from_pause := false) -> String:
	if from_pause:
		return "LOCH %d/%d  •  P%d %s AM BALL" % [
			session.current_hole_index + 1,
			session.config.hole_ids.size(),
			session.get_current_player().player_id,
			session.get_current_player().player_name,
		]
	if final and session.config.best_eligible:
		var best := best_store.get_best(session.config.course_id)
		var course_par := 0
		for hole_id in session.config.hole_ids:
			course_par += hole_catalog.get_hole(hole_id).par
		return "KURSBESTWERT  %d  (%s)" % [best, _format_difference(best - course_par)] if best >= 0 else "RUNDE ABGESCHLOSSEN"
	if final:
		return "UEBUNG ABGESCHLOSSEN" if session.config.mode == RoundConfig.GameMode.PRACTICE else "FREIE RUNDE ABGESCHLOSSEN"
	return "LOCH %d VON %d ABGESCHLOSSEN" % [session.current_hole_index + 1, session.config.hole_ids.size()]


func _continue_after_hole() -> void:
	if session.advance_hole():
		_start_current_attempt()


func _update_best_score() -> void:
	if not session.config.best_eligible or not session.is_complete():
		return
	for player_index in range(session.config.players.size()):
		best_store.submit(session.config.course_id, session.get_player_total(player_index))


func _rematch() -> void:
	var config := session.config
	_start_round(config)


func _change_selection() -> void:
	var mode := session.config.mode
	session = null
	match mode:
		RoundConfig.GameMode.COURSE_SOLO, RoundConfig.GameMode.COURSE_LOCAL:
			_show_course_select()
		RoundConfig.GameMode.PRACTICE:
			_show_hole_select()
		RoundConfig.GameMode.FREE_PLAY:
			_show_free_builder()


func _show_pause() -> void:
	if gameplay == null:
		return
	gameplay.set_external_paused(true)
	get_tree().paused = true
	current_screen = ScreenState.PAUSE
	_build_screen("PAUSE", "RUNDE ANGEHALTEN")
	_add_option_button("FORTSETZEN", Rect2(190, 94, 260, 36), _resume_game)
	_add_option_button("TABELLE", Rect2(190, 138, 260, 36), func(): _show_scorecard(false, true))
	if session.config.allows_restart():
		_add_option_button("LOCH NEU STARTEN", Rect2(190, 182, 260, 36), _restart_from_pause)
	_add_option_button("RUNDE VERLASSEN", Rect2(190, 226, 260, 36), _show_leave_confirm)
	_add_footer("START / KREIS: FORTSETZEN", "LAUFENDE RUNDE WIRD NICHT GESPEICHERT")
	_finalize_options()


func _resume_game() -> void:
	_clear_screen()
	current_screen = ScreenState.GAMEPLAY
	get_tree().paused = false
	if gameplay != null:
		gameplay.set_external_paused(false)
	_arm_input_gate()


func _restart_from_pause() -> void:
	if gameplay != null and session.config.allows_restart():
		gameplay.restart_hole()
	_resume_game()


func _show_leave_confirm() -> void:
	current_screen = ScreenState.LEAVE_CONFIRM
	_build_screen("RUNDE VERLASSEN?", "DER AKTUELLE STAND GEHT VERLOREN")
	_add_option_button("NEIN", Rect2(156, 150, 150, 40), _show_pause)
	_add_option_button("JA", Rect2(334, 150, 150, 40), _leave_to_menu)
	option_columns = 2
	_add_footer("KREIS: NEIN", "BESTWERTE NUR NACH VOLLSTAENDIGER RUNDE")
	_finalize_options()


func _leave_to_menu() -> void:
	get_tree().paused = false
	_remove_gameplay()
	session = null
	working_players.clear()
	free_hole_ids.clear()
	setup_name = ""
	_show_mode()


func _on_practice_hole_switched(hole_id: StringName) -> void:
	if session != null and session.config.mode == RoundConfig.GameMode.PRACTICE:
		session.config.hole_ids[0] = hole_id
		if gameplay != null:
			gameplay.set_input_enabled(false)
		_arm_input_gate()


func _get_course_holes() -> Array[HoleDefinition]:
	var result: Array[HoleDefinition] = []
	for hole in hole_catalog.holes:
		if hole.is_course_hole():
			result.append(hole)
	return result


func _free_sequence_text() -> String:
	var parts := PackedStringArray()
	for index in range(free_hole_ids.size()):
		var course_index := 1
		var course_holes := _get_course_holes()
		for hole_index in range(course_holes.size()):
			if course_holes[hole_index].hole_id == free_hole_ids[index]:
				course_index = hole_index + 1
				break
		parts.append(str(course_index))
	return "FOLGE: " + "-".join(parts)


func _format_difference(value: int) -> String:
	if value == 0:
		return "E"
	return "+%d" % value if value > 0 else str(value)


func _go_back() -> void:
	match current_screen:
		ScreenState.MODE:
			_show_title()
		ScreenState.PLAYER_COUNT:
			_show_mode()
		ScreenState.PLAYER_NAME:
			if setup_player_index > 0:
				setup_player_index -= 1
				var previous: PlayerProfile = working_players.pop_back()
				setup_name = previous.player_name
				_show_player_name()
			else:
				_show_mode()
		ScreenState.PLAYER_COLOR:
			_show_player_name()
		ScreenState.COURSE_SELECT, ScreenState.HOLE_SELECT, ScreenState.FREE_BUILD:
			_show_mode()
		ScreenState.PAUSE:
			_resume_game()
		ScreenState.PAUSE_SCORECARD, ScreenState.LEAVE_CONFIRM:
			_show_pause()
		ScreenState.FINAL:
			_leave_to_menu()


func _build_screen(title: String, subtitle: String) -> Control:
	_clear_screen()
	screen_layer = CanvasLayer.new()
	screen_layer.layer = 50
	screen_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(screen_layer)
	screen_root = Control.new()
	screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_root.process_mode = Node.PROCESS_MODE_ALWAYS
	screen_layer.add_child(screen_root)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#081018")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_root.add_child(background)
	for y in range(0, 360, 24):
		var line := ColorRect.new()
		line.position = Vector2(0, y)
		line.size = Vector2(640, 1)
		line.color = Color(0.15, 0.28, 0.32, 0.22)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_root.add_child(line)
	var title_label := _label(title, Vector2(20, 17), Vector2(600, 32), 23, Color("#fff1b0"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(title_label)
	var subtitle_label := _label(subtitle, Vector2(20, 50), Vector2(600, 22), 10, Color("#8fd5cc"))
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	screen_root.add_child(subtitle_label)
	controller_status_label = _label("", Vector2(12, 8), Vector2(160, 32), 8, Color("#9fb2c1"))
	screen_root.add_child(controller_status_label)
	_update_screen_controller_status()
	_build_diagnostics_overlay()
	option_buttons.clear()
	option_actions.clear()
	selected_option = 0
	option_columns = 1
	_arm_input_gate()
	return screen_root


func _add_option_button(text: String, rect: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#d7edcf"))
	button.add_theme_color_override("font_disabled_color", Color("#52616b"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("#122331"), Color("#40596a"), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#19394a"), Color("#75d4c7"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#274a54"), Color("#fff1b0"), 2))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("#0b141b"), Color("#293741"), 1))
	var index := option_buttons.size()
	button.mouse_entered.connect(func(): _select_option(index))
	button.pressed.connect(func(): _invoke_option(index))
	screen_root.add_child(button)
	option_buttons.append(button)
	option_actions.append(action)
	return button


func _finalize_options() -> void:
	if option_buttons.is_empty():
		return
	selected_option = _find_enabled_option(0, 1)
	_refresh_option_styles()


func _select_option(index: int) -> void:
	if index >= 0 and index < option_buttons.size() and not option_buttons[index].disabled:
		selected_option = index
		_refresh_option_styles()


func _move_selection(direction: Vector2) -> void:
	if option_buttons.is_empty():
		return
	var step := 1
	if option_columns > 1 and absf(direction.y) > absf(direction.x):
		step = option_columns if direction.y > 0.0 else -option_columns
	else:
		step = 1 if (direction.x > 0.0 or direction.y > 0.0) else -1
	selected_option = _find_enabled_option(selected_option + step, step)
	_refresh_option_styles()


func _find_enabled_option(candidate: int, step: int) -> int:
	if option_buttons.is_empty():
		return 0
	var index := posmod(candidate, option_buttons.size())
	for _attempt in range(option_buttons.size()):
		if not option_buttons[index].disabled:
			return index
		index = posmod(index + (1 if step >= 0 else -1), option_buttons.size())
	return 0


func _activate_selected() -> void:
	_invoke_option(selected_option)


func _invoke_option(index: int) -> void:
	if index < 0 or index >= option_actions.size() or option_buttons[index].disabled:
		return
	option_actions[index].call()


func _refresh_option_styles() -> void:
	for index in range(option_buttons.size()):
		var button := option_buttons[index]
		if index == selected_option and not button.disabled:
			button.add_theme_stylebox_override("normal", _panel_style(Color("#24505a"), Color("#f0c45b"), 3))
		else:
			button.add_theme_stylebox_override("normal", _panel_style(Color("#122331"), Color("#40596a"), 2))


func _add_footer(left_text: String, right_text: String) -> void:
	var left := _label(left_text, Vector2(14, 334), Vector2(300, 18), 8, Color("#8fa5b5"))
	screen_root.add_child(left)
	var right := _label(right_text, Vector2(326, 334), Vector2(300, 18), 8, Color("#8fa5b5"))
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	screen_root.add_child(right)


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


func _arm_input_gate() -> void:
	_menu_input_locked = true
	_neutral_elapsed = 0.0
	_nav_was_active = false
	_nav_repeat_left = 0.0


func _clear_screen() -> void:
	if screen_layer != null and is_instance_valid(screen_layer):
		screen_layer.queue_free()
	screen_layer = null
	screen_root = null
	option_buttons.clear()
	option_actions.clear()
	diagnostics_panel = null
	diagnostics_label = null
	name_value_label = null


func _remove_gameplay() -> void:
	if gameplay != null and is_instance_valid(gameplay):
		remove_child(gameplay)
		gameplay.queue_free()
	gameplay = null


func _build_diagnostics_overlay() -> void:
	diagnostics_panel = Panel.new()
	diagnostics_panel.position = Vector2(82, 58)
	diagnostics_panel.size = Vector2(476, 244)
	diagnostics_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	diagnostics_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.06, 0.09, 0.98), Color("#75d4c7"), 2))
	diagnostics_panel.visible = diagnostics_visible
	screen_root.add_child(diagnostics_panel)
	diagnostics_label = _label("", Vector2(12, 10), Vector2(452, 222), 11, Color("#dcecf0"))
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_panel.add_child(diagnostics_label)
	_refresh_diagnostics()


func _toggle_diagnostics() -> void:
	diagnostics_visible = not diagnostics_visible
	_refresh_diagnostics()


func _refresh_diagnostics() -> void:
	if diagnostics_panel != null:
		diagnostics_panel.visible = diagnostics_visible
	if diagnostics_label != null:
		diagnostics_label.text = ControllerSupport.get_diagnostics_text()


func _on_controller_changed(_id: int, _name: String, _guid: String) -> void:
	_arm_input_gate()
	if current_screen == ScreenState.GAMEPLAY and gameplay != null:
		gameplay.set_input_enabled(false)
	_update_screen_controller_status()
	_refresh_diagnostics()


func _on_focus_changed(has_focus: bool) -> void:
	_arm_input_gate()
	if current_screen == ScreenState.GAMEPLAY and gameplay != null:
		gameplay.set_input_enabled(false)
	if not has_focus and current_screen == ScreenState.GAMEPLAY and gameplay != null:
		gameplay.shot_controller.cancel_shot()


func _on_calibration_updated(_prompt: String) -> void:
	diagnostics_visible = true
	_refresh_diagnostics()


func _on_calibration_finished(_guid: String) -> void:
	diagnostics_visible = true
	_refresh_diagnostics()


func _update_screen_controller_status() -> void:
	if controller_status_label == null:
		return
	if ControllerSupport.active_device_id < 0:
		controller_status_label.text = "KEIN CONTROLLER\nTASTATUR / MAUS"
	else:
		controller_status_label.text = "CONTROLLER %d\n%s" % [ControllerSupport.active_device_id, ControllerSupport.active_device_name]
