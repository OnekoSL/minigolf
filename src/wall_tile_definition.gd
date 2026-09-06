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
	T_UP,
	T_RIGHT,
	T_DOWN,
	T_LEFT,
}

const CELL_SIZE := 16
const THICKNESS := 4.0

@export var grid_cell := Vector2i.ZERO
@export_enum("Ecke oben-rechts", "Ecke rechts-unten", "Ecke unten-links", "Ecke links-oben", "Diagonal abwaerts", "Diagonal aufwaerts", "Waagerecht", "Senkrecht", "T oben", "T rechts", "T unten", "T links") var variant: int = Variant.HORIZONTAL


func validate(label: String, grid_spacing: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if grid_spacing <= 0 or CELL_SIZE % grid_spacing != 0:
		errors.append("%s liegt nicht im Bahnraster" % label)
	if variant < Variant.CORNER_UP_RIGHT or variant > Variant.T_LEFT:
		errors.append("%s besitzt keine der zwoelf Wandvarianten" % label)
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
		Variant.T_UP:
			segments = [_segment(center, top), _segment(center, right), _segment(center, left)]
		Variant.T_RIGHT:
			segments = [_segment(center, right), _segment(center, bottom), _segment(center, top)]
		Variant.T_DOWN:
			segments = [_segment(center, bottom), _segment(center, left), _segment(center, right)]
		Variant.T_LEFT:
			segments = [_segment(center, left), _segment(center, top), _segment(center, bottom)]
	return segments


static func get_cardinal_mask(value: int) -> int:
	match value:
		Variant.CORNER_UP_RIGHT:
			return 1 | 2
		Variant.CORNER_RIGHT_DOWN:
			return 2 | 4
		Variant.CORNER_DOWN_LEFT:
			return 4 | 8
		Variant.CORNER_LEFT_UP:
			return 8 | 1
		Variant.HORIZONTAL:
			return 8 | 2
		Variant.VERTICAL:
			return 1 | 4
		Variant.T_UP:
			return 1 | 2 | 8
		Variant.T_RIGHT:
			return 1 | 2 | 4
		Variant.T_DOWN:
			return 2 | 4 | 8
		Variant.T_LEFT:
			return 1 | 4 | 8
	return 0


static func variant_from_cardinal_mask(mask: int) -> int:
	match mask:
		1 | 2:
			return Variant.CORNER_UP_RIGHT
		2 | 4:
			return Variant.CORNER_RIGHT_DOWN
		4 | 8:
			return Variant.CORNER_DOWN_LEFT
		8 | 1:
			return Variant.CORNER_LEFT_UP
		8 | 2:
			return Variant.HORIZONTAL
		1 | 4:
			return Variant.VERTICAL
		1 | 2 | 8:
			return Variant.T_UP
		1 | 2 | 4:
			return Variant.T_RIGHT
		2 | 4 | 8:
			return Variant.T_DOWN
		1 | 4 | 8:
			return Variant.T_LEFT
	return -1


static func segments_from_cardinal_mask(cell: Vector2i, mask: int) -> Array[PackedVector2Array]:
	var rect := Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
	var center := rect.get_center()
	var segments: Array[PackedVector2Array] = []
	if mask & 1:
		segments.append(_segment(center, Vector2(center.x, rect.position.y)))
	if mask & 2:
		segments.append(_segment(center, Vector2(rect.end.x, center.y)))
	if mask & 4:
		segments.append(_segment(center, Vector2(center.x, rect.end.y)))
	if mask & 8:
		segments.append(_segment(center, Vector2(rect.position.x, center.y)))
	return segments


static func _segment(start: Vector2, end: Vector2) -> PackedVector2Array:
	return PackedVector2Array([start, end])
