class_name ScorecardView
extends Control


func configure(session: RoundSession, hole_catalog: HoleCatalog, course_catalog: CourseCatalog, final: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640, 360)
	var hole_count := session.config.hole_ids.size()
	var name_width := 132
	var hole_width := 288 / maxi(1, hole_count)
	var table_width := name_width + hole_count * hole_width + 96
	var start_x := (640 - table_width) / 2
	var course := course_catalog.get_course(session.config.course_id)
	var total_par := 0
	for hole_id in session.config.hole_ids:
		total_par += hole_catalog.get_hole(hole_id).par
	var course_title := course.display_name if course != null and session.config.is_course_mode() else "DEINE RUNDE"
	_score_panel(Rect2(start_x, 76, table_width, 23), Color("#173c39"))
	var course_label := _fitted_label(course_title, Vector2(start_x + 10, 78), Vector2(table_width - 180, 18), 10, Color("#b6e0c8"))
	add_child(course_label)
	var course_info := _fitted_label("%d %s   /   PAR %d" % [hole_count, "LOCH" if hole_count == 1 else "LOECHER", total_par], Vector2(start_x + table_width - 160, 78), Vector2(150,18), 9, Color("#8fd5cc"))
	course_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(course_info)
	var header_y := 105
	_add_table_label("SPIELER", Rect2(start_x, header_y, name_width, 22), Color("#d7edcf"), HORIZONTAL_ALIGNMENT_LEFT)
	for hole_index in range(hole_count):
		_add_table_label(str(hole_index + 1), Rect2(start_x + name_width + hole_index * hole_width, header_y, hole_width, 22), Color("#d7edcf"))
	_add_table_label("TOTAL", Rect2(start_x + name_width + hole_count * hole_width, header_y, 48, 22), Color("#d7edcf"))
	_add_table_label("+/-", Rect2(start_x + name_width + hole_count * hole_width + 48, header_y, 48, 22), Color("#d7edcf"))
	var par_y := header_y + 21
	_add_table_label("PAR", Rect2(start_x, par_y, name_width, 20), Color("#8fa5b5"), HORIZONTAL_ALIGNMENT_LEFT)
	for hole_index in range(hole_count):
		var hole := hole_catalog.get_hole(session.config.hole_ids[hole_index])
		_add_table_label(str(hole.par), Rect2(start_x + name_width + hole_index * hole_width, par_y, hole_width, 20), Color("#8fa5b5"))
	_add_table_label(str(total_par), Rect2(start_x + name_width + hole_count * hole_width, par_y, 48, 20), Color("#8fa5b5"))
	var player_order := range(session.config.players.size())
	if final:
		player_order = session.get_ranked_player_indices()
	for row in range(player_order.size()):
		var player_index: int = player_order[row]
		var y := par_y + 27 + row * 30
		var profile := session.config.players[player_index]
		var winner := final and session.get_competition_rank(player_index) == 1
		_score_panel(Rect2(start_x,y,table_width,28), Color("#233a36") if winner else Color("#12232c"))
		_score_panel(Rect2(start_x,y+4,3,20), profile.get_color())
		var prefix := "%d. " % session.get_competition_rank(player_index) if final else "P%d " % profile.player_id
		_add_table_label(prefix + profile.player_name, Rect2(start_x, y, name_width, 28), profile.get_color(), HORIZONTAL_ALIGNMENT_LEFT)
		for hole_index in range(hole_count):
			var score: int = session.scores[player_index][hole_index]
			var value := "–" if score < 0 else str(score) + ("*" if session.capped[player_index][hole_index] else "")
			var par := hole_catalog.get_hole(session.config.hole_ids[hole_index]).par
			var ink := Color("#8398a2") if score < 0 else Color("#e9e4ce")
			if score >= 0 and score != par:
				ink = Color("#9de0bd") if score < par else Color("#efb48e")
				_score_panel(Rect2(start_x + name_width + hole_index * hole_width + 3,y+4,hole_width-6,20), Color("#254c40") if score < par else Color("#483830"))
			_add_table_label(value, Rect2(start_x + name_width + hole_index * hole_width, y, hole_width, 28), ink)
		_add_table_label(str(session.get_player_total(player_index)), Rect2(start_x + name_width + hole_count * hole_width, y, 48, 28), Color.WHITE)
		_add_table_label(_format_difference(session.get_player_difference(player_index)), Rect2(start_x + name_width + hole_count * hole_width + 48, y, 48, 28), Color("#f0c45b"))
	if final and player_order.size() == 1:
		var under_par := 0
		for hole_index in range(hole_count):
			if session.scores[0][hole_index] >= 0 and session.scores[0][hole_index] < hole_catalog.get_hole(session.config.hole_ids[hole_index]).par:
				under_par += 1
		var stats := [["SCHLAEGE", str(session.get_player_total(0))], ["ZU PAR", _format_difference(session.get_player_difference(0))], ["LOECHER UNTER PAR", str(under_par)]]
		var stat_width := (table_width - 16) / 3.0
		for index in range(3):
			var x := start_x + index * (stat_width + 8)
			_score_panel(Rect2(x,205,stat_width,53), Color("#12262c"))
			add_child(_fitted_label(stats[index][0], Vector2(x+12,211), Vector2(stat_width-24,14), 8, Color("#8fa5a7")))
			add_child(_fitted_label(stats[index][1], Vector2(x+12,226), Vector2(stat_width-24,26), 20, Color("#e9dfae")))
	var legend := _fitted_label("GRUEN: UNTER PAR   /   APRICOT: UEBER PAR     * LIMIT: MIN. 8 ODER PAR + 3", Vector2(start_x, 276), Vector2(table_width, 16), 8, Color("#8fa5b5"))
	add_child(legend)


func _fitted_label(text: String, at: Vector2, bounds: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	# Set the font and overflow policy before any text or bounds: an early
	# default-font minimum can otherwise enlarge the label before parenting.
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	label.position = at
	label.size = bounds
	# Parenting refreshes the cached minimum height on the next frame.
	label.set_deferred("size", bounds)
	return label


func _add_table_label(text: String, rect: Rect2, color: Color, alignment := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	if alignment == HORIZONTAL_ALIGNMENT_LEFT:
		rect.position.x += 8
		rect.size.x -= 10
	var label := _fitted_label(text, rect.position, rect.size, 10, color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)


func _score_panel(rect: Rect2, color: Color) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", MenuWidgets.panel_style(color, color, 0))
	add_child(panel)


func _format_difference(value: int) -> String:
	if value == 0:
		return "E"
	return "+%d" % value if value > 0 else str(value)
