extends SceneTree

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const WOLVES_FACT := {
	"id": "wolves_near_village_a",
	"subject_id": "village_a",
	"topic": "danger_wolves",
	"claim": "Wolves are hunting near Village A",
	"confidence": 95,
	"truth_state": "true",
	"fresh_for_years": 3
}


func _init() -> void:
	_test_direct_knowledge()
	_test_rumor_transfer()
	_test_relationship_effect()
	_test_trait_acceptance_and_distortion()
	_test_false_rumor()
	_test_knowledge_aging()
	_test_yearly_three_entity_chain()
	print("KNOWLEDGE TEST PASSED: direct facts, rumors, traits, falsehood, aging, and yearly chain.")
	quit(0)


func _test_direct_knowledge() -> void:
	var simulation = _new_simulation()
	var learned: Dictionary = simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	assert(learned["id"] == "wolves_near_village_a")
	assert(learned["owner_id"] == "mara")
	assert(learned["source_id"] == "mara")
	assert(learned["source_type"] == "direct")
	assert(learned["confidence"] == 95)
	assert(learned["truth_state"] == "true")
	assert(simulation.state.has_knowledge("mara", learned["id"]))
	assert(simulation.state.does_entity_believe("mara", learned["id"], 90))
	assert(simulation.state.get_knowledge_confidence("mara", learned["id"]) == 95)

	# Re-learning the stable ID updates one record rather than duplicating it.
	var updated := WOLVES_FACT.duplicate(true)
	updated["confidence"] = 140
	simulation.state.learn_knowledge("mara", updated)
	assert(simulation.state.get_all_knowledge("mara").size() == 1)
	assert(simulation.state.get_knowledge_confidence("mara", learned["id"]) == 100)
	assert(simulation.state.invalidate_knowledge("mara", learned["id"]))
	assert(not simulation.state.does_entity_believe("mara", learned["id"]))
	assert(simulation.state.remove_knowledge("mara", learned["id"]))
	assert(not simulation.state.has_knowledge("mara", learned["id"]))
	print("  DIRECT: stable record stored, clamped, queried, invalidated, and removed.")


func _test_rumor_transfer() -> void:
	var simulation = _new_simulation()
	var mara_record: Dictionary = simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	var transfer: Dictionary = simulation.share_knowledge("mara", "aster_king", mara_record["id"])
	assert(transfer["shared"])
	var king_record: Dictionary = simulation.state.get_knowledge("aster_king", mara_record["id"])
	assert(not king_record.is_empty())
	assert(king_record["source_id"] == "mara")
	assert(king_record["source_type"] == "rumor")
	assert(king_record["transmission_count"] == 1)
	assert(king_record["confidence"] < mara_record["confidence"])
	print("  TRANSFER: Mara %d -> King %d confidence." % [
		mara_record["confidence"], king_record["confidence"]
	])


func _test_relationship_effect() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	simulation.state.set_relationship("mara", "aster_king", {
		"trust": 90, "respect": 40, "fear": 0, "hostility": 0
	})
	var trusted: Dictionary = simulation.evaluate_knowledge_share("mara", "aster_king", WOLVES_FACT["id"])
	assert(trusted["allowed"])

	simulation.state.set_relationship("mara", "aster_king", {
		"trust": 5, "respect": 0, "fear": 0, "hostility": 100
	})
	var hostile: Dictionary = simulation.evaluate_knowledge_share("mara", "aster_king", WOLVES_FACT["id"])
	assert(not hostile["allowed"])
	assert(hostile["reason"] == "source_unwilling")
	assert(trusted["share_score"] > hostile["share_score"])
	print("  RELATIONSHIP: trusted score %d vs hostile score %d." % [
		trusted["share_score"], hostile["share_score"]
	])


func _test_trait_acceptance_and_distortion() -> void:
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("cautious_scout", "The Scout", "person", ["cautious"]))
	assert(simulation.state.set_relationship("mara", "cautious_scout", {
		"trust": 90, "respect": 20, "hostility": 0, "fear": 0
	}))
	var weak_claim := {
		"id": "weak_border_claim",
		"subject_id": "border",
		"topic": "weakness",
		"claim": "The northern border may be undefended",
		"confidence": 45,
		"truth_state": "unknown"
	}
	simulation.state.learn_knowledge("mara", weak_claim)
	var cautious_result: Dictionary = simulation.share_knowledge("mara", "cautious_scout", weak_claim["id"])
	assert(not cautious_result["shared"])
	assert(cautious_result["reason"] == "target_rejected")
	assert(not simulation.state.has_knowledge("cautious_scout", weak_claim["id"]))

	assert(simulation.state.add_notable_entity("court_whisperer", "The Whisperer", "person", ["deceitful"]))
	assert(simulation.state.set_relationship("court_whisperer", "aster_king", {
		"trust": 90, "respect": 10, "hostility": 0, "fear": 0
	}))
	simulation.state.learn_knowledge("court_whisperer", {
		"id": "merchant_hoards_grain",
		"subject_id": "merchant",
		"topic": "resources",
		"claim": "The merchant is hiding grain",
		"confidence": 90,
		"truth_state": "false",
		"source_id": "unknown_informant",
		"source_type": "rumor"
	})
	var distorted: Dictionary = simulation.share_knowledge("court_whisperer", "aster_king", "merchant_hoards_grain")
	assert(distorted["shared"])
	assert(distorted["distorted"])
	assert(simulation.state.get_knowledge("aster_king", "merchant_hoards_grain")["truth_state"] == "false")
	print("  TRAITS: cautious rejected weak evidence; deceitful sharing marked distortion.")


func _test_false_rumor() -> void:
	var simulation = _new_simulation()
	simulation.state.set_relationship("mara", "aster_king", {
		"trust": 90, "respect": 30, "hostility": 0, "fear": 0
	})
	simulation.state.learn_knowledge("mara", {
		"id": "king_is_dying",
		"subject_id": "aster_king",
		"topic": "ruler_health",
		"claim": "The king is dying",
		"confidence": 85,
		"truth_state": "false",
		"source_id": "travelling_physician",
		"source_type": "rumor"
	})
	var transfer: Dictionary = simulation.share_knowledge("mara", "aster_king", "king_is_dying")
	assert(transfer["shared"])
	var believed_falsehood: Dictionary = simulation.state.get_knowledge("aster_king", "king_is_dying")
	assert(believed_falsehood["truth_state"] == "false")
	assert(believed_falsehood["objective_truth_state"] == "false")
	assert(simulation.state.does_entity_believe("aster_king", "king_is_dying", 50))
	print("  FALSE: King believes a false claim at %d confidence." % believed_falsehood["confidence"])


func _test_knowledge_aging() -> void:
	var simulation = _new_simulation()
	var short_lived := WOLVES_FACT.duplicate(true)
	short_lived["fresh_for_years"] = 1
	simulation.state.learn_direct_knowledge("mara", short_lived)
	simulation.state.year = 14
	var aged: Array[Dictionary] = simulation.state.age_knowledge()
	var record: Dictionary = simulation.state.get_knowledge("mara", WOLVES_FACT["id"])
	assert(aged.size() == 1)
	assert(record["is_outdated"])
	assert(record["truth_state"] == "outdated")
	assert(record["objective_truth_state"] == "true")
	assert(record["last_updated_year"] == 12)
	print("  AGING: current belief became outdated while objective truth metadata remained true.")


func _test_yearly_three_entity_chain() -> void:
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("grey_merchant", "The Grey Merchant", "person", ["cautious"]))
	assert(simulation.state.set_relationship("mara", "aster_king", {
		"trust": 90, "respect": 35, "hostility": 0, "fear": 0
	}))
	assert(simulation.state.set_relationship("aster_king", "grey_merchant", {
		"trust": 80, "respect": 30, "hostility": 0, "fear": 0
	}))
	var mara_record: Dictionary = simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)

	simulation.state.year = 13
	var first_tick: Array[Dictionary] = simulation.tick_knowledge()
	assert(first_tick.size() <= KnowledgeRules.MAX_YEARLY_SHARES)
	var king_record: Dictionary = simulation.state.get_knowledge("aster_king", mara_record["id"])
	assert(not king_record.is_empty())

	simulation.state.year = 15
	var second_tick: Array[Dictionary] = simulation.tick_knowledge()
	assert(second_tick.size() <= KnowledgeRules.MAX_YEARLY_SHARES)
	var merchant_record: Dictionary = simulation.state.get_knowledge("grey_merchant", mara_record["id"])
	assert(not merchant_record.is_empty())
	assert(mara_record["confidence"] > king_record["confidence"])
	assert(king_record["confidence"] > merchant_record["confidence"])
	assert(merchant_record["source_id"] == "aster_king")
	assert(merchant_record["transmission_count"] == 2)
	print("  CHAIN: Mara %d -> King %d -> Merchant %d confidence." % [
		mara_record["confidence"],
		king_record["confidence"],
		merchant_record["confidence"]
	])


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation
