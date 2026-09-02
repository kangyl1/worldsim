class_name WorldMapView
extends Control

# Presentation only. This control never reads WorldSimulation and never stores
# world statistics: Main.gd pushes it identity, selection, and marker flags.
# Geometry lives here because map shape is presentation, not simulation state.

signal location_clicked(location_id: String)

const LAND_COLOUR := Color(0.075, 0.094, 0.086, 1.0)
const LAND_EDGE := Color(0.19, 0.24, 0.25, 1.0)
const WATER_COLOUR := Color(0.055, 0.086, 0.106, 1.0)
const ROAD_COLOUR := Color(0.16, 0.2, 0.21, 1.0)
const SITE_FILL := Color(0.11, 0.14, 0.15, 1.0)
const SITE_EDGE := Color(0.35, 0.42, 0.43, 1.0)
const SELECTED_EDGE := Color(0.91, 0.75, 0.39, 1.0)
const LABEL_COLOUR := Color(0.9, 0.88, 0.85, 1.0)
const MUTED_LABEL := Color(0.55, 0.6, 0.61, 1.0)
const CRISIS_COLOUR := Color(0.84, 0.42, 0.37, 1.0)
const DIVINE_COLOUR := Color(0.7, 0.55, 0.77, 1.0)

# Positions are fractions of the drawing area so the map scales with the panel.
const SITES := {
	"aster": {"anchor": Vector2(0.68, 0.68), "radius": 15.0},
	"westfield": {"anchor": Vector2(0.28, 0.72), "radius": 12.0},
	"frontier": {"anchor": Vector2(0.5, 0.2), "radius": 12.0}
}
const ROADS := [["westfield", "aster"], ["aster", "frontier"]]
const CLICK_PADDING := 14.0

var location_names: Dictionary = {}
var selected_location_id: String = ""
var markers: Dictionary = {}

var _hovered_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_locations(names: Dictionary) -> void:
	location_names = names.duplicate(true)
	queue_redraw()


func set_selected_location(location_id: String) -> void:
	if selected_location_id == location_id:
		return
	selected_location_id = location_id
	queue_redraw()


func set_markers(marker_data: Dictionary) -> void:
	markers = marker_data.duplicate(true)
	queue_redraw()


func location_at(point: Vector2) -> String:
	# Nearest site within its click radius; empty string means open ground.
	var best_id := ""
	var best_distance := INF
	for location_id: String in _drawable_ids():
		var site: Dictionary = SITES[location_id]
		var centre := _site_position(location_id)
		var distance := centre.distance_to(point)
		if distance <= float(site["radius"]) + CLICK_PADDING and distance < best_distance:
			best_distance = distance
			best_id = location_id
	return best_id


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var hovered := location_at(event.position)
		if hovered != _hovered_id:
			_hovered_id = hovered
			queue_redraw()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked := location_at(event.position)
		if not clicked.is_empty():
			location_clicked.emit(clicked)
			accept_event()


func _drawable_ids() -> Array[String]:
	var ids: Array[String] = []
	for location_id: String in ["westfield", "aster", "frontier"]:
		if location_names.has(location_id):
			ids.append(location_id)
	return ids


func _site_position(location_id: String) -> Vector2:
	var anchor: Vector2 = SITES[location_id]["anchor"]
	return Vector2(size.x * anchor.x, size.y * anchor.y)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_land()
	_draw_roads()
	for location_id: String in _drawable_ids():
		_draw_site(location_id)


func _draw_land() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), WATER_COLOUR)
	# One region, one silhouette: a simple landmass with a river notch.
	var land := PackedVector2Array([
		Vector2(size.x * 0.06, size.y * 0.30),
		Vector2(size.x * 0.22, size.y * 0.09),
		Vector2(size.x * 0.55, size.y * 0.05),
		Vector2(size.x * 0.82, size.y * 0.14),
		Vector2(size.x * 0.95, size.y * 0.42),
		Vector2(size.x * 0.88, size.y * 0.86),
		Vector2(size.x * 0.58, size.y * 0.95),
		Vector2(size.x * 0.18, size.y * 0.90),
		Vector2(size.x * 0.04, size.y * 0.62)
	])
	draw_colored_polygon(land, LAND_COLOUR)
	draw_polyline(_closed(land), LAND_EDGE, 1.0, true)
	var river := PackedVector2Array([
		Vector2(size.x * 0.10, size.y * 0.46),
		Vector2(size.x * 0.34, size.y * 0.50),
		Vector2(size.x * 0.52, size.y * 0.42),
		Vector2(size.x * 0.74, size.y * 0.48),
		Vector2(size.x * 0.92, size.y * 0.44)
	])
	draw_polyline(river, WATER_COLOUR, 3.0, true)


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed


func _draw_roads() -> void:
	for road: Array in ROADS:
		var from_id := str(road[0])
		var to_id := str(road[1])
		if not location_names.has(from_id) or not location_names.has(to_id):
			continue
		draw_line(_site_position(from_id), _site_position(to_id), ROAD_COLOUR, 1.0, true)


func _draw_site(location_id: String) -> void:
	var centre := _site_position(location_id)
	var radius := float(SITES[location_id]["radius"])
	var is_selected := location_id == selected_location_id
	var edge := SELECTED_EDGE if is_selected else SITE_EDGE
	if is_selected:
		draw_arc(centre, radius + 6.0, 0.0, TAU, 40, SELECTED_EDGE, 1.0, true)
	elif location_id == _hovered_id:
		draw_arc(centre, radius + 4.0, 0.0, TAU, 40, MUTED_LABEL, 1.0, true)
	draw_circle(centre, radius, SITE_FILL)
	draw_arc(centre, radius, 0.0, TAU, 48, edge, 2.0 if is_selected else 1.0, true)

	var font := get_theme_default_font()
	var font_size := 12
	var label := str(location_names.get(location_id, location_id)).to_upper()
	var label_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		centre + Vector2(-label_width * 0.5, radius + 16.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		LABEL_COLOUR if is_selected else MUTED_LABEL
	)
	_draw_markers(location_id, centre, radius, font, font_size)


func _draw_markers(
	location_id: String,
	centre: Vector2,
	radius: float,
	font: Font,
	font_size: int
) -> void:
	var flags: Dictionary = markers.get(location_id, {})
	var symbols: Array[Dictionary] = []
	if bool(flags.get("crisis", false)):
		symbols.append({"text": "!", "colour": CRISIS_COLOUR})
	if bool(flags.get("divine", false)):
		symbols.append({"text": "*", "colour": DIVINE_COLOUR})
	var offset := centre + Vector2(radius + 4.0, -radius - 2.0)
	for symbol: Dictionary in symbols:
		draw_string(
			font,
			offset,
			str(symbol["text"]),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size + 2,
			symbol["colour"]
		)
		offset.x += 10.0
