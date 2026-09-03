extends SceneTree

# Selective Perception v1.
#
# The law under test: an event happening is not the same as a mortal knowing it
# happened. Nothing in the perception layer may be written against a particular
# mortal, settlement or event, so these tests drive it through reusable
# properties — observability, subject, participants, and where someone lives.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 18

const SHORTAGE_TEMPLATE := {
	"id": "aster_food_shortage",
	"event_id": "drought",
	"subject_id": "aster",
	"topic": "food_shortage",
	"claim": "Aster does not have enough food",
	"confidence": 90,
	"truth_state": "true",
	"objective_truth_state": "true",
	"fresh_for_years": 3,
	"observability": "local",
	"participants": []
}

var completed := 0


func _init() -> void:
	_test_events_no_longer_teach_everyone()
	_test_local_resident_perceives()
	_test_non_resident_does_not()
	_test_no_home_perceives_no_local_event()
	_test_direct_participant_always_perceives()
	_test_non_participant_misses_a_direct_event()
	_test_hidden_events_teach_nobody()
	_test_public_events_reach_the_kingdom()
	_test_confidence_follows_the_pathway()
	_test_claim_comes_from_the_template()
	_test_hidden_world_state_is_not_leaked()
	_test_perception_enters_through_the_knowledge_api()
	_test_perception_is_not_rumor()
	_test_observer_order_changes_nothing()
	_test_rejections_are_recent_only()
	_test_tell_is_no_longer_shadowed()
	_test_rumor_still_reaches_the_uninformed()
	_test_confidence_reconciles_to_its_factors()

	if completed != EXPECTED_TESTS:
		push_error("Perception suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("PERCEPTION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("PERCEPTION TEST PASSED: mortals know different worlds.")
	quit(0)


func _test_events_no_longer_teach_everyone() -> void:
	# The whole point. Before, every notable entity learned every event fact.
	var simulation = _drought_world()
	var opportunities: Array[Dictionary] = simulation.tick_perception()
	assert(opportunities.size() == simulation.state.notable_entities.size(),
		"every entity should get a chance, judged one by one")

	var learned := 0
	for entity_id_value in simulation.state.notable_entities:
		if simulation.state.has_knowledge(str(entity_id_value), "aster_food_shortage"):
			learned += 1
	assert(learned > 0, "somebody has to notice, or the event is invisible")
	assert(learned < simulation.state.notable_entities.size(),
		"an event must no longer be known to everyone merely because it happened")
	print("  SELECTIVE: %d of %d entities learned the shortage." % [
		learned, simulation.state.notable_entities.size()
	])
	completed += 1


func _test_local_resident_perceives() -> void:
	var simulation = _drought_world()
	assert(simulation.state.get_home_location("aster_king") == "aster")
	simulation.tick_perception()

	assert(simulation.state.has_knowledge("aster_king", "aster_food_shortage"))
	var records: Array[Dictionary] = simulation.state.get_perceptions_for("aster_king")
	assert(not records.is_empty())
	var latest: Dictionary = records.back()
	assert(bool(latest["eligible"]) and bool(latest["perceived"]))
	assert(str(latest["reason"]) == "local")
	assert(str(latest["knowledge_id"]) == "aster_food_shortage")
	print("  LOCAL: the King lives in Aster and saw it, at confidence %d." % int(latest["confidence"]))
	completed += 1


func _test_non_resident_does_not() -> void:
	var simulation = _drought_world()
	assert(simulation.state.get_home_location("mara") == "westfield")
	var opportunities: Array[Dictionary] = simulation.tick_perception()

	assert(not simulation.state.has_knowledge("mara", "aster_food_shortage"),
		"someone living elsewhere must not learn a local event for free")
	var missed := _opportunity_for(opportunities, "mara")
	assert(not bool(missed["eligible"]))
	assert(not bool(missed["perceived"]))
	assert(str(missed["reason"]) == "elsewhere")
	assert(int(missed["confidence"]) == 0)
	assert(simulation.state.get_perceptions_for("mara").is_empty(),
		"a missed chance is not a perception")
	print("  ELSEWHERE: Mara is in Westfield and knew nothing of Aster's shortage.")
	completed += 1


func _test_no_home_perceives_no_local_event() -> void:
	# An entity with no association perceives no local event. Honest, rather
	# than silently placing everyone in the capital.
	var simulation = _drought_world()
	assert(simulation.state.add_notable_entity("drifter", "The Drifter", "person", []))
	assert(simulation.state.get_home_location("drifter").is_empty())
	var opportunities: Array[Dictionary] = simulation.tick_perception()

	var missed := _opportunity_for(opportunities, "drifter")
	assert(str(missed["reason"]) == "no_home_location")
	assert(not simulation.state.has_knowledge("drifter", "aster_food_shortage"))

	# Give them a home in the affected place and the same event reaches them.
	assert(simulation.state.set_home_location("drifter", "aster"))
	simulation.tick_perception()
	assert(simulation.state.has_knowledge("drifter", "aster_food_shortage"))
	assert(simulation.state.residents_of("aster") == ["aster_king", "drifter"])
	print("  NO HOME: unplaced mortals notice nothing local until they are placed.")
	completed += 1


func _test_direct_participant_always_perceives() -> void:
	# Being part of something beats being near it, whatever the scope.
	var simulation = _drought_world()
	var private_fact := _fact("hidden", ["mara"])
	var opportunity: Dictionary = simulation.perception_rules.evaluate(
		simulation.state, private_fact, "mara"
	)
	assert(bool(opportunity["eligible"]) and bool(opportunity["perceived"]))
	assert(str(opportunity["reason"]) == "direct")
	assert(int(opportunity["confidence"]) == 90, "a participant loses nothing in the telling")
	print("  DIRECT: a participant perceives a hidden event at full clarity.")
	completed += 1


func _test_non_participant_misses_a_direct_event() -> void:
	var simulation = _drought_world()
	var private_fact := _fact("direct", ["mara"])
	# The King lives where it happened and still has no part in it.
	var opportunity: Dictionary = simulation.perception_rules.evaluate(
		simulation.state, private_fact, "aster_king"
	)
	assert(not bool(opportunity["eligible"]))
	assert(str(opportunity["reason"]) == "not_a_participant")
	assert(int(opportunity["confidence"]) == 0)
	print("  PRIVATE: living nearby is not the same as being party to it.")
	completed += 1


func _test_hidden_events_teach_nobody() -> void:
	var simulation = _drought_world()
	var secret := _fact("hidden", [])
	for entity_id in ["aster_king", "mara"]:
		var opportunity: Dictionary = simulation.perception_rules.evaluate(
			simulation.state, secret, str(entity_id)
		)
		assert(not bool(opportunity["perceived"]), "a secret must stay secret")
		assert(str(opportunity["reason"]) == "not_a_participant")
	print("  HIDDEN: a secret with no participants is known to nobody.")
	completed += 1


func _test_public_events_reach_the_kingdom() -> void:
	# One kingdom exists, so public means every notable entity in it. Broad, but
	# not omniscient: it still costs clarity, and it is still a decision made
	# per observer rather than a bulk insert.
	var simulation = _drought_world()
	assert(simulation.state.add_notable_entity("drifter", "The Drifter", "person", []))
	var proclamation := _fact("public", [])
	var perceived := 0
	for entity_id_value in simulation.state.notable_entities:
		var opportunity: Dictionary = simulation.perception_rules.evaluate(
			simulation.state, proclamation, str(entity_id_value)
		)
		assert(bool(opportunity["eligible"]), "a public event excludes nobody")
		assert(str(opportunity["reason"]) == "public")
		perceived += 1
	assert(perceived == 3, "including the one with no home at all")
	print("  PUBLIC: reached all %d, including the unplaced." % perceived)
	completed += 1


func _test_confidence_follows_the_pathway() -> void:
	var simulation = _drought_world()
	var direct: Dictionary = simulation.perception_rules.evaluate(
		simulation.state, _fact("local", ["mara"]), "mara"
	)
	var local: Dictionary = simulation.perception_rules.evaluate(
		simulation.state, _fact("local", []), "aster_king"
	)
	var public: Dictionary = simulation.perception_rules.evaluate(
		simulation.state, _fact("public", []), "mara"
	)
	assert(int(direct["confidence"]) > int(local["confidence"]),
		"being in it beats seeing it")
	assert(int(local["confidence"]) > int(public["confidence"]),
		"seeing it beats it merely being visible")
	assert(int(direct["confidence"]) <= 90, "the event's own plainness is the ceiling")
	print("  PATHWAY: direct %d, local %d, public %d." % [
		int(direct["confidence"]), int(local["confidence"]), int(public["confidence"])
	])
	completed += 1


func _test_claim_comes_from_the_template() -> void:
	var simulation = _drought_world()
	simulation.tick_perception()
	var known: Dictionary = simulation.state.get_knowledge("aster_king", "aster_food_shortage")
	assert(str(known["claim"]) == str(SHORTAGE_TEMPLATE["claim"]))
	assert(str(known["topic"]) == str(SHORTAGE_TEMPLATE["topic"]))
	assert(str(known["subject_id"]) == str(SHORTAGE_TEMPLATE["subject_id"]))
	print("  TEMPLATE: what he came away with is what the event offered.")
	completed += 1


func _test_hidden_world_state_is_not_leaked() -> void:
	# The template is the boundary. He may learn that Aster lacks food; he may
	# not learn the number behind it, or anything the event did not expose.
	var simulation = _drought_world()
	simulation.state.stability_level = 0
	simulation.state.military_level = 3
	simulation.tick_perception()

	var known := str(simulation.state.get_knowledge("aster_king", "aster_food_shortage"))
	assert(not known.contains("food_level"))
	assert(not known.contains("stability_level"))
	assert(not known.contains("military_level"))
	assert(simulation.state.get_all_knowledge("aster_king").size() == 1,
		"one event offers one claim, not a survey of the world")
	print("  BOUNDARY: the claim, and nothing the event did not expose.")
	completed += 1


func _test_perception_enters_through_the_knowledge_api() -> void:
	var simulation = _drought_world()
	simulation.tick_perception()
	var record: Dictionary = simulation.state.get_knowledge("aster_king", "aster_food_shortage")
	# Perception supplies the observation; the knowledge system owns the rest.
	for field: String in [
		"confidence", "freshness", "is_outdated", "invalidated", "truth_state",
		"objective_truth_state", "source_id", "source_type", "transmission_count",
		"distorted", "year_learned", "last_updated_year", "fresh_for_years"
	]:
		assert(record.has(field), "the knowledge record is missing %s" % field)
	assert(int(record["transmission_count"]) == 0, "nobody passed this on; he saw it")
	assert(str(record["owner_id"]) == "aster_king")

	# Ageing still applies to it exactly as to anything else.
	simulation.state.year += 6
	simulation.state.age_knowledge()
	var aged: Dictionary = simulation.state.get_knowledge("aster_king", "aster_food_shortage")
	assert(bool(aged["is_outdated"]), "perceived knowledge ages like any other")
	print("  KNOWLEDGE API: stored, sourced, aged and invalidated by the existing system.")
	completed += 1


func _test_perception_is_not_rumor() -> void:
	# Seeing a thing and being told it must stay distinguishable.
	var simulation = _drought_world()
	simulation.tick_perception()
	var seen: Dictionary = simulation.state.get_knowledge("aster_king", "aster_food_shortage")
	assert(str(seen["source_type"]) == "direct", "he saw it himself")
	assert(str(seen["source_id"]) == "aster_king")

	simulation.share_knowledge("aster_king", "mara", "aster_food_shortage")
	var heard: Dictionary = simulation.state.get_knowledge("mara", "aster_food_shortage")
	assert(not heard.is_empty(), "the fixture needs the rumor to land")
	assert(str(heard["source_type"]) == "rumor", "she was told")
	assert(str(heard["source_id"]) == "aster_king")
	assert(int(heard["confidence"]) < int(seen["confidence"]),
		"hearsay must cost something against seeing it")
	print("  NOT RUMOR: seen at %d, heard at %d, and the two are labelled apart." % [
		int(seen["confidence"]), int(heard["confidence"])
	])
	completed += 1


func _test_observer_order_changes_nothing() -> void:
	# One observer coming to know a thing must never change whether another
	# could have seen it for themselves.
	var forward = _crowded_world()
	var forward_results := _perception_map(forward.tick_perception())

	var backward = _crowded_world()
	var fact = backward.observable_fact()
	var entity_ids: Array = backward.state.notable_entities.keys()
	entity_ids.sort()
	entity_ids.reverse()
	var reversed_results := {}
	for entity_id_value in entity_ids:
		var opportunity: Dictionary = backward.perception_rules.evaluate(
			backward.state, fact, str(entity_id_value)
		)
		reversed_results[str(opportunity["observer_id"])] = "%s:%d" % [
			str(opportunity["reason"]), int(opportunity["confidence"])
		]
	assert(forward_results == reversed_results,
		"reversing the observers must change nothing: %s vs %s" % [
			str(forward_results), str(reversed_results)
		])
	print("  FAIR ORDER: %s either way round." % str(forward_results))
	completed += 1


func _test_rejections_are_recent_only() -> void:
	# Who missed something is worth inspecting this year and not worth
	# remembering forever.
	var simulation = _drought_world()
	var opportunities: Array[Dictionary] = simulation.tick_perception()
	simulation.state.last_perceptions = opportunities

	var missed := 0
	for opportunity: Dictionary in simulation.state.last_perceptions:
		if not bool(opportunity["perceived"]):
			missed += 1
			assert(not str(opportunity["reason"]).is_empty(), "a miss must name its cause")
	assert(missed > 0, "the fixture needs someone to miss it")
	for record: Dictionary in simulation.state.perception_archive:
		assert(bool(record["perceived"]), "the archive keeps only what was actually noticed")
	assert(simulation.state.perceptions.size() <= WorldState.MAX_STORED_PERCEPTIONS)
	print("  BOUNDED: %d misses visible this year, none kept forever." % missed)
	completed += 1


func _test_tell_is_no_longer_shadowed() -> void:
	# The success condition. One mortal perceives, another does not, and the
	# opportunity to tell them genuinely exists.
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	simulation.state.current_event_id = "unrest"
	simulation.tick_perception()
	assert(simulation.state.has_knowledge("aster_king", "aster_unrest"))
	assert(not simulation.state.has_knowledge("mara", "aster_unrest"))

	var intent: Dictionary = simulation.choose_intent("aster_king")
	var action: Dictionary = simulation.choose_mortal_action(intent)
	var tell := _candidate_for(action["considered"], "tell", "mara")
	assert(not tell.is_empty(), "telling her must at least be on the table")
	assert(bool(tell["viable"]), "and it must not be refused")
	assert(str(tell["reason"]) != "target_already_knows",
		"the whole point: she does not already know")

	var execution: Dictionary = simulation.execute_mortal_action(action)
	if str(execution["action_type"]) == "tell":
		assert(str(execution["outcome"]) == "success")
		assert(simulation.state.has_knowledge("mara", "aster_unrest"))
	print("  TELL REACHABLE: %s was viable at score %d, and the King chose %s." % [
		"tell", int(tell["score"]), str(action["action_type"])
	])
	completed += 1


func _test_rumor_still_reaches_the_uninformed() -> void:
	# Selective perception must not cut anyone off permanently. What she did not
	# see, she can still come to hear.
	var simulation = _drought_world()
	simulation.tick_perception()
	assert(not simulation.state.has_knowledge("mara", "aster_food_shortage"))

	var attempt: Dictionary = simulation.share_knowledge("aster_king", "mara", "aster_food_shortage")
	assert(bool(attempt["shared"]), "the ordinary rumor path must still work")
	assert(simulation.state.has_knowledge("mara", "aster_food_shortage"))

	# And now she can want something because of it.
	var intent: Dictionary = simulation.choose_intent("mara")
	var used: Array = intent["knowledge_used"]
	var drove := false
	for factor: Dictionary in used:
		if str(factor["knowledge_id"]) == "aster_food_shortage":
			drove = true
	assert(drove, "what she was told must be able to reach her intentions")
	print("  RUMOR ROUTE: told, then wanting to %s because of it." % str(intent["intent_type"]))
	completed += 1


func _test_confidence_reconciles_to_its_factors() -> void:
	var simulation = _crowded_world()
	var checked := 0
	for opportunity: Dictionary in simulation.tick_perception():
		if not bool(opportunity["eligible"]):
			assert(opportunity["factors"].is_empty())
			assert(int(opportunity["confidence"]) == 0)
			continue
		var total := 0
		for factor: Dictionary in opportunity["factors"]:
			total += int(factor["delta"])
		assert(total == int(opportunity["confidence"]),
			"confidence must equal what was recorded")
		assert(not opportunity["reasons"].is_empty(), "a perception must say how it happened")
		checked += 1
	assert(checked > 0)
	print("  INTEGRITY: %d perceptions reconciled to their factors." % checked)
	completed += 1


# --- fixtures ----------------------------------------------------------------


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _drought_world():
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"
	return simulation


func _crowded_world():
	var simulation = _drought_world()
	simulation.state.add_notable_entity("scribe", "The Scribe", "person", [], {}, "aster")
	simulation.state.add_notable_entity("watchman", "The Watchman", "person", [], {}, "frontier")
	simulation.state.add_notable_entity("drifter", "The Drifter", "person", [])
	return simulation


func _fact(observability: String, participants: Array) -> Dictionary:
	var fact := SHORTAGE_TEMPLATE.duplicate(true)
	fact["observability"] = observability
	fact["participants"] = participants
	return fact


func _opportunity_for(opportunities: Array, observer_id: String) -> Dictionary:
	for opportunity: Dictionary in opportunities:
		if str(opportunity["observer_id"]) == observer_id:
			return opportunity
	return {}


func _candidate_for(considered: Array, action_type: String, target_id: String) -> Dictionary:
	for candidate: Dictionary in considered:
		if str(candidate["action_type"]) == action_type and str(candidate["target_id"]) == target_id:
			return candidate
	return {}


func _perception_map(opportunities: Array) -> Dictionary:
	var results := {}
	for opportunity: Dictionary in opportunities:
		results[str(opportunity["observer_id"])] = "%s:%d" % [
			str(opportunity["reason"]), int(opportunity["confidence"])
		]
	return results
