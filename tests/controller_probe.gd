extends Node


func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	var joypads := Input.get_connected_joypads()
	print("Gefundene Controller: ", joypads.size())
	var ps3_found := false
	for id in joypads:
		var joy_name := Input.get_joy_name(id)
		var guid := Input.get_joy_guid(id)
		var known := Input.is_joy_known(id)
		print("ID=%d Name=%s GUID=%s SDL-bekannt=%s Info=%s" % [id, joy_name, guid, known, Input.get_joy_info(id)])
		if "PS3" in joy_name or ("4c05" in guid.to_lower() and "6802" in guid.to_lower()):
			ps3_found = known
	if not ps3_found:
		push_error("Der angeschlossene PS3-Controller wurde nicht mit bekannter SDL-Zuordnung gefunden.")
	get_tree().quit(0 if ps3_found else 1)

