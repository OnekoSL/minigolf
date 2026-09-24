extends Node

var failures := 0
var checks := 0


func _ready() -> void:
	call_deferred("run")


func verify(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print("%s %s" % ["OK" if condition else "FEHLER", message])


func run() -> void:
	var manager := get_node("/root/SettingsManager")
	var window := get_window()
	manager.begin()
	manager.draft.window_size = 0
	manager.preview()
	await get_tree().create_timer(0.3).timeout
	verify(window.mode == Window.MODE_WINDOWED and window.size.x <= 1280 and window.size.y <= 720, "Fenstergröße 1280×720 wird angewendet und auf den Bildschirm begrenzt")
	manager.confirm_display()
	manager.draft.fullscreen = true
	manager.preview()
	await get_tree().create_timer(0.3).timeout
	verify(window.mode == Window.MODE_FULLSCREEN, "Randloses Vollbild wird angewendet")
	manager._process(15.1)
	await get_tree().create_timer(0.3).timeout
	verify(window.mode == Window.MODE_WINDOWED and not manager.draft.fullscreen, "Unbestätigtes Vollbild kehrt automatisch ins Fenster zurück")
	manager.draft.vsync = false
	manager.preview()
	await get_tree().create_timer(0.3).timeout
	verify(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "VSync kann abgeschaltet werden")
	manager.confirm_display()
	manager.cancel()
	await get_tree().create_timer(0.3).timeout
	verify(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED and not manager.current.fullscreen, "Abbrechen stellt Anzeige und VSync wieder her")
	verify(window.content_scale_size == Vector2i(640, 360), "Interne Spielauflösung bleibt 640×360")
	print("Anzeigeprobe: %d Checks, %d Fehler" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
