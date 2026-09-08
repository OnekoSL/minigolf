class_name PrototypeHUD
extends CanvasLayer

var power_bar: PowerDistanceMeter
var accuracy_bar: AccuracyMeter
var stroke_label: Label
var state_label: Label
var distance_label: Label
var controller_label: Label
var help_label: Label
var diagnostics_panel: Panel
var diagnostics_label: Label
var result_panel: Panel
var result_label: Label
var pause_label: Label
var course_label: Label
var golfer: PlaceholderGolfer
var player_label: Label
var round_label: Label
var golfer_title: Label


func _ready() -> void:
	_build_hud()


func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var sidebar_background := ColorRect.new()
	sidebar_background.position = Vector2.ZERO
	sidebar_background.size = Vector2(168, 360)
	sidebar_background.color = Color("#080d12")
	sidebar_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sidebar_background)
	var sidebar_border := ColorRect.new()
	sidebar_border.position = Vector2(168, 0)
	sidebar_border.size = Vector2(8, 360)
	sidebar_border.color = Color("#dad1af")
	sidebar_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(sidebar_border)
	for edge_x in [168, 175]:
		var border_edge := ColorRect.new()
		border_edge.position = Vector2(edge_x, 0)
		border_edge.size = Vector2(1, 360)
		border_edge.color = Color("#584d43")
		border_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(border_edge)

	var golfer_panel := Panel.new()
	golfer_panel.position = Vector2(8, 218)
	golfer_panel.size = Vector2(160, 134)
	golfer_panel.add_theme_stylebox_override("panel", _panel_style(Color("#172332"), Color("#d5c477")))
	root.add_child(golfer_panel)

	golfer_title = _label("P1  ALLROUNDER", Vector2(7, 4), Vector2(146, 16), 11, Color("#f0df9b"))
	golfer_panel.add_child(golfer_title)

	golfer = PlaceholderGolfer.new()
	golfer.position = Vector2(15, 20)
	golfer.size = Vector2(88, 78)
	golfer_panel.add_child(golfer)

	power_bar = PowerDistanceMeter.new()
	power_bar.position = Vector2(96, 12)
	power_bar.size = Vector2(60, 106)
	golfer_panel.add_child(power_bar)

	var accuracy_title := _label("GENAU", Vector2(15, 113), Vector2(88, 10), 8, Color("#d6e1e8"))
	golfer_panel.add_child(accuracy_title)
	accuracy_bar = AccuracyMeter.new()
	accuracy_bar.position = Vector2(15, 126)
	accuracy_bar.size = Vector2(88, 5)
	golfer_panel.add_child(accuracy_bar)

	state_label = _label("ZIELEN", Vector2(7, 99), Vector2(88, 12), 9, Color("#ffffff"))
	golfer_panel.add_child(state_label)

	# Keep the entire playable area clear, including upper return corridors.
	stroke_label = _label("SCHLAEGE 0   PAR 4", Vector2(8, 86), Vector2(152, 20), 11, Color("#fff3ba"))
	root.add_child(stroke_label)
	player_label = _label("SPIELER 1", Vector2(8, 110), Vector2(152, 18), 10, Color("#49d6cf"))
	player_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	root.add_child(player_label)
	round_label = _label("LOCH 1/1   GESAMT 0", Vector2(8, 132), Vector2(152, 16), 9, Color("#d7edcf"))
	root.add_child(round_label)
	distance_label = _label("ENTFERNUNG 0 dm", Vector2(8, 148), Vector2(152, 18), 10, Color("#d7edcf"))
	root.add_child(distance_label)
	controller_label = _label("Controller wird gesucht ...", Vector2(8, 8), Vector2(152, 38), 10, Color("#c9d6df"))
	controller_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(controller_label)
	help_label = _label("Stick/D-Pad/Maus: Zielen\nKreuz/Leertaste: Schlag\nKreis: Abbruch  |  F3: Diagnose\nDreieck/F2: Loch wechseln", Vector2(8, 168), Vector2(152, 46), 7, Color("#9fb2c1"))
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.add_theme_constant_override("line_spacing", 0)
	root.add_child(help_label)
	course_label = _label("", Vector2(8, 50), Vector2(152, 32), 10, Color("#d7edcf"))
	course_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(course_label)

	diagnostics_panel = Panel.new()
	diagnostics_panel.position = Vector2(145, 36)
	diagnostics_panel.size = Vector2(480, 286)
	diagnostics_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.035, 0.06, 0.09, 0.97), Color("#69c4c1")))
	diagnostics_panel.visible = false
	diagnostics_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(diagnostics_panel)
	diagnostics_label = _label("", Vector2(12, 10), Vector2(456, 264), 12, Color("#dcecf0"))
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_panel.add_child(diagnostics_label)

	result_panel = Panel.new()
	result_panel.position = Vector2(260, 122)
	result_panel.size = Vector2(280, 118)
	result_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.08, 0.12, 0.96), Color("#f0cf64")))
	result_panel.visible = false
	root.add_child(result_panel)
	result_label = _label("", Vector2(12, 12), Vector2(256, 92), 15, Color("#fff1b0"))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)

	pause_label = _label("PAUSE", Vector2(270, 150), Vector2(160, 46), 24, Color("#fff1b0"))
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.visible = false
	root.add_child(pause_label)


func _label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	# Apply font metrics before assigning bounds; otherwise the default font's
	# minimum size can permanently enlarge narrow sidebar labels.
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.clip_text = true
	label.text = text
	label.position = position
	label.size = size
	# Reapply once the label is in the tree and its real font/wrapping metrics
	# are available (the detached default font can report a larger minimum).
	label.set_deferred("size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


func _flat_style(background: Color, width: int, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	return style


func update_game(strokes: int, par: int, power: float, accuracy: float, shot_state: int, distance_decimeters: int, stroke_limit := 0) -> void:
	stroke_label.text = "SCHLAEGE %d/%d   PAR %d" % [strokes, stroke_limit, par] if stroke_limit > 0 else "SCHLAEGE %d   PAR %d" % [strokes, par]
	distance_label.text = "ENTFERNUNG %d dm" % distance_decimeters
	power_bar.set_value(power)
	accuracy_bar.set_value(accuracy)
	golfer.set_shot_state(shot_state)
	var names := {
		ShotController.ShotState.AIMING: "ZIELEN",
		ShotController.ShotState.POWER: "KRAFT",
		ShotController.ShotState.ACCURACY: "GENAUIGKEIT",
		ShotController.ShotState.ARMED: "BEREIT ...",
		ShotController.ShotState.SWINGING: "SCHWUNG",
		ShotController.ShotState.BALL_MOVING: "BALL LAEUFT",
		ShotController.ShotState.HOLE_COMPLETE: "GESCHAFFT!",
	}
	state_label.text = names.get(shot_state, "")


func set_controller_status(text: String) -> void:
	controller_label.text = text


func set_diagnostics(visible: bool, text: String) -> void:
	diagnostics_panel.visible = visible
	diagnostics_label.text = text


func show_result(strokes: int, par: int, prompt := "Kreuz / Leertaste: Nochmal") -> void:
	var difference := strokes - par
	var result := "PAR" if difference == 0 else ("%d UNTER PAR" % abs(difference) if difference < 0 else "+%d UEBER PAR" % difference)
	result_label.text = "LOCH GESCHAFFT!\n%d SCHLAEGE - %s%s" % [
		strokes,
		result,
		"\n\n" + prompt if not prompt.is_empty() else "",
	]
	result_panel.visible = true


func show_limit_result(strokes: int) -> void:
	result_label.text = "MAXIMUM ERREICHT\n%d SCHLAEGE\n\nNAECHSTER SPIELER ..." % strokes
	result_panel.visible = true


func hide_result() -> void:
	result_panel.visible = false


func set_paused(value: bool) -> void:
	pause_label.visible = value


func set_course_name(value: String) -> void:
	course_label.text = value


func set_player_context(profile: PlayerProfile, hole_number: int, hole_count: int, total_strokes: int) -> void:
	if profile == null:
		return
	player_label.text = "P%d  %s" % [profile.player_id, profile.player_name]
	player_label.add_theme_color_override("font_color", profile.get_color())
	round_label.text = "LOCH %d/%d   GESAMT %d" % [hole_number, hole_count, total_strokes]
	golfer_title.text = "P%d  ALLROUNDER" % profile.player_id
	golfer_title.add_theme_color_override("font_color", profile.get_color())
	golfer.set_palette(profile.palette_id)


func play_golfer_reaction(kind: String) -> void:
	golfer.play_reaction(kind)
	if kind == "perfect_swing":
		accuracy_bar.flash_perfect()
