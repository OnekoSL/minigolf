extends SceneTree


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	if arguments.size()!=1:
		quit(1)
		return
	var file := FileAccess.open(arguments[0],FileAccess.WRITE)
	if file == null:
		push_error("Lizenzdatei konnte nicht geschrieben werden")
		quit(1)
		return
	file.store_string("GODOT ENGINE\n\n"+Engine.get_license_text()+"\n\nTHIRD-PARTY COPYRIGHT NOTICES\n\n")
	for component in Engine.get_copyright_info():
		file.store_string(JSON.stringify(component,"\t")+"\n\n")
	file.store_string("THIRD-PARTY LICENSE TEXTS\n\n")
	var licenses := Engine.get_license_info()
	for name in licenses:
		file.store_string(String(name)+"\n\n"+String(licenses[name])+"\n\n")
	file.close()
	quit()
