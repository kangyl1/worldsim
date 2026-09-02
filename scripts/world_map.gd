class_name WorldMapView
extends Control

# Presentation only. This control never reads WorldSimulation and never stores
# world statistics: Main.gd pushes it identity, selection, and marker flags.
# Geometry and terrain marks are decorative and carry no simulation meaning.

signal location_clicked(location_id: String)

const LAND_COLOUR := Color(0.078, 0.096, 0.088, 1.0)
const LAND_INNER := Color(0.094, 0.114, 0.104, 1.0)
const LAND_EDGE := Color(0.22, 0.28, 0.28, 1.0)
const WATER_COLOUR := Color(0.043, 0.063, 0.075, 1.0)
const RIVER_COLOUR := Color(0.16, 0.27, 0.31, 1.0)
const TERRAIN_COLOUR := Color(0.17, 0.22, 0.2, 1.0)
const SITE_FILL := Color(0.12, 0.15, 0.16, 1.0)
const SITE_EDGE := Color(0.43, 0.5, 0.5, 1.0)
const SELECTED_EDGE := Color(0.91, 0.75, 0.39, 1.0)
const HOVER_EDGE := Color(0.6, 0.66, 0.66, 1.0)
const LABEL_COLOUR := Color(0.91, 0.89, 0.85, 1.0)
const MUTED_LABEL := Color(0.56, 0.61, 0.62, 1.0)
const CRISIS_COLOUR := Color(0.84, 0.42, 0.37, 1.0)
const DIVINE_COLOUR := Color(0.68, 0.54, 0.76, 1.0)

# Positions are fractions of the drawing area, so the map scales with the panel.
# Aster sits south-east on the river, Westfield in the western lowland, and
# Frontier alone against the northern hills.
const SITES := {
	"aster": {"anchor": Vector2(0.63, 0.65), "radius": 13.0},
	"westfield": {"anchor": Vector2(0.30, 0.56), "radius": 11.0},
	"frontier": {"anchor": Vector2(0.51, 0.24), "radius": 11.0}
}
const DRAW_ORDER := ["frontier", "westfield", "aster"]
const CLICK_PADDING := 13.0
const COAST_SAMPLES := 84

# Decorative only. Fractions of the drawing area.
const FOREST_MARKS := [
	Vector2(0.20, 0.34), Vector2(0.26, 0.30), Vector2(0.15, 0.44),
	Vector2(0.76, 0.32), Vector2(0.82, 0.40), Vector2(0.71, 0.24),
	Vector2(0.37, 0.78), Vector2(0.45, 0.83)
]
const RIDGE_MARKS := [
	Vector2(0.38, 0.16), Vector2(0.46, 0.12), Vector2(0.55, 0.13), Vector2(0.63, 0.18)
]
const RIVER_POINTS := [
	Vector2(0.09, 0.47), Vector2(0.22, 0.53), Vector2(0.33, 0.58),
	Vector2(0.46, 0.57), Vector2(0.57, 0.62), Vector2(0.68, 0.70), Vector2(0.80, 0.83)
]

var locations: Dictionary = {}
var selected_location_id: String = ""
var markers: Dictionary = {}

var _hovered_id: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_locations(location_data: Dictionary) -> void:
	locations = location_data.duplicate(true)
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
		var distance := _site_position(location_id).distance_to(point)
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
	for location_id: String in DRAW_ORDER:
		if locations.has(location_id):
			ids.append(location_id)
	return ids


func _site_position(location_id: String) -> Vector2:
	var anchor: Vector2 = SITES[location_id]["anchor"]
	return Vector2(size.x * anchor.x, size.y * anchor.y)


func _at(fraction: Vector2) -> Vector2:
	return Vector2(size.x * fraction.x, size.y * fraction.y)


func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), WATER_COLOUR)
	var coast := _coastline()
	draw_colored_polygon(coast, LAND_COLOUR)
	draw_polyline(_closed(coast), LAND_EDGE, 1.0, true)
	_draw_river()
	_draw_terrain_marks()
	for location_id: String in _drawable_ids():
		_draw_site(location_id)


func _coastline() -> PackedVector2Array:
	# A closed contour with a few fixed harmonics: organic to read, fully
	# deterministic, and no art asset needed.
	var centre := size * 0.5
	var radius_x := size.x * 0.455
	var radius_y := size.y * 0.44
	var points := PackedVector2Array()
	for index in COAST_SAMPLES:
		var angle := TAU * float(index) / float(COAST_SAMPLES)
		var wobble := (
			1.0
			+ 0.105 * sin(angle * 3.0 + 0.7)
			+ 0.062 * sin(angle * 5.0 + 2.2)
			+ 0.034 * sin(angle * 8.0 + 4.1)
			+ 0.021 * sin(angle * 13.0 + 1.3)
		)
		points.append(centre + Vector2(
			cos(angle) * radius_x * wobble,
			sin(angle) * radius_y * wobble
		))
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var closed := points.duplicate()
	closed.append(points[0])
	return closed


func _draw_river() -> void:
	var points := PackedVector2Array()
	for fraction: Vector2 in RIVER_POINTS:
		points.append(_at(fraction))
	draw_polyline(_smooth(points), RIVER_COLOUR, 2.0, true)


func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	# Chaikin-style corner cutting, so hand-placed points read as a curve.
	if points.size() < 3:
		return points
	var smoothed := PackedVector2Array([points[0]])
	for index in range(points.size() - 1):
		var start := points[index]
		var end := points[index + 1]
		smoothed.append(start.lerp(end, 0.25))
		smoothed.append(start.lerp(end, 0.75))
	smoothed.append(points[points.size() - 1])
	return smoothed


func _draw_terrain_marks() -> void:
	for fraction: Vector2 in FOREST_MARKS:
		var point := _at(fraction)
		draw_line(point + Vector2(-3.0, 2.0), point + Vector2(0.0, -3.0), TERRAIN_COLOUR, 1.0, true)
		draw_line(point + Vector2(0.0, -3.0), point + Vector2(3.0, 2.0), TERRAIN_COLOUR, 1.0, true)
	for fraction: Vector2 in RIDGE_MARKS:
		var point := _at(fraction)
		draw_line(point + Vector2(-6.0, 3.0), point + Vector2(-1.0, -4.0), TERRAIN_COLOUR, 1.0, true)
		draw_line(point + Vector2(-1.0, -4.0), point + Vector2(4.0, 3.0), TERRAIN_COLOUR, 1.0, true)
		draw_line(point + Vector2(1.0, 0.0), point + Vector2(5.0, -3.0), TERRAIN_COLOUR, 1.0, true)


func _draw_site(location_id: String) -> void:
	var centre := _site_position(location_id)
	var radius := float(SITES[location_id]["radius"])
	var is_selected := location_id == selected_location_id
	var edge := SELECTED_EDGE if is_selected else SITE_EDGE
	var width := 2.0 if is_selected else 1.0

	if is_selected:
		draw_arc(centre, radius + 7.0, 0.0, TAU, 44, SELECTED_EDGE, 1.6, true)
	elif location_id == _hovered_id:
		draw_arc(centre, radius + 5.0, 0.0, TAU, 44, HOVER_EDGE, 1.0, true)

	match str(locations.get(location_id, {}).get("kind", "")):
		"capital":
			draw_circle(centre, radius, SITE_FILL)
			draw_arc(centre, radius, 0.0, TAU, 48, edge, width, true)
			draw_circle(centre, radius * 0.42, edge)
		"farming_village":
			var half := radius * 0.78
			var square := PackedVector2Array([
				centre + Vector2(-half, -half), centre + Vector2(half, -half),
				centre + Vector2(half, half), centre + Vector2(-half, half)
			])
			draw_colored_polygon(square, SITE_FILL)
			draw_polyline(_closed(square), edge, width, true)
		"frontier_settlement":
			var triangle := PackedVector2Array([
				centre + Vector2(0.0, -radius),
				centre + Vector2(radius * 0.92, radius * 0.72),
				centre + Vector2(-radius * 0.92, radius * 0.72)
			])
			draw_colored_polygon(triangle, SITE_FILL)
			draw_polyline(_closed(triangle), edge, width, true)
		_:
			draw_circle(centre, radius, SITE_FILL)
			draw_arc(centre, radius, 0.0, TAU, 48, edge, width, true)

	_draw_label(location_id, centre, radius, is_selected)
	_draw_markers(location_id, centre, radius)


func _draw_label(location_id: String, centre: Vector2, radius: float, is_selected: bool) -> void:
	var font := get_theme_default_font()
	var font_size := 11
	var label := str(locations.get(location_id, {}).get("name", location_id)).to_upper()
	var label_width := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(
		font,
		centre + Vector2(-label_width * 0.5, radius + 15.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		LABEL_COLOUR if is_selected else MUTED_LABEL
	)


func _draw_markers(location_id: String, centre: Vector2, radius: float) -> void:
	var flags: Dictionary = markers.get(location_id, {})
	var font := get_theme_default_font()
	var offset := centre + Vector2(radius + 3.0, -radius + 1.0)
	if bool(flags.get("crisis", false)):
		draw_circle(offset + Vector2(4.0, -3.0), 6.0, WATER_COLOUR)
		draw_arc(offset + Vector2(4.0, -3.0), 6.0, 0.0, TAU, 24, CRISIS_COLOUR, 1.0, true)
		draw_string(font, offset + Vector2(2.0, 1.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, CRISIS_COLOUR)
		offset.x += 14.0
	if bool(flags.get("divine", false)):
		var point := offset + Vector2(4.0, -3.0)
		var diamond := PackedVector2Array([
			point + Vector2(0.0, -5.0), point + Vector2(4.0, 0.0),
			point + Vector2(0.0, 5.0), point + Vector2(-4.0, 0.0)
		])
		draw_polyline(_closed(diamond), DIVINE_COLOUR, 1.0, true)
