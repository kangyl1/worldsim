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
	_test_unrest_unlocks_protect()
	_test_shortage_unlocks_help()
	_test_surplus_requires_real_surplus()
	_test_end_to_end_event_to_intent()
	if completed != EXPECTED_TESTS:
		push_error("Event knowledge suite incomplete: %d of %d tests finished." % [
			completed, EXPECTED_TESTS
		])
		print("EVENT KNOWLEDGE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("EVENT KNOWLEDGE TEST PASSED: events teach, repeats refresh, beliefs reach intents.")
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


func _test_unrest_unlocks_protect() -> void:
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	simulation.state.current_event_id = "unrest"
	var before: Dictionary = simulation.choose_intent("mara")
	assert(str(before["intent_type"]) != "protect",
		"nothing is known before the event, so nothing is being protected from")

	simulation.tick_event_knowledge()
	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) == "protect", "a loyal witness wants the danger kept off people")
	assert(str(intent["target_id"]) == "aster")
	assert(str(intent["target_kind"]) == "settlement")
	assert(str(intent["knowledge_used"][0]["knowledge_id"]) == "aster_unrest")
	print("  UNREST: witnessing it moves Mara from %s to protect at score %d." % [
		str(before["intent_type"]), int(intent["score"])
	])
	completed += 1


func _test_shortage_unlocks_help() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"
	simulation.tick_event_knowledge()

	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) == "help")
	assert(str(intent["target_id"]) == "aster")
	assert(str(intent["knowledge_used"][0]["knowledge_id"]) == "aster_food_shortage")
	print("  SHORTAGE: Mara wants to help aster at score %d." % int(intent["score"]))
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


func _test_end_to_end_event_to_intent() -> void:
	# The full loop with no hand-placed knowledge: events must seed everything.
	var simulation = _new_simulation()
	var actions := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
	var facts_generated := 0
	var chosen_intents: Array[String] = []
	var knowledge_driven := 0
	for turn in 16:
		simulation.resolve_action(actions[turn % actions.size()])
		simulation.advance_year()
		facts_generated += simulation.state.last_event_knowledge.size()
		for intent: Dictionary in simulation.state.last_intents:
			if str(intent["selection"]) != "argmax":
				continue
			chosen_intents.append("%s:%s" % [intent["actor_id"], intent["intent_type"]])
			if not intent["knowledge_used"].is_empty():
				knowledge_driven += 1
	assert(facts_generated > 0, "the running world must generate knowledge on its own")
	assert(not chosen_intents.is_empty(), "the world must produce wants without a fallback")
	assert(knowledge_driven > 0, "generated knowledge must reach a real intent")
	assert(simulation.state.get_all_knowledge("mara").size() > 0)
	print("  END TO END: %d facts generated, %d chosen intents, %d of them belief-driven (%s)." % [
		facts_generated, chosen_intents.size(), knowledge_driven,
		", ".join(chosen_intents.slice(0, 3))
	])
	completed += 1


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation
