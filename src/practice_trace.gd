class_name PracticeTrace
extends Node2D

const MAX_POINTS := 12000
var current: Array[PackedVector2Array] = []
var previous: Array[PackedVector2Array] = []
var _new_segment := true
var _count := 0


func break_segment() -> void:
	_new_segment = true


func sample(point: Vector2) -> void:
	if _new_segment or current.is_empty():
		current.append(PackedVector2Array())
		_new_segment = false
	var segment := current[-1]
	if not segment.is_empty() and segment[-1].distance_to(point) < 1.0:
		return
	segment.append(point)
	current[-1] = segment
	_count += 1
	if _count > MAX_POINTS:
		var first := current[0]
		first.remove_at(0)
		current[0] = first
		if first.is_empty():
			current.remove_at(0)
		_count -= 1
	queue_redraw()


func compare() -> void:
	if not current.is_empty():
		previous = current.duplicate(true)
	clear_current()


func clear_current() -> void:
	current.clear()
	_count = 0
	_new_segment = true
	queue_redraw()


func clear_all() -> void:
	previous.clear()
	clear_current()


func _draw() -> void:
	for segment in previous:
		# Dashes distinguish the old path without relying solely on color.
		for index in range(1, segment.size(), 2):
			draw_line(segment[index - 1], segment[index], Color(0.6, 0.85, 0.95, 0.48), 1)
	for segment in current:
		if segment.size() > 1:
			draw_polyline(segment, Color(1, 0.85, 0.3, 0.85), 1)
