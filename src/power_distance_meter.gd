class_name PowerDistanceMeter
extends Control

const MINIMUM_BALL_SPEED := ShotController.MINIMUM_BALL_SPEED
const MAXIMUM_BALL_SPEED := ShotController.MAXIMUM_BALL_SPEED
const GRASS_DECELERATION := 120.0
const PIXELS_PER_METER := 32.0

var value := 0.0


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


func power_for_distance_dm(distance_dm: float) -> float:
	var distance_pixels := maxf(distance_dm, 0.0) * PIXELS_PER_METER / 10.0
	var speed := sqrt(2.0 * GRASS_DECELERATION * distance_pixels)
	return clampf(inverse_lerp(MINIMUM_BALL_SPEED, MAXIMUM_BALL_SPEED, speed), 0.0, 1.0)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bar_top: float = 2.0
	var bar_bottom: float = size.y - 8.0
	var bar_height: float = bar_bottom - bar_top
	var bar_rect := Rect2(7, bar_top, 5, bar_height)
	draw_rect(bar_rect, Color("#0d141c"), true)
	draw_rect(bar_rect, Color("#63717b"), false, 1.0)
	var fill_height := bar_height * value
	draw_rect(Rect2(7, bar_bottom - fill_height, 5, fill_height), Color("#e9b34f"), true)
	# Round distances need nonlinear spacing along the linear power bar.
	var tick_distances: Array[int] = []
	tick_distances.assign(range(1, 10))
	tick_distances.append_array(range(10, distance_dm_for_power(1.0), 10))
	for distance_dm in tick_distances:
		var power := power_for_distance_dm(float(distance_dm))
		var y: float = bar_bottom - bar_height * power
		var major_tick: bool = distance_dm % 50 == 0 or distance_dm in [1, 5, 10]
		var tick_end := 18.0 if major_tick else 15.0
		var tick_color := Color("#c8d2d8") if major_tick else Color("#798b98")
		draw_line(Vector2(13, roundf(y)), Vector2(tick_end, roundf(y)), tick_color, 1.0)
		if major_tick:
			draw_string(font, Vector2(21, roundf(y) + 3), str(distance_dm), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, tick_color)
	draw_line(Vector2(13, bar_top), Vector2(18, bar_top), Color("#c8d2d8"), 1.0)
	draw_string(font, Vector2(21, bar_top + 3), str(distance_dm_for_power(1.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#c8d2d8"))
