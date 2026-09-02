class_name PowerDistanceMeter
extends Control

const MINIMUM_BALL_SPEED := 60.0
const MAXIMUM_BALL_SPEED := 420.0
const GRASS_DECELERATION := 120.0
const PIXELS_PER_METER := 32.0

var value := 0.05


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_value(new_value: float) -> void:
	value = clampf(new_value, 0.0, 1.0)
	queue_redraw()


func distance_dm_for_power(power: float) -> int:
	var speed := lerpf(MINIMUM_BALL_SPEED, MAXIMUM_BALL_SPEED, power)
	var distance_pixels := speed * speed / (2.0 * GRASS_DECELERATION)
	return int(round(distance_pixels / PIXELS_PER_METER * 10.0))


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 9), "WEITE", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#d6e1e8"))
	var bar_top: float = 14.0
	var bar_bottom: float = 102.0
	var bar_height: float = bar_bottom - bar_top
	var bar_rect := Rect2(7, bar_top, 5, bar_height)
	draw_rect(bar_rect, Color("#0d141c"), true)
	draw_rect(bar_rect, Color("#63717b"), false, 1.0)
	var fill_height := bar_height * value
	draw_rect(Rect2(7, bar_bottom - fill_height, 5, fill_height), Color("#e9b34f"), true)
	var tick_powers: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0]
	for power in tick_powers:
		var y: float = bar_bottom - bar_height * power
		draw_line(Vector2(13, y), Vector2(17, y), Color("#c8d2d8"), 1.0)
		var label := str(distance_dm_for_power(power))
		draw_string(font, Vector2(20, y + 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#c8d2d8"))
