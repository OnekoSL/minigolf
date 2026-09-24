class_name CourseDefinition
extends Resource

@export var course_id := &"unnamed"
@export var display_name := "UNBENANNTER KURS"
@export var hole_ids: Array[StringName] = []
@export var allow_technical_holes := false
@export_range(1, 99, 1) var best_score_revision := 1


func validate(hole_catalog: HoleCatalog) -> PackedStringArray:
	var errors := PackedStringArray()
	if course_id == &"" or course_id == &"unnamed":
		errors.append(I18n.text("TEXT_COURSE_HAS_NO_UNIQUE_ID"))
	if display_name.strip_edges().is_empty():
		errors.append(I18n.text("TEXT_COURSE_HAS_NO_DISPLAY_NAME") % course_id)
	if best_score_revision < 1:
		errors.append(I18n.text("TEXT_COURSE_HAS_AN_INVALID_RECORD_REVISION") % course_id)
	if hole_ids.is_empty():
		errors.append(I18n.text("TEXT_COURSE_HAS_NO_HOLES") % course_id)
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id) if hole_catalog != null else null
		if hole == null:
			errors.append(I18n.text("TEXT_COURSE_REFERS_TO_UNKNOWN_HOLE") % [course_id, hole_id])
		elif not hole.is_course_hole() and not allow_technical_holes:
			errors.append(I18n.text("TEXT_COURSE_CONTAINS_TECHNICAL_HOLE") % [course_id, hole_id])
	return errors


func get_best_score_key() -> StringName:
	if best_score_revision <= 1:
		return course_id
	return StringName("%s_v%d" % [course_id, best_score_revision])


func get_total_par(hole_catalog: HoleCatalog) -> int:
	var total := 0
	for hole_id in hole_ids:
		var hole := hole_catalog.get_hole(hole_id)
		if hole != null:
			total += hole.par
	return total
