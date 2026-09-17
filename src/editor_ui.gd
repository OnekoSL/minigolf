class_name EditorUI
extends Control

signal closed()
signal play_requested(course: CourseDefinition, players: Array[PlayerProfile])

var document: EditorDocument
var store := CustomContentStore.new()
var start_in_library := false
var canvas: EditorCanvas
var inspector: VBoxContainer
var issues_list: ItemList
var status: Label
var title_label: Label
var body: VBoxContainer
var golfer_choice: OptionButton
var _autosave: Timer
var _issues: Array[Dictionary] = []
var _library_tab := 0
var _library_list: ItemList
var _library_preview: EditorCanvas
var _course_work: CourseDefinition
var _course_sequence: ItemList
var _course_name: LineEdit
var _course_holes: ItemList
var _refresh_pending := false
var _previous_auto_quit := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().content_scale_size = Vector2i(1280, 720)
	_previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_theme()
	store.load_library()
	document = EditorDocument.new()
	document.changed.connect(_document_changed)
	_autosave = Timer.new()
	_autosave.one_shot = true
	_autosave.wait_time = 2.0
	_autosave.timeout.connect(_write_recovery)
	add_child(_autosave)
	if start_in_library:
		document.mark_saved()
		show_library()
	else:
		show_editor()
	if not store.error.is_empty():
		_message(store.error)
	if FileAccess.file_exists(store.root.path_join("recovery.json")):
		var dialog := ConfirmationDialog.new()
		dialog.cancel_button_text = "Abbrechen"
		dialog.title = "Entwurf wiederherstellen"
		dialog.dialog_text = "Es gibt einen automatisch gesicherten Entwurf. Wiederherstellen?"
		add_child(dialog)
		dialog.confirmed.connect(func():
			var data: Variant = store.read_file(store.root.path_join("recovery.json"))
			if data != null and data.get("holes") is Array and not data.holes.is_empty():
				var codec := EditorCodec.new()
				var recovered := codec.decode(data.holes[0], "hole") as HoleDefinition
				if recovered != null:
					_open_document(EditorDocument.new(recovered))
					document.saved_text = ""
				else:
					_message(codec.error)
			else:
				_message(store.error)
		)
		dialog.popup_centered(Vector2i(520, 160))


func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font_size = 16
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("142831")
	panel.border_color = Color("34545c")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(5)
	panel.content_margin_left = 10
	panel.content_margin_right = 10
	panel.content_margin_top = 7
	panel.content_margin_bottom = 7
	theme.set_stylebox("normal", "Button", panel)
	var hover := panel.duplicate() as StyleBoxFlat
	hover.bg_color = Color("28515b")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", hover)
	theme.set_color("font_color", "Label", Color("d9e9e5"))
	theme.set_color("font_color", "Button", Color("e1eee7"))


func _clear_body() -> void:
	canvas = null
	inspector = null
	issues_list = null
	if is_instance_valid(body):
		remove_child(body)
		body.queue_free()
	else:
		var background := ColorRect.new()
		background.color = Color("0c1a22")
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(background)
	body = VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 16
	body.offset_top = 12
	body.offset_right = -16
	body.offset_bottom = -10
	body.add_theme_constant_override("separation", 10)
	add_child(body)


func _label(parent: Node, text: String, font_size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _scroll_column(parent: Node, width: float) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = width
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 7)
	scroll.add_child(column)
	return column


func show_editor() -> void:
	_clear_body()
	var heading := HBoxContainer.new()
	body.add_child(heading)
	title_label = _label(heading, "BAHNEDITOR", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(heading, "PUTT & PIXEL  /  BAUEN · PROBIEREN · TEILEN", 14)
	var toolbar := HBoxContainer.new()
	body.add_child(toolbar)
	_button(toolbar, "Neu", func(): _guard(func(): _open_document(EditorDocument.new())))
	_button(toolbar, "Bibliothek", show_library)
	_button(toolbar, "Vorlage", _template_dialog)
	_button(toolbar, "Speichern", _save)
	_button(toolbar, "Export", func(): _file_dialog(true, func(path: String): _report(store.write_file(path, store.payload([document.hole], [])), "Bahn exportiert")))
	_button(toolbar, "↶", func(): document.undo())
	_button(toolbar, "↷", func(): document.redo())
	golfer_choice = OptionButton.new()
	for id in GolferDefinition.IDS:
		golfer_choice.add_item(GolferDefinition.get_golfer(id).display_name)
	toolbar.add_child(golfer_choice)
	_button(toolbar, "▶ Testspiel", _test)
	_button(toolbar, "Menü", func(): _guard(_close))
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 12)
	body.add_child(main)
	var palette := _scroll_column(main, 184)
	_label(palette, "WERKZEUGE", 14)
	for entry in [["Auswahl / Verschieben", "select"], ["Kontur / Eckpunkte", "contour"], ["Außenbogen", "boundary_arc"], ["Abschlag", "tee"], ["Zielloch", "hole"], ["Zielrichtung", "aim"], ["Schalter verbinden", "link"]]:
		var key: String = entry[1]
		_button(palette, entry[0], func(): _tool(key))
	_button(palette, "Kontur neu zeichnen", func():
		document.begin()
		document.hole.lane_outline.points.clear()
		document.hole.lane_outline.boundary_arcs.clear()
		document.commit()
		_tool("contour")
	)
	_label(palette, "WÄNDE", 14)
	var wall_names := ["Ecke oben-rechts", "Ecke rechts-unten", "Ecke unten-links", "Ecke links-oben", "Diagonal ↘", "Diagonal ↗", "Waagerecht", "Senkrecht", "T oben", "T rechts", "T unten", "T links"]
	var walls := OptionButton.new()
	for name in wall_names:
		walls.add_item(name)
	walls.select(6)
	walls.item_selected.connect(func(index: int): _tool("wall", index))
	palette.add_child(walls)
	_button(palette, "Wand zeichnen", func(): _tool("wall", walls.selected))
	_button(palette, "Kreisbumper", func(): _tool("circle"))
	_button(palette, "Innenbogen", func(): _tool("arc"))
	_label(palette, "BELÄGE & GEFÄLLE", 14)
	for entry in [["Sand", 0], ["Wasser", 2], ["Beton", 3], ["Eis", 4]]:
		var value: int = entry[1]
		_button(palette, entry[0], func(): _tool("surface", value))
	var directions := OptionButton.new()
	for name in ["↑ Oben", "↗ Oben rechts", "→ Rechts", "↘ Unten rechts", "↓ Unten", "↙ Unten links", "← Links", "↖ Oben links"]:
		directions.add_item(name)
	directions.select(2)
	palette.add_child(directions)
	var grades := OptionButton.new()
	for name in ["Grün – flach", "Blau – mittel", "Rot – steil"]:
		grades.add_item(name)
	palette.add_child(grades)
	_button(palette, "Pfeile malen", func():
		canvas.arrow_direction = directions.selected
		canvas.arrow_grade = grades.selected
		_tool("arrow")
	)
	_button(palette, "Pfeilfeld aufziehen", func():
		canvas.arrow_direction = directions.selected
		canvas.arrow_grade = grades.selected
		_tool("arrow_rect")
	)
	_label(palette, "MECHANIKEN", 14)
	for index in range(5):
		var value := index
		_button(palette, ["Rotor", "Schiebetor", "Wippe", "Tunnelzahnrad", "Elefant"][index], func(): _tool("obstacle", value))
	for entry in [["Tunnelpaar", "tunnel"], ["Tempo-Rohr", "pipe"], ["Schalter", "trigger"], ["Kanone", "cannon"]]:
		var key: String = entry[1]
		_button(palette, entry[0], func(): _tool(key))
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(center)
	var view_bar := HBoxContainer.new()
	center.add_child(view_bar)
	_button(view_bar, "Auswahl", func(): _tool("select"))
	_button(view_bar, "Gesamtansicht", func(): canvas.fit())
	_button(view_bar, "Hilfen", func():
		canvas.show_helpers = not canvas.show_helpers
		canvas.queue_redraw()
	)
	_button(view_bar, "Duplizieren", func(): document.duplicate_selection())
	_button(view_bar, "Löschen", func(): canvas.delete_selected())
	canvas = EditorCanvas.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.add_child(canvas)
	canvas.configure(document)
	canvas.rebuild()
	canvas.selection_changed.connect(_refresh_inspector)
	canvas.hint_changed.connect(func(message: String): status.text = message)
	canvas.call_deferred("fit")
	issues_list = ItemList.new()
	issues_list.custom_minimum_size.y = 92
	issues_list.add_theme_font_size_override("font_size", 13)
	issues_list.item_selected.connect(_focus_issue)
	center.add_child(issues_list)
	inspector = _scroll_column(main, 260)
	status = _label(body, "Mausrad: Zoom  ·  Mitte: Verschieben  ·  Shift: Mehrfachauswahl  ·  Strg+Z/Y: Rückgängig/Wiederholen", 13)
	_refresh()


func _tool(key: String, subtype := 0) -> void:
	canvas.set_tool(key, subtype)
	var names := {"select": "Auswahl", "contour": "Kontur", "boundary_arc": "Außenbogen", "tee": "Abschlag", "hole": "Zielloch", "aim": "Zielrichtung", "link": "Schalter verbinden", "wall": "Wand", "circle": "Kreisbumper", "arc": "Innenbogen", "surface": "Belag", "arrow": "Pfeilpinsel", "arrow_rect": "Pfeilfeld", "obstacle": "Hindernis", "tunnel": "Tunnelpaar", "pipe": "Tempo-Rohr", "trigger": "Schalter", "cannon": "Kanone"}
	status.text = "Werkzeug: %s  ·  Ziehen zum Platzieren/Verschieben  ·  Escape bricht ab" % names.get(key, key)
	if key == "tunnel":
		status.text = "Tunnelpaar setzen · danach Enden einzeln oder das Paar am mittleren Griff verschieben"


func _document_changed() -> void:
	_autosave.start()
	if not _refresh_pending:
		_refresh_pending = true
		call_deferred("_refresh")


func _refresh() -> void:
	_refresh_pending = false
	if not is_instance_valid(canvas):
		return
	title_label.text = "%s%s" % [document.hole.display_name, " *" if document.dirty() else ""]
	_issues = document.issues()
	issues_list.clear()
	if _issues.is_empty():
		issues_list.add_item("✓ Daten gültig. PAR und Spielbarkeit bitte im Testspiel prüfen.")
	else:
		for issue in _issues:
			issues_list.add_item(("Hinweis: " if issue.get("severity", "error") == "warning" else "! ") + issue.message)
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not inspector.is_ancestor_of(focused):
		_refresh_inspector()


func _focus_issue(index: int) -> void:
	if index >= _issues.size():
		return
	var id: String = _issues[index].id
	if not id.is_empty():
		document.selection = [id]
		var resource := document.find(id)
		var point := EditorDocument.position_of(resource) if resource != null else canvas._marker_position(id)
		canvas.pan = canvas.size * 0.5 - point * canvas.zoom
		canvas._update_transform()
		_refresh_inspector()


func _refresh_inspector() -> void:
	if not is_instance_valid(inspector):
		return
	for child in inspector.get_children():
		inspector.remove_child(child)
		child.queue_free()
	_label(inspector, "EIGENSCHAFTEN", 14)
	var resource: Resource = document.hole
	if document.selection.size() == 1:
		var id := document.selection[0]
		if id.begins_with("boundary:"):
			var index := int(id.get_slice(":", 1))
			if index < document.hole.lane_outline.boundary_arcs.size():
				resource = document.hole.lane_outline.boundary_arcs[index]
		else:
			var selected := document.find(id)
			if selected != null:
				resource = selected
	var type_names := {"WallDefinition": "Kreis / Bogen", "WallTileDefinition": "Wandstück", "SurfaceDefinition": "Belag", "ArrowTileDefinition": "Gefällepfeil", "ObstacleDefinition": "Bewegliches Hindernis", "TriggerDefinition": "Schalter", "CannonDefinition": "Kanone", "TunnelDefinition": "Tunnelpaar", "PipeSystemDefinition": "Tempo-Rohr"}
	_label(inspector, "Bahn" if resource == document.hole else type_names.get(String(resource.get_script().get_global_name()), "Bauteil"), 17)
	if document.selection.size() > 1:
		_label(inspector, "%d Elemente ausgewählt" % document.selection.size(), 14)
	if resource == document.hole:
		_field(resource, "display_name", "Name")
		_field(resource, "par", "PAR")
		_vector_field("Bahngröße", document.hole.course_rect.size, func(value: Vector2):
			document.begin()
			document.resize_course(value)
			document.commit()
		)
		_field(resource, "base_surface", "Grundbelag")
		var themes := OptionButton.new()
		for id in EditorCodec.THEMES:
			themes.add_item(id.capitalize())
		if document.hole.theme != null:
			themes.select(maxi(0, EditorCodec.THEMES.find(String(document.hole.theme.theme_id))))
		inspector.add_child(themes)
		themes.item_selected.connect(func(index: int): _set_field(document.hole, "theme", load("res://data/themes/%s.tres" % EditorCodec.THEMES[index])))
		_field(resource, "tee_position", "Abschlag")
		_field(resource, "hole_position", "Zielloch")
		_field(resource, "initial_aim_offset", "Zielrichtung")
	else:
		if resource is WallDefinition and resource in document.items("boundary_arcs") and document.boundary_edge(resource) >= 0:
			_label(inspector, "Auswölbung (+ / −)", 13)
			_number(inspector, document.boundary_bulge(resource), func(value: float):
				document.begin()
				document.set_boundary_bulge(resource, value)
				document.commit()
			)
			_label(inspector, "Die Endpunkte bleiben verankert.", 13)
		else:
			for property in EditorCodec.fields(resource):
				var key: String = property.name
				if _visible_property(resource, key):
					_field(resource, key, _property_label(key))
		if resource is SurfaceDefinition:
			_button(inspector, "Fläche eine Ebene höher", func(): _reorder_surface(resource, 1))
			_button(inspector, "Fläche eine Ebene tiefer", func(): _reorder_surface(resource, -1))
		if resource is CannonDefinition:
			_button(inspector, "Schalterverbindung lösen", func():
				document.begin()
				for trigger in document.hole.triggers:
					trigger.target_ids.erase(resource.mechanism_id)
				resource.required_trigger_id = &""
				document.commit()
			)
	_button(inspector, "Bahneigenschaften", func():
		document.selection.clear()
		_refresh_inspector()
	)


func _visible_property(resource: Resource, key: String) -> bool:
	if key in ["mechanism_id", "trigger_id", "required_trigger_id", "target_ids", "trigger_type", "wall_type", "obstacle_type", "cell_size", "minimum_flow_speed", "maximum_flow_speed", "flow_alignment_rate", "flow_centering_strength", "clip_polygon"]:
		return false
	if resource is ArrowTileDefinition and key == "deceleration":
		return false
	if resource is SurfaceDefinition and key in ["acceleration", "slope_direction", "slope_strength"]:
		return false
	if resource is WallDefinition:
		if key in ["size", "rotation_degrees"]:
			return false
		if resource.wall_type == WallDefinition.WallType.CIRCLE and key != "center" and key != "radius":
			return false
		if key == "thickness":
			return false
	if resource is ObstacleDefinition:
		if key == "position" or key == "start_rotation_degrees":
			return true
		match resource.obstacle_type:
			0: return key in ["blade_size", "seconds_per_revolution", "impulse_multiplier", "minimum_kick_speed"]
			1: return key in ["gate_size", "open_offset", "cycle_seconds", "transition_seconds", "open_hold_seconds", "phase_offset_seconds"]
			2: return key.begins_with("seesaw_")
			3: return key in ["gear_links", "seconds_per_revolution"]
			4: return key.begins_with("elephant_")
	return true


func _property_label(key: String) -> String:
	var names := {"position": "Position", "center": "Mittelpunkt", "radius": "Radius", "rect": "Fläche (X, Y, Breite, Höhe)", "rotation_degrees": "Drehung", "start_rotation_degrees": "Ausrichtung", "grid_cell": "Rasterzelle", "grid_offset": "Rasterversatz", "variant": "Wandstück", "direction": "Richtung", "slope_grade": "Gefällestärke", "endpoint_a": "Tunnel A", "endpoint_b": "Tunnel B", "entrance": "Rohreingang", "exits": "Ausgänge: langsam / passend / schnell", "exit_directions": "Ausgangsrichtungen", "landing_position": "Landeposition", "entry_direction": "Einfahrtrichtung", "landing_velocity": "Geschwindigkeit nach Landung", "gear_links": "Zahnradpaare (0–7)", "arc_start_degrees": "Bogenbeginn (Grad)", "arc_sweep_degrees": "Bogenwinkel", "arc_segments": "Bogensegmente", "surface_type": "Belag", "deceleration": "Rollwiderstand", "capture_size": "Aufnahmebereich", "intake_seconds": "Einzug (Sekunden)", "ignition_seconds": "Zündverzögerung (Sekunden)", "flight_seconds": "Flugdauer (Sekunden)", "arc_height": "Flughöhe", "blade_size": "Rotorgröße", "seconds_per_revolution": "Sekunden pro Umdrehung", "impulse_multiplier": "Kontaktimpuls (Faktor)", "minimum_kick_speed": "Mindestimpuls", "gate_size": "Torgröße", "open_offset": "Öffnungsweg", "cycle_seconds": "Zyklusdauer (Sekunden)", "transition_seconds": "Bewegungsdauer (Sekunden)", "open_hold_seconds": "Offen halten (Sekunden)", "phase_offset_seconds": "Zeitversatz (Sekunden)", "seesaw_size": "Wippengröße", "seesaw_max_angle_degrees": "Maximale Neigung", "seesaw_response_seconds": "Kippdauer (Sekunden)", "seesaw_slope_strength": "Gefällekraft", "seesaw_end_lip_thickness": "Stirnkantenstärke", "seesaw_blocker_tilt_threshold": "Freigabeschwelle", "seesaw_preferred_tilt": "Ruhelage (−1 bis 1)", "elephant_intake": "Aufnahme (lokal)", "elephant_exit": "Ausgang (lokal)", "elephant_gate_size": "Rüsselgröße", "elephant_gate_offset": "Rüsselweg", "elephant_intake_radius": "Aufnahmeradius", "elephant_exit_speed": "Ausgangstempo", "elephant_transport_seconds": "Transportdauer (Sekunden)", "elephant_cycle_seconds": "Elefantenzyklus (Sekunden)", "size": "Größe"}
	return names.get(key, key.replace("_", " ").capitalize())


func _field(resource: Resource, key: String, label: String) -> void:
	var value: Variant = resource.get(key)
	var property := {}
	for candidate in EditorCodec.fields(resource):
		if candidate.name == key:
			property = candidate
	if property.is_empty():
		return
	if value is Vector2 or value is Vector2i:
		_vector_field(label, Vector2(value), func(next: Vector2): _set_field(resource, key, Vector2i(next) if value is Vector2i else next))
	elif value is Rect2:
		_vector_field(label, value.position, func(next: Vector2):
			var rect: Rect2 = resource.get(key)
			rect.position = next
			_set_field(resource, key, rect)
		)
		_vector_field("Breite / Höhe", value.size, func(next: Vector2):
			var rect: Rect2 = resource.get(key)
			rect.size = next
			_set_field(resource, key, rect)
		)
	elif value is PackedVector2Array:
		_label(inspector, label, 13)
		for index in range(value.size()):
			var item := index
			_vector_field(str(index + 1), value[index], func(next: Vector2):
				var points: PackedVector2Array = resource.get(key)
				points[item] = next
				_set_field(resource, key, points)
			)
	elif value is PackedInt32Array:
		_label(inspector, label, 13)
		var line := LineEdit.new()
		var parts := PackedStringArray()
		for item in value:
			parts.append(str(item))
		line.text = ",".join(parts)
		inspector.add_child(line)
		line.text_submitted.connect(func(text: String):
			var values := PackedInt32Array()
			for part in text.split(","):
				if not part.strip_edges().is_valid_int():
					_message("Bitte durch Kommas getrennte Ganzzahlen eingeben")
					return
				values.append(int(part))
			_set_field(resource, key, values)
		)
	elif property.hint == PROPERTY_HINT_ENUM:
		_label(inspector, label, 13)
		var choice := OptionButton.new()
		var index := 0
		for option in String(property.hint_string).split(","):
			var id := int(option.get_slice(":", 1)) if ":" in option else index
			choice.add_item(option.get_slice(":", 0), id)
			if id == value:
				choice.select(index)
			index += 1
		inspector.add_child(choice)
		choice.item_selected.connect(func(selected: int): _set_field(resource, key, choice.get_item_id(selected)))
	elif value is int or value is float:
		_label(inspector, label, 13)
		_number(inspector, float(value), func(next: float): _set_field(resource, key, int(next) if value is int else next), 1.0 if value is int else 0.1)
	elif value is String or value is StringName:
		_label(inspector, label, 13)
		var line := LineEdit.new()
		line.text = value
		line.max_length = 100
		inspector.add_child(line)
		line.text_submitted.connect(func(next: String): _set_field(resource, key, next))
		line.focus_exited.connect(func():
			if is_instance_valid(line) and line.text != resource.get(key):
				_set_field(resource, key, line.text)
		)


func _number(parent: Node, value: float, callback: Callable, step := 1.0) -> SpinBox:
	var spin := SpinBox.new()
	spin.min_value = -100000
	spin.max_value = 100000
	spin.step = step
	spin.value = value
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.custom_minimum_size.x = 90
	parent.add_child(spin)
	spin.value_changed.connect(callback)
	return spin


func _vector_field(label: String, value: Vector2, callback: Callable) -> void:
	_label(inspector, label, 13)
	var row := HBoxContainer.new()
	inspector.add_child(row)
	var x_spin := _number(row, value.x, func(_x: float): pass)
	var y_spin := _number(row, value.y, func(_y: float): pass)
	x_spin.value_changed.connect(func(x: float): callback.call(Vector2(x, y_spin.value)))
	y_spin.value_changed.connect(func(y: float): callback.call(Vector2(x_spin.value, y)))


func _set_field(resource: Resource, key: String, value: Variant) -> void:
	if resource.get(key) == value:
		return
	document.begin()
	resource.set(key, value)
	document.commit()


func _reorder_surface(resource: Resource, direction: int) -> void:
	var index := document.hole.surfaces.find(resource)
	var next := clampi(index + direction, 0, document.hole.surfaces.size() - 1)
	document.begin()
	document.hole.surfaces.remove_at(index)
	document.hole.surfaces.insert(next, resource)
	document.commit()


func _open_document(value: EditorDocument) -> void:
	if document.changed.is_connected(_document_changed):
		document.changed.disconnect(_document_changed)
	document = value
	document.changed.connect(_document_changed)
	show_editor()


func _save() -> void:
	if store.save_hole(document.hole):
		document.mark_saved()
		_clear_recovery()
		_refresh()
		if is_instance_valid(status):
			status.text = "Bahn gespeichert"
	else:
		_message(store.error)


func _write_recovery() -> void:
	if document.dirty():
		if not store.write_file(store.root.path_join("recovery.json"), store.payload([document.hole], [])):
			if is_instance_valid(status):
				status.text = "Automatische Sicherung fehlgeschlagen: " + store.error


func _clear_recovery() -> void:
	_autosave.stop()
	if FileAccess.file_exists(store.root.path_join("recovery.json")):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.root.path_join("recovery.json")))


func _guard(action: Callable) -> void:
	if not document.dirty():
		action.call()
		return
	var dialog := ConfirmationDialog.new()
	dialog.cancel_button_text = "Abbrechen"
	dialog.title = "Ungespeicherte Änderungen"
	dialog.dialog_hide_on_ok = false
	dialog.dialog_text = "Änderungen vor dem Verlassen speichern?"
	dialog.ok_button_text = "Speichern"
	dialog.add_button("Verwerfen", false, "discard")
	add_child(dialog)
	dialog.confirmed.connect(func():
		_save()
		if not document.dirty():
			dialog.hide()
			action.call()
	)
	dialog.custom_action.connect(func(_name: StringName):
		dialog.hide()
		_clear_recovery()
		action.call()
	)
	dialog.popup_centered(Vector2i(500, 160))


func _close() -> void:
	get_window().content_scale_size = Vector2i(640, 360)
	get_tree().auto_accept_quit = _previous_auto_quit
	closed.emit()


func _exit_tree() -> void:
	get_tree().auto_accept_quit = _previous_auto_quit


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		_guard(func(): get_tree().quit())


func _message(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Bahneditor"
	dialog.dialog_text = text
	add_child(dialog)
	dialog.popup_centered(Vector2i(560, 180))
	dialog.confirmed.connect(dialog.queue_free)


func _report(success: bool, message: String) -> void:
	_message(message if success else store.error)


func _file_dialog(save: bool, action: Callable) -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.json ; Putt & Pixel Bahnen/Kurse"])
	dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	dialog.current_file = "Meine-Bahn.json" if save else ""
	add_child(dialog)
	dialog.file_selected.connect(action)
	dialog.file_selected.connect(func(_path: String): dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(950, 560))


func _template_dialog() -> void:
	_guard(func():
		var dialog := AcceptDialog.new()
		dialog.title = "Spielbahn als eigene Kopie öffnen"
		var list := ItemList.new()
		list.custom_minimum_size = Vector2(720, 400)
		var templates: Array[HoleDefinition] = []
		for hole in HoleCatalog.load_default().holes:
			if hole.is_course_hole():
				templates.append(hole)
				list.add_item("%s  /  PAR %d" % [hole.display_name, hole.par])
		dialog.add_child(list)
		add_child(dialog)
		dialog.ok_button_text = "Kopie öffnen"
		dialog.confirmed.connect(func():
			if not list.get_selected_items().is_empty():
				_open_document(EditorDocument.new(templates[list.get_selected_items()[0]], true))
			dialog.queue_free()
		)
		dialog.popup_centered(Vector2i(760, 470))
	)


func _test() -> void:
	if not document.blocking_issues().is_empty():
		_message("Bitte zuerst die markierten Datenfehler beheben. Der Entwurf kann jederzeit gespeichert werden.")
		return
	var test := EditorPlaytest.new()
	test.definition = document.hole.duplicate(true)
	test.golfer_id = GolferDefinition.IDS[golfer_choice.selected]
	var previous_pan := canvas.pan
	var previous_zoom := canvas.zoom
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	test.closed.connect(func():
		get_window().content_scale_size = Vector2i(1280, 720)
		process_mode = Node.PROCESS_MODE_ALWAYS
		show()
		canvas.pan = previous_pan
		canvas.zoom = previous_zoom
		canvas._update_transform()
		test.queue_free()
	)
	get_parent().add_child(test)


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not event.pressed or event.echo:
		return
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
		return
	if event.ctrl_pressed:
		match event.keycode:
			KEY_S: _save()
			KEY_Z: document.undo()
			KEY_Y: document.redo()
			KEY_D: document.duplicate_selection()
			_: return
		get_viewport().set_input_as_handled()


func show_library() -> void:
	_clear_body()
	var header := HBoxContainer.new()
	body.add_child(header)
	_label(header, "EIGENE INHALTE", 26).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(header, "Zum Entwurf", show_editor)
	_button(header, "Importieren", func(): _file_dialog(false, func(path: String):
		if store.import_file(path):
			show_library()
		else:
			_message(store.error)
	))
	_button(header, "Menü", func(): _guard(_close))
	var tabs := HBoxContainer.new()
	body.add_child(tabs)
	_button(tabs, "Bahnen", func():
		_library_tab = 0
		show_library()
	)
	_button(tabs, "Kurse", func():
		_library_tab = 1
		show_library()
	)
	_button(tabs, "Neue Bahn", func(): _guard(func(): _open_document(EditorDocument.new())))
	_button(tabs, "Neuer Kurs", func(): _edit_course(null))
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(main)
	_library_list = ItemList.new()
	_library_list.custom_minimum_size.x = 410
	_library_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(_library_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(right)
	_library_preview = EditorCanvas.new()
	_library_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_library_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_library_preview.show_helpers = false
	right.add_child(_library_preview)
	var row := HBoxContainer.new()
	right.add_child(row)
	_button(row, "Bearbeiten", _edit_selected)
	_button(row, "Spielen", _play_selected)
	_button(row, "Exportieren", _export_selected)
	_button(row, "Löschen", _delete_selected)
	status = _label(body, "Eigene Inhalte werden lokal gespeichert. Doppelklick öffnet die Bearbeitung.", 14)
	if _library_tab == 0:
		for hole in store.holes:
			var valid := EditorDocument.new(hole).blocking_issues().is_empty()
			_library_list.add_item("%s  /  PAR %d%s" % [hole.display_name, hole.par, "" if valid else "  [Entwurf]"])
	else:
		for course in store.courses:
			var best := BestScoreStore.new(store.root.path_join("progress.cfg")).get_best(store.best_key(course))
			_library_list.add_item("%s  /  %d Bahnen%s" % [course.display_name, course.hole_ids.size(), "  /  Bestwert %d" % best if best >= 0 else ""])
	_library_list.item_selected.connect(_preview_selected)
	_library_list.item_activated.connect(func(_index: int): _edit_selected())
	if _library_list.item_count > 0:
		_library_list.select(0)
		_preview_selected(0)


func _preview_selected(index: int) -> void:
	var hole: HoleDefinition
	if _library_tab == 0:
		hole = store.holes[index]
	else:
		hole = store.get_hole(store.courses[index].hole_ids[0])
	if hole != null:
		_library_preview.configure(EditorDocument.new(hole))
		_library_preview.rebuild()
		_library_preview.call_deferred("fit")


func _selected_index() -> int:
	return -1 if _library_list.get_selected_items().is_empty() else _library_list.get_selected_items()[0]


func _edit_selected() -> void:
	var index := _selected_index()
	if index < 0:
		return
	if _library_tab == 0:
		_guard(func(): _open_document(EditorDocument.new(store.holes[index])))
	else:
		_edit_course(store.courses[index])


func _export_selected() -> void:
	var index := _selected_index()
	if index < 0:
		return
	_file_dialog(true, func(path: String):
		var success := store.write_file(path, store.payload([store.holes[index]], [])) if _library_tab == 0 else store.export_course(store.courses[index], path)
		_report(success, "Datei exportiert")
	)


func _delete_selected() -> void:
	var index := _selected_index()
	if index < 0:
		return
	var dialog := ConfirmationDialog.new()
	dialog.cancel_button_text = "Abbrechen"
	dialog.dialog_text = "Ausgewählten Inhalt aus der Bibliothek löschen?"
	add_child(dialog)
	dialog.confirmed.connect(func():
		var success := store.delete_hole(store.holes[index].hole_id) if _library_tab == 0 else store.delete_course(store.courses[index])
		if success:
			show_library()
		else:
			_message(store.error)
		dialog.queue_free()
	)
	dialog.popup_centered()


func _edit_course(source: CourseDefinition) -> void:
	_course_work = source.duplicate(true) if source != null else CourseDefinition.new()
	if source == null:
		_course_work.course_id = EditorCodec.new_id()
		_course_work.display_name = "Mein Kurs"
	var dialog := ConfirmationDialog.new()
	dialog.cancel_button_text = "Abbrechen"
	dialog.title = "Kurs zusammenstellen"
	dialog.dialog_hide_on_ok = false
	dialog.ok_button_text = "Kurs speichern"
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(850, 440)
	dialog.add_child(column)
	_course_name = LineEdit.new()
	_course_name.text = _course_work.display_name
	column.add_child(_course_name)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	_course_holes = ItemList.new()
	_course_holes.custom_minimum_size.x = 380
	row.add_child(_course_holes)
	for hole in store.holes:
		_course_holes.add_item(hole.display_name)
	_course_holes.item_activated.connect(func(index: int): _append_course_hole(index))
	var commands := VBoxContainer.new()
	row.add_child(commands)
	_button(commands, "Hinzufügen →", func():
		if not _course_holes.get_selected_items().is_empty():
			_append_course_hole(_course_holes.get_selected_items()[0])
	)
	_button(commands, "↑", func(): _move_course_hole(-1))
	_button(commands, "↓", func(): _move_course_hole(1))
	_button(commands, "Entfernen", func():
		if not _course_sequence.get_selected_items().is_empty():
			_course_work.hole_ids.remove_at(_course_sequence.get_selected_items()[0])
			_refresh_course_sequence()
	)
	_course_sequence = ItemList.new()
	_course_sequence.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_course_sequence)
	_refresh_course_sequence()
	_label(column, "1 bis 9 Bahnen · Wiederholungen erlaubt · Änderungen an Bahnen gelten auch im Kurs", 13)
	add_child(dialog)
	dialog.confirmed.connect(func():
		_course_work.display_name = _course_name.text
		if store.save_course(_course_work):
			_library_tab = 1
			show_library()
			dialog.hide()
			dialog.queue_free()
		else:
			_message(store.error)
	)
	dialog.popup_centered(Vector2i(890, 520))


func _append_course_hole(index: int) -> void:
	if _course_work.hole_ids.size() < 9:
		_course_work.hole_ids.append(store.holes[index].hole_id)
		_refresh_course_sequence()


func _refresh_course_sequence() -> void:
	_course_sequence.clear()
	for index in range(_course_work.hole_ids.size()):
		var hole := store.get_hole(_course_work.hole_ids[index])
		_course_sequence.add_item("%d. %s" % [index + 1, hole.display_name if hole != null else "Fehlende Bahn"])


func _move_course_hole(direction: int) -> void:
	if _course_sequence.get_selected_items().is_empty():
		return
	var index := _course_sequence.get_selected_items()[0]
	var next := clampi(index + direction, 0, _course_work.hole_ids.size() - 1)
	var id := _course_work.hole_ids[index]
	_course_work.hole_ids.remove_at(index)
	_course_work.hole_ids.insert(next, id)
	_refresh_course_sequence()
	_course_sequence.select(next)


func _play_selected() -> void:
	var index := _selected_index()
	if index < 0:
		return
	var course: CourseDefinition
	if _library_tab == 1:
		course = store.courses[index]
	else:
		course = CourseDefinition.new()
		course.course_id = &"custom_practice"
		course.display_name = store.holes[index].display_name
		course.hole_ids = [store.holes[index].hole_id]
	for id in course.hole_ids:
		var hole := store.get_hole(id)
		if hole == null or not EditorDocument.new(hole).blocking_issues().is_empty():
			_message("Diese Auswahl enthält einen Entwurf mit Datenfehlern. Bitte zuerst bearbeiten.")
			return
	var dialog := ConfirmationDialog.new()
	dialog.cancel_button_text = "Abbrechen"
	dialog.title = "Spieler für „%s“" % course.display_name
	dialog.ok_button_text = "Spielen"
	var column := VBoxContainer.new()
	dialog.add_child(column)
	var count := OptionButton.new()
	for number in range(1, 5):
		count.add_item("%d Spieler" % number)
	column.add_child(count)
	var names: Array[LineEdit] = []
	var golfers: Array[OptionButton] = []
	for number in range(4):
		var row := HBoxContainer.new()
		column.add_child(row)
		var name := LineEdit.new()
		name.text = "Spieler %d" % (number + 1)
		name.max_length = 12
		row.add_child(name)
		names.append(name)
		var golfer := OptionButton.new()
		for id in GolferDefinition.IDS:
			golfer.add_item(GolferDefinition.get_golfer(id).display_name)
		row.add_child(golfer)
		golfers.append(golfer)
	add_child(dialog)
	dialog.confirmed.connect(func():
		var players: Array[PlayerProfile] = []
		for number in range(count.selected + 1):
			players.append(PlayerProfile.create(number + 1, names[number].text, number, GolferDefinition.IDS[golfers[number].selected]))
		_guard(func(): play_requested.emit(course, players))
	)
	dialog.popup_centered(Vector2i(540, 280))
