class_name GolferDefinition
extends Resource

const IDS: Array[StringName] = [&"allrounder", &"mara", &"bruno", &"nika", &"don"]
const TEST_STATS := [&"range_factor", &"power_cycle_seconds", &"accuracy_cycle_seconds", &"perfect_accuracy_window", &"maximum_error_degrees"]
const TEST_MINIMUMS := [0.1, 0.2, 0.2, 0.005, 0.0]
const TEST_MAXIMUMS := [3.0, 12.0, 12.0, 0.5, 45.0]
const TEST_STEPS := [0.05, 0.2, 0.2, 0.005, 1.0]

@export var golfer_id := &"allrounder"
@export var display_name := "BEN"
@export var description := "Ausgewogene Reichweite\nund ruhiges Timing."
@export var atlas: Texture2D
@export var range_factor := 1.0
@export var power_cycle_seconds := 4.0
@export var accuracy_cycle_seconds := 2.4
@export var perfect_accuracy_window := 0.05
@export var maximum_error_degrees := 8.0


static func get_golfer(id: StringName = &"allrounder") -> GolferDefinition:
	var known_id: StringName = id if id in IDS else &"allrounder"
	return load("res://data/golfers/%s.tres" % known_id) as GolferDefinition


func get_maximum_ball_speed() -> float:
	return 420.0 * sqrt(range_factor)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for stat in TEST_STATS:
		if not is_finite(float(get(stat))):
			errors.append(I18n.text("TEXT_GOLFER_VALUES_MUST_BE_FINITE"))
	if golfer_id == &"don":
		for index in range(TEST_STATS.size()):
			var value := float(get(TEST_STATS[index]))
			if value < TEST_MINIMUMS[index] or value > TEST_MAXIMUMS[index]:
				errors.append(I18n.text("TEXT_TEST_VALUE_OUTSIDE_THE_ALLOWED_RANGE"))
	if golfer_id not in IDS or display_name.is_empty() or atlas == null:
		errors.append(I18n.text("TEXT_GOLFER_NEEDS_A_KNOWN_ID_NAME_AND_ATLAS"))
	if range_factor <= 0.0 or power_cycle_seconds <= 0.0 or accuracy_cycle_seconds <= 0.0:
		errors.append(I18n.text("TEXT_RANGE_AND_CYCLE_DURATIONS_MUST_BE_POSITIVE"))
	if perfect_accuracy_window <= 0.0 or perfect_accuracy_window >= 1.0 or maximum_error_degrees < 0.0:
		errors.append(I18n.text("TEXT_INVALID_ACCURACY_PROFILE"))
	return errors
