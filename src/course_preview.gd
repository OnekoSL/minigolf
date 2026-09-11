class_name CoursePreview
extends Control

const IMAGE_SIZE := Vector2i(396, 174)
const CELL_SIZE := Vector2(132, 58)

var course_id: StringName
var hole_ids: Array[StringName] = []
var title: Label
var picture: TextureRect
var tile_labels: Control
var viewport: SubViewport
var runtimes: Array[HoleRuntime] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title = MenuWidgets.label("", Vector2.ZERO, Vector2(396,18), 10, Color("#fff1b0"))
	add_child(title)
	picture = TextureRect.new()
	picture.position = Vector2(0,20)
	picture.size = Vector2(IMAGE_SIZE)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(picture)
	tile_labels = Control.new()
	tile_labels.position = picture.position
	tile_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tile_labels)


func show_course(course: CourseDefinition, catalog: HoleCatalog) -> void:
	if course_id == course.course_id:
		return
	course_id = course.course_id
	hole_ids = course.hole_ids.duplicate()
	title.text = "%s  /  ALLE %d BAHNEN" % [course.display_name,hole_ids.size()]
	if viewport != null:
		picture.texture = null
		viewport.queue_free()
	runtimes.clear()
	for child in tile_labels.get_children():
		child.queue_free()
	viewport = SubViewport.new()
	viewport.size = IMAGE_SIZE
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	# Isolated, static scene: previews cannot move or collide with the real ball.
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	for index in range(hole_ids.size()):
		var hole := catalog.get_hole(hole_ids[index])
		var origin := Vector2(index%3,index/3)*CELL_SIZE
		var backdrop := ColorRect.new()
		backdrop.position = origin
		backdrop.size = CELL_SIZE-Vector2(4,4)
		backdrop.color = Color("#122331")
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viewport.add_child(backdrop)
		var area := Rect2(origin+Vector2(3,13),CELL_SIZE-Vector2(10,20))
		var factor := minf(area.size.x/hole.course_rect.size.x,area.size.y/hole.course_rect.size.y)
		var runtime := HoleRuntime.new()
		runtime.configure(hole)
		runtime.process_mode = Node.PROCESS_MODE_DISABLED
		runtime.scale = Vector2.ONE*factor
		runtime.position = area.get_center()-hole.course_rect.get_center()*factor
		viewport.add_child(runtime)
		runtimes.append(runtime)
		var label := MenuWidgets.label("%d  /  PAR %d" % [index+1,hole.par],origin+Vector2(4,1),Vector2(120,11),8,Color("#d7edcf"))
		tile_labels.add_child(label)
	picture.texture = viewport.get_texture()
