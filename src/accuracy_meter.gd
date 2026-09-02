class_name AccuracyMeter
extends Control

var value := 0.0
var perfect_flash_left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_value(new_value: float) -> void:
	value = clampf(new_value, -1.0, 1.0)
	queue_redraw()


func flash_perfect() -> void:
	perfect_flash_left = 0.25
	queue_redraw()


func _process(delta: float) -> void:
	if perfect_flash_left <= 0.0:
		return
	perfect_flash_left = maxf(0.0, perfect_flash_left - delta)
	queue_redraw()


func _draw() -> void:
	var center_x := size.x * 0.5
	var marker_x := remap(value, -1.0, 1.0, 2.0, size.x - 2.0)
	draw_rect(Rect2(0.0, 0.0, size.x, 5.0), Color("#0d141c"), true)
	draw_line(Vector2(center_x, 0.0), Vector2(center_x, 5.0), Color("#ffffff"), 1.0)
	draw_line(Vector2(center_x, 2.0), Vector2(marker_x, 2.0), Color("#5fc3b3"), 3.0)
	draw_rect(Rect2(marker_x - 1.0, -1.0, 3.0, 7.0), Color("#f5e8ba"), true)
	if perfect_flash_left > 0.0:
		var alpha := perfect_flash_left / 0.25
		draw_rect(Rect2(center_x - 5.0, -2.0, 10.0, 9.0), Color(1.0, 0.91, 0.42, alpha * 0.35), true)
		draw_rect(Rect2(center_x - 5.0, -2.0, 10.0, 9.0), Color(1.0, 0.96, 0.68, alpha), false, 1.0)
