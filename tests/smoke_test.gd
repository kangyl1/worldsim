extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")


func _init() -> void:
	_test_traits_and_relationships()
	_test_mixed_divine_style()
	_test_silence_as_a_strategy()
	print("SMOKE TEST PASSED: project booted; social systems and 72 world turns completed.")
	quit(0)


func _test_traits_and_relationships() -> void:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	assert(simulation.state.notable_entities.size() == 2)
	assert(simulation.state.get_notable_entity("aster_king")["traits"] == ["ambitious"])
	assert(simulation.state.get_notable_entity("mara")["traits"] == ["compassionate", "loyal"])

	var before: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	var changes: Array[Dictionary] = simulation.tick_relationships()
	var after: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	assert(changes.size() == 2)
	assert(after["trust"] > before["trust"])
	assert(after["respect"] > before["respect"])
	assert(after["fear"] < before["fear"])
	assert(after["hostility"] < before["hostility"])

	assert(simulation.state.add_notable_entity("cruel_warden", "The Warden", "person", ["cruel"]))
	assert(simulation.state.set_relationship("mara", "cruel_warden"))
	var warden_before: Dictionary = simulation.state.get_relationship("mara", "cruel_warden")
	changes = simulation.tick_relationships()
	var warden_after: Dictionary = simulation.state.get_relationship("mara", "cruel_warden")
	assert(changes.size() == 3)
	assert(warden_after["trust"] < warden_before["trust"])
	assert(warden_after["fear"] > warden_before["fear"])
	assert(warden_after["respect"] > warden_before["respect"])
	assert(not simulation.state.set_relationship("mara", "missing_entity"))
	print("  SOCIAL: traits changed %d directed relationships." % changes.size())


func _test_mixed_divine_style() -> void:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	var interpretations_by_action := {
		"send_rain": {},
		"bless_harvest": {},
		"speak_mortal": {},
		"do_nothing": {}
	}

	assert(simulation.state.year == 12)
	assert(not simulation.advance_year()["ok"])
	for turn in 36:
		var action_id := _mixed_action_for(simulation.state.current_event_id, turn)
		var action_result: Dictionary = simulation.resolve_action(action_id)
		assert(action_result["ok"], "Action failed on mixed turn %d" % turn)
		assert(not str(action_result["interpretation"]).is_empty())
		assert(not str(action_result["belief_tag"]).is_empty())
		interpretations_by_action[action_id][action_result["interpretation_id"]] = true
		assert(not simulation.resolve_action("do_nothing")["ok"])
		assert(simulation.state.population > 0)
		assert(simulation.state.divine_power >= 0)
		assert(simulation.advance_year()["ok"], "Advance failed on mixed turn %d" % turn)

	var actions_with_varied_meanings := 0
	var total_interpretations := 0
	for action_id: String in interpretations_by_action:
		var unique_count: int = interpretations_by_action[action_id].size()
		total_interpretations += unique_count
		if unique_count > 1:
			actions_with_varied_meanings += 1
	assert(simulation.state.year == 48)
	assert(total_interpretations >= 7)
	assert(actions_with_varied_meanings >= 2)
	assert(simulation.state.known_beliefs.size() >= 2)
	assert(simulation.state.beliefs.size() <= 3)
	assert(simulation.state.reputation != "Unknown")
	assert(not simulation.state.reputation_changes.is_empty())
	_assert_no_duplicate_beliefs(simulation)
	_assert_valid_state(simulation)
	print("  MIXED: %d interpretations, %d formed beliefs, reputation %s." % [
		total_interpretations,
		simulation.state.known_beliefs.size(),
		simulation.state.reputation
	])


func _test_silence_as_a_strategy() -> void:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	var silence_interpretations := {}
	for turn in 36:
		var power_before: int = simulation.state.divine_power
		var result: Dictionary = simulation.resolve_action("do_nothing")
		assert(result["ok"], "Silence failed on turn %d" % turn)
		assert(simulation.state.divine_power == power_before)
		silence_interpretations[result["interpretation_id"]] = true
		assert(simulation.advance_year()["ok"])
		_assert_valid_state(simulation)

	assert(silence_interpretations.size() >= 4)
	assert(simulation.state.useful_silence_outcomes > 0)
	assert(simulation.state.world_flags["wells_built"])
	assert(simulation.state.world_flags["irrigation_known"])
	assert(simulation.state.world_flags["local_council_empowered"])
	assert(simulation.state.world_flag_use_counts["wells_built"] > 0)
	assert(simulation.state.world_flag_use_counts["irrigation_known"] > 0)
	assert(simulation.state.world_flag_use_counts["local_council_empowered"] > 0)
	assert(_history_contains(simulation, "wells built during the Great Silence"))
	assert(_history_contains(simulation, "Channels first cut"))
	assert(simulation.state.reputation != "Unknown")
	assert(simulation.state.belief_pressure["self_reliance"] >= 3)
	assert(simulation.state.belief_pressure["naturalism"] >= 3)
	_assert_no_duplicate_beliefs(simulation)
	print("  SILENT: %d interpretations, %d useful outcomes, flags reused %s." % [
		silence_interpretations.size(),
		simulation.state.useful_silence_outcomes,
		simulation.state.world_flag_use_counts
	])


func _mixed_action_for(event_id: String, turn: int) -> String:
	match event_id:
		"drought":
			return "send_rain" if turn % 2 == 0 else "do_nothing"
		"good_harvest":
			return "do_nothing" if turn % 4 == 0 else "bless_harvest"
		"unrest":
			return "do_nothing" if turn % 5 == 0 else "speak_mortal"
	return "do_nothing"


func _assert_valid_state(simulation) -> void:
	assert(simulation.state.population > 0)
	assert(simulation.state.divine_power >= 0)
	assert(simulation.state.followers >= 0)
	assert(simulation.state.followers <= simulation.state.population)
	for relationship_value in simulation.state.relationships.values():
		var relationship: Dictionary = relationship_value
		for axis: String in WorldState.RELATIONSHIP_AXES:
			assert(relationship[axis] >= WorldState.RELATIONSHIP_MIN)
			assert(relationship[axis] <= WorldState.RELATIONSHIP_MAX)


func _assert_no_duplicate_beliefs(simulation) -> void:
	var unique_tags := {}
	for tag: String in simulation.state.known_beliefs:
		unique_tags[tag] = true
	assert(unique_tags.size() == simulation.state.known_beliefs.size())


func _history_contains(simulation, text: String) -> bool:
	for entry: String in simulation.state.history_archive:
		if text in entry:
			return true
	return false
