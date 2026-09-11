class_name GolferStatsView
extends Control

const STAT_LABELS := ["REICHWEITE", "KRAFT-RUHE", "ZIEL-RUHE", "RICHTUNGSTREUE", "PERFEKTFENSTER"]
const ROW_HEIGHT := 36.0

var definition: GolferDefinition
var _values: Array[float] = []
var _reference: Array[float] = []
var _maxima: Array[float] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reference = _comparison_values(GolferDefinition.get_golfer())
	_maxima = _reference.duplicate()
	for id in GolferDefinition.IDS:
		var values := _comparison_values(GolferDefinition.get_golfer(id))
		for index in range(values.size()):
			_maxima[index] = maxf(_maxima[index], values[index])
	set_golfer(GolferDefinition.get_golfer())


func set_golfer(value: GolferDefinition) -> void:
	definition = value
	_values = _comparison_values(value)
	queue_redraw()


func _comparison_values(value: GolferDefinition) -> Array[float]:
	# All bars point in the same direction: range or ease of control.
	# Smaller angular errors mean greater directional precision.
	return [value.range_factor, value.power_cycle_seconds, value.accuracy_cycle_seconds,
		1.0 / maxf(value.maximum_error_degrees, 0.001), value.perfect_accuracy_window]


func _value_labels() -> Array[String]:
	return ["%d %%" % roundi(definition.range_factor * 100.0),
		("%.1f s" % definition.power_cycle_seconds).replace(".", ","),
		("%.1f s" % definition.accuracy_cycle_seconds).replace(".", ","),
		"max. %d°" % roundi(definition.maximum_error_degrees),
		("%.1f %%" % (definition.perfect_accuracy_window * 100.0)).replace(".", ",")]


func _draw() -> void:
	if definition == null or _maxima.is_empty():
		return
	var font := ThemeDB.fallback_font
	var labels := _value_labels()
	var ink := Color("#d7edcf")
	var muted := Color("#8fa5b5")
	var reference_color := Color("#fff1b0")
	for index in range(STAT_LABELS.size()):
		var y := index * ROW_HEIGHT
		draw_string(font, Vector2(0, y + 10), STAT_LABELS[index], HORIZONTAL_ALIGNMENT_LEFT, size.x, 10, ink)
		draw_string(font, Vector2(0, y + 10), labels[index], HORIZONTAL_ALIGNMENT_RIGHT, size.x, 10, muted)
		var bar := Rect2(0, y + 17, size.x, 8)
		draw_rect(bar, Color("#20333e"))
		var fill := roundf(size.x * clampf(_values[index] / _maxima[index], 0.0, 1.0))
		draw_rect(Rect2(bar.position, Vector2(fill, bar.size.y)), Color("#d5b85c") if index == 0 else Color("#62bdb0"))
		for segment in range(1, 12):
			var x := roundf(size.x * segment / 12.0)
			draw_line(Vector2(x, bar.position.y), Vector2(x, bar.end.y - 1), Color("#081018"), 1.0)
		var marker_x := clampf(roundf(size.x * _reference[index] / _maxima[index]), 1.0, size.x - 2.0)
		draw_line(Vector2(marker_x, bar.position.y - 2), Vector2(marker_x, bar.end.y + 1), reference_color, 1.0)
	var legend_y := STAT_LABELS.size() * ROW_HEIGHT + 5
	draw_line(Vector2(1, legend_y - 7), Vector2(1, legend_y + 1), reference_color, 1.0)
	draw_string(font, Vector2(8, legend_y), "BEN ZUM VERGLEICH", HORIZONTAL_ALIGNMENT_LEFT, size.x - 8, 8, muted)
	draw_string(font, Vector2(0, legend_y + 14), "MEHR BALKEN: MEHR WEITE / KONTROLLE", HORIZONTAL_ALIGNMENT_LEFT, size.x, 8, muted)
