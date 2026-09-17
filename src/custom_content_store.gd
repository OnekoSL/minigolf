class_name CustomContentStore
extends RefCounted

var root := "user://custom_content"
var holes: Array[HoleDefinition] = []
var courses: Array[CourseDefinition] = []
var error := ""
var _load_failed := false


func _init(directory := "user://custom_content") -> void:
	root = directory


func load_library() -> bool:
	holes.clear()
	courses.clear()
	error = ""
	_load_failed = false
	if not FileAccess.file_exists(root.path_join("library.json")):
		return true
	var data: Variant = read_file(root.path_join("library.json"))
	if data == null or not _decode_library(data):
		_load_failed = true
		return false
	return true


func read_file(path: String) -> Variant:
	error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error = "Datei konnte nicht geöffnet werden: %s" % error_string(FileAccess.get_open_error())
		return null
	if file.get_length() > EditorCodec.MAX_BYTES:
		error = "Datei ist größer als 16 MB"
		return null
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		error = "Ungültiges JSON: %s" % parser.get_error_message()
		return null
	var data: Variant = parser.data
	if not data is Dictionary or data.get("version") != EditorCodec.VERSION:
		error = "Unbekannte Dateiversion"
		return null
	return data


func _decode_library(data: Dictionary) -> bool:
	if not data.get("holes") is Array or not data.get("courses") is Array or data.holes.size() > 1024 or data.courses.size() > 1024:
		error = "Ungültige Bibliothek"
		return false
	var decoded_holes: Array[HoleDefinition] = []
	var decoded_courses: Array[CourseDefinition] = []
	var ids := {}
	var codec := EditorCodec.new()
	for raw in data.holes:
		var hole := codec.decode(raw, "hole") as HoleDefinition
		if hole == null:
			error = codec.error
			return false
		if not String(hole.hole_id).begins_with("custom_") or ids.has(hole.hole_id):
			error = "Ungültige oder doppelte Bahnkennung"
			return false
		ids[hole.hole_id] = true
		decoded_holes.append(hole)
	for raw in data.courses:
		var course := codec.decode(raw, "course") as CourseDefinition
		if course == null:
			error = codec.error
			return false
		if not String(course.course_id).begins_with("custom_") or ids.has(course.course_id) or course.hole_ids.is_empty() or course.hole_ids.size() > 9:
			error = "Ungültiger Kurs"
			return false
		ids[course.course_id] = true
		for id in course.hole_ids:
			var found := false
			for hole in decoded_holes:
				found = found or hole.hole_id == id
			if not found:
				error = "Kurs verweist auf eine fehlende Bahn"
				return false
		decoded_courses.append(course)
	holes = decoded_holes
	courses = decoded_courses
	return true


func payload(selected_holes: Array[HoleDefinition], selected_courses: Array[CourseDefinition]) -> Dictionary:
	var data := {"version": EditorCodec.VERSION, "holes": [], "courses": [], "draft": false}
	for hole in selected_holes:
		data.holes.append(EditorCodec.encode(hole))
		data.draft = data.draft or not EditorDocument.new(hole).blocking_issues().is_empty()
	for course in selected_courses:
		data.courses.append(EditorCodec.encode(course))
	return data


func write_file(path: String, data: Dictionary) -> bool:
	error = ""
	var serialized := JSON.stringify(data, "\t", true, true)
	if serialized.to_utf8_buffer().size() > EditorCodec.MAX_BYTES:
		error = "Datei würde die unterstützte Größe von 16 MB überschreiten"
		return false
	var folder := ProjectSettings.globalize_path(path.get_base_dir())
	var ancestor := folder
	while not ancestor.is_empty() and ancestor != ancestor.get_base_dir():
		if FileAccess.file_exists(ancestor):
			error = "Speicherordner ist durch eine Datei blockiert"
			return false
		ancestor = ancestor.get_base_dir()
	var mkdir_error := DirAccess.make_dir_recursive_absolute(folder)
	if mkdir_error != OK:
		error = "Ordner konnte nicht angelegt werden: %s" % error_string(mkdir_error)
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		error = "Speichern fehlgeschlagen: %s" % error_string(FileAccess.get_open_error())
		return false
	file.store_string(serialized)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = "Datei konnte nicht vollständig geschrieben werden"
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var backup := absolute + ".bak"
	var had_file := FileAccess.file_exists(path)
	if had_file:
		var backup_error := DirAccess.copy_absolute(absolute, backup)
		if backup_error != OK:
			error = "Sicherung fehlgeschlagen; bisherige Datei bleibt erhalten"
			return false
	var move_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute)
	if move_error != OK:
		error = "Datei konnte nicht ersetzt werden; bisherige Datei bleibt erhalten"
		return false
	return true


func save_library() -> bool:
	if holes.size() > 1024 or courses.size() > 1024:
		error = "Die Bibliothek unterstützt bis zu 1024 Bahnen und 1024 Kurse"
		return false
	if _load_failed:
		error = "Beschädigte Bibliothek wird nicht überschrieben. Bitte library.json sichern und reparieren."
		return false
	return write_file(root.path_join("library.json"), payload(holes, courses))


func save_hole(hole: HoleDefinition) -> bool:
	var codec := EditorCodec.new()
	if codec.decode(EditorCodec.encode(hole), "hole") == null:
		error = "Entwurf überschreitet unterstützte Datengrenzen: " + codec.error
		return false
	var previous := holes.duplicate()
	var replaced := false
	for index in range(holes.size()):
		if holes[index].hole_id == hole.hole_id:
			holes[index] = hole.duplicate(true)
			replaced = true
	if not replaced:
		holes.append(hole.duplicate(true))
	if not save_library():
		holes = previous
		return false
	return true


func save_course(course: CourseDefinition) -> bool:
	if course.hole_ids.is_empty() or course.hole_ids.size() > 9 or course.display_name.strip_edges().is_empty():
		error = "Kurs benötigt einen Namen und 1 bis 9 Bahnen"
		return false
	for id in course.hole_ids:
		if get_hole(id) == null:
			error = "Kurs enthält eine fehlende Bahn"
			return false
	var previous := courses.duplicate()
	for index in range(courses.size() - 1, -1, -1):
		if courses[index].course_id == course.course_id:
			courses.remove_at(index)
	courses.append(course.duplicate(true))
	if not save_library():
		courses = previous
		return false
	return true


func get_hole(id: StringName) -> HoleDefinition:
	for hole in holes:
		if hole.hole_id == id:
			return hole
	return null


func delete_hole(id: StringName) -> bool:
	for course in courses:
		if id in course.hole_ids:
			error = "Bahn wird noch in „%s“ verwendet" % course.display_name
			return false
	var previous := holes.duplicate()
	holes.erase(get_hole(id))
	if not save_library():
		holes = previous
		return false
	return true


func delete_course(course: CourseDefinition) -> bool:
	var previous := courses.duplicate()
	courses.erase(course)
	if not save_library():
		courses = previous
		return false
	return true


func import_file(path: String) -> bool:
	var data: Variant = read_file(path)
	if data == null:
		return false
	var staging := CustomContentStore.new(root)
	if not staging._decode_library(data):
		error = staging.error
		return false
	var mapping := {}
	for hole in staging.holes:
		var id := StringName(EditorCodec.new_id())
		mapping[hole.hole_id] = id
		hole.hole_id = id
	for course in staging.courses:
		course.course_id = EditorCodec.new_id()
		for index in range(course.hole_ids.size()):
			course.hole_ids[index] = mapping[course.hole_ids[index]]
	var old_holes := holes.duplicate()
	var old_courses := courses.duplicate()
	holes.append_array(staging.holes)
	courses.append_array(staging.courses)
	if not save_library():
		holes = old_holes
		courses = old_courses
		return false
	return true


func export_course(course: CourseDefinition, path: String) -> bool:
	var included: Array[HoleDefinition] = []
	for id in course.hole_ids:
		var hole := get_hole(id)
		if hole == null:
			error = "Kurs enthält eine fehlende Bahn"
			return false
		if hole not in included:
			included.append(hole)
	return write_file(path, payload(included, [course]))


func best_key(course: CourseDefinition) -> StringName:
	var parts := "editor-physics-1:"
	for id in course.hole_ids:
		var hole := get_hole(id)
		if hole == null:
			return &""
		parts += EditorCodec.gameplay_hash(hole) + ":"
	return StringName("%s_%s" % [course.course_id, parts.sha256_text()])


func playable_catalog() -> HoleCatalog:
	var catalog := HoleCatalog.new()
	for hole in holes:
		if EditorDocument.new(hole).blocking_issues().is_empty():
			catalog.holes.append(hole.duplicate(true))
	return catalog
