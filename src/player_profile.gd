class_name PlayerProfile
extends Resource

const PALETTE_NAMES := ["TUERKIS", "MAGENTA", "GOLD", "VIOLETT"]
const PALETTE_COLORS := [
	Color("#49d6cf"),
	Color("#ee66cf"),
	Color("#f0c45b"),
	Color("#9b7bea"),
]

@export_range(1, 4, 1) var player_id := 1
@export var player_name := "SPIELER 1"
@export_range(0, 3, 1) var palette_id := 0


static func create(id: int, name: String, palette: int) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_id = clampi(id, 1, 4)
	profile.player_name = sanitize_name(name, profile.player_id)
	profile.palette_id = clampi(palette, 0, PALETTE_COLORS.size() - 1)
	return profile


static func sanitize_name(value: String, fallback_id: int) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return "SPIELER %d" % clampi(fallback_id, 1, 4)
	return clean.left(12)


func get_color() -> Color:
	return PALETTE_COLORS[clampi(palette_id, 0, PALETTE_COLORS.size() - 1)]


func get_palette_name() -> String:
	return PALETTE_NAMES[clampi(palette_id, 0, PALETTE_NAMES.size() - 1)]
