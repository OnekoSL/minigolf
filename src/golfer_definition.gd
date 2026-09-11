class_name GolferDefinition
extends Resource

const IDS: Array[StringName] = [&"allrounder", &"mara", &"bruno", &"nika"]

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
	if golfer_id not in IDS or display_name.is_empty() or atlas == null:
		errors.append("Golfer benoetigt bekannte ID, Namen und Atlas")
	if range_factor <= 0.0 or power_cycle_seconds <= 0.0 or accuracy_cycle_seconds <= 0.0:
		errors.append("Reichweite und Zykluszeiten muessen positiv sein")
	if perfect_accuracy_window <= 0.0 or perfect_accuracy_window >= 1.0 or maximum_error_degrees < 0.0:
		errors.append("Ungueltiges Genauigkeitsprofil")
	return errors
