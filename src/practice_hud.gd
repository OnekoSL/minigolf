class_name PracticeHUD
extends Control

signal menu_requested()

var game: PrototypeMain
var section: TutorialSection
var guided := false
var hint: Label
var menu_button: Button
var highlight := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.hud.controller_label.hide()
	game.hud.course_label.hide()
	menu_button = MenuWidgets.button(I18n.text("PRACTICE_TOOLS"), Rect2(8, 4, 152, 23))
	menu_button.add_theme_font_size_override("font_size", 9)
	menu_button.size = Vector2(152, 23)
	menu_button.set_deferred("size", Vector2(152, 23))
	menu_button.pressed.connect(func(): menu_requested.emit())
	add_child(menu_button)
	hint = MenuWidgets.label("", Vector2(8, 30), Vector2(152, 52), 8, Color("#fff1b0"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.size = Vector2(152, 52)
	add_child(hint)
	game.hud.accuracy_bar.practice_window = game.shot_controller.perfect_accuracy_window
	game.hud.accuracy_bar.queue_redraw()
	update_hint()


func update_hint() -> void:
	if hint == null:
		return
	menu_button.text = I18n.text("PRACTICE_TOOLS")
	highlight = Rect2()
	var key := String(section.hint_key) if section != null else "PRACTICE_FREE_HINT"
	if guided:
		match game.shot_controller.state:
			ShotController.ShotState.AIMING:
				key = "PRACTICE_AIM"
			ShotController.ShotState.POWER:
				key = "PRACTICE_POWER"
				highlight = Rect2(104, 190, 58, 158)
			ShotController.ShotState.ACCURACY:
				key = "PRACTICE_ACCURACY"
				highlight = Rect2(21, 340, 92, 11)
			ShotController.ShotState.ARMED:
				key = "PRACTICE_HOLD"
				highlight = Rect2(21, 190, 90, 149)
			ShotController.ShotState.SWINGING, ShotController.ShotState.BALL_MOVING:
				key = String(section.hint_key)
	hint.text = I18n.text(key)
	queue_redraw()


func _draw() -> void:
	if highlight.has_area():
		draw_rect(highlight, Color("#fff1b0"), false, 1)
