class_name MenuWidgets
extends RefCounted


static func label(text: String, position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style


static func button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#d7edcf"))
	button.add_theme_color_override("font_disabled_color", Color("#52616b"))
	button.add_theme_stylebox_override("normal", panel_style(Color("#122331"), Color("#40596a"), 2))
	button.add_theme_stylebox_override("hover", panel_style(Color("#19394a"), Color("#75d4c7"), 2))
	button.add_theme_stylebox_override("pressed", panel_style(Color("#274a54"), Color("#fff1b0"), 2))
	button.add_theme_stylebox_override("disabled", panel_style(Color("#0b141b"), Color("#293741"), 1))
	return button
