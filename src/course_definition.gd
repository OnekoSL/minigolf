class_name CourseDefinition
extends Resource

@export var course_id := &"unnamed"
@export var display_name := "UNBENANNTER KURS"
@export var hole_ids: Array[StringName] = []
@export var allow_technical_holes := false


func validate(hole_catalog: HoleCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	if course_id == &"" or course_id == &"unnamed":
		errors.append("Kurs besitzt keine eindeutige ID")
	if display_name.strip_edges().is_empty():
		errors.append("Kurs %s besitzt keinen Anzeigenamen" % course_id)
	if hole_ids.is_empty():
		errors.append("Kurs %s besitzt keine Loecher" % course_id)
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id) if hole_catalog != null else null
		if hole == null:
			errors.append("Kurs %s verweist auf unbekannte Bahn %s" % [course_id, hole_id])
		elif not hole.is_course_hole() and not allow_technical_holes:
			errors.append("Kurs %s enthaelt technische Bahn %s" % [course_id, hole_id])
	return errors


func get_total_par(hole_catalog: HoleCatalog) -> int:
	var total := 0
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id)
		if hole != null:
			total += hole.par
	return total
