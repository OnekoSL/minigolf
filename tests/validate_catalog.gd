extends SceneTree


func _initialize() -> void:
	var catalog := HoleCatalog.load_default()
	if catalog == null:
		push_error("Lochkatalog konnte nicht geladen werden")
		quit(1)
		return
	var errors := catalog.validate()
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	print("Lochkatalog: %d gueltige Definitionen" % catalog.holes.size())
	for definition in catalog.holes:
		print("  %s: %s" % [definition.hole_id, definition.display_name])
	quit(0)
