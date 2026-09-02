extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const STARVING_FACT := {
	"id": "village_a_starving",
	"subject_id": "village_a",
	"topic": "food_shortage",
	"claim": "Village A is starving",
	"confidence": 80,
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
	"id": "wolves_near_village_a",
	"subject_id": "village_a",
	"topic": "danger_wolves",
	"claim": "Wolves are hunting near Village A",
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


func _init() -> void:
	_test_compassionate_send_aid()
	_test_traits_do_not_gate()
	_test_ambitious_exploit_weakness()
	_test_cautious_investigates_stale_rumor()
	_test_warn_ally_is_directional()
	_test_false_belief_still_decides()
	_test_determinism()
	_test_no_valid_decision()
	_test_score_integrity()
	_test_bounded_yearly_decisions()
	_test_intentions_only()
	print("DECISION TEST PASSED: traits weight, beliefs drive, direction matters, intentions only.")
	quit(0)


func _test_compassionate_send_aid() -> void:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)

	var decision: Dictionary = simulation.choose_decision("mara")
	assert(decision["decision_type"] == "send_aid", "compassionate actor should intend aid")
	assert(decision["target_id"] == "village_a")
	assert(decision["target_kind"] == "subject")
	assert(_has_factor(decision["trait_factors"], "compassionate"))
	assert(decision["knowledge_used"].size() == 1)
	assert(str(decision["knowledge_used"][0]["knowledge_id"]) == "village_a_starving")
	assert(not decision["reasons"].is_empty())
	print("  AID: Mara intends send_aid toward village_a at score %d." % int(decision["score"]))


func _test_traits_do_not_gate() -> void:
	# An ambitious ruler is penalised for aid but must never be barred from it.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)

	var candidates: Array[Dictionary] = simulation.evaluate_decisions("aster_king")
	var aid := _find_candidate(candidates, "send_aid", "village_a")
	assert(not aid.is_empty())
	assert(bool(aid["eligible"]), "traits must not hard-gate send_aid")
	assert(_factor_delta(aid["trait_factors"], "ambitious") < 0, "ambition should cost, not forbid")

	var decision: Dictionary = simulation.choose_decision("aster_king")
	assert(decision["decision_type"] == "send_aid")
	print("  NO GATE: ambitious king still reaches send_aid at score %d." % int(decision["score"]))


func _test_ambitious_exploit_weakness() -> void:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	assert(simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20,
		"fear": 0,
		"respect": 10,
		"hostility": 40
	}))
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)

	var decision: Dictionary = simulation.choose_decision("aster_king")
	assert(decision["decision_type"] == "exploit_weakness")
	assert(decision["target_id"] == "rival_lord")
	assert(decision["target_kind"] == "entity")
	assert(_has_factor(decision["trait_factors"], "ambitious"))
	assert(_axis_delta(decision["relationship_factors"], "hostility") > 0)
	assert(_axis_delta(decision["relationship_factors"], "trust") < 0, "low trust should push toward exploitation")
	print("  EXPLOIT: King intends exploit_weakness at score %d." % int(decision["score"]))


func _test_cautious_investigates_stale_rumor() -> void:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	assert(simulation.state.add_notable_entity("grey_merchant", "The Grey Merchant", "person", ["cautious"]))
	simulation.state.learn_direct_knowledge("grey_merchant", STALE_RUMOR)

	simulation.state.year += 5
	simulation.state.age_knowledge()
	var aged: Dictionary = simulation.state.get_knowledge("grey_merchant", "border_garrison_rumor")
	assert(bool(aged["is_outdated"]), "the rumor should have aged")

	var decision: Dictionary = simulation.choose_decision("grey_merchant")
	assert(decision["decision_type"] == "investigate", "weak stale evidence should invite enquiry")
	assert(_has_factor(decision["trait_factors"], "cautious"))
	var used: Dictionary = decision["knowledge_used"][0]
	assert(int(used["effective_confidence"]) < int(used["confidence"]), "aging must reduce weight")
	assert(int(used["effective_confidence"]) > 0, "aging must not erase the belief")

	# Aggressive intent must not outrank enquiry on this evidence.
	var candidates: Array[Dictionary] = simulation.evaluate_decisions("grey_merchant")
	var exploit := _find_candidate(candidates, "exploit_weakness", "border")
	assert(not bool(exploit["eligible"]))
	assert(str(exploit["rejection_reason"]) == "confidence_too_low")
	print("  DOUBT: merchant investigates at score %d (belief weighed %d of %d)." % [
		int(decision["score"]), int(used["effective_confidence"]), int(used["confidence"])
	])


func _test_warn_ally_is_directional() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", DANGER_FACT)
	simulation.state.learn_direct_knowledge("aster_king", DANGER_FACT)

	# Mara trusts the King (45); the King trusts Mara less (35).
	var mara_decision: Dictionary = simulation.choose_decision("mara")
	assert(mara_decision["decision_type"] == "warn_ally")
	assert(mara_decision["target_id"] == "aster_king")
	assert(mara_decision["target_kind"] == "entity")
	assert(_has_factor(mara_decision["trait_factors"], "loyal"))

	var king_decision: Dictionary = simulation.choose_decision("aster_king")
	assert(king_decision["decision_type"] == "wait_and_observe",
		"the same belief must not produce the same intention in the other direction")
	var rejected := _find_considered(king_decision["considered"], "warn_ally", "mara")
	assert(str(rejected["reason"]) == "relationship_not_trusted")
	print("  DIRECTION: Mara warns the King; the King does not warn Mara (%s)." % str(rejected["reason"]))


func _test_false_belief_still_decides() -> void:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	assert(simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 15,
		"fear": 0,
		"respect": 5,
		"hostility": 45
	}))
	simulation.state.learn_direct_knowledge("aster_king", FALSE_WEAKNESS)

	var stored: Dictionary = simulation.state.get_knowledge("aster_king", "rival_lord_dying")
	assert(str(stored["objective_truth_state"]) == "false", "the world knows the claim is false")

	var decision: Dictionary = simulation.choose_decision("aster_king")
	assert(decision["decision_type"] == "exploit_weakness",
		"an actor must be free to act on what it believes")
	assert(str(decision["knowledge_used"][0]["knowledge_id"]) == "rival_lord_dying")
	print("  FALSEHOOD: King acts on a false belief he holds at confidence %d." % int(stored["confidence"]))


func _test_determinism() -> void:
	var first = _seeded_simulation()
	var second = _seeded_simulation()
	var first_decision: Dictionary = first.choose_decision("aster_king")
	var second_decision: Dictionary = second.choose_decision("aster_king")
	assert(str(first_decision["id"]) == str(second_decision["id"]))
	assert(str(first_decision["decision_type"]) == str(second_decision["decision_type"]))
	assert(int(first_decision["score"]) == int(second_decision["score"]))
	assert(str(first_decision["trait_factors"]) == str(second_decision["trait_factors"]))
	assert(str(first_decision["relationship_factors"]) == str(second_decision["relationship_factors"]))
	assert(str(first_decision["knowledge_used"]) == str(second_decision["knowledge_used"]))
	assert(str(first_decision["world_state_factors"]) == str(second_decision["world_state_factors"]))
	assert(str(first_decision["considered"]) == str(second_decision["considered"]))

	# Re-evaluating the same state must not drift either.
	var repeat: Dictionary = first.choose_decision("aster_king")
	assert(str(repeat["considered"]) == str(first_decision["considered"]))
	print("  DETERMINISM: identical context reproduced %s at score %d." % [
		str(first_decision["decision_type"]), int(first_decision["score"])
	])


func _test_no_valid_decision() -> void:
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("silent_scribe", "The Scribe", "person", []))

	var decision: Dictionary = simulation.choose_decision("silent_scribe")
	assert(decision["decision_type"] == "wait_and_observe")
	assert(str(decision["target_id"]).is_empty())
	assert(decision["target_kind"] == "none")
	assert(decision["knowledge_used"].is_empty())
	assert(not decision["reasons"].is_empty(), "a fallback must still explain itself")
	assert(simulation.choose_decision("missing_entity").is_empty())
	print("  FALLBACK: knowledgeless actor waits and says why.")


func _test_score_integrity() -> void:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	assert(simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"]))
	assert(simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20,
		"fear": 5,
		"respect": 10,
		"hostility": 40
	}))
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)
	simulation.state.learn_direct_knowledge("mara", DANGER_FACT)

	var checked := 0
	for actor_id in ["aster_king", "mara"]:
		for candidate: Dictionary in simulation.evaluate_decisions(str(actor_id)):
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


func _test_bounded_yearly_decisions() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", DANGER_FACT)
	simulation.state.learn_direct_knowledge("aster_king", STARVING_FACT)

	var total := 0
	for turn in 60:
		var action_result: Dictionary = simulation.resolve_action("do_nothing")
		assert(action_result["ok"])
		assert(simulation.advance_year()["ok"])
		var made: Array = simulation.state.last_decisions
		assert(made.size() <= DecisionRules.MAX_DECISIONS_PER_YEAR,
			"yearly decisions must stay bounded")
		total += made.size()
	assert(total > WorldState.MAX_STORED_DECISIONS, "the run must overflow the retention cap")
	assert(simulation.state.decisions.size() == WorldState.MAX_STORED_DECISIONS,
		"recent decisions must stay capped")
	assert(simulation.state.decision_archive.size() == total, "the archive must keep everything")
	var king_records: Array[Dictionary] = simulation.state.get_decisions_for("aster_king")
	assert(not king_records.is_empty())
	assert(not simulation.state.get_decision(str(king_records[0]["id"])).is_empty())
	print("  BOUNDS: %d intentions across 60 years, %d retained." % [
		total, simulation.state.decisions.size()
	])


func _test_intentions_only() -> void:
	# Entities are scheduled on alternating years, so check both parities and
	# require that at least one of them genuinely records an intention.
	var recorded := 0
	for year_offset in 2:
		recorded += _assert_tick_changes_nothing(year_offset)
	assert(recorded > 0, "the non-mutation check must observe a real decision tick")
	print("  INTENTIONS ONLY: %d recorded, nothing else in the world moved." % recorded)


func _assert_tick_changes_nothing(year_offset: int) -> int:
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	simulation.state.year += year_offset
	simulation.state.learn_direct_knowledge("mara", STARVING_FACT)
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)

	var relationships_before := str(simulation.state.relationships)
	var entities_before := str(simulation.state.notable_entities)
	var history_before: int = simulation.state.history.size()
	var stats_before := _world_snapshot(simulation)

	var made: Array[Dictionary] = simulation.tick_decisions()

	assert(str(simulation.state.relationships) == relationships_before,
		"decisions must not change relationships")
	assert(str(simulation.state.notable_entities) == entities_before,
		"decisions must not change entities or their knowledge")
	assert(simulation.state.history.size() == history_before, "decisions must not write history")
	assert(_world_snapshot(simulation) == stats_before, "decisions must not change world statistics")
	return made.size()


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


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _seeded_simulation():
	var simulation = _new_simulation()
	simulation.state.military_level = 2
	simulation.state.add_notable_entity("rival_lord", "The Rival Lord", "person", ["cruel"])
	simulation.state.set_relationship("aster_king", "rival_lord", {
		"trust": 20,
		"fear": 0,
		"respect": 10,
		"hostility": 40
	})
	simulation.state.learn_direct_knowledge("aster_king", WEAKNESS_FACT)
	return simulation


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


func _axis_delta(factors: Array, axis: String) -> int:
	for factor: Dictionary in factors:
		if str(factor.get("axis", "")) == axis:
			return int(factor["delta"])
	return 0


func _sum_deltas(factors: Array) -> int:
	var total := 0
	for factor: Dictionary in factors:
		total += int(factor.get("delta", 0))
	return total


func _find_candidate(candidates: Array, decision_type: String, target_id: String) -> Dictionary:
	for candidate: Dictionary in candidates:
		if str(candidate["decision_type"]) == decision_type and str(candidate["target_id"]) == target_id:
			return candidate
	return {}


func _find_considered(considered: Array, decision_type: String, target_id: String) -> Dictionary:
	for entry: Dictionary in considered:
		if str(entry["decision_type"]) == decision_type and str(entry["target_id"]) == target_id:
			return entry
	return {}
