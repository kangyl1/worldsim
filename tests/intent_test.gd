extends SceneTree

# Broad Intent Model v1.
#
# The law under test is GDD Part II section 31: an intent says what a mortal
# WANTS, never what they attempt. These tests exist as much to stop the layer
# collapsing back into a list of executions as to check the arithmetic.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 18

# The vocabulary Decision Engine v1 used. No intent may ever be named like one
# of these again: each describes a thing someone does.
const RETIRED_ACTION_NAMES := [
	"send_aid", "warn_ally", "investigate", "exploit_weakness", "wait_and_observe"
]
const EXPECTED_VOCABULARY := [
	"help", "protect", "acquire", "learn", "influence",
	"connect", "distance", "resolve", "preserve", "wait"
]

const STARVING_FACT := {
	"id": "village_a_starving",
	"subject_id": "village_a",
	"topic": "food_shortage",
	"claim": "Village A is starving",
	"confidence": 80,
	"truth_state": "true",
	"fresh_for_years": 3
}

const UNREST_FACT := {
	"id": "aster_unrest",
	"subject_id": "aster",
	"topic": "danger_unrest",
	"claim": "Order is breaking down in Aster",
	"confidence": 90,
	"truth_state": "true",
	"fresh_for_years": 3
}

const WEAKNESS_FACT := {
	"id": "rival_lord_weak",
	"subject_id": "rival_lord",
	"topic": "weakness",
	"claim": "The rival lord cannot defend his border",
	"confidence": 70,
	"truth_state": "true",
	"fresh_for_years": 3
}

const DANGER_FACT := {
	"id": "king_in_danger",
	"subject_id": "aster_king",
	"topic": "danger_plot",
	"claim": "Someone means the King harm",
	"confidence": 85,
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

const RIVAL_STANDING_FACT := {
	"id": "rival_rising",
	"subject_id": "rival",
	"topic": "rival_standing",
	"claim": "The rival grows popular",
	"confidence": 80,
	"truth_state": "true",
	"fresh_for_years": 3
}

var completed := 0


func _init() -> void:
	_test_vocabulary_is_not_action_shaped()
	_test_compassionate_intends_help()
	_test_traits_weight_but_never_gate()
	_test_capability_never_gates_intent()
	_test_relationships_are_directional()
	_test_same_world_produces_different_intents()
	_test_same_intent_from_different_traits()
	_test_doubt_produces_learn()
	_test_false_belief_still_forms_an_intent()
	_test_objective_truth_cannot_reach_the_choice()
	_test_wait_can_be_chosen_on_merit()
	_test_fallback_still_explains_itself()
	_test_ordinary_life_is_not_war_shaped()
	_test_considered_alternatives_are_stored()
	_test_determinism()
	_test_score_integrity()
	_test_bounded_yearly_intents()
	_test_intentions_only()

	if completed != EXPECTED_TESTS:
		push_error("Intent suite incomplete: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		print("INTENT TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("INTENT TEST PASSED: mortals want directions, not executions.")
	quit(0)


func _test_vocabulary_is_not_action_shaped() -> void:
	assert(IntentRules.INTENT_ORDER == EXPECTED_VOCABULARY, "the vocabulary is settled design")
	var declared: Array = IntentRules.INTENT_CANDIDATES.keys()
	declared.sort()
	var expected := EXPECTED_VOCABULARY.duplicate()
	expected.sort()
	assert(declared == expected, "every intent needs a template and vice versa")

	for retired: String in RETIRED_ACTION_NAMES:
		assert(retired not in IntentRules.INTENT_ORDER, "%s names an execution" % retired)
		assert(not IntentRules.INTENT_CANDIDATES.has(retired))
		for trait_rule_value in IntentRules.INTENT_TRAIT_RULES.values():
			var trait_rule: Dictionary = trait_rule_value
			assert(not trait_rule.has(retired), "traits must not weight retired actions")
	# Every trait rule must name intents that actually exist.
	for trait_rule_value in IntentRules.INTENT_TRAIT_RULES.values():
		for intent_type_value in (trait_rule_value as Dictionary).keys():
			assert(str(intent_type_value) in EXPECTED_VOCABULARY,
				"unknown intent %s in the trait table" % str(intent_type_value))
	print("  VOCABULARY: %d intents, none named after an execution." % IntentRules.INTENT_ORDER.size())
	completed += 1


func _test_compassionate_intends_help() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)

	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) == "help", "compassion facing suffering should want to help")
	assert(str(intent["target_id"]) == "village_a")
	assert(str(intent["target_kind"]) == "subject")
	assert(str(intent["selection"]) == "argmax")
	assert(_has_factor(intent["trait_factors"], "compassionate"))
	assert(intent["knowledge_used"].size() == 1)
	assert(str(intent["knowledge_used"][0]["knowledge_id"]) == "village_a_starving")
	assert(not intent["reasons"].is_empty())
	print("  HELP: Mara wants to help village_a at score %d." % int(intent["score"]))
	completed += 1


func _test_traits_weight_but_never_gate() -> void:
	# An ambitious ruler is penalised for helping and must never be barred from
	# it. With nothing else pressing, he reaches it anyway.
	var simulation = _new_simulation()
	simulation.state.food_level = 2
	simulation.state.prosperity_level = 2
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)

	var candidates: Array[Dictionary] = simulation.evaluate_intents("aster_king")
	var help := _find_candidate(candidates, "help", "village_a")
	assert(not help.is_empty())
	assert(bool(help["eligible"]), "traits must not hard-gate help")
	assert(_factor_delta(help["trait_factors"], "ambitious") < 0, "ambition should cost, not forbid")

	var intent: Dictionary = simulation.choose_intent("aster_king")
	assert(str(intent["intent_type"]) == "help", "a penalised want can still win")
	print("  NO GATE: ambitious king still wants to help at score %d." % int(intent["score"]))
	completed += 1


func _test_capability_never_gates_intent() -> void:
	# GDD section 30: an intent with no available action is a valid outcome.
	# Wanting and being unable are separate layers, so an empty granary must
	# weigh on the want without forbidding it.
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.prosperity_level = 0
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)

	var intent: Dictionary = simulation.choose_intent("mara")
	assert(str(intent["intent_type"]) == "help",
		"having nothing to give must not stop her wanting to help")
	var scarcity := _world_delta(intent["world_state_factors"], "food_level")
	assert(scarcity < 0, "her own empty stores should weigh against the want, visibly")

	# The same rule on the other side of the vocabulary: no army, no wealth, and
	# the king can still want to sway a rival he believes is faltering.
	var second = _new_simulation()
	second.state.military_level = 0
	assert(second.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(second.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20, "fear": 0, "respect": 10, "hostility": 40
	}))
	second.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)

	var reach: Dictionary = second.choose_intent("aster_king")
	assert(str(reach["intent_type"]) == "influence")
	assert(str(reach["target_id"]) == "rival_lord")
	for candidate: Dictionary in second.evaluate_intents("aster_king"):
		assert(str(candidate["rejection_reason"]) != "world_state_unmet",
			"capability must never appear as a rejection reason")
	print("  CAPABILITY: empty stores weigh %d on help, and never bar it." % scarcity)
	completed += 1


func _test_relationships_are_directional() -> void:
	# Mara trusts the King (45); the King trusts Mara less (35). The same want,
	# read from either end, must not produce the same number.
	var simulation = _new_simulation()
	var mara_connect := _find_candidate(
		simulation.evaluate_intents("mara"), "connect", "aster_king"
	)
	var king_connect := _find_candidate(
		simulation.evaluate_intents("aster_king"), "connect", "mara"
	)
	assert(not mara_connect.is_empty() and not king_connect.is_empty())
	assert(int(mara_connect["score"]) != int(king_connect["score"]),
		"a directed relationship must score differently in each direction")
	assert(_axis_value(mara_connect["relationship_factors"], "trust") == 45)
	assert(_axis_value(king_connect["relationship_factors"], "trust") == 35)
	print("  DIRECTION: Mara -> King connect %d, King -> Mara connect %d." % [
		int(mara_connect["score"]), int(king_connect["score"])
	])
	completed += 1


func _test_same_world_produces_different_intents() -> void:
	# One fact, two people, two different wants. The fact does not decide;
	# who is reading it does.
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	simulation.state.learn_direct_knowledge("mara", UNREST_FACT)
	simulation.state.learn_direct_knowledge("aster_king", UNREST_FACT)

	var mara_intent: Dictionary = simulation.choose_intent("mara")
	var king_intent: Dictionary = simulation.choose_intent("aster_king")
	assert(str(mara_intent["intent_type"]) == "protect", "a loyal witness wants people kept safe")
	assert(str(king_intent["intent_type"]) == "influence", "an ambitious ruler wants the crowd swayed")
	assert(str(mara_intent["intent_type"]) != str(king_intent["intent_type"]))
	assert(str(mara_intent["knowledge_used"][0]["knowledge_id"])
		== str(king_intent["knowledge_used"][0]["knowledge_id"]),
		"both must be reading the same fact")
	print("  DIVERGENCE: on one fact Mara wants %s, the King wants %s." % [
		str(mara_intent["intent_type"]), str(king_intent["intent_type"])
	])
	completed += 1


func _test_same_intent_from_different_traits() -> void:
	# The mirror of the previous test: different people, same want.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("farmer", "The Farmer", "person", ["cautious"]))
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)
	simulation.state.learn_direct_knowledge("farmer", STARVING_FACT)

	var mara_intent: Dictionary = simulation.choose_intent("mara")
	var farmer_intent: Dictionary = simulation.choose_intent("farmer")
	assert(str(mara_intent["intent_type"]) == "help")
	assert(str(farmer_intent["intent_type"]) == "help")
	assert(int(mara_intent["score"]) != int(farmer_intent["score"]),
		"the same want should still be held with different strength")
	print("  CONVERGENCE: compassion %d and caution %d both want to help." % [
		int(mara_intent["score"]), int(farmer_intent["score"])
	])
	completed += 1


func _test_doubt_produces_learn() -> void:
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("grey_merchant", "The Grey Merchant", "person", ["cautious"]))
	simulation.state.learn_direct_knowledge("grey_merchant", STALE_RUMOR)

	simulation.state.year += 5
	simulation.state.age_knowledge()
	var aged: Dictionary = simulation.state.get_knowledge("grey_merchant", "border_garrison_rumor")
	assert(bool(aged["is_outdated"]), "the rumor should have aged")

	var intent: Dictionary = simulation.choose_intent("grey_merchant")
	assert(str(intent["intent_type"]) == "learn", "weak stale evidence should invite understanding")
	assert(_has_factor(intent["trait_factors"], "cautious"))
	var used: Dictionary = intent["knowledge_used"][0]
	assert(int(used["effective_confidence"]) < int(used["confidence"]), "aging must reduce weight")
	assert(int(used["effective_confidence"]) > 0, "aging must not erase the belief")

	# Evidence this thin must not be strong enough to want anything acted on.
	var preserve := _find_candidate(simulation.evaluate_intents("grey_merchant"), "preserve", "grey_merchant")
	assert(not bool(preserve["eligible"]))
	assert(str(preserve["rejection_reason"]) == "confidence_too_low")
	print("  DOUBT: merchant wants to understand at score %d (belief weighed %d of %d)." % [
		int(intent["score"]), int(used["effective_confidence"]), int(used["confidence"])
	])
	completed += 1


func _test_false_belief_still_forms_an_intent() -> void:
	# GDD section 33: the engine must never quietly correct a character.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 15, "fear": 0, "respect": 5, "hostility": 45
	}))
	simulation.state.learn_direct_knowledge("aster_king", FALSE_WEAKNESS)

	var stored: Dictionary = simulation.state.get_knowledge("aster_king", "rival_lord_dying")
	assert(str(stored["objective_truth_state"]) == "false", "the world knows the claim is false")

	var intent: Dictionary = simulation.choose_intent("aster_king")
	assert(str(intent["intent_type"]) == "influence",
		"an actor must be free to want things on what it believes")
	assert(str(intent["target_id"]) == "rival_lord")
	assert(str(intent["knowledge_used"][0]["knowledge_id"]) == "rival_lord_dying")
	assert(str(simulation.state.get_knowledge("aster_king", "rival_lord_dying")["objective_truth_state"])
		== "false", "forming an intent must not repair the belief")
	print("  FALSEHOOD: King wants to sway a rival he wrongly believes is dying (confidence %d)." % [
		int(stored["confidence"])
	])
	completed += 1


func _test_objective_truth_cannot_reach_the_choice() -> void:
	# Two worlds identical except for what is actually true. The mortal cannot
	# see the difference, so neither may the record.
	var believed_true = _false_belief_simulation("true")
	var believed_false = _false_belief_simulation("false")
	assert(str(believed_true.state.get_knowledge("aster_king", "rival_lord_dying")["objective_truth_state"])
		!= str(believed_false.state.get_knowledge("aster_king", "rival_lord_dying")["objective_truth_state"]))

	var first: Dictionary = believed_true.choose_intent("aster_king")
	var second: Dictionary = believed_false.choose_intent("aster_king")
	assert(str(first) == str(second), "objective truth must be invisible to intent selection")
	assert(not str(first).contains("objective"), "no record may carry objective truth")
	print("  BLINDNESS: truth flipped underneath, %s at score %d either way." % [
		str(first["intent_type"]), int(first["score"])
	])
	completed += 1


func _test_wait_can_be_chosen_on_merit() -> void:
	# WAIT is a want, not only a failure. A settled world and a cautious mind
	# are reasons to hold still.
	var simulation = _settled_world()
	assert(simulation.state.add_notable_entity("quiet_elder", "The Elder", "person", ["cautious"]))

	var intent: Dictionary = simulation.choose_intent("quiet_elder")
	assert(str(intent["intent_type"]) == "wait")
	assert(str(intent["selection"]) == "argmax", "this must be a choice, not a fallback")
	assert(int(intent["score"]) >= IntentRules.MINIMUM_INTENT_SCORE)
	assert(_has_factor(intent["trait_factors"], "cautious"))
	assert(not intent["world_state_factors"].is_empty(), "the calm world should be on the record")
	print("  WAIT ON MERIT: the elder chooses to wait at score %d." % int(intent["score"]))
	completed += 1


func _test_fallback_still_explains_itself() -> void:
	# The same settled world, minus the disposition to hold still on purpose.
	# WAIT arrives by the other road, and the record says which.
	var simulation = _settled_world()
	assert(simulation.state.add_notable_entity("silent_scribe", "The Scribe", "person", []))

	var intent: Dictionary = simulation.choose_intent("silent_scribe")
	assert(str(intent["intent_type"]) == "wait")
	assert(str(intent["selection"]) == "fallback")
	assert(str(intent["target_id"]).is_empty())
	assert(str(intent["target_kind"]) == "none")
	assert(intent["knowledge_used"].is_empty())
	var explained := false
	for reason in intent["reasons"]:
		if str(reason).contains("threshold"):
			explained = true
	assert(explained, "a fallback must still say why it happened")
	assert(simulation.choose_intent("missing_entity").is_empty())
	print("  FALLBACK: a blank scribe waits, and the record separates it from choosing to.")
	completed += 1


func _test_ordinary_life_is_not_war_shaped() -> void:
	# The five situations from the design pass. None of them may resolve into
	# an aggressive want by default.
	var checked := 0
	for scenario: Dictionary in _ordinary_life_scenarios():
		var simulation = _build_scenario(str(scenario["name"]))
		assert(simulation != null, "unknown scenario %s" % str(scenario["name"]))
		var intent: Dictionary = simulation.choose_intent(str(scenario["actor"]))
		var intent_type := str(intent["intent_type"])
		assert(intent_type in scenario["allowed"], "%s produced %s, outside %s" % [
			str(scenario["name"]), intent_type, str(scenario["allowed"])
		])
		print("    %-24s -> %s" % [str(scenario["name"]), intent_type])
		checked += 1
	assert(checked == 5, "all five ordinary-life cases must run")
	print("  ORDINARY LIFE: %d situations, every want inside its plausible set." % checked)
	completed += 1


func _test_considered_alternatives_are_stored() -> void:
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	simulation.state.learn_direct_knowledge("mara", UNREST_FACT)

	var intent: Dictionary = simulation.choose_intent("mara")
	var considered: Array = intent["considered"]
	assert(considered.size() > 1, "the rejected wants are part of the explanation")
	var chosen_present := false
	var rejected_present := false
	for entry: Dictionary in considered:
		assert(entry.has("intent_type") and entry.has("score") and entry.has("reason"))
		if str(entry["intent_type"]) == str(intent["intent_type"]) \
			and str(entry["target_id"]) == str(intent["target_id"]):
			chosen_present = true
		if not bool(entry["eligible"]):
			rejected_present = true
			assert(not str(entry["reason"]).is_empty(), "a rejection must name its cause")
	assert(chosen_present, "the winner must appear among what was weighed")
	assert(rejected_present, "so must something that was ruled out")
	print("  CONSIDERED: %d alternatives kept alongside the choice." % considered.size())
	completed += 1


func _test_determinism() -> void:
	var first = _seeded_simulation()
	var second = _seeded_simulation()
	var first_intent: Dictionary = first.choose_intent("aster_king")
	var second_intent: Dictionary = second.choose_intent("aster_king")
	assert(str(first_intent) == str(second_intent), "identical context must reproduce exactly")

	# Re-evaluating the same state must not drift either.
	var repeat: Dictionary = first.choose_intent("aster_king")
	assert(str(repeat) == str(first_intent))
	print("  DETERMINISM: identical context reproduced %s at score %d." % [
		str(first_intent["intent_type"]), int(first_intent["score"])
	])
	completed += 1


func _test_score_integrity() -> void:
	var simulation = _new_simulation()
	simulation.state.stability_level = 0
	assert(simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20, "fear": 5, "respect": 10, "hostility": 40
	}))
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)
	simulation.state.learn_direct_knowledge("mara", UNREST_FACT)

	var checked := 0
	for actor_id in ["aster_king", "mara"]:
		for candidate: Dictionary in simulation.evaluate_intents(str(actor_id)):
			if not bool(candidate["eligible"]):
				assert(int(candidate["score"]) == 0)
				continue
			var total := int(candidate["base_priority"])
			total += _sum_deltas(candidate["trait_factors"])
			total += _sum_deltas(candidate["relationship_factors"])
			total += _sum_deltas(candidate["knowledge_used"])
			total += _sum_deltas(candidate["world_state_factors"])
			assert(total == int(candidate["score"]),
				"score must equal base plus every recorded contribution")
			checked += 1
	assert(checked > 0)
	print("  INTEGRITY: %d eligible candidates reconciled to their factors." % checked)
	completed += 1


func _test_bounded_yearly_intents() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", DANGER_FACT)
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)

	var total := 0
	for turn in 60:
		var action_result: Dictionary = simulation.resolve_action("do_nothing")
		assert(action_result["ok"])
		assert(simulation.advance_year()["ok"])
		var made: Array = simulation.state.last_intents
		assert(made.size() <= IntentRules.MAX_INTENTS_PER_YEAR, "yearly intents must stay bounded")
		total += made.size()
	assert(total > WorldState.MAX_STORED_INTENTS, "the run must overflow the retention cap")
	assert(simulation.state.intents.size() == WorldState.MAX_STORED_INTENTS,
		"recent intents must stay capped")
	assert(simulation.state.intent_archive.size() == total, "the archive must keep everything")
	var king_records: Array[Dictionary] = simulation.state.get_intents_for("aster_king")
	assert(not king_records.is_empty())
	assert(not simulation.state.get_intent(str(king_records[0]["id"])).is_empty())
	print("  BOUNDS: %d intentions across 60 years, %d retained." % [
		total, simulation.state.intents.size()
	])
	completed += 1


func _test_intentions_only() -> void:
	# Entities are scheduled on alternating years, so check both parities and
	# require that at least one of them genuinely records an intention.
	var recorded := 0
	for year_offset in 2:
		recorded += _assert_tick_changes_nothing(year_offset)
	assert(recorded > 0, "the non-mutation check must observe a real intent tick")
	print("  INTENTIONS ONLY: %d recorded, nothing else in the world moved." % recorded)
	completed += 1


func _assert_tick_changes_nothing(year_offset: int) -> int:
	var simulation = _new_simulation()
	simulation.state.year += year_offset
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)

	var relationships_before := str(simulation.state.relationships)
	var entities_before := str(simulation.state.notable_entities)
	var history_before: int = simulation.state.history.size()
	var stats_before := _world_snapshot(simulation)

	var made: Array[Dictionary] = simulation.tick_intents()

	assert(str(simulation.state.relationships) == relationships_before,
		"intents must not change relationships")
	assert(str(simulation.state.notable_entities) == entities_before,
		"intents must not change entities or their knowledge")
	assert(simulation.state.history.size() == history_before, "intents must not write history")
	assert(_world_snapshot(simulation) == stats_before, "intents must not change world statistics")
	return made.size()


# --- scenarios ---------------------------------------------------------------


func _ordinary_life_scenarios() -> Array[Dictionary]:
	return [
		{"name": "A hunger", "actor": "hungry_farmer",
			"allowed": ["acquire", "help", "protect", "wait"]},
		{"name": "B new neighbour", "actor": "mara",
			"allowed": ["connect", "distance", "learn", "wait"]},
		{"name": "C religious dispute", "actor": "aster_king",
			"allowed": ["preserve", "learn", "influence", "resolve", "distance"]},
		{"name": "D popular rival", "actor": "aster_king",
			"allowed": ["influence", "preserve", "connect", "distance", "resolve"]},
		{"name": "E friend in danger", "actor": "mara",
			"allowed": ["help", "protect", "learn", "wait"]}
	]


func _build_scenario(scenario_name: String):
	match scenario_name:
		"A hunger":
			# Nothing to eat and no one to ask. The want may be for resources,
			# for someone else, or to hold still, but it is not for a fight.
			var hunger = _new_simulation()
			hunger.state.add_notable_entity("hungry_farmer", "The Farmer", "person", ["cautious"])
			return hunger
		"B new neighbour":
			var neighbour = _settled_world()
			neighbour.state.add_notable_entity("newcomer", "The Newcomer", "person", [])
			neighbour.state.set_relationship("mara", "newcomer", {
				"trust": 50, "fear": 0, "respect": 10, "hostility": 0
			})
			return neighbour
		"C religious dispute":
			var dispute = _new_simulation()
			dispute.state.learn_direct_knowledge("aster_king", HERESY_FACT)
			return dispute
		"D popular rival":
			# Respected, feared, and resented at once. Still not an attack.
			var rival = _new_simulation()
			rival.state.food_level = 2
			rival.state.prosperity_level = 2
			rival.state.add_notable_entity("rival", "The Rival", "person", [])
			rival.state.set_relationship("aster_king", "rival", {
				"trust": 25, "fear": 30, "respect": 55, "hostility": 35
			})
			rival.state.learn_direct_knowledge("aster_king", RIVAL_STANDING_FACT)
			return rival
		"E friend in danger":
			var danger = _new_simulation()
			danger.state.learn_direct_knowledge("mara", DANGER_FACT)
			return danger
	return null


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _settled_world():
	var simulation = _new_simulation()
	simulation.state.food_level = 2
	simulation.state.stability_level = 2
	simulation.state.prosperity_level = 2
	return simulation


func _seeded_simulation():
	var simulation = _new_simulation()
	simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"])
	simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20, "fear": 0, "respect": 10, "hostility": 40
	})
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)
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
		simulation.state.divine_power
	]


# --- factor helpers ----------------------------------------------------------


func _has_factor(factors: Array, detail: String) -> bool:
	for factor: Dictionary in factors:
		if str(factor.get("detail", "")) == detail:
			return true
	return false


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


func _world_delta(factors: Array, field: String) -> int:
	var total := 0
	for factor: Dictionary in factors:
		if str(factor.get("field", "")) == field:
			total += int(factor["delta"])
	return total


func _sum_deltas(factors: Array) -> int:
	var total := 0
	for factor: Dictionary in factors:
		total += int(factor.get("delta", 0))
	return total


func _find_candidate(candidates: Array, intent_type: String, target_id: String) -> Dictionary:
	for candidate: Dictionary in candidates:
		if str(candidate["intent_type"]) == intent_type and str(candidate["target_id"]) == target_id:
			return candidate
	return {}
