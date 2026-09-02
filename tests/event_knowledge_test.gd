extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const DIRECT_CONFIDENCE := 90
const EXPECTED_TESTS := 8

var completed := 0


func _init() -> void:
	_test_drought_generates_fact()
	_test_absorbed_event_teaches_nothing()
	_test_repeat_refreshes_same_record()
	_test_generated_fact_spreads_as_rumor()
	_test_unrest_unlocks_warn_ally()
	_test_shortage_unlocks_send_aid()
	_test_surplus_requires_real_surplus()
	_test_end_to_end_event_to_decision()
	if completed != EXPECTED_TESTS:
		push_error("Event knowledge suite incomplete: %d of %d tests finished." % [
			completed, EXPECTED_TESTS
		])
		print("EVENT KNOWLEDGE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("EVENT KNOWLEDGE TEST PASSED: events teach, repeats refresh, beliefs reach decisions.")
	quit(0)


func _test_drought_generates_fact() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"

	var learned: Array[Dictionary] = simulation.tick_event_knowledge()
	assert(learned.size() == 2, "every notable entity should witness a public event")
	for entity_id in ["aster_king", "mara"]:
		var record: Dictionary = simulation.state.get_knowledge(str(entity_id), "aster_food_shortage")
		assert(not record.is_empty(), "%s should have learned the shortage" % entity_id)
		assert(int(record["confidence"]) == DIRECT_CONFIDENCE)
		assert(str(record["subject_id"]) == "aster")
		assert(str(record["topic"]) == "food_shortage")
		assert(str(record["source_type"]) == "direct")
		assert(str(record["source_id"]) == str(entity_id), "a witness is its own source")
		assert(int(record["transmission_count"]) == 0)
		assert(str(record["objective_truth_state"]) == "true")
		assert(not bool(record["is_outdated"]))
	print("  DROUGHT: both witnesses learned aster_food_shortage at %d." % DIRECT_CONFIDENCE)
	completed += 1


func _test_absorbed_event_teaches_nothing() -> void:
	# A drought the wells absorbed leaves food intact, so there is nothing to learn.
	var simulation = _new_simulation()
	simulation.state.food_level = 3
	simulation.state.current_event_id = "drought"
	assert(simulation.tick_event_knowledge().is_empty())
	assert(simulation.state.get_all_knowledge("mara").is_empty())

	# Unrest settled by the council leaves stability standing.
	simulation.state.stability_level = 2
	simulation.state.current_event_id = "unrest"
	assert(simulation.tick_event_knowledge().is_empty())
	assert(simulation.state.get_all_knowledge("mara").is_empty())
	print("  ABSORBED: an event the world withstood generates no belief.")
	completed += 1


func _test_repeat_refreshes_same_record() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"

	var first: Array[Dictionary] = simulation.tick_event_knowledge()
	assert(not bool(first[0]["refreshed"]))
	var learned_year: int = int(simulation.state.get_knowledge("mara", "aster_food_shortage")["year_learned"])

	# Age the belief past its freshness window, then witness the shortage again.
	simulation.state.year += 4
	simulation.state.age_knowledge()
	var stale: Dictionary = simulation.state.get_knowledge("mara", "aster_food_shortage")
	assert(int(stale["confidence"]) < DIRECT_CONFIDENCE, "the belief should have decayed first")

	var second: Array[Dictionary] = simulation.tick_event_knowledge()
	assert(bool(second[0]["refreshed"]), "a repeat must refresh rather than announce a new fact")
	assert(simulation.state.get_all_knowledge("mara").size() == 1, "no duplicate record may appear")
	var refreshed: Dictionary = simulation.state.get_knowledge("mara", "aster_food_shortage")
	assert(str(refreshed["id"]) == "aster_food_shortage", "the stable id must be reused")
	assert(int(refreshed["year_learned"]) == learned_year, "first learning year must survive")
	assert(int(refreshed["last_updated_year"]) == simulation.state.year)
	assert(int(refreshed["confidence"]) == DIRECT_CONFIDENCE)
	assert(not bool(refreshed["is_outdated"]))
	print("  REPEAT: same id refreshed to %d, learned year %d preserved." % [
		int(refreshed["confidence"]), learned_year
	])
	completed += 1


func _test_generated_fact_spreads_as_rumor() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"
	simulation.tick_event_knowledge()

	# A newcomer who never witnessed the drought can only hear about it.
	assert(simulation.state.add_notable_entity("grey_merchant", "The Grey Merchant", "person", []))
	assert(simulation.state.set_relationship("mara", "grey_merchant", {
		"trust": 80,
		"fear": 0,
		"respect": 40,
		"hostility": 0
	}))
	assert(not simulation.state.has_knowledge("grey_merchant", "aster_food_shortage"))

	var result: Dictionary = simulation.share_knowledge("mara", "grey_merchant", "aster_food_shortage")
	assert(bool(result["allowed"]), "the existing rumor system should carry a generated fact")
	var received: Dictionary = simulation.state.get_knowledge("grey_merchant", "aster_food_shortage")
	assert(int(received["confidence"]) < DIRECT_CONFIDENCE, "hearsay must cost confidence")
	assert(str(received["source_type"]) == "rumor")
	assert(str(received["source_id"]) == "mara")
	assert(int(received["transmission_count"]) == 1)
	print("  RUMOR: generated fact travelled Mara %d -> Merchant %d." % [
		DIRECT_CONFIDENCE, int(received["confidence"])
	])
	completed += 1


func _test_unrest_unlocks_warn_ally() -> void:
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	simulation.state.current_event_id = "unrest"
	assert(simulation.choose_decision("mara")["decision_type"] == "wait_and_observe",
		"nothing is known before the event")

	simulation.tick_event_knowledge()
	var decision: Dictionary = simulation.choose_decision("mara")
	assert(decision["decision_type"] == "warn_ally", "a loyal witness should warn her ally")
	assert(str(decision["target_id"]) == "aster_king")
	assert(str(decision["knowledge_used"][0]["knowledge_id"]) == "aster_unrest")
	print("  UNREST: Mara moves from wait_and_observe to warn_ally at score %d." % int(decision["score"]))
	completed += 1


func _test_shortage_unlocks_send_aid() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"
	simulation.tick_event_knowledge()

	var decision: Dictionary = simulation.choose_decision("mara")
	assert(decision["decision_type"] == "send_aid")
	assert(str(decision["target_id"]) == "aster")
	assert(str(decision["knowledge_used"][0]["knowledge_id"]) == "aster_food_shortage")
	print("  SHORTAGE: Mara intends send_aid toward aster at score %d." % int(decision["score"]))
	completed += 1


func _test_surplus_requires_real_surplus() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 1
	simulation.state.current_event_id = "good_harvest"
	assert(simulation.tick_event_knowledge().is_empty(), "a thin harvest is not a surplus")

	simulation.state.food_level = 2
	var learned: Array[Dictionary] = simulation.tick_event_knowledge()
	assert(learned.size() == 2)
	var record: Dictionary = simulation.state.get_knowledge("aster_king", "aster_surplus")
	assert(str(record["topic"]) == "surplus")
	assert(int(record["confidence"]) == DIRECT_CONFIDENCE)
	print("  SURPLUS: recorded only once stores actually recovered.")
	completed += 1


func _test_end_to_end_event_to_decision() -> void:
	# The full loop with no hand-placed knowledge: events must seed everything.
	var simulation = _new_simulation()
	var actions := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
	var facts_generated := 0
	var real_decisions: Array[String] = []
	for turn in 16:
		simulation.resolve_action(actions[turn % actions.size()])
		simulation.advance_year()
		facts_generated += simulation.state.last_event_knowledge.size()
		for decision: Dictionary in simulation.state.last_decisions:
			if str(decision["decision_type"]) != "wait_and_observe":
				real_decisions.append("%s:%s" % [decision["actor_id"], decision["decision_type"]])
	assert(facts_generated > 0, "the running world must generate knowledge on its own")
	assert(not real_decisions.is_empty(), "generated knowledge must reach a real decision")
	assert(simulation.state.get_all_knowledge("mara").size() > 0)
	print("  END TO END: %d facts generated, %d non-fallback decisions (%s)." % [
		facts_generated, real_decisions.size(), ", ".join(real_decisions.slice(0, 3))
	])
	completed += 1


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation
