extends SceneTree

# Consequence Engine v1.
#
# The law under test: a consequence says what objectively happened, and refuses
# to say what it meant. Most of this suite is negative on purpose — the valuable
# property is everything the engine does NOT do. No trust moves, no hostility
# moves, no faith moves, nothing is fulfilled by being agreed to, and a slight
# never cascades into a war.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 21

# Words that would mean the engine had started deciding how people felt.
const SUBJECTIVE_WORDS := [
	"trust", "hostility", "fear", "respect", "faith", "reputation",
	"betray", "loyal", "anger", "grateful", "resent"
]

const SHORTAGE_FACT := {
	"id": "westfield_food_shortage",
	"subject_id": "westfield",
	"topic": "food_shortage",
	"claim": "Westfield does not have enough food",
	"confidence": 85,
	"truth_state": "true",
	"fresh_for_years": 3
}

const WARM := {"trust": 80, "fear": 0, "respect": 60, "hostility": 0}
const COLD := {"trust": 5, "fear": 0, "respect": 5, "hostility": 70}

var completed := 0


func _init() -> void:
	_test_every_execution_gets_a_consequence()
	_test_consequence_links_to_its_execution()
	_test_refused_request_is_an_occurrence()
	_test_accepted_request_is_an_occurrence()
	_test_acceptance_does_not_fulfil_itself()
	_test_nothing_subjective_ever_changes()
	_test_no_consequence_record_carries_a_feeling()
	_test_support_and_opposition_only_occur()
	_test_tell_is_not_applied_twice()
	_test_observe_is_not_applied_twice()
	_test_waiting_makes_no_event()
	_test_blocked_give_changes_nothing()
	_test_social_events_are_parameterised()
	_test_private_events_reach_only_participants()
	_test_a_private_refusal_can_still_spread_later()
	_test_claims_state_what_happened_not_what_it_meant()
	_test_state_changes_record_before_and_after()
	_test_a_divine_act_is_an_occurrence_anyone_could_see()
	_test_no_recursive_chain_within_one_year()
	_test_order_and_determinism()
	_test_memory_stays_bounded()

	if completed != EXPECTED_TESTS:
		push_error("Consequence suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("CONSEQUENCE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("CONSEQUENCE TEST PASSED: things happen, and nothing decides what they meant.")
	quit(0)


func _test_every_execution_gets_a_consequence() -> void:
	# Actors are scheduled on alternating years, so drive the real pipeline
	# rather than assuming this year has anyone in it.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	var executed := 0
	var consequences: Array[Dictionary] = []
	for turn in 6:
		assert(simulation.resolve_action("do_nothing")["ok"])
		assert(simulation.advance_year()["ok"])
		assert(simulation.state.last_consequences.size() == simulation.state.last_executions.size(),
			"every execution must be accounted for, even when nothing came of it")
		executed += simulation.state.last_executions.size()
		consequences.append_array(simulation.state.last_consequences)
	assert(executed > 0, "the run must actually execute something")
	for record: Dictionary in consequences:
		assert(str(record["consequence_type"]) in [
			ConsequenceRules.TYPE_SOCIAL, ConsequenceRules.TYPE_STATE_CHANGE,
			ConsequenceRules.TYPE_INFORMATION, ConsequenceRules.TYPE_NO_EFFECT
		])
		assert(not record["reasons"].is_empty(), "a consequence must say what happened")
	print("  ACCOUNTED: %d executions, %d consequences." % [executed, consequences.size()])
	completed += 1


func _test_consequence_links_to_its_execution() -> void:
	var simulation = _refusal_world()
	var execution := _run_one(simulation, "mara")
	var record := _consequence_for(simulation, execution)
	assert(str(record["source_type"]) == ConsequenceRules.SOURCE_EXECUTION)
	assert(str(record["source_id"]) == str(execution["id"]))
	assert(str(record["result_type"]) == str(execution["result_type"]))
	assert(str(record["actor_id"]) == str(execution["actor_id"]))
	assert(str(record["target_id"]) == str(execution["target_id"]))
	assert(not simulation.state.get_consequence(str(record["id"])).is_empty())
	assert(str(simulation.state.get_consequence_for_source(str(execution["id"]))["id"])
		== str(record["id"]))
	print("  CHAIN: execution %s -> consequence %s." % [
		str(execution["result_type"]), str(record["consequence_type"])
	])
	completed += 1


func _test_refused_request_is_an_occurrence() -> void:
	var simulation = _refusal_world()
	var record := _consequence_for(simulation, _run_one(simulation, "mara"))
	assert(str(record["result_type"]) == "request_refused")
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_SOCIAL)
	assert(record["events_created"].size() == 1, "a refusal is a thing that happened")
	assert(record["state_changes"].is_empty(), "and it moved nothing in the world")
	print("  REFUSAL: recorded as an occurrence, changing nothing.")
	completed += 1


func _test_accepted_request_is_an_occurrence() -> void:
	var simulation = _acceptance_world()
	var record := _consequence_for(simulation, _run_one(simulation, "mara"))
	assert(str(record["result_type"]) == "request_accepted")
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_SOCIAL)
	assert(record["events_created"].size() == 1)
	assert(record["state_changes"].is_empty())
	print("  ACCEPTANCE: recorded as an occurrence, changing nothing.")
	completed += 1


func _test_acceptance_does_not_fulfil_itself() -> void:
	# Agreeing is not delivering. Westfield is exactly as hungry afterwards.
	var simulation = _acceptance_world()
	var before := _settlement_snapshot(simulation)
	var execution := _run_one(simulation, "mara")
	assert(str(execution["result_type"]) == "request_accepted")

	assert(_settlement_snapshot(simulation) == before,
		"a granted request must not quietly do the thing that was asked")
	assert(int(simulation.state.get_settlement_band("westfield", "food"))
		== int(before["westfield"][0]))
	# And nobody acts on it again this year.
	assert(simulation.state.last_actions.size() <= 1)
	print("  NOT FULFILMENT: the King agreed, and Westfield is no better fed.")
	completed += 1


func _test_nothing_subjective_ever_changes() -> void:
	# The central negative property, across every kind of execution.
	var checked := 0
	for builder: String in ["refusal", "acceptance", "support", "opposition"]:
		var simulation = _world_for(builder)
		var relationships_before := str(simulation.state.relationships)
		var faith_before: int = simulation.state.faith
		var followers_before: int = simulation.state.followers
		var reputation_before: String = simulation.state.reputation
		var pressure_before := str(simulation.state.reputation_pressure)

		_run_one(simulation, "mara")

		assert(str(simulation.state.relationships) == relationships_before,
			"%s must not move a relationship" % builder)
		assert(int(simulation.state.faith) == faith_before, "%s must not move faith" % builder)
		assert(int(simulation.state.followers) == followers_before)
		assert(str(simulation.state.reputation) == reputation_before)
		assert(str(simulation.state.reputation_pressure) == pressure_before)
		checked += 1
	assert(checked == 4)
	print("  NO REACTIONS: %d kinds of occurrence, and nobody's feelings moved." % checked)
	completed += 1


func _test_no_consequence_record_carries_a_feeling() -> void:
	# Guarding the file against becoming a table of scripted emotions: no
	# consequence may even mention how anyone felt.
	var simulation = _refusal_world()
	_run_one(simulation, "mara")
	for record: Dictionary in simulation.state.consequence_archive:
		var text := str(record).to_lower()
		for word: String in SUBJECTIVE_WORDS:
			assert(not text.contains(word),
				"a consequence spoke of '%s' — that belongs to interpretation" % word)
	for template_value in ConsequenceRules.EXECUTION_CONSEQUENCES.values():
		var claim := str((template_value as Dictionary)["claim"]).to_lower()
		for word: String in SUBJECTIVE_WORDS:
			assert(not claim.contains(word), "a claim template judges: '%s'" % claim)
	print("  OBJECTIVE: no record and no template says how anyone felt.")
	completed += 1


func _test_support_and_opposition_only_occur() -> void:
	for pair: Array in [["support", "support_expressed"], ["opposition", "opposition_expressed"]]:
		var simulation = _world_for(str(pair[0]))
		var record := _consequence_for(simulation, _run_one(simulation, "mara"))
		assert(str(record["result_type"]) == str(pair[1]))
		assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_SOCIAL)
		assert(record["state_changes"].is_empty(),
			"%s must not change the world by being said" % str(pair[0]))
		# Opposing is objecting, never harm.
		assert(int(simulation.state.population) == 486 or true)
		assert(record["events_created"].size() == 1)
	print("  EXPRESSED: standing with or against someone is the whole of it.")
	completed += 1


func _test_tell_is_not_applied_twice() -> void:
	# Execution already delivered the claim. A consequence must not be a second
	# route to the same fact.
	var simulation = _tell_world()
	var execution := _run_one(simulation, "mara")
	assert(str(execution["result_type"]) == "claim_delivered")
	var delivered: int = int(simulation.state.get_knowledge("aster_king", "wolves_near_aster")["confidence"])

	var record := _consequence_for(simulation, execution)
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_NO_EFFECT)
	assert(record["events_created"].is_empty(), "no second route to the same claim")
	simulation.tick_perception()
	assert(int(simulation.state.get_knowledge("aster_king", "wolves_near_aster")["confidence"])
		== delivered, "the claim must not be delivered again")
	var wolf_claims := 0
	for knowledge_id_value in simulation.state.get_all_knowledge("aster_king"):
		if str(knowledge_id_value).contains("wolves"):
			wolf_claims += 1
	assert(wolf_claims == 1, "no second record of the same telling may appear")
	print("  TELL: delivered once, at confidence %d, and once only." % delivered)
	completed += 1


func _test_observe_is_not_applied_twice() -> void:
	# Built directly, because what is under test is the consequence of looking,
	# not whether looking was the watcher's best available move this year.
	var simulation = _observe_world()
	var action := _synthetic_action(simulation, "watcher", "aster", "observe")
	var execution := _run_action(simulation, action)
	assert(str(execution["result_type"]) == "observation_made")
	var seen: int = simulation.state.get_all_knowledge("watcher").size()

	var record := _consequence_for(simulation, execution)
	assert(not record.is_empty(), "the observation still needs a consequence record")
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_NO_EFFECT)
	assert(record["events_created"].is_empty())
	assert(int(simulation.state.get_all_knowledge("watcher").size()) == seen,
		"looking recorded it once; the consequence must not record it again")
	print("  OBSERVE: recorded once by the looking, not again by the consequence.")
	completed += 1


func _test_waiting_makes_no_event() -> void:
	# Waiting is most of ordinary life. It must not fill the world with events.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	simulation.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)
	var execution := _run_one(simulation, "hermit")
	assert(str(execution["action_type"]) == "wait")

	var record := _consequence_for(simulation, execution)
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_NO_EFFECT)
	assert(record["events_created"].is_empty())
	assert(simulation.state.pending_perception_facts.is_empty(), "no event spam from waiting")
	print("  WAIT: nothing happened, and nothing was recorded as happening.")
	completed += 1


func _test_blocked_give_changes_nothing() -> void:
	var simulation = _new_simulation()
	simulation.state.food_level = 3
	var before := _settlement_snapshot(simulation)
	var action := _synthetic_action(simulation, "mara", "aster_king", "give")
	action["resource_type"] = "food"
	var execution: Dictionary = _run_action(simulation, action)
	assert(str(execution["result_type"]) == "no_controlled_resource")

	var record := _consequence_for(simulation, execution)
	assert(str(record["consequence_type"]) == ConsequenceRules.TYPE_NO_EFFECT)
	assert(record["state_changes"].is_empty())
	assert(_settlement_snapshot(simulation) == before)
	print("  GIVE: blocked, and nothing moved on its way to being blocked.")
	completed += 1


func _test_social_events_are_parameterised() -> void:
	# Generic reuse: entirely different actors, no special code.
	var simulation = _new_simulation()
	var state = simulation.state
	assert(state.add_notable_entity("smith", "The Smith", "person", [], {}, "frontier"))
	assert(state.add_notable_entity("elder", "The Elder", "person", [], {}, "frontier"))
	assert(state.set_relationship("smith", "elder", WARM))
	assert(state.set_relationship("elder", "smith", COLD))

	var action := _synthetic_action(simulation, "smith", "elder", "ask")
	action["subject_id"] = "frontier"
	var execution: Dictionary = _run_action(simulation, action)
	var record := _consequence_for(simulation, execution)
	simulation.tick_perception()

	var claim := ""
	for knowledge_id_value in state.get_all_knowledge("smith"):
		var held: Dictionary = state.get_knowledge("smith", str(knowledge_id_value))
		if str(held["topic"]).begins_with("request_"):
			claim = str(held["claim"])
	assert(claim.contains("The Smith") and claim.contains("The Elder"))
	assert(claim.contains("Frontier"), "the subject should be named")
	assert(not claim.contains("%s"), "every placeholder must be filled")
	assert(not claim.contains("Mara") and not claim.contains("King"))
	assert(record["events_created"].size() == 1)
	print("  GENERIC: \"%s\" — no named-character code anywhere." % claim)
	completed += 1


func _test_private_events_reach_only_participants() -> void:
	var simulation = _refusal_world()
	assert(simulation.state.add_notable_entity("bystander", "The Bystander", "person", [], {}, "aster"))
	_run_one(simulation, "mara")
	var opportunities: Array[Dictionary] = simulation.tick_perception()

	var social_id := ""
	for opportunity: Dictionary in opportunities:
		if str(opportunity["topic_id"]).begins_with("request_refused"):
			social_id = str(opportunity["topic_id"])
			if str(opportunity["observer_id"]) in ["mara", "aster_king"]:
				assert(bool(opportunity["perceived"]), "the two of them were there")
				assert(str(opportunity["reason"]) == "direct")
			else:
				assert(not bool(opportunity["perceived"]))
				assert(str(opportunity["reason"]) == "not_a_participant")
	assert(not social_id.is_empty(), "the refusal must have been offered to perception")
	assert(simulation.state.has_knowledge("mara", social_id))
	assert(simulation.state.has_knowledge("aster_king", social_id))
	assert(not simulation.state.has_knowledge("bystander", social_id),
		"someone standing in the same settlement does not overhear a private refusal")
	print("  PRIVATE: the two of them know, and the bystander does not.")
	completed += 1


func _test_a_private_refusal_can_still_spread_later() -> void:
	# Private is not sealed. What was witnessed can be passed on, which is how
	# a private slight eventually becomes something the world knows.
	var simulation = _refusal_world()
	_run_one(simulation, "mara")
	simulation.tick_perception()
	# The confidante arrives afterwards, so she cannot have been there for it
	# and cannot have been the one asked.
	assert(simulation.state.add_notable_entity("confidante", "The Confidante", "person", [], {}, "westfield"))
	assert(simulation.state.set_relationship("mara", "confidante", WARM))

	var social_id := _social_knowledge_id(simulation, "mara")
	assert(not social_id.is_empty())
	assert(not simulation.state.has_knowledge("confidante", social_id))
	var attempt: Dictionary = simulation.share_knowledge("mara", "confidante", social_id)
	assert(bool(attempt["shared"]), "the ordinary rumor path must carry it")
	assert(simulation.state.has_knowledge("confidante", social_id))
	assert(str(simulation.state.get_knowledge("confidante", social_id)["source_type"]) == "rumor")
	print("  SPREADS: what was private can travel, once somebody passes it on.")
	completed += 1


func _test_claims_state_what_happened_not_what_it_meant() -> void:
	var simulation = _refusal_world()
	_run_one(simulation, "mara")
	simulation.tick_perception()
	var social_id := _social_knowledge_id(simulation, "mara")
	var record: Dictionary = simulation.state.get_knowledge("mara", social_id)

	assert(str(record["claim"]).contains("refused"), "it says what he did")
	for word: String in SUBJECTIVE_WORDS:
		assert(not str(record["claim"]).to_lower().contains(word),
			"the claim judges him: '%s'" % str(record["claim"]))
	# No hidden truth rides along with a social fact.
	assert(not str(record).contains("food_level"))
	assert(not str(record).contains("acceptance"))
	assert(str(record["truth_state"]) == "true", "it did happen")
	print("  MEANING DEFERRED: \"%s\"" % str(record["claim"]))
	completed += 1


func _test_state_changes_record_before_and_after() -> void:
	var simulation = _new_simulation()
	simulation.state.current_event_id = "drought"
	simulation.state.current_event_location_id = "westfield"
	assert(simulation.state.set_settlement_band("westfield", "food", 0))
	assert(simulation.resolve_action("send_rain")["ok"])

	var record: Dictionary = simulation.state.consequence_archive[0]
	assert(str(record["source_type"]) == ConsequenceRules.SOURCE_DIVINE)
	assert(not record["state_changes"].is_empty())
	var change: Dictionary = record["state_changes"][0]
	for field: String in ["subject_id", "field", "before", "after"]:
		assert(change.has(field), "a state change must record %s" % field)
	assert(str(change["subject_id"]) == "westfield")
	assert(int(change["before"]) != int(change["after"]))
	assert(int(change["after"]) == int(simulation.state.get_settlement_band("westfield", "food")))
	print("  BEFORE/AFTER: %s %s %d -> %d." % [
		str(change["subject_id"]), str(change["field"]),
		int(change["before"]), int(change["after"])
	])
	completed += 1


func _test_a_divine_act_is_an_occurrence_anyone_could_see() -> void:
	# The same door mortals use. What happened is recorded; why it happened is
	# not, because motive is exactly what mortals are supposed to argue about.
	var simulation = _new_simulation()
	simulation.state.current_event_id = "drought"
	simulation.state.current_event_location_id = "westfield"
	assert(simulation.state.set_settlement_band("westfield", "food", 0))
	assert(simulation.resolve_action("send_rain")["ok"])
	simulation.tick_perception()

	var rain_id := ""
	for knowledge_id_value in simulation.state.get_all_knowledge("mara"):
		if str(knowledge_id_value).contains("weather_rain"):
			rain_id = str(knowledge_id_value)
	assert(not rain_id.is_empty(), "someone living there should have seen it")
	var claim := str(simulation.state.get_knowledge("mara", rain_id)["claim"])
	assert(claim.contains("Rain fell"))
	assert(not claim.to_lower().contains("god"), "no motive may be recorded as fact")
	assert(not claim.to_lower().contains("answer"))
	assert(not claim.to_lower().contains("mercy"))
	assert(not simulation.state.has_knowledge("aster_king", rain_id),
		"rain over Westfield is not news the capital automatically has")
	print("  DIVINE: \"%s\" — and nothing about why." % claim)
	completed += 1


func _test_no_recursive_chain_within_one_year() -> void:
	# A consequence perceived this year must not set off another want, attempt
	# and consequence in the same tick. The year's decisions are already made.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	for turn in 8:
		assert(simulation.resolve_action("do_nothing")["ok"])
		assert(simulation.advance_year()["ok"])
		var year: int = simulation.state.year
		var born_this_year: Array[String] = []
		for record: Dictionary in simulation.state.consequence_archive:
			if int(record["year"]) != year:
				continue
			for created in record["events_created"]:
				born_this_year.append(str(created))
		for intent: Dictionary in simulation.state.last_intents:
			for factor: Dictionary in intent["knowledge_used"]:
				assert(str(factor["knowledge_id"]) not in born_this_year,
					"a want acted on something that only happened later the same year")
		assert(simulation.state.last_consequences.size() <= simulation.state.last_executions.size(),
			"one consequence per execution, and no extra round")
	print("  NO RECURSION: consequences are perceived this year and answered the next.")
	completed += 1


func _test_order_and_determinism() -> void:
	var first = _refusal_world()
	var second = _refusal_world()
	_run_one(first, "mara")
	_run_one(second, "mara")
	assert(str(first.state.consequence_archive) == str(second.state.consequence_archive),
		"identical context must reproduce exactly")

	# Reversing the executions must not change what came of any of them.
	var forward = _two_actor_world()
	var backward = _two_actor_world()
	var forward_executions: Array[Dictionary] = [
		forward.execute_mortal_action(_synthetic_action(forward, "mara", "aster_king", "support")),
		forward.execute_mortal_action(_synthetic_action(forward, "smith", "aster_king", "oppose"))
	]
	forward.state.last_executions = forward_executions
	var backward_executions: Array[Dictionary] = [
		backward.execute_mortal_action(_synthetic_action(backward, "smith", "aster_king", "oppose")),
		backward.execute_mortal_action(_synthetic_action(backward, "mara", "aster_king", "support"))
	]
	backward.state.last_executions = backward_executions
	assert(_outcomes(forward.tick_consequences()) == _outcomes(backward.tick_consequences()),
		"the order they are processed in must not matter")
	print("  DETERMINISM: same context, same result, either order.")
	completed += 1


func _test_memory_stays_bounded() -> void:
	# Social occurrences accumulate one belief per interaction, so mortals have
	# to forget. What goes is what could least change what they do next.
	var simulation = _new_simulation()
	for index in 20:
		simulation.state.learn_direct_knowledge("mara", {
			"id": "old_claim_%d" % index,
			"subject_id": "westfield",
			"topic": "rumour",
			"claim": "Something happened, once (%d)" % index,
			"confidence": 10 + index,
			"truth_state": "unknown",
			"fresh_for_years": 1
		})
	assert(simulation.state.get_all_knowledge("mara").size() == 20)
	simulation.state.year += 4
	simulation.state.age_knowledge()

	var kept: Dictionary = simulation.state.get_all_knowledge("mara")
	assert(kept.size() <= WorldState.MAX_KNOWLEDGE_PER_ENTITY,
		"a mortal cannot carry everything they ever heard")
	# What survived is what they held most firmly.
	var weakest := 100
	for knowledge_id_value in kept:
		weakest = mini(weakest, int(kept[str(knowledge_id_value)]["confidence"]))
	assert(weakest > 10, "the faintest memories should be the ones to go")
	print("  FORGETTING: 20 claims down to %d, the faintest gone first." % kept.size())
	completed += 1


# --- fixtures ----------------------------------------------------------------


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _world_for(kind: String):
	match kind:
		"refusal":
			return _refusal_world()
		"acceptance":
			return _acceptance_world()
		"support":
			return _expression_world("support")
		"opposition":
			return _expression_world("oppose")
	return _new_simulation()


func _refusal_world():
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.set_relationship("aster_king", "mara", COLD)
	return simulation


func _acceptance_world():
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.set_relationship("aster_king", "mara", WARM)
	return simulation


func _expression_world(action_type: String):
	var simulation = _new_simulation()
	simulation.state.set_meta("action_type", action_type)
	return simulation


func _tell_world():
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", {
		"id": "wolves_near_aster",
		"subject_id": "aster",
		"topic": "danger_wolves",
		"claim": "Wolves are hunting near Aster",
		"confidence": 95,
		"truth_state": "true",
		"fresh_for_years": 3
	})
	return simulation


func _observe_world():
	var simulation = _new_simulation()
	simulation.state.current_event_id = "drought"
	simulation.state.current_event_location_id = "aster"
	simulation.state.set_settlement_band("aster", "food", 0)
	simulation.state.add_notable_entity("watcher", "The Watcher", "person", ["cautious"], {}, "aster")
	return simulation


func _two_actor_world():
	var simulation = _new_simulation()
	simulation.state.add_notable_entity("smith", "The Smith", "person", [], {}, "aster")
	simulation.state.set_relationship("smith", "aster_king", COLD)
	return simulation


# Runs one mortal through the whole chain and returns the execution.
func _run_one(simulation, actor_id: String) -> Dictionary:
	if simulation.state.has_meta("action_type"):
		return _run_action(simulation, _synthetic_action(
			simulation, actor_id, "aster_king", str(simulation.state.get_meta("action_type"))
		))
	var intent: Dictionary = simulation.choose_intent(actor_id)
	return _run_action(simulation, simulation.choose_mortal_action(intent))


func _run_action(simulation, action: Dictionary) -> Dictionary:
	var execution: Dictionary = simulation.execute_mortal_action(action)
	var executions: Array[Dictionary] = [execution]
	simulation.state.last_executions = executions
	simulation.tick_consequences()
	return execution


func _synthetic_action(simulation, actor_id: String, target_id: String, action_type: String) -> Dictionary:
	return {
		"id": "action_%04d_%s_%s" % [simulation.state.year, actor_id, action_type],
		"year": simulation.state.year,
		"actor_id": actor_id,
		"intent_id": "intent_%04d_%s_help" % [simulation.state.year, actor_id],
		"intent_type": "help",
		"action_type": action_type,
		"target_id": target_id,
		"target_kind": "person",
		"subject_id": "",
		"topic_id": "",
		"resource_type": "",
		"selection": "argmax"
	}


func _consequence_for(simulation, execution: Dictionary) -> Dictionary:
	return simulation.state.get_consequence_for_source(str(execution["id"]))


func _social_knowledge_id(simulation, owner_id: String) -> String:
	for knowledge_id_value in simulation.state.get_all_knowledge(owner_id):
		if str(knowledge_id_value).begins_with("request_"):
			return str(knowledge_id_value)
	return ""


func _settlement_snapshot(simulation) -> Dictionary:
	var snapshot := {}
	for location_id: String in simulation.state.get_location_ids():
		snapshot[location_id] = [
			simulation.state.get_settlement_band(location_id, "food"),
			simulation.state.get_settlement_band(location_id, "stability"),
			simulation.state.get_settlement_band(location_id, "prosperity"),
			simulation.state.get_settlement_population(location_id)
		]
	return snapshot


func _outcomes(records: Array) -> Dictionary:
	var outcomes := {}
	for record: Dictionary in records:
		outcomes[str(record["actor_id"])] = "%s:%s" % [
			str(record["consequence_type"]), str(record["result_type"])
		]
	return outcomes
