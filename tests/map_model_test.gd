extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const WorldMapScript = preload("res://scripts/world_map.gd")
const MainScript = preload("res://Main.gd")

# Values the map must never keep its own copy of.
const EXPECTED_TESTS := 9

var completed := 0


func _init() -> void:
	_test_location_model()
	_test_settlements_are_the_single_source_of_truth()
	_test_location_accessor_returns_a_copy()
	_test_map_view_cannot_touch_simulation()
	_test_person_rows_are_selectable()
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
	# Every settlement carries its own conditions now, not just the capital.
	for location_id: String in ids:
		var location: Dictionary = simulation.state.get_location(location_id)
		assert(not location.is_empty())
		assert(not str(location["role"]).is_empty(), "a settlement still needs a stated role")
		for band: String in WorldState.SETTLEMENT_BANDS:
			assert(location.has(band), "%s must carry its own %s" % [location_id, band])
		assert(int(location["population"]) > 0, "%s must have people in it" % location_id)
	assert(simulation.state.get_location("nowhere").is_empty())
	completed += 1
	print("  MODEL: %s, each carrying its own conditions." % ", ".join(ids))


func _test_settlements_are_the_single_source_of_truth() -> void:
	# Settlements own local conditions; the kingdom view is derived from them.
	# Two independent copies would be the thing to fear, not one owner.
	var simulation = _new_simulation()
	var state = simulation.state
	var aster_food: int = state.get_settlement_band("aster", "food")
	assert(bool(state.set_settlement_band("westfield", "food", 3)))
	assert(int(state.get_settlement_band("westfield", "food")) == 3)
	assert(int(state.get_settlement_band("aster", "food")) == aster_food,
		"changing one settlement must not change another")

	# The realm reads as the people in it, weighted by where they live.
	var weighted := 0
	var people := 0
	for location_id: String in state.get_location_ids():
		var residents: int = state.get_settlement_population(location_id)
		weighted += int(state.get_settlement_band(location_id, "food")) * residents
		people += residents
	assert(int(state.food_level) == int(round(float(weighted) / float(people))),
		"the kingdom view must be derived, never stored separately")
	assert(int(state.population) == people, "the realm is exactly the people in its settlements")

	# Kingdom-only values stay kingdom-only.
	for location_id: String in state.get_location_ids():
		var location: Dictionary = state.get_location(location_id)
		for field: String in ["military_level", "faith", "followers", "divine_power"]:
			assert(not location.has(field),
				"%s must not carry the kingdom's %s" % [location_id, field])
	completed += 1
	print("  ONE TRUTH: settlements own local conditions, the kingdom view derives from them.")


func _test_location_accessor_returns_a_copy() -> void:
	var simulation = _new_simulation()
	var location: Dictionary = simulation.state.get_location("aster")
	location["name"] = "Tampered"
	location["food"] = 3
	assert(str(simulation.state.get_location("aster")["name"]) == "Aster",
		"interface code must not be able to edit world data through an accessor")
	assert(simulation.state.get_settlement_band("aster", "food") != 3,
		"nor edit a settlement's conditions through one")
	completed += 1
	print("  ACCESSOR: get_location() hands out a copy, not the record.")


func _test_map_view_cannot_touch_simulation() -> void:
	var simulation = _new_simulation()
	var before := _snapshot(simulation)

	var map = WorldMapScript.new()
	map.size = Vector2(480, 320)
	var map_locations := {}
	for location_id: String in simulation.state.get_location_ids():
		var location: Dictionary = simulation.state.get_location(location_id)
		map_locations[location_id] = {"name": str(location["name"]), "kind": str(location["kind"])}
	map.set_locations(map_locations)
	map.set_markers({"aster": {"crisis": true, "divine": false}})
	map.set_selected_location("aster")

	# Hit-testing is the whole of selection, and it is pure geometry. Points are
	# derived from the site table so repositioning cannot silently break this.
	for location_id: String in simulation.state.get_location_ids():
		assert(WorldMapScript.SITES.has(location_id), "every location needs a place on the map")
		var anchor: Vector2 = WorldMapScript.SITES[location_id]["anchor"]
		assert(anchor.x > 0.0 and anchor.x < 1.0 and anchor.y > 0.0 and anchor.y < 1.0,
			"%s must sit inside the drawing area" % location_id)
		var point := Vector2(map.size.x * anchor.x, map.size.y * anchor.y)
		assert(map.location_at(point) == location_id,
			"clicking %s should select %s" % [str(point), location_id])
	assert(map.location_at(Vector2(3, 3)).is_empty(), "open ground selects nothing")

	# Sites must stay far enough apart that a click is unambiguous.
	var ids: Array[String] = simulation.state.get_location_ids()
	for first_index in ids.size():
		for second_index in range(first_index + 1, ids.size()):
			var a: Vector2 = WorldMapScript.SITES[ids[first_index]]["anchor"]
			var b: Vector2 = WorldMapScript.SITES[ids[second_index]]["anchor"]
			var gap := Vector2(map.size.x * (a.x - b.x), map.size.y * (a.y - b.y)).length()
			var reach := (
				float(WorldMapScript.SITES[ids[first_index]]["radius"])
				+ float(WorldMapScript.SITES[ids[second_index]]["radius"])
				+ WorldMapScript.CLICK_PADDING * 2.0
			)
			assert(gap > reach, "%s and %s overlap as click targets" % [
				ids[first_index], ids[second_index]
			])

	map.set_selected_location("frontier")
	assert(map.selected_location_id == "frontier", "only one location is selected at a time")

	assert(_snapshot(simulation) == before, "looking at the world must not change it")
	map.free()
	completed += 1
	print("  READ ONLY: every site hit-tests to itself, and no world value moved.")


func _test_person_rows_are_selectable() -> void:
	var ui = MainScript.new()
	assert(ui._person_id_from_meta("person:mara") == "mara")
	assert(ui._person_id_from_meta("person:aster_king") == "aster_king")
	assert(ui._person_id_from_meta("https://example.com").is_empty(),
		"only person links may select a person")
	assert(ui._person_id_from_meta("").is_empty())
	assert(ui.selected_person_id.is_empty(), "no person is selected at start")
	ui.free()
	completed += 1
	print("  PEOPLE: rows carry person metadata and nothing else is selectable.")


func _test_crisis_marker_rule() -> void:
	var ui = MainScript.new()
	ui.simulation.state.current_event_location_id = "aster"
	ui.simulation.state.current_event_id = "drought"
	assert(ui._location_in_crisis("aster"), "a drought is an active crisis")
	ui.simulation.state.current_event_id = "unrest"
	assert(ui._location_in_crisis("aster"), "unrest is an active crisis")
	ui.simulation.state.current_event_id = "good_harvest"
	assert(not ui._location_in_crisis("aster"), "a good harvest is not a crisis")
	ui.simulation.state.current_event_id = "drought"
	for elsewhere in ["westfield", "frontier"]:
		assert(not ui._location_in_crisis(str(elsewhere)),
			"a crisis belongs to the settlement it is happening in")
	# And it travels with the event.
	ui.simulation.state.current_event_location_id = "westfield"
	assert(ui._location_in_crisis("westfield"))
	assert(not ui._location_in_crisis("aster"), "the capital does not keep every crisis")
	assert(not ui._location_is_holy("aster"), "no beliefs have formed yet")
	ui.simulation.state.beliefs.append("God answers sincere prayer.")
	assert(ui._location_is_holy("aster"))
	ui.free()
	completed += 1
	print("  MARKERS: crisis follows the event to the settlement it is happening in.")


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
	# Perception is selective now, so who knows what is no longer a given. What
	# must still hold is that the knowledge tick ran at all and reached someone.
	assert(not simulation.state.knowledge_events.is_empty(), "knowledge tick must still run")
	assert(not simulation.state.perception_archive.is_empty(), "perception tick must still run")
	assert(not simulation.state.intent_archive.is_empty(), "intent tick must still run")
	assert(not simulation.state.action_archive.is_empty(), "action selection must still run")
	assert(not simulation.state.execution_archive.is_empty(), "action execution must still run")
	assert(simulation.state.history.size() > 0, "history must still be written")
	completed += 1
	print("  TICKS: relationships, perception, knowledge, intents, actions, executions, history.")


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
		simulation.state.intent_archive.size(),
		simulation.state.action_archive.size(),
		simulation.state.execution_archive.size()
	]


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation
