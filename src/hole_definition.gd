class_name HoleDefinition
extends Resource

enum HoleCategory { COURSE, TECHNICAL }

@export var hole_id := &"unnamed"
@export var display_name := "UNBENANNTE BAHN"
@export var category := HoleCategory.COURSE
@export_range(1, 20, 1) var par := 4
@export var course_rect := Rect2(176.0, 16.0, 448.0, 328.0)
@export var tee_position := Vector2(220.0, 305.0)
@export var hole_position := Vector2(575.0, 55.0)
@export var initial_aim_offset := Vector2(60.0, 0.0)
@export var camera_center_bounds := Rect2(Vector2(320.0, 180.0), Vector2.ZERO)
@export var grid_spacing := 16
@export var walls: Array[WallDefinition] = []
@export var surfaces: Array[SurfaceDefinition] = []
@export var obstacles: Array[ObstacleDefinition] = []
@export var triggers: Array[TriggerDefinition] = []
@export var cannons: Array[CannonDefinition] = []


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if hole_id == &"" or hole_id == &"unnamed":
		errors.append("Bahn besitzt keine eindeutige ID")
	if display_name.strip_edges().is_empty():
		errors.append("Bahn %s besitzt keinen Anzeigenamen" % hole_id)
	if course_rect.size.x <= 0.0 or course_rect.size.y <= 0.0:
		errors.append("Bahn %s besitzt kein gueltiges Spielfeld" % hole_id)
	if not course_rect.has_point(tee_position):
		errors.append("Bahn %s: Abschlag liegt ausserhalb des Spielfelds" % hole_id)
	if not course_rect.has_point(hole_position):
		errors.append("Bahn %s: Loch liegt ausserhalb des Spielfelds" % hole_id)
	if camera_center_bounds.size.x < 0.0 or camera_center_bounds.size.y < 0.0:
		errors.append("Bahn %s besitzt negative Kameragrenzen" % hole_id)
	var expected_camera_end := Vector2(
		maxf(320.0, course_rect.end.x + 8.0 - 320.0),
		maxf(180.0, course_rect.end.y + 8.0 - 180.0)
	)
	if not camera_center_bounds.position.is_equal_approx(Vector2(320.0, 180.0)) \
		or not camera_center_bounds.end.is_equal_approx(expected_camera_end):
		errors.append("Bahn %s: Kameragrenzen zeigen die Aussenwaende nicht vollstaendig" % hole_id)
	for index in range(walls.size()):
		if walls[index] == null:
			errors.append("Bahn %s enthaelt eine leere Bande" % hole_id)
			continue
		errors.append_array(walls[index].validate("Bahn %s, Bande %d" % [hole_id, index]))
		if not course_rect.grow(16.0).has_point(walls[index].center):
			errors.append("Bahn %s, Bande %d liegt ausserhalb der Bahn" % [hole_id, index])
	for index in range(surfaces.size()):
		if surfaces[index] == null:
			errors.append("Bahn %s enthaelt eine leere Flaeche" % hole_id)
			continue
		errors.append_array(surfaces[index].validate("Bahn %s, Flaeche %d" % [hole_id, index]))
		for corner in surfaces[index].get_rotated_corners():
			if not course_rect.has_point(corner):
				errors.append("Bahn %s, Flaeche %d liegt ausserhalb der Bahn" % [hole_id, index])
				break
	for index in range(obstacles.size()):
		if obstacles[index] == null:
			errors.append("Bahn %s enthaelt ein leeres Hindernis" % hole_id)
			continue
		errors.append_array(obstacles[index].validate("Bahn %s, Hindernis %d" % [hole_id, index]))
		if not course_rect.has_point(obstacles[index].position):
			errors.append("Bahn %s, Hindernis %d liegt ausserhalb der Bahn" % [hole_id, index])
	var trigger_ids: Dictionary = {}
	for index in range(triggers.size()):
		var trigger := triggers[index]
		if trigger == null:
			errors.append("Bahn %s enthaelt einen leeren Trigger" % hole_id)
			continue
		errors.append_array(trigger.validate("Bahn %s, Trigger %d" % [hole_id, index]))
		if trigger_ids.has(trigger.trigger_id):
			errors.append("Bahn %s besitzt doppelte Trigger-ID %s" % [hole_id, trigger.trigger_id])
		trigger_ids[trigger.trigger_id] = true
		if not course_rect.has_point(trigger.position):
			errors.append("Bahn %s, Trigger %d liegt ausserhalb der Bahn" % [hole_id, index])
	var cannon_ids: Dictionary = {}
	for index in range(cannons.size()):
		var cannon := cannons[index]
		if cannon == null:
			errors.append("Bahn %s enthaelt eine leere Kanone" % hole_id)
			continue
		errors.append_array(cannon.validate("Bahn %s, Kanone %d" % [hole_id, index]))
		if cannon_ids.has(cannon.mechanism_id):
			errors.append("Bahn %s besitzt doppelte Mechanismus-ID %s" % [hole_id, cannon.mechanism_id])
		cannon_ids[cannon.mechanism_id] = true
		if not course_rect.has_point(cannon.position):
			errors.append("Bahn %s, Kanone %d liegt ausserhalb der Bahn" % [hole_id, index])
		if not course_rect.has_point(cannon.landing_position):
			errors.append("Bahn %s, Kanone %d landet ausserhalb der Bahn" % [hole_id, index])
	for trigger in triggers:
		if trigger == null:
			continue
		for target_id in trigger.target_ids:
			if not cannon_ids.has(target_id):
				errors.append("Bahn %s: Trigger %s verweist auf unbekanntes Ziel %s" % [hole_id, trigger.trigger_id, target_id])
	for cannon in cannons:
		if cannon == null or cannon.required_trigger_id == &"":
			continue
		if not trigger_ids.has(cannon.required_trigger_id):
			errors.append("Bahn %s: Kanone %s benoetigt unbekannten Trigger %s" % [hole_id, cannon.mechanism_id, cannon.required_trigger_id])
		else:
			var linked := false
			for trigger in triggers:
				if trigger != null and trigger.trigger_id == cannon.required_trigger_id and cannon.mechanism_id in trigger.target_ids:
					linked = true
					break
			if not linked:
				errors.append("Bahn %s: Kanone %s ist nicht als Ziel ihres Triggers eingetragen" % [hole_id, cannon.mechanism_id])
	return errors


func is_course_hole() -> bool:
	return category == HoleCategory.COURSE
