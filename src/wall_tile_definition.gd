class_name WallTileDefinition
extends Resource

enum Variant {
	CORNER_UP_RIGHT,
	CORNER_RIGHT_DOWN,
	CORNER_DOWN_LEFT,
	CORNER_LEFT_UP,
	DIAGONAL_DOWN,
	DIAGONAL_UP,
	HORIZONTAL,
	VERTICAL,
}

const CELL_SIZE := 16
const THICKNESS := 4.0

@export var grid_cell := Vector2i.ZERO
@export_enum("Ecke oben-rechts", "Ecke rechts-unten", "Ecke unten-links", "Ecke links-oben", "Diagonal abwaerts", "Diagonal aufwaerts", "Waagerecht", "Senkrecht") var variant: int = Variant.HORIZONTAL


func validate(label: String, grid_spacing: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if grid_spacing <= 0 or CELL_SIZE % grid_spacing != 0:
		errors.append("%s liegt nicht im Bahnraster" % label)
	if variant < Variant.CORNER_UP_RIGHT or variant > Variant.VERTICAL:
		errors.append("%s besitzt keine der acht Wandvarianten" % label)
	return errors


func get_cell_rect() -> Rect2:
	return Rect2(Vector2(grid_cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))


func get_segments() -> Array[PackedVector2Array]:
	var rect := get_cell_rect()
	var center := rect.get_center()
	var top := Vector2(center.x, rect.position.y)
	var right := Vector2(rect.end.x, center.y)
	var bottom := Vector2(center.x, rect.end.y)
	var left := Vector2(rect.position.x, center.y)
	var segments: Array[PackedVector2Array] = []
	match variant:
		Variant.CORNER_UP_RIGHT:
			segments = [_segment(top, center), _segment(center, right)]
		Variant.CORNER_RIGHT_DOWN:
			segments = [_segment(right, center), _segment(center, bottom)]
		Variant.CORNER_DOWN_LEFT:
			segments = [_segment(bottom, center), _segment(center, left)]
		Variant.CORNER_LEFT_UP:
			segments = [_segment(left, center), _segment(center, top)]
		Variant.DIAGONAL_DOWN:
			segments = [_segment(rect.position, rect.end)]
		Variant.DIAGONAL_UP:
			segments = [_segment(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y))]
		Variant.HORIZONTAL:
			segments = [_segment(left, right)]
		Variant.VERTICAL:
			segments = [_segment(top, bottom)]
	return segments


static func _segment(start: Vector2, end: Vector2) -> PackedVector2Array:
	return PackedVector2Array([start, end])
