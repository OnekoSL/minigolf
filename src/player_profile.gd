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
@export var golfer_id := &"allrounder"
@export var test_golfer: GolferDefinition


static func create(id: int, name: String, palette: int, golfer := &"allrounder", test_definition: GolferDefinition = null) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.player_id = clampi(id, 1, 4)
	profile.player_name = sanitize_name(name, profile.player_id)
	profile.palette_id = clampi(palette, 0, PALETTE_COLORS.size() - 1)
	profile.golfer_id = golfer
	if golfer == &"don" and test_definition != null:
		profile.test_golfer = test_definition.duplicate() as GolferDefinition
	return profile


func get_golfer_definition() -> GolferDefinition:
	if golfer_id == &"don" and test_golfer != null:
		return test_golfer
	return GolferDefinition.get_golfer(golfer_id)


static func sanitize_name(value: String, fallback_id: int) -> String:
	var clean := value.strip_edges()
	if clean.is_empty():
		return I18n.text("TEXT_PLAYER_385") % clampi(fallback_id, 1, 4)
	return clean.left(12)


func get_color() -> Color:
	return PALETTE_COLORS[clampi(palette_id, 0, PALETTE_COLORS.size() - 1)]


func get_palette_name() -> String:
	return I18n.source(PALETTE_NAMES[clampi(palette_id, 0, PALETTE_NAMES.size() - 1)])
