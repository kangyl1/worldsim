extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const WorldMapScript = preload("res://scripts/world_map.gd")
const MainScript = preload("res://Main.gd")

# Values the map must never keep its own copy of.
const SIMULATION_STATISTICS := [
	"population", "food", "food_level", "stability", "stability_level",
	"prosperity", "prosperity_level", "military", "military_level",
	"faith", "followers", "divine_power"
]
const EXPECTED_TESTS := 8

var completed := 0


func _init() -> void:
	_test_location_model()
	_test_locations_hold_no_statistics()
	_test_location_accessor_returns_a_copy()
	_test_map_view_cannot_touch_simulation()
	_test_crisis_marker_rule()
	_test_actions_still_resolve_once()
	_test_advance_year_still_requires_an_action()
	_test_yearly_ticks_still_execute()
	if completed != EXPECTED_TESTS:
		push_error("Map model suite incomplete: %d of %d finished." % [completed, EXPECTED_TESTS])
		print("MAP MODEL TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("MAP MODEL TEST PASSED: locations describe, the map reads, the simulation still owns truth.")
	quit(0)


func _test_location_model() -> void:
	var simulation = _new_simulation()
	var ids: Array[String] = simulation.state.get_location_ids()
	assert(ids == ["aster", "westfield", "frontier"], "prototype scope is one region, three settlements")
	assert(simulation.state.get_location("aster")["kind"] == "capital")
	assert(bool(simulation.state.get_location("aster")["simulated"]), "only the capital carries conditions")
	for placeholder in ["westfield", "frontier"]:
		var location: Dictionary = simulation.state.get_location(str(placeholder))
		assert(not location.is_empty())
		assert(not bool(location["simulated"]), "%s has no simulated statistics yet" % placeholder)
		assert(not str(location["role"]).is_empty(), "a placeholder still needs a stated role")
	assert(simulation.state.get_location("nowhere").is_empty())
	completed += 1
	print("  MODEL: %s, capital simulated, others declared placeholders." % ", ".join(ids))


func _test_locations_hold_no_statistics() -> void:
	# The map must read world values, never keep a second copy of them.
	var simulation = _new_simulation()
	for location_id: String in simulation.state.get_location_ids():
		var location: Dictionary = simulation.state.get_location(location_id)
		for field: String in SIMULATION_STATISTICS:
			assert(not location.has(field),
				"location '%s' must not duplicate the simulation value '%s'" % [location_id, field])
	completed += 1
	print("  NO DUPLICATION: locations carry identity only, no world statistics.")


func _test_location_accessor_returns_a_copy() -> void:
	var simulation = _new_simulation()
	var location: Dictionary = simulation.state.get_location("aster")
	location["name"] = "Tampered"
	location["simulated"] = false
	assert(str(simulation.state.get_location("aster")["name"]) == "Aster",
		"interface code must not be able to edit world data through an accessor")
	assert(bool(simulation.state.get_location("aster")["simulated"]))
	completed += 1
	print("  ACCESSOR: get_location() hands out a copy, not the record.")


func _test_map_view_cannot_touch_simulation() -> void:
	var simulation = _new_simulation()
	var before := _snapshot(simulation)

	var map = WorldMapScript.new()
	map.size = Vector2(420, 300)
	var names := {}
	for location_id: String in simulation.state.get_location_ids():
		names[location_id] = str(simulation.state.get_location(location_id)["name"])
	map.set_locations(names)
	map.set_markers({"aster": {"crisis": true, "divine": false}})
	map.set_selected_location("aster")

	# Hit-testing is the whole of selection, and it is pure geometry.
	assert(map.location_at(Vector2(420 * 0.68, 300 * 0.68)) == "aster")
	assert(map.location_at(Vector2(420 * 0.28, 300 * 0.72)) == "westfield")
	assert(map.location_at(Vector2(420 * 0.5, 300 * 0.2)) == "frontier")
	assert(map.location_at(Vector2(4, 4)).is_empty(), "open ground selects nothing")
	map.set_selected_location("frontier")
	assert(map.selected_location_id == "frontier", "only one location is selected at a time")

	assert(_snapshot(simulation) == before, "looking at the world must not change it")
	map.free()
	completed += 1
	print("  READ ONLY: selecting and re-selecting changed no simulation value.")


func _test_crisis_marker_rule() -> void:
	var ui = MainScript.new()
	ui.simulation.state.current_event_id = "drought"
	assert(ui._location_in_crisis("aster"), "a drought is an active crisis")
	ui.simulation.state.current_event_id = "unrest"
	assert(ui._location_in_crisis("aster"), "unrest is an active crisis")
	ui.simulation.state.current_event_id = "good_harvest"
	assert(not ui._location_in_crisis("aster"), "a good harvest is not a crisis")
	ui.simulation.state.current_event_id = "drought"
	for placeholder in ["westfield", "frontier"]:
		assert(not ui._location_in_crisis(str(placeholder)),
			"unsimulated settlements must not claim the capital's crisis")
	assert(not ui._location_is_holy("aster"), "no beliefs have formed yet")
	ui.simulation.state.beliefs.append("God answers sincere prayer.")
	assert(ui._location_is_holy("aster"))
	ui.free()
	completed += 1
	print("  MARKERS: crisis follows the event, and only where conditions are simulated.")


func _test_actions_still_resolve_once() -> void:
	var simulation = _new_simulation()
	var power_before: int = simulation.state.divine_power
	var cost := int(simulation.get_action("send_rain")["cost"])
	assert(simulation.can_resolve("send_rain"))

	var first: Dictionary = simulation.resolve_action("send_rain")
	assert(bool(first["ok"]))
	assert(simulation.state.divine_power == power_before - cost, "power is spent exactly once")
	assert(simulation.state.action_taken)

	var second: Dictionary = simulation.resolve_action("send_rain")
	assert(not bool(second["ok"]), "a second action in the same year must be refused")
	assert(simulation.state.divine_power == power_before - cost, "the refusal must not spend power again")
	completed += 1
	print("  ACTIONS: resolved once, %d power spent, repeat refused." % cost)


func _test_advance_year_still_requires_an_action() -> void:
	var simulation = _new_simulation()
	var year_before: int = simulation.state.year
	assert(not bool(simulation.advance_year()["ok"]), "time must not move before a divine choice")
	assert(simulation.state.year == year_before)
	simulation.resolve_action("do_nothing")
	assert(bool(simulation.advance_year()["ok"]))
	assert(simulation.state.year == year_before + 1)
	completed += 1
	print("  TIME: advance still blocked until an action is chosen.")


func _test_yearly_ticks_still_execute() -> void:
	var simulation = _new_simulation()
	var relationship_before: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	for turn in 4:
		simulation.resolve_action("do_nothing")
		assert(bool(simulation.advance_year()["ok"]))
	var relationship_after: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	assert(int(relationship_after["trust"]) != int(relationship_before["trust"]),
		"relationship tick must still run")
	assert(simulation.state.get_all_knowledge("mara").size() > 0, "knowledge tick must still run")
	assert(not simulation.state.decision_archive.is_empty(), "decision tick must still run")
	assert(simulation.state.history.size() > 0, "history must still be written")
	completed += 1
	print("  TICKS: relationships, knowledge, decisions, and history all still advance.")


func _snapshot(simulation) -> Array:
	return [
		simulation.state.year,
		simulation.state.population,
		simulation.state.food_level,
		simulation.state.stability_level,
		simulation.state.prosperity_level,
		simulation.state.military_level,
		simulation.state.faith,
		simulation.state.followers,
		simulation.state.divine_power,
		simulation.state.current_event_id,
		simulation.state.action_taken,
		str(simulation.state.relationships),
		str(simulation.state.notable_entities),
		simulation.state.history.size(),
		simulation.state.decision_archive.size()
	]


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation
