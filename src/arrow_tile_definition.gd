class_name ArrowTileDefinition
extends Resource

const CELL_SIZE := 16
const DECELERATION := 30.0

@export var grid_cell := Vector2i.ZERO
@export var grid_offset := Vector2i.ZERO
# Optional cut edge, in cell-local coordinates (0..16). The grid stays square.
@export var clip_polygon := PackedVector2Array()
@export_range(8, 128, 1) var cell_size := CELL_SIZE
@export_enum("Oben", "Oben rechts", "Rechts", "Unten rechts", "Unten", "Unten links", "Links", "Oben links") var direction: int = SurfaceZone.SlopeDirection.UP
@export_enum("Flach", "Mittel", "Steil") var slope_grade: int = SurfaceZone.SlopeGrade.SHALLOW
@export var deceleration := DECELERATION
@export_range(0.0, 300.0, 1.0) var minimum_flow_speed := 0.0
@export_range(0.0, 500.0, 1.0) var maximum_flow_speed := 0.0
@export_range(0.0, 30.0, 0.5) var flow_alignment_rate := 0.0
@export_range(0.0, 30.0, 0.5) var flow_centering_strength := 0.0


func validate(label: String, grid_spacing: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if cell_size != CELL_SIZE:
		errors.append("%s muss exakt %d x %d Pixel gross sein" % [label, CELL_SIZE, CELL_SIZE])
	if grid_spacing <= 0 or cell_size % grid_spacing != 0:
		errors.append("%s liegt nicht im Bahnraster" % label)
	var half_cell := maxi(1, int(cell_size / 2))
	if grid_offset.x < 0 or grid_offset.y < 0 or grid_offset.x >= cell_size or grid_offset.y >= cell_size \
		or grid_offset.x % half_cell != 0 or grid_offset.y % half_cell != 0:
		errors.append("%s besitzt keinen gueltigen Ganz- oder Halbrasterversatz" % label)
	if direction < SurfaceZone.SlopeDirection.UP or direction > SurfaceZone.SlopeDirection.UP_LEFT:
		errors.append("%s besitzt keine der acht Pfeilrichtungen" % label)
	if slope_grade < SurfaceZone.SlopeGrade.SHALLOW or slope_grade > SurfaceZone.SlopeGrade.STEEP:
		errors.append("%s besitzt keine gueltige Steigungsstufe" % label)
	if deceleration < 0.0:
		errors.append("%s besitzt negative Reibung" % label)
	if not clip_polygon.is_empty():
		if Geometry2D.triangulate_polygon(clip_polygon).is_empty():
			errors.append("%s besitzt keinen gueltigen Zellzuschnitt" % label)
		for point in clip_polygon:
			if not Rect2(-0.01,-0.01,cell_size+0.02,cell_size+0.02).has_point(point):
				errors.append("%s: Zellzuschnitt verlaesst die Rasterzelle" % label)
				break
	return errors


func get_rect() -> Rect2:
	return Rect2(
		Vector2(grid_cell.x * cell_size + grid_offset.x, grid_cell.y * cell_size + grid_offset.y),
		Vector2(cell_size, cell_size)
	)


func get_inset_corners() -> PackedVector2Array:
	if not clip_polygon.is_empty():
		var center := Vector2.ZERO
		for point in clip_polygon:
			center += point/clip_polygon.size()
		var inset := PackedVector2Array()
		for point in clip_polygon:
			inset.append(get_rect().position+point.lerp(center,0.001))
		return inset
	var rect := get_rect().grow(-0.1)
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


func get_strength() -> float:
	return SurfaceZone.slope_strength_for_grade(slope_grade as SurfaceZone.SlopeGrade)


func instantiate_zone() -> SurfaceZone:
	var zone := SurfaceZone.new()
	for point in clip_polygon:
		zone.clip_polygon.append(point-Vector2.ONE*cell_size*0.5)
	zone.configure_arrow_tile(
		get_rect(),
		direction as SurfaceZone.SlopeDirection,
		slope_grade as SurfaceZone.SlopeGrade,
		deceleration,
		minimum_flow_speed,
		maximum_flow_speed,
		flow_alignment_rate,
		flow_centering_strength
	)
	return zone
