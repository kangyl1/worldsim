extends SceneTree

# Scene-level tests: person navigation lives in the interface, so it is
# exercised through a real Main.tscn instance rather than in isolation.

const EXPECTED_TESTS := 11
# Fields that belong to the simulation's bookkeeping, never to a mortal's view.
const FORBIDDEN_IN_PERSON_VIEW := [
	"objective", "truth_state", "distorted", "transmission",
	"invalidated", "is_outdated", "freshness", "source_type",
	"decision_", "knowledge_id", "subject_id"
]

var main
var completed := 0
var frames := 0


func _initialize() -> void:
	main = load("res://Main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 2:
		return false
	main.simulation.debug_logging_enabled = false
	_advance_years(6)

	_test_person_selection_does_not_mutate_state()
	_test_selection_is_interface_only()
	_test_person_detail_uses_existing_entity_data()
	_test_relationships_stay_directional()
	_test_intention_is_the_latest_record()
	_test_knowledge_keeps_the_mortal_perspective()
	_test_back_returns_to_the_settlement()
	_test_changing_settlement_closes_the_person()
	_test_unknown_person_is_ignored()
	_test_divine_actions_still_work_during_inspection()
	_test_debug_panel_is_hidden_but_available()

	if completed != EXPECTED_TESTS:
		push_error("Person view suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("PERSON VIEW TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return true
	print("PERSON VIEW TEST PASSED: people are navigable, and the panel stays their view.")
	quit(0)
	return true


func _test_person_selection_does_not_mutate_state() -> void:
	var before := _snapshot()
	main._on_person_clicked("person:mara")
	main._on_person_clicked("person:aster_king")
	main._on_person_clicked("back")
	assert(_snapshot() == before, "inspecting people must not change the world")
	completed += 1
	print("  READ ONLY: opening and closing people changed no simulation value.")


func _test_selection_is_interface_only() -> void:
	var state = main.simulation.state
	for field in ["selected_person_id", "selected_location_id", "hovered_person_id", "ui_mode"]:
		assert(not (str(field) in state), "WorldState must not learn what the player is looking at")
	assert(typeof(main.selected_person_id) == TYPE_STRING)
	assert(typeof(main.selected_location_id) == TYPE_STRING)
	completed += 1
	print("  BOUNDARY: navigation state lives only in the interface.")


func _test_person_detail_uses_existing_entity_data() -> void:
	main._on_person_clicked("person:mara")
	var view := _view_text()
	var entity: Dictionary = main.simulation.state.get_notable_entity("mara")
	assert(view.contains(str(entity["name"]).to_upper()))
	for trait_value in entity["traits"]:
		assert(view.to_lower().contains(str(trait_value).to_lower()),
			"trait %s should be shown" % trait_value)
	assert(view.contains("CURRENT INTENTION"))
	assert(view.contains("RELATIONSHIPS"))
	assert(view.contains("KNOWN INFORMATION"))
	completed += 1
	print("  IDENTITY: name and traits come straight from the entity record.")


func _test_relationships_stay_directional() -> void:
	var state = main.simulation.state
	var outward: Dictionary = state.get_relationship("mara", "aster_king")
	var inward: Dictionary = state.get_relationship("aster_king", "mara")
	assert(int(outward["trust"]) != int(inward["trust"]),
		"the fixture needs the two directions to differ")

	main._on_person_clicked("person:mara")
	var mara_view := _view_text()
	assert(mara_view.contains(str(int(outward["trust"]))), "Mara's panel shows Mara's trust")
	main._on_person_clicked("person:aster_king")
	var king_view := _view_text()
	assert(king_view.contains(str(int(inward["trust"]))), "the King's panel shows the King's trust")
	assert(mara_view != king_view, "the two directions must not render identically")
	completed += 1
	print("  DIRECTION: Mara reads %d trust toward the King, he reads %d toward her." % [
		int(outward["trust"]), int(inward["trust"])
	])


func _test_intention_is_the_latest_record() -> void:
	var records: Array[Dictionary] = main.simulation.state.get_decisions_for("mara")
	assert(not records.is_empty(), "the fixture needs a recorded decision")
	var latest: Dictionary = records.back()
	main._on_person_clicked("person:mara")
	var view := _view_text()
	var label := str(main.DECISION_LABELS.get(str(latest["decision_type"]), ""))
	assert(not label.is_empty(), "every decision type needs a readable label")
	assert(view.contains(label), "the newest intention should be the one shown")
	assert(not view.contains(str(latest["decision_type"])), "raw decision ids must not leak")
	assert(view.contains("year %d" % int(latest["year"])))
	completed += 1
	print("  INTENTION: showing '%s', the most recent record." % label)


func _test_knowledge_keeps_the_mortal_perspective() -> void:
	# A belief the world knows to be false, reached second-hand and distorted.
	main.simulation.state.learn_knowledge("mara", {
		"id": "king_divine_claim",
		"subject_id": "aster_king",
		"topic": "ruler_claim",
		"claim": "The King was chosen by God",
		"confidence": 72,
		"truth_state": "true",
		"objective_truth_state": "false",
		"source_id": "aster_king",
		"source_type": "rumor",
		"transmission_count": 2,
		"distorted": true,
		"fresh_for_years": 3
	})
	main._on_person_clicked("person:mara")
	var view := _view_text().to_lower()

	assert(view.contains("the king was chosen by god"), "her belief should be stated plainly")
	assert(view.contains("72%"), "her own confidence is hers to know")
	assert(view.contains("heard from"), "she knows who told her")
	for field: String in FORBIDDEN_IN_PERSON_VIEW:
		assert(not view.contains(field), "'%s' is bookkeeping and must not surface here" % field)
	assert(not view.contains("false"), "the panel must never reveal that she is wrong")
	assert(not view.contains("king_divine_claim"), "raw record ids must not leak")
	main.simulation.state.remove_knowledge("mara", "king_divine_claim")
	completed += 1
	print("  PERSPECTIVE: a false belief reads as belief, with no hint that it is false.")


func _test_back_returns_to_the_settlement() -> void:
	main._on_location_clicked("aster")
	main._on_person_clicked("person:mara")
	assert(main.selected_person_id == "mara")
	var year_before: int = main.simulation.state.year
	var event_before: String = main.simulation.state.current_event_id
	var action_before: bool = main.simulation.state.action_taken

	main._on_person_clicked("back")
	assert(main.selected_person_id.is_empty(), "back clears the person")
	assert(main.selected_location_id == "aster", "back keeps the settlement")
	assert(_view_text().contains("ASTER"))
	assert(_view_text().contains("IMPORTANT PEOPLE"))
	assert(main.simulation.state.year == year_before, "back must not advance time")
	assert(main.simulation.state.current_event_id == event_before, "back must not change the event")
	assert(main.simulation.state.action_taken == action_before, "back must not touch action state")
	completed += 1
	print("  BACK: returns to Aster without spending a year or an action.")


func _test_changing_settlement_closes_the_person() -> void:
	main._on_location_clicked("aster")
	main._on_person_clicked("person:mara")
	assert(main.selected_person_id == "mara")
	main._on_location_clicked("westfield")
	assert(main.selected_person_id.is_empty(), "looking elsewhere closes the person")
	assert(main.selected_location_id == "westfield")
	var view := _view_text()
	assert(view.contains("WESTFIELD"))
	assert(not view.contains("CURRENT INTENTION"), "the person view must be gone")
	main._on_location_clicked("aster")
	completed += 1
	print("  SWITCH: selecting Westfield closed Mara and showed the settlement.")


func _test_unknown_person_is_ignored() -> void:
	main._on_location_clicked("aster")
	main._on_person_clicked("person:nobody")
	assert(main.selected_person_id.is_empty(), "an unknown person must not open a view")
	main._on_person_clicked("https://example.com")
	assert(main.selected_person_id.is_empty(), "only person links select a person")
	completed += 1
	print("  GUARD: unknown links select nobody.")


func _test_divine_actions_still_work_during_inspection() -> void:
	main._on_location_clicked("aster")
	main._on_person_clicked("person:mara")
	var power_before: int = main.simulation.state.divine_power
	var year_before: int = main.simulation.state.year
	assert(not main.simulation.state.action_taken, "the fixture starts the year unanswered")

	main.choose_action(3)
	assert(main.simulation.state.action_taken, "an action still resolves while a person is open")
	assert(main.simulation.state.divine_power == power_before, "do_nothing costs no power")
	for button in main.action_buttons:
		assert(button.disabled, "actions close for the year once answered")

	main.advance_year()
	assert(main.simulation.state.year == year_before + 1, "time still advances")
	assert(not main.simulation.state.action_taken)
	completed += 1
	print("  ACTIONS: resolving and advancing still work with a person open.")


func _test_debug_panel_is_hidden_but_available() -> void:
	assert(not main.notable_panel.visible, "raw telemetry is not part of the normal layout")
	main.notable_panel.visible = true
	main._render_notable_people()
	assert(main.notable_text.text.contains("Mara"), "the debug view still renders when asked")
	main.notable_panel.visible = false
	completed += 1
	print("  DEBUG: panel hidden by default, still renders when toggled on.")


func _advance_years(count: int) -> void:
	for turn in count:
		main.choose_action(3)
		main.advance_year()


func _view_text() -> String:
	return main.location_text.text


func _snapshot() -> Array:
	var state = main.simulation.state
	return [
		state.year, state.population, state.food_level, state.stability_level,
		state.prosperity_level, state.military_level, state.faith, state.followers,
		state.divine_power, state.current_event_id, state.action_taken,
		str(state.relationships), str(state.notable_entities),
		state.history.size(), state.decision_archive.size(), str(state.beliefs)
	]
