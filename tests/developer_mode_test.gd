extends SceneTree

# Developer Mode is an inspection tool. These tests hold it to two promises:
# it shows the machine underneath, and it never touches the machine.

const EXPECTED_TESTS := 16
const FALSE_BELIEF := {
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
}

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
	for turn in 6:
		main.choose_action(3)
		main.advance_year()

	_test_starts_disabled()
	_test_button_exists_and_is_visible()
	_test_button_enables_and_disables()
	_test_f1_toggles_the_same_state()
	_test_toggling_does_not_mutate_state()
	_test_panel_costs_no_layout_space_when_closed()
	_test_world_section_shows_exact_values()
	_test_people_section_shows_exact_directed_values()
	_test_knowledge_section_exposes_objective_truth()
	_test_normal_person_view_still_hides_truth()
	_test_intent_section_renders_stored_record()
	_test_action_section_is_kept_separate()
	_test_execution_section_shows_what_happened()
	_test_perception_section_shows_who_noticed()
	_test_actions_still_work_with_developer_mode_open()
	_test_sections_all_render()

	if completed != EXPECTED_TESTS:
		push_error("Developer mode suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("DEVELOPER MODE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return true
	print("DEVELOPER MODE TEST PASSED: the machine is visible, and untouched.")
	quit(0)
	return true


func _test_starts_disabled() -> void:
	assert(not main.developer_mode_enabled, "Developer Mode must start off")
	assert(not main.developer_overlay.visible, "its panel must start hidden")
	assert(main.dev_button.text == "DEV")
	completed += 1
	print("  DEFAULT: Developer Mode starts off.")


func _test_button_exists_and_is_visible() -> void:
	assert(main.dev_button != null, "a visible control is the primary route")
	assert(main.dev_button.visible)
	assert(main.dev_button.is_visible_in_tree(), "the button must be on screen, not just present")
	assert(main.dev_button.pressed.is_connected(main.toggle_developer_mode),
		"the button must drive the one toggle function")
	completed += 1
	print("  BUTTON: DEV is on screen and wired to the toggle.")


func _test_button_enables_and_disables() -> void:
	main.dev_button.pressed.emit()
	assert(main.developer_mode_enabled, "clicking DEV opens Developer Mode")
	assert(main.developer_overlay.visible)
	assert(main.dev_button.text == "DEV: ON", "the state must be unmistakable")

	main.dev_button.pressed.emit()
	assert(not main.developer_mode_enabled, "clicking again closes it")
	assert(not main.developer_overlay.visible)
	assert(main.dev_button.text == "DEV")
	completed += 1
	print("  BUTTON: click opens, click again closes.")


func _test_f1_toggles_the_same_state() -> void:
	assert(not main.developer_mode_enabled)
	_press_f1()
	assert(main.developer_mode_enabled, "F1 is a second route to the same state")
	assert(main.developer_overlay.visible)
	assert(main.dev_button.text == "DEV: ON", "the button must reflect a keyboard toggle")
	_press_f1()
	assert(not main.developer_mode_enabled)
	assert(main.dev_button.text == "DEV", "there is only one developer state")
	completed += 1
	print("  F1: secondary route drives the same single state.")


func _test_toggling_does_not_mutate_state() -> void:
	var before := _snapshot()
	for repeat in 3:
		main.toggle_developer_mode()
		for section: String in main.DEV_SECTIONS:
			main._on_developer_meta("dev_tab:" + section)
		main.toggle_developer_mode()
	assert(_snapshot() == before, "inspection must never change the simulation")
	assert(not main.developer_mode_enabled)
	completed += 1
	print("  READ ONLY: three full passes over every section changed nothing.")


func _test_panel_costs_no_layout_space_when_closed() -> void:
	var column = main.get_node("Margin/MainColumn")
	var closed_size: Vector2 = column.get_combined_minimum_size()
	main.toggle_developer_mode()
	var open_size: Vector2 = column.get_combined_minimum_size()
	main.toggle_developer_mode()
	assert(not main.developer_overlay.visible, "the panel leaves the layout when disabled")
	assert(column.get_combined_minimum_size() == closed_size)
	assert(open_size == closed_size, "an overlay must not resize the production layout")
	completed += 1
	print("  LAYOUT: overlay costs no production space, open or closed.")


func _test_world_section_shows_exact_values() -> void:
	var state = main.simulation.state
	var view := _section_text("world")
	for value in [state.year, state.population, state.faith, state.followers, state.divine_power]:
		assert(view.contains(str(value)), "exact value %s should appear" % str(value))
	assert(view.contains("food_level"), "raw field names belong here")
	assert(view.contains(state.current_event_id))
	assert(view.contains("action_taken"))
	completed += 1
	print("  WORLD: exact values and raw ids are exposed.")


func _test_people_section_shows_exact_directed_values() -> void:
	var state = main.simulation.state
	var outward: Dictionary = state.get_relationship("mara", "aster_king")
	var inward: Dictionary = state.get_relationship("aster_king", "mara")
	assert(int(outward["trust"]) != int(inward["trust"]), "the fixture needs differing directions")

	var view := _section_text("people")
	assert(view.contains("mara -> aster_king"), "direction must be explicit")
	assert(view.contains("aster_king -> mara"))
	assert(view.contains("trust %d" % int(outward["trust"])))
	assert(view.contains("trust %d" % int(inward["trust"])))
	assert(view.contains("compassionate"), "raw trait ids belong here")
	completed += 1
	print("  PEOPLE: both directions shown exactly (%d and %d trust)." % [
		int(outward["trust"]), int(inward["trust"])
	])


func _test_knowledge_section_exposes_objective_truth() -> void:
	main.simulation.state.learn_knowledge("mara", FALSE_BELIEF)
	main.developer_person_id = "mara"
	var view := _section_text("knowledge")
	# The whole point: the tool may show what the mortal cannot know.
	assert(view.contains("king_divine_claim"), "raw record ids belong here")
	assert(view.contains("objective_truth_state"))
	assert(view.contains("false"), "the hidden truth must be visible to the developer")
	assert(view.contains("distorted"))
	assert(view.contains("transmission_count"))
	assert(view.contains("72"), "her confidence is shown alongside the truth")
	completed += 1
	print("  KNOWLEDGE: belief and objective truth sit side by side.")


func _test_normal_person_view_still_hides_truth() -> void:
	# Same planted belief, seen through the player's panel.
	main.toggle_developer_mode() if main.developer_mode_enabled else null
	main._on_location_clicked("aster")
	main._on_person_clicked("person:mara")
	var view: String = main.location_text.text.to_lower()
	assert(view.contains("the king was chosen by god"), "she still believes it")
	for field: String in ["objective", "truth_state", "distorted", "transmission", "king_divine_claim"]:
		assert(not view.contains(field), "'%s' must not leak into the player panel" % field)
	assert(not view.contains("false"), "Developer Mode must not contaminate the mortal view")
	main.simulation.state.remove_knowledge("mara", "king_divine_claim")
	main._on_person_clicked("back")
	completed += 1
	print("  ISOLATION: the same belief stays truth-free in the player panel.")


func _test_intent_section_renders_stored_record() -> void:
	var records: Array[Dictionary] = main.simulation.state.get_intents_for("mara")
	assert(not records.is_empty(), "the fixture needs an intent")
	var latest: Dictionary = records.back()
	main.developer_person_id = "mara"
	var view := _section_text("intents")
	# Rendered from the stored explanation, never recomputed.
	assert(view.contains(str(latest["id"])))
	assert(view.contains(str(latest["intent_type"])))
	assert(view.contains(str(latest["selection"])), "the record must say how it was chosen")
	assert(view.contains(str(int(latest["score"]))))
	assert(view.contains("considered"), "the rejected candidates are part of the record")
	for candidate: Dictionary in latest["considered"]:
		assert(view.contains(str(candidate["reason"])), "each rejection reason is stored, so show it")
	for reason in latest["reasons"]:
		assert(view.contains(str(reason)), "stored reasons must be rendered verbatim")
	completed += 1
	print("  DECISIONS: stored explanation rendered, %d candidates listed." % latest["considered"].size())


func _test_action_section_is_kept_separate() -> void:
	# Why someone wanted something and why they chose that way of pursuing it
	# are two questions. Merging the records would make neither answerable.
	var records: Array[Dictionary] = main.simulation.state.get_actions_for("mara")
	assert(not records.is_empty(), "the fixture needs a selected action")
	var latest: Dictionary = records.back()

	var view := _section_text("actions")
	assert(view.contains(str(latest["id"])))
	assert(view.contains(str(latest["action_type"])))
	assert(view.contains(str(latest["selection"])), "the record must say how it was chosen")
	assert(view.contains(str(latest["intent_id"])), "an attempt must point at the want it serves")
	assert(view.contains("considered"), "the roads not taken belong in the inspection")

	var intent_view := _section_text("intents")
	assert(not intent_view.contains(str(latest["id"])), "the two records must not be merged")
	assert(intent_view != view)
	completed += 1


func _test_execution_section_shows_what_happened() -> void:
	# The third question, and it must stay its own record: why she wanted it,
	# why she chose that way, and what came of it.
	var records: Array[Dictionary] = main.simulation.state.get_executions_for("mara")
	assert(not records.is_empty(), "the fixture needs an execution")
	var latest: Dictionary = records.back()

	var view := _section_text("executions")
	assert(view.contains(str(latest["id"])))
	assert(view.contains(str(latest["outcome"])), "blocked, failed and succeeded must be visible")
	assert(view.contains(str(latest["result_type"])))
	assert(view.contains(str(latest["action_id"])), "a result must point at the attempt")
	assert(view.contains(str(latest["intent_id"])), "and through it at the want")
	assert(view.contains("effects_applied"), "what actually moved must be inspectable")

	var action_view := _section_text("actions")
	var intent_view := _section_text("intents")
	assert(not action_view.contains(str(latest["id"])), "the three records must not be merged")
	assert(not intent_view.contains(str(latest["id"])))
	assert(view != action_view and view != intent_view)
	completed += 1


func _test_perception_section_shows_who_noticed() -> void:
	# The value of selective perception is being able to see who missed what,
	# and why. That has to be inspectable or the system is invisible.
	var state = main.simulation.state
	var view := _section_text("perceptions")
	assert(view.contains(state.current_event_id))
	assert(view.contains("who had a chance"))
	for entity_id in ["aster_king", "mara"]:
		assert(view.contains(str(entity_id)), "every entity's chance should be listed")
	assert(view.contains("SAW") or view.contains("MISSED"))
	# Homes are what decide it, so they belong in the same view.
	assert(view.contains(state.get_home_location("aster_king")))
	# Kept apart from what they ended up believing.
	assert(view != _section_text("knowledge"))
	completed += 1


func _test_actions_still_work_with_developer_mode_open() -> void:
	if not main.developer_mode_enabled:
		main.toggle_developer_mode()
	assert(main.developer_overlay.visible)
	var year_before: int = main.simulation.state.year
	assert(not main.simulation.state.action_taken)

	main.choose_action(0)
	assert(main.simulation.state.action_taken, "a divine action still resolves")
	assert(main.developer_mode_enabled, "resolving must not close the panel")
	main.advance_year()
	assert(main.simulation.state.year == year_before + 1, "time still advances")
	assert(main.developer_mode_enabled, "advancing must not close the panel")
	main.toggle_developer_mode()
	completed += 1
	print("  GAMEPLAY: actions and Advance Year work with the panel open.")


func _test_sections_all_render() -> void:
	for section: String in main.DEV_SECTIONS:
		var view := _section_text(section)
		assert(not view.strip_edges().is_empty(), "section '%s' rendered nothing" % section)
		assert(not view.contains("Unknown section"), "section '%s' is unhandled" % section)
	assert(main.developer_tabs.text.to_lower().contains("history"), "every section needs a tab")
	completed += 1
	print("  SECTIONS: all %d render content." % main.DEV_SECTIONS.size())


func _section_text(section: String) -> String:
	var was_open: bool = main.developer_mode_enabled
	if not was_open:
		main.toggle_developer_mode()
	main._on_developer_meta("dev_tab:" + section)
	var text: String = main.developer_text.text
	if not was_open:
		main.toggle_developer_mode()
	return text


func _press_f1() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_F1
	event.pressed = true
	main._unhandled_key_input(event)


func _snapshot() -> Array:
	var state = main.simulation.state
	return [
		state.year, state.population, state.food_level, state.stability_level,
		state.prosperity_level, state.military_level, state.faith, state.followers,
		state.divine_power, state.current_event_id, state.action_taken,
		state.previous_action_id, state.reputation,
		str(state.relationships), str(state.notable_entities), str(state.beliefs),
		str(state.belief_pressure), str(state.world_flags),
		state.history_archive.size(), state.intent_archive.size(), state.action_archive.size(),
		state.execution_archive.size(), state.perception_archive.size(),
		state.knowledge_events.size()
	]
