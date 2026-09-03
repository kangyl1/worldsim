extends SceneTree

# Mortal Action Selection v1.
#
# The law under test is GDD Part II section 31, one layer further down: an
# intent says what a mortal WANTS, an action says what they will ATTEMPT, and
# nothing here may make anything happen. Selecting "ask the King for help" is
# not the King answering.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 20

const ACTIVE_VOCABULARY := ["give", "ask", "tell", "support", "oppose", "observe", "wait"]

const SHORTAGE_FACT := {
	"id": "westfield_food_shortage",
	"subject_id": "westfield",
	"topic": "food_shortage",
	"claim": "Westfield does not have enough food",
	"confidence": 85,
	"truth_state": "true",
	"fresh_for_years": 3
}

const WOLVES_FACT := {
	"id": "wolves_near_aster",
	"subject_id": "aster",
	"topic": "danger_wolves",
	"claim": "Wolves are hunting near Aster",
	"confidence": 95,
	"truth_state": "true",
	"fresh_for_years": 3
}

const STALE_RUMOR := {
	"id": "border_garrison_rumor",
	"subject_id": "border",
	"topic": "weakness",
	"claim": "The border garrison has deserted",
	"confidence": 30,
	"truth_state": "unknown",
	"fresh_for_years": 1
}

const FALSE_WEAKNESS := {
	"id": "rival_lord_dying",
	"subject_id": "rival_lord",
	"topic": "ruler_health",
	"claim": "The rival lord is dying",
	"confidence": 75,
	"truth_state": "true",
	"objective_truth_state": "false",
	"fresh_for_years": 3
}

const HERESY_FACT := {
	"id": "heresy_spreading",
	"subject_id": "aster",
	"topic": "heresy",
	"claim": "A new teaching spreads in Aster",
	"confidence": 75,
	"truth_state": "true",
	"fresh_for_years": 3
}

var completed := 0


func _init() -> void:
	_test_vocabulary_stays_small()
	_test_action_serves_its_intent()
	_test_incompatible_actions_are_never_considered()
	_test_give_requires_a_resource_nobody_has()
	_test_tell_requires_communicable_knowledge()
	_test_capability_never_invalidates_the_intent()
	_test_same_intent_different_actions()
	_test_traits_weight_the_method()
	_test_relationships_choose_the_target()
	_test_false_belief_produces_a_real_attempt()
	_test_objective_truth_cannot_reach_the_choice()
	_test_wait_is_always_viable()
	_test_wait_intent_and_wait_action_differ()
	_test_no_viable_action_is_legible()
	_test_ordinary_life_is_not_aggressive()
	_test_rejections_all_name_a_cause()
	_test_record_explains_itself()
	_test_determinism()
	_test_score_integrity()
	_test_selection_changes_nothing()

	if completed != EXPECTED_TESTS:
		push_error("Action suite incomplete: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		print("ACTION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("ACTION TEST PASSED: mortals choose attempts, and nothing happens yet.")
	quit(0)


func _test_vocabulary_stays_small() -> void:
	assert(ActionRules.ACTION_ORDER == ACTIVE_VOCABULARY, "the action vocabulary is settled design")
	var declared: Array = ActionRules.ACTION_CANDIDATES.keys()
	declared.sort()
	var expected := ACTIVE_VOCABULARY.duplicate()
	expected.sort()
	assert(declared == expected, "every action needs a template and vice versa")
	# GO is reserved, not implemented: entities have no location to move from.
	assert("go" not in ActionRules.ACTION_ORDER, "movement must not be faked")
	for intent_type: String in IntentRules.INTENT_ORDER:
		assert(ActionRules.INTENT_ACTIONS.has(intent_type), "%s has no executions" % intent_type)
		var allowed: Array = ActionRules.INTENT_ACTIONS[intent_type]
		assert(ActionRules.FALLBACK_ACTION in allowed, "%s must be able to wait" % intent_type)
		for action_type_value in allowed:
			assert(str(action_type_value) in ACTIVE_VOCABULARY,
				"%s maps to unknown action %s" % [intent_type, str(action_type_value)])
	for trait_rule_value in ActionRules.ACTION_TRAIT_RULES.values():
		for action_type_value in (trait_rule_value as Dictionary).keys():
			assert(str(action_type_value) in ACTIVE_VOCABULARY,
				"unknown action %s in the trait table" % str(action_type_value))
	print("  VOCABULARY: %d actions, movement deferred, every want able to wait." % [
		ActionRules.ACTION_ORDER.size()
	])
	completed += 1


func _test_action_serves_its_intent() -> void:
	# The success condition: Mara wants to help, cannot give, and asks the King.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)

	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) == "help")
	var action: Dictionary = simulation.choose_mortal_action(intent)

	assert(str(action["action_type"]) == "ask", "a powerless helper asks someone who can act")
	assert(str(action["target_id"]) == "aster_king")
	assert(str(action["target_kind"]) == "person")
	assert(str(action["selection"]) == "argmax")
	# The attempt is aimed at a person, but it is about a settlement.
	assert(str(action["subject_id"]) == "westfield", "the action must carry what the want was about")
	assert(str(action["topic_id"]) == "westfield_food_shortage")
	assert(str(action["resource_type"]) == "food")
	assert(str(action["intent_id"]) == str(intent["id"]), "an action must name the want it serves")
	assert(str(action["intent_type"]) == "help")
	var give := _find_candidate(action["considered"], "give", "aster_king")
	assert(str(give["reason"]) == "no_controlled_resource", "she has nothing to hand over")
	print("  SUCCESS CASE: help Westfield -> ask the King for food at score %d." % int(action["score"]))
	completed += 1


func _test_incompatible_actions_are_never_considered() -> void:
	# An action outside its intent's list is not scored badly. It does not exist.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("merchant", "The Merchant", "person", ["cautious"]))
	assert(simulation.state.set_relationship("merchant", "mara", {
		"trust": 40, "fear": 0, "respect": 20, "hostility": 0
	}))
	simulation.state.learn_direct_knowledge("merchant", STALE_RUMOR)
	simulation.state.year += 5
	simulation.state.age_knowledge()

	var intent: Dictionary = simulation.choose_intent("merchant")
	assert(str(intent["intent_type"]) == "learn")
	var action: Dictionary = simulation.choose_mortal_action(intent)
	var allowed: Array = ActionRules.INTENT_ACTIONS["learn"]
	for candidate: Dictionary in action["considered"]:
		assert(str(candidate["action_type"]) in allowed,
			"%s is not something LEARN can reach for" % str(candidate["action_type"]))
	assert(_find_candidate(action["considered"], "give", "mara").is_empty())
	assert(_find_candidate(action["considered"], "oppose", "mara").is_empty())
	assert(str(action["action_type"]) == "observe", "uncertainty invites watching")
	print("  COMPATIBILITY: LEARN weighed only %s." % ", ".join(allowed))
	completed += 1


func _test_give_requires_a_resource_nobody_has() -> void:
	# Nothing in the world models a resource a mortal controls, so GIVE is
	# generated and refused every time. The refusal is the point: it shows
	# capability filtering an action without touching the want.
	var simulation = _new_simulation()
	simulation.state.food_level = 3
	simulation.state.prosperity_level = 3
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)

	var action: Dictionary = _action_for(simulation, "mara")
	var give := _find_candidate(action["considered"], "give", "aster_king")
	assert(not give.is_empty(), "GIVE must still be weighed, so its refusal is on the record")
	assert(not bool(give["viable"]))
	assert(str(give["reason"]) == "no_controlled_resource")
	assert(int(give["score"]) == 0, "a refused action scores nothing")
	print("  GIVE: refused even with the realm's stores full — nobody owns them.")
	completed += 1


func _test_tell_requires_communicable_knowledge() -> void:
	# Someone who believes nothing has nothing to pass on.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("mute_clerk", "The Clerk", "person", []))
	assert(simulation.state.set_relationship("mute_clerk", "mara", {
		"trust": 60, "fear": 0, "respect": 40, "hostility": 0
	}))

	var action: Dictionary = _action_for(simulation, "mute_clerk")
	var tell := _find_candidate(action["considered"], "tell", "mara")
	assert(not tell.is_empty())
	assert(str(tell["reason"]) == "no_communicable_knowledge")

	# And there is nothing to tell someone who already knows it as well as you.
	var shared = _new_simulation()
	shared.state.stability_level = 0
	for entity_id in ["mara", "aster_king"]:
		shared.state.learn_direct_knowledge(str(entity_id), WOLVES_FACT)
	var shared_action: Dictionary = _action_for(shared, "mara")
	var shared_tell := _find_candidate(shared_action["considered"], "tell", "aster_king")
	assert(str(shared_tell["reason"]) == "target_already_knows")
	print("  TELL: needs something believed, and someone who has not heard it.")
	completed += 1


func _test_capability_never_invalidates_the_intent() -> void:
	# GDD section 30: an intent with no available action is a valid outcome.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	simulation.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)

	var intent: Dictionary = simulation.choose_intent("hermit")
	assert(str(intent["intent_type"]) == "help")
	assert(str(intent["target_id"]) == "westfield")
	var before := str(intent)

	var action: Dictionary = simulation.choose_mortal_action(intent)
	assert(str(action["action_type"]) == "wait")
	assert(str(action["selection"]) == "fallback_no_viable_action")
	assert(str(intent) == before, "selecting an action must not edit the want")
	assert(str(action["intent_type"]) == "help", "the record still says what she wanted")
	assert(str(action["subject_id"]) == "westfield")
	# Asking again gives the same want back, unweakened.
	var again: Dictionary = simulation.choose_intent("hermit")
	assert(str(again["intent_type"]) == "help")
	assert(int(again["score"]) == int(intent["score"]))
	print("  CAPABILITY: a hermit who can do nothing still wants to help.")
	completed += 1


func _test_same_intent_different_actions() -> void:
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)

	var mara_intent: Dictionary = simulation.choose_intent("mara")
	var hermit_intent: Dictionary = simulation.choose_intent("hermit")
	assert(str(mara_intent["intent_type"]) == str(hermit_intent["intent_type"]))
	assert(str(mara_intent["target_id"]) == str(hermit_intent["target_id"]))

	var mara_action: Dictionary = simulation.choose_mortal_action(mara_intent)
	var hermit_action: Dictionary = simulation.choose_mortal_action(hermit_intent)
	assert(str(mara_action["action_type"]) != str(hermit_action["action_type"]),
		"the same want, in different circumstances, must not force the same attempt")
	print("  DIVERGENCE: one HELP becomes %s, the other %s." % [
		str(mara_action["action_type"]), str(hermit_action["action_type"])
	])
	completed += 1


func _test_traits_weight_the_method() -> void:
	# Two people with the same grievance who want the same thing, separated only
	# by disposition. Holding the want constant is the point: this has to test
	# how an intent is pursued, not which intent is formed.
	var steadfast = _grievance_simulation("loyal")
	var scheming = _grievance_simulation("deceitful")

	var steadfast_intent: Dictionary = steadfast.choose_intent("claimant")
	var scheming_intent: Dictionary = scheming.choose_intent("claimant")
	assert(str(steadfast_intent["intent_type"]) == str(scheming_intent["intent_type"]),
		"the fixture only works while both want the same thing")
	assert(str(steadfast_intent["target_id"]) == str(scheming_intent["target_id"]))

	var steadfast_oppose := _find_evaluated(
		steadfast.evaluate_mortal_actions(steadfast_intent), "oppose", "aster_king"
	)
	var scheming_oppose := _find_evaluated(
		scheming.evaluate_mortal_actions(scheming_intent), "oppose", "aster_king"
	)
	assert(not steadfast_oppose.is_empty() and not scheming_oppose.is_empty())
	assert(_factor_delta(steadfast_oppose["trait_factors"], "loyal") < 0, "loyalty resists this")
	assert(_factor_delta(scheming_oppose["trait_factors"], "deceitful") > 0)
	assert(int(scheming_oppose["score"]) > int(steadfast_oppose["score"]),
		"disposition must move the score for the same approach")
	# And never bar it: the one it costs can still reach for it.
	assert(bool(steadfast_oppose["viable"]), "traits must not hard-gate an approach")
	print("  TRAITS: one want, opposing scores %d scheming and %d steadfast." % [
		int(scheming_oppose["score"]), int(steadfast_oppose["score"])
	])
	completed += 1


func _test_relationships_choose_the_target() -> void:
	# Two people to turn to, and the actor's own view of each decides which.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("envoy", "The Envoy", "person", []))
	assert(simulation.state.set_relationship("envoy", "mara", {
		"trust": 75, "fear": 0, "respect": 55, "hostility": 0
	}))
	assert(simulation.state.set_relationship("envoy", "aster_king", {
		"trust": 15, "fear": 45, "respect": 20, "hostility": 25
	}))
	simulation.state.learn_direct_knowledge("envoy", SHORTAGE_FACT)

	var action: Dictionary = _action_for(simulation, "envoy")
	assert(str(action["target_id"]) == "mara", "they turn to the one they trust")
	var trusted := _find_candidate(action["considered"], str(action["action_type"]), "mara")
	var feared := _find_candidate(action["considered"], str(action["action_type"]), "aster_king")
	assert(int(trusted["score"]) > int(feared["score"]))
	# The recorded axes are the actor's own outgoing view, not the return edge.
	assert(_axis_value(action["relationship_factors"], "trust") == 75)
	print("  RELATIONSHIPS: %s toward Mara (%d) over the King (%d)." % [
		str(action["action_type"]), int(trusted["score"]), int(feared["score"])
	])
	completed += 1


func _test_false_belief_produces_a_real_attempt() -> void:
	# GDD section 33: a false belief makes a perfectly valid thing to say.
	var simulation = _false_belief_simulation("false")
	var stored: Dictionary = simulation.state.get_knowledge("aster_king", "rival_lord_dying")
	assert(str(stored["objective_truth_state"]) == "false", "the world knows the claim is false")

	var action: Dictionary = _action_for(simulation, "aster_king")
	assert(str(action["action_type"]) in ["tell", "ask"],
		"a false belief must still be able to reach someone")
	assert(str(action["topic_id"]) == "rival_lord_dying")
	assert(str(simulation.state.get_knowledge("aster_king", "rival_lord_dying")["objective_truth_state"])
		== "false", "choosing an attempt must not repair the belief")
	print("  FALSEHOOD: the King will %s about a rival who is not dying." % str(action["action_type"]))
	completed += 1


func _test_objective_truth_cannot_reach_the_choice() -> void:
	var believed_true = _false_belief_simulation("true")
	var believed_false = _false_belief_simulation("false")
	var first: Dictionary = _action_for(believed_true, "aster_king")
	var second: Dictionary = _action_for(believed_false, "aster_king")
	assert(str(first) == str(second), "objective truth must be invisible to action selection")
	assert(not str(first).contains("objective"), "no record may carry objective truth")
	print("  BLINDNESS: truth flipped underneath, %s either way." % str(first["action_type"]))
	completed += 1


func _test_wait_is_always_viable() -> void:
	var checked := 0
	for scenario_name: String in _scenario_names():
		var simulation = _build_scenario(scenario_name)
		assert(simulation != null)
		var action: Dictionary = _action_for(simulation, _scenario_actor(scenario_name))
		var wait := _find_candidate(action["considered"], "wait", "")
		assert(not wait.is_empty(), "%s never weighed waiting" % scenario_name)
		assert(bool(wait["viable"]), "waiting must always remain possible")
		checked += 1
	assert(checked == 6)
	print("  WAIT: viable in all %d situations." % checked)
	completed += 1


func _test_wait_intent_and_wait_action_differ() -> void:
	# Three roads to the same attempt, and the record must separate them.
	var settled = _new_simulation()
	settled.state.food_level = 2
	settled.state.stability_level = 2
	settled.state.prosperity_level = 2
	assert(settled.state.add_notable_entity("quiet_elder", "The Elder", "person", ["cautious"]))
	var elder_intent: Dictionary = settled.choose_intent("quiet_elder")
	assert(str(elder_intent["intent_type"]) == "wait")
	var elder_action: Dictionary = settled.choose_mortal_action(elder_intent)
	assert(str(elder_action["action_type"]) == "wait")
	assert(str(elder_action["selection"]) == "intended_wait", "he meant to hold back")

	var stuck = _new_simulation()
	assert(stuck.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	stuck.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)
	var hermit_action: Dictionary = _action_for(stuck, "hermit")
	assert(str(hermit_action["action_type"]) == "wait")
	assert(str(hermit_action["selection"]) == "fallback_no_viable_action", "she was simply unable")

	assert(str(elder_action["selection"]) != str(hermit_action["selection"]))
	assert(str(elder_action["intent_type"]) != str(hermit_action["intent_type"]))
	var elder_reasons := str(elder_action["reasons"])
	var hermit_reasons := str(hermit_action["reasons"])
	assert(elder_reasons.contains("hold back"))
	assert(hermit_reasons.contains("no viable way"))
	assert(elder_reasons != hermit_reasons, "the two kinds of waiting must read differently")
	print("  TWO WAITS: %s vs %s." % [
		str(elder_action["selection"]), str(hermit_action["selection"])
	])
	completed += 1


func _test_no_viable_action_is_legible() -> void:
	# Developer Mode must be able to show why every road was closed.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	simulation.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)

	var action: Dictionary = _action_for(simulation, "hermit")
	var considered: Array = action["considered"]
	var refused := 0
	for candidate: Dictionary in considered:
		if str(candidate["action_type"]) == "wait":
			continue
		assert(not bool(candidate["viable"]))
		assert(not str(candidate["reason"]).is_empty())
		refused += 1
	assert(refused >= 4, "every closed road must be listed, not silently dropped")
	assert(str(_find_candidate(considered, "give", "")["reason"]) == "no_controlled_resource")
	assert(str(_find_candidate(considered, "ask", "")["reason"]) == "no_social_target")
	assert(str(_find_candidate(considered, "support", "")["reason"]) == "no_support_target")
	print("  NO VIABLE ACTION: %d closed roads, each naming its cause." % refused)
	completed += 1


func _test_ordinary_life_is_not_aggressive() -> void:
	var checked := 0
	for scenario_name: String in _scenario_names():
		var simulation = _build_scenario(scenario_name)
		var actor_id := _scenario_actor(scenario_name)
		var intent: Dictionary = simulation.choose_intent(actor_id)
		var action: Dictionary = simulation.choose_mortal_action(intent)
		var action_type := str(action["action_type"])
		assert(action_type in ACTIVE_VOCABULARY)
		assert(action_type in _scenario_allowed(scenario_name),
			"%s produced %s, outside %s" % [
				scenario_name, action_type, str(_scenario_allowed(scenario_name))
			])
		print("    %-22s %-9s -> %s" % [scenario_name, str(intent["intent_type"]), action_type])
		checked += 1
	assert(checked == 6)
	print("  ORDINARY LIFE: %d situations, no attempt outside the peaceful vocabulary." % checked)
	completed += 1


func _test_rejections_all_name_a_cause() -> void:
	var known_reasons := [
		"viable", "no_controlled_resource", "no_communicable_knowledge",
		"target_already_knows", "no_uncertainty", "no_social_target",
		"no_support_target", "no_oppose_target", "self_target"
	]
	var seen: Array[String] = []
	var checked := 0
	for scenario_name: String in _scenario_names():
		var simulation = _build_scenario(scenario_name)
		var action: Dictionary = _action_for(simulation, _scenario_actor(scenario_name))
		for candidate: Dictionary in action["considered"]:
			var reason := str(candidate["reason"])
			assert(reason in known_reasons, "unexplained rejection %s" % reason)
			assert(bool(candidate["viable"]) == (reason == "viable"),
				"viability and its reason must agree")
			if reason not in seen:
				seen.append(reason)
			checked += 1
	assert(checked > 0)
	assert(seen.size() > 1, "the run must produce refusals as well as viable options")
	print("  REJECTIONS: %d candidates, %d distinct outcomes, all named." % [checked, seen.size()])
	completed += 1


func _test_record_explains_itself() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	var action: Dictionary = _action_for(simulation, "mara")

	for field: String in [
		"id", "year", "actor_id", "intent_id", "intent_type", "action_type",
		"target_id", "target_kind", "subject_id", "topic_id", "resource_type",
		"score", "selection", "viable", "reasons", "considered"
	]:
		assert(action.has(field), "the record is missing %s" % field)
	assert(not action["reasons"].is_empty(), "a chosen attempt must say why")
	assert(not action["knowledge_factors"].is_empty(), "this one was driven by a belief")
	assert(not action["trait_factors"].is_empty())
	assert(not action["relationship_factors"].is_empty())
	assert(not action["target_factors"].is_empty())
	assert(action["considered"].size() > 1, "the roads not taken are part of the explanation")
	print("  EXPLAINABILITY: %d reasons, %d alternatives kept." % [
		action["reasons"].size(), action["considered"].size()
	])
	completed += 1


func _test_determinism() -> void:
	var first: Dictionary = _action_for(_seeded_simulation(), "aster_king")
	var second: Dictionary = _action_for(_seeded_simulation(), "aster_king")
	assert(str(first) == str(second), "identical context must reproduce exactly")

	var simulation = _seeded_simulation()
	var repeat_intent: Dictionary = simulation.choose_intent("aster_king")
	var once: Dictionary = simulation.choose_mortal_action(repeat_intent)
	var twice: Dictionary = simulation.choose_mortal_action(repeat_intent)
	assert(str(once) == str(twice), "re-selecting on the same state must not drift")
	print("  DETERMINISM: identical context reproduced %s at score %d." % [
		str(first["action_type"]), int(first["score"])
	])
	completed += 1


func _test_score_integrity() -> void:
	var checked := 0
	for scenario_name: String in _scenario_names():
		var simulation = _build_scenario(scenario_name)
		var actor_id := _scenario_actor(scenario_name)
		var intent: Dictionary = simulation.choose_intent(actor_id)
		for candidate: Dictionary in simulation.evaluate_mortal_actions(intent):
			if not bool(candidate["viable"]):
				assert(int(candidate["score"]) == 0)
				continue
			var total := int(candidate["base_priority"])
			total += _sum_deltas(candidate["trait_factors"])
			total += _sum_deltas(candidate["relationship_factors"])
			total += _sum_deltas(candidate["knowledge_factors"])
			total += _sum_deltas(candidate["target_factors"])
			assert(total == int(candidate["score"]),
				"score must equal base plus every recorded contribution")
			checked += 1
	assert(checked > 0)
	print("  INTEGRITY: %d viable candidates reconciled to their factors." % checked)
	completed += 1


func _test_selection_changes_nothing() -> void:
	# Choosing to ask the King for help is not the King answering. Nothing in
	# the world may move because an attempt was written down.
	var recorded := 0
	for year_offset in 2:
		recorded += _assert_selection_changes_nothing(year_offset)
	assert(recorded > 0, "the non-mutation check must observe a real selection pass")
	print("  NO CONSEQUENCES: %d attempts recorded, nothing else in the world moved." % recorded)
	completed += 1


func _assert_selection_changes_nothing(year_offset: int) -> int:
	var simulation = _new_simulation()
	simulation.state.year += year_offset
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.learn_direct_knowledge("aster_king", WOLVES_FACT)
	simulation.state.last_intents = simulation.tick_intents()

	var relationships_before := str(simulation.state.relationships)
	var entities_before := str(simulation.state.notable_entities)
	var intents_before := str(simulation.state.intent_archive)
	var history_before: int = simulation.state.history.size()
	var knowledge_events_before: int = simulation.state.knowledge_events.size()
	var stats_before := _world_snapshot(simulation)

	var selected: Array[Dictionary] = simulation.tick_action_selection()

	assert(str(simulation.state.relationships) == relationships_before,
		"selection must not change relationships")
	assert(str(simulation.state.notable_entities) == entities_before,
		"selection must not change entities or their knowledge")
	assert(str(simulation.state.intent_archive) == intents_before,
		"selection must not edit the wants it serves")
	assert(simulation.state.history.size() == history_before, "selection must not write history")
	assert(simulation.state.knowledge_events.size() == knowledge_events_before,
		"selecting TELL must not move any knowledge")
	assert(_world_snapshot(simulation) == stats_before, "selection must not change statistics")
	assert(selected.size() <= simulation.state.last_intents.size(),
		"at most one attempt per want")
	return selected.size()


# --- scenarios ---------------------------------------------------------------


func _scenario_names() -> Array[String]:
	return [
		"hunger", "friend in need", "new neighbour",
		"religious disagreement", "uncertain rumor", "personal danger"
	]


func _scenario_actor(scenario_name: String) -> String:
	match scenario_name:
		"hunger":
			return "farmer"
		"uncertain rumor":
			return "merchant"
		"personal danger":
			return "watchman"
	return "mara"


# Peaceful by construction: nothing in the vocabulary is violent, and these
# situations must not even reach for its sharpest verb by default.
func _scenario_allowed(scenario_name: String) -> Array:
	match scenario_name:
		"hunger":
			return ["ask", "observe", "wait"]
		"friend in need":
			return ["give", "ask", "tell", "support", "wait"]
		"new neighbour":
			return ["ask", "tell", "support", "wait"]
		"religious disagreement":
			return ["ask", "tell", "support", "observe", "wait"]
		"uncertain rumor":
			return ["ask", "observe", "wait"]
		"personal danger":
			return ["ask", "tell", "support", "observe", "wait"]
	return []


func _build_scenario(scenario_name: String):
	match scenario_name:
		"hunger":
			var hunger = _new_simulation()
			hunger.state.add_notable_entity("farmer", "The Farmer", "person", ["ambitious"])
			hunger.state.set_relationship("farmer", "aster_king", {
				"trust": 30, "fear": 25, "respect": 20, "hostility": 0
			})
			return hunger
		"friend in need":
			var need = _new_simulation()
			need.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
			return need
		"new neighbour":
			var neighbour = _new_simulation()
			neighbour.state.food_level = 2
			neighbour.state.stability_level = 2
			neighbour.state.prosperity_level = 2
			neighbour.state.add_notable_entity("newcomer", "The Newcomer", "person", [])
			neighbour.state.set_relationship("mara", "newcomer", {
				"trust": 50, "fear": 0, "respect": 10, "hostility": 0
			})
			return neighbour
		"religious disagreement":
			var dispute = _new_simulation()
			dispute.state.learn_direct_knowledge("mara", HERESY_FACT)
			return dispute
		"uncertain rumor":
			var rumor = _new_simulation()
			rumor.state.add_notable_entity("merchant", "The Merchant", "person", ["cautious"])
			rumor.state.set_relationship("merchant", "mara", {
				"trust": 40, "fear": 0, "respect": 20, "hostility": 0
			})
			rumor.state.learn_direct_knowledge("merchant", STALE_RUMOR)
			rumor.state.year += 5
			rumor.state.age_knowledge()
			return rumor
		"personal danger":
			var danger = _new_simulation()
			danger.state.add_notable_entity("watchman", "The Watchman", "person", ["cautious", "loyal"])
			danger.state.set_relationship("watchman", "aster_king", {
				"trust": 55, "fear": 20, "respect": 45, "hostility": 0
			})
			danger.state.learn_direct_knowledge("watchman", WOLVES_FACT)
			return danger
	return null


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _seeded_simulation():
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("aster_king", WOLVES_FACT)
	return simulation


func _grievance_simulation(disposition: String):
	var simulation = _new_simulation()
	simulation.state.add_notable_entity("claimant", "The Claimant", "person", [disposition])
	simulation.state.set_relationship("claimant", "aster_king", {
		"trust": 10, "fear": 5, "respect": 15, "hostility": 70
	})
	return simulation


func _false_belief_simulation(objective_truth: String):
	var simulation = _new_simulation()
	simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"])
	simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 15, "fear": 0, "respect": 5, "hostility": 45
	})
	var belief := FALSE_WEAKNESS.duplicate(true)
	belief["objective_truth_state"] = objective_truth
	simulation.state.learn_direct_knowledge("aster_king", belief)
	return simulation


func _action_for(simulation, actor_id: String) -> Dictionary:
	return simulation.choose_mortal_action(simulation.choose_intent(actor_id))


func _world_snapshot(simulation) -> Array:
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
		simulation.state.reputation,
		str(simulation.state.world_flags)
	]


# --- factor helpers ----------------------------------------------------------


func _factor_delta(factors: Array, detail: String) -> int:
	for factor: Dictionary in factors:
		if str(factor.get("detail", "")) == detail:
			return int(factor["delta"])
	return 0


func _axis_value(factors: Array, axis: String) -> int:
	for factor: Dictionary in factors:
		if str(factor.get("axis", "")) == axis:
			return int(factor["value"])
	return 0


func _sum_deltas(factors: Array) -> int:
	var total := 0
	for factor: Dictionary in factors:
		total += int(factor.get("delta", 0))
	return total


func _find_candidate(considered: Array, action_type: String, target_id: String) -> Dictionary:
	for entry: Dictionary in considered:
		if str(entry["action_type"]) == action_type and str(entry["target_id"]) == target_id:
			return entry
	return {}


func _find_evaluated(candidates: Array, action_type: String, target_id: String) -> Dictionary:
	for candidate: Dictionary in candidates:
		if str(candidate["action_type"]) == action_type and str(candidate["target_id"]) == target_id:
			return candidate
	return {}
