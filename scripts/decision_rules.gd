class_name DecisionRules
extends RefCounted

# Decision Engine v1 produces INTENTIONS ONLY. Nothing in this file may change
# world statistics, relationships, or knowledge. Scoring reads believed
# information and never consults objective truth, so an entity acting on a
# false rumor is expected behaviour rather than a bug.

const MINIMUM_DECISION_SCORE := 30
const MAX_BELIEFS_CONSIDERED := 3
const MAX_TARGETS_CONSIDERED := 3
const MAX_DECISIONS_PER_YEAR := 2
const MIN_FRESHNESS_FACTOR := 0.5
const DISTORTED_FACTOR := 0.85
const OUTDATED_FACTOR := 0.75
const DOUBT_CONFIDENCE := 55
const FALLBACK_DECISION := "wait_and_observe"

# Fixed order gives argmax a deterministic tie-break before target/knowledge id.
const DECISION_ORDER := [
	"send_aid",
	"warn_ally",
	"exploit_weakness",
	"investigate",
	"wait_and_observe"
]

# Traits weight decisions; they never gate them. A ruler without "compassionate"
# can still send aid, it simply costs points against a rival intention.
const DECISION_TRAIT_RULES := {
	"compassionate": {"send_aid": 25, "warn_ally": 10, "exploit_weakness": -25},
	"loyal": {"warn_ally": 25, "send_aid": 8, "exploit_weakness": -10},
	"ambitious": {"exploit_weakness": 25, "investigate": 5, "send_aid": -10},
	"cruel": {"exploit_weakness": 20, "send_aid": -20, "warn_ally": -10},
	"cautious": {"investigate": 20, "wait_and_observe": 10, "exploit_weakness": -15},
	"gullible": {"investigate": -15, "wait_and_observe": -5},
	"deceitful": {"exploit_weakness": 12, "warn_ally": -12, "send_aid": -8}
}

# target_mode:
#   "subject"       -> the subject_id carried by the triggering belief
#   "relationship"  -> an entity this actor has a directed relationship toward
#   "none"          -> no target
# confidence_mode:
#   "direct"        -> stronger belief scores higher
#   "inverse"       -> weaker belief scores higher (doubt motivates enquiry)
const DECISION_CANDIDATES := {
	"send_aid": {
		"base_priority": 20,
		"target_mode": "subject",
		"topics": ["food_shortage", "shortage", "starving", "famine", "hunger", "suffering", "plague"],
		"min_confidence": 35,
		"confidence_mode": "direct",
		"confidence_weight": 0.6,
		"axis_weights": {"trust": 0.25, "respect": 0.1, "hostility": -0.5, "fear": -0.1},
		"requires_world_state_any": [
			{"field": "food_level", "op": "gte", "value": 1},
			{"field": "prosperity_level", "op": "gte", "value": 1}
		],
		"world_state_rules": [
			{"field": "food_level", "op": "gte", "value": 2, "delta": 8, "detail": "food stores are adequate"},
			{"field": "food_level", "op": "lte", "value": 0, "delta": -12, "detail": "own food is critical"},
			{"field": "prosperity_level", "op": "gte", "value": 2, "delta": 6, "detail": "the realm is prosperous"}
		]
	},
	"warn_ally": {
		"base_priority": 18,
		"target_mode": "relationship",
		"topics": ["danger", "threat", "attack", "raid", "betrayal", "wolves"],
		"min_confidence": 30,
		"confidence_mode": "direct",
		"confidence_weight": 0.6,
		"axis_weights": {"trust": 0.45, "respect": 0.2, "hostility": -0.6, "fear": -0.15},
		"requires_relationship": {"trust_min": 40, "hostility_max": 40},
		"world_state_rules": [
			{"field": "stability_level", "op": "lte", "value": 1, "delta": 4, "detail": "the realm is uneasy"}
		]
	},
	"exploit_weakness": {
		"base_priority": 16,
		"target_mode": "subject",
		"topics": ["weakness", "weak", "unrest", "instability", "succession", "ruler_health"],
		"min_confidence": 35,
		"confidence_mode": "direct",
		"confidence_weight": 0.65,
		"axis_weights": {"hostility": 0.55, "fear": 0.1, "trust": -0.35, "respect": -0.15},
		# Applied only when a directed relationship exists. Bare subject targets
		# (Q1 option B) have no relationship record and are scored without it.
		"relationship_gate_any": [
			{"axis": "hostility", "op": "gte", "value": 20},
			{"axis": "trust", "op": "lte", "value": 40}
		],
		"requires_world_state": [
			{"field": "military_level", "op": "gte", "value": 1}
		],
		"world_state_rules": [
			{"field": "military_level", "op": "gte", "value": 2, "delta": 10, "detail": "the army is capable"},
			{"field": "military_level", "op": "gte", "value": 3, "delta": 6, "detail": "the army is strong"},
			{"field": "stability_level", "op": "lte", "value": 1, "delta": -6, "detail": "own realm is unsettled"}
		]
	},
	"investigate": {
		"base_priority": 14,
		"target_mode": "subject",
		"topics": [],
		"min_confidence": 5,
		"confidence_mode": "inverse",
		"confidence_weight": 0.5,
		"requires_doubt": true,
		"axis_weights": {},
		"world_state_rules": []
	},
	"wait_and_observe": {
		"base_priority": 12,
		"target_mode": "none",
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {},
		"world_state_rules": []
	}
}


func choose_decision(state: WorldState, actor_id: String) -> Dictionary:
	var actor := state.get_notable_entity(actor_id)
	if actor.is_empty():
		return {}
	var evaluated := evaluate_decisions(state, actor_id)
	var considered: Array[Dictionary] = []
	var best: Dictionary = {}
	for candidate: Dictionary in evaluated:
		considered.append({
			"decision_type": candidate["decision_type"],
			"target_id": candidate["target_id"],
			"score": candidate["score"],
			"eligible": candidate["eligible"],
			"reason": candidate["rejection_reason"]
		})
		if str(candidate["decision_type"]) == FALLBACK_DECISION:
			continue
		if not bool(candidate["eligible"]):
			continue
		if int(candidate["score"]) < MINIMUM_DECISION_SCORE:
			continue
		if best.is_empty() or _outranks(candidate, best):
			best = candidate
	if best.is_empty():
		best = _build_fallback(state, actor)
	var record := _build_record(state, actor, best)
	record["considered"] = considered
	return record


func evaluate_decisions(state: WorldState, actor_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var actor := state.get_notable_entity(actor_id)
	if actor.is_empty():
		return results
	var beliefs := _beliefs_for(state, actor_id)
	var relationship_targets := _relationship_targets_for(state, actor_id)
	for decision_type: String in DECISION_ORDER:
		var template: Dictionary = DECISION_CANDIDATES[decision_type]
		var target_mode := str(template["target_mode"])
		if target_mode == "none":
			results.append(_evaluate_candidate(state, actor, decision_type, "", {}))
			continue
		for belief: Dictionary in beliefs:
			if target_mode == "relationship":
				for target_id: String in relationship_targets:
					results.append(_evaluate_candidate(state, actor, decision_type, target_id, belief))
			else:
				results.append(_evaluate_candidate(
					state, actor, decision_type, str(belief.get("subject_id", "")), belief
				))
	return results


func _evaluate_candidate(
	state: WorldState,
	actor: Dictionary,
	decision_type: String,
	target_id: String,
	belief: Dictionary
) -> Dictionary:
	var template: Dictionary = DECISION_CANDIDATES[decision_type]
	var actor_id := str(actor["id"])
	var needs_belief := str(template["target_mode"]) != "none"
	var trait_factors: Array[Dictionary] = []
	var relationship_factors: Array[Dictionary] = []
	var knowledge_used: Array[Dictionary] = []
	var world_state_factors: Array[Dictionary] = []
	var reasons: Array[String] = []
	var candidate := {
		"decision_type": decision_type,
		"target_id": target_id,
		"target_kind": _target_kind(state, template, target_id),
		"knowledge_id": str(belief.get("id", "")),
		"base_priority": int(template["base_priority"]),
		"score": 0,
		"eligible": false,
		"rejection_reason": "",
		"trait_factors": trait_factors,
		"relationship_factors": relationship_factors,
		"knowledge_used": knowledge_used,
		"world_state_factors": world_state_factors,
		"reasons": reasons
	}

	if needs_belief:
		if target_id.is_empty():
			candidate["rejection_reason"] = "no_target"
			return candidate
		if target_id == actor_id:
			candidate["rejection_reason"] = "self_target"
			return candidate
		if belief.is_empty():
			candidate["rejection_reason"] = "no_matching_belief"
			return candidate
		if bool(belief.get("invalidated", false)):
			candidate["rejection_reason"] = "invalidated_knowledge"
			return candidate
		var topics: Array = template["topics"]
		if not topics.is_empty() and not _topic_matches(topics, str(belief.get("topic", ""))):
			candidate["rejection_reason"] = "topic_mismatch"
			return candidate
		if bool(template.get("requires_doubt", false)) and not _is_doubtful(belief):
			candidate["rejection_reason"] = "belief_not_in_doubt"
			return candidate

	var effective_confidence := 0
	if not belief.is_empty():
		effective_confidence = _effective_confidence(belief)
		if needs_belief and effective_confidence < int(template["min_confidence"]):
			candidate["rejection_reason"] = "confidence_too_low"
			return candidate

	var relationship := state.get_relationship(actor_id, target_id)
	var requires_relationship: Dictionary = template.get("requires_relationship", {})
	if not requires_relationship.is_empty():
		if relationship.is_empty():
			candidate["rejection_reason"] = "no_relationship"
			return candidate
		if int(relationship["trust"]) < int(requires_relationship.get("trust_min", 0)):
			candidate["rejection_reason"] = "relationship_not_trusted"
			return candidate
		if int(relationship["hostility"]) > int(requires_relationship.get("hostility_max", 100)):
			candidate["rejection_reason"] = "relationship_hostile"
			return candidate
	# Adversarial gate applies only where a directed relationship exists at all.
	var relationship_gate: Array = template.get("relationship_gate_any", [])
	if not relationship_gate.is_empty() and not relationship.is_empty():
		var gate_met := false
		for condition: Dictionary in relationship_gate:
			var axis_value := int(relationship.get(str(condition["axis"]), 0))
			if _compare(axis_value, str(condition["op"]), int(condition["value"])):
				gate_met = true
				break
		if not gate_met:
			candidate["rejection_reason"] = "relationship_not_adversarial"
			return candidate

	for condition: Dictionary in template.get("requires_world_state", []):
		if not _check_world_state(state, condition):
			candidate["rejection_reason"] = "world_state_unmet"
			return candidate
	var any_conditions: Array = template.get("requires_world_state_any", [])
	if not any_conditions.is_empty():
		var any_met := false
		for condition: Dictionary in any_conditions:
			if _check_world_state(state, condition):
				any_met = true
				break
		if not any_met:
			candidate["rejection_reason"] = "world_state_unmet"
			return candidate

	var score := int(template["base_priority"])

	if not belief.is_empty() and float(template["confidence_weight"]) != 0.0:
		var basis := effective_confidence
		if str(template["confidence_mode"]) == "inverse":
			basis = 100 - effective_confidence
		var knowledge_delta := int(round(basis * float(template["confidence_weight"])))
		score += knowledge_delta
		knowledge_used.append({
			"knowledge_id": str(belief["id"]),
			"subject_id": str(belief.get("subject_id", "")),
			"topic": str(belief.get("topic", "")),
			"claim": str(belief.get("claim", "")),
			"confidence": int(belief["confidence"]),
			"effective_confidence": effective_confidence,
			"freshness": int(belief.get("freshness", 100)),
			"is_outdated": bool(belief.get("is_outdated", false)),
			"distorted": bool(belief.get("distorted", false)),
			"truth_state": str(belief.get("truth_state", "unknown")),
			"delta": knowledge_delta
		})
		if str(template["confidence_mode"]) == "inverse":
			reasons.append("doubts \"%s\" (confidence %d, weighed as %d)" % [
				str(belief.get("claim", belief["id"])), int(belief["confidence"]), effective_confidence
			])
		else:
			reasons.append("believes \"%s\" (confidence %d, weighed as %d)" % [
				str(belief.get("claim", belief["id"])), int(belief["confidence"]), effective_confidence
			])
		if bool(belief.get("is_outdated", false)):
			reasons.append("that belief is outdated and counts for less")
		if bool(belief.get("distorted", false)):
			reasons.append("that belief reached them distorted")

	var axis_weights: Dictionary = template["axis_weights"]
	if not relationship.is_empty() and not axis_weights.is_empty():
		for axis: String in WorldState.RELATIONSHIP_AXES:
			if not axis_weights.has(axis):
				continue
			var axis_value := int(relationship[axis])
			if axis_value == 0:
				continue
			var axis_delta := int(round(axis_value * float(axis_weights[axis])))
			if axis_delta == 0:
				continue
			score += axis_delta
			relationship_factors.append({
				"source": "relationship",
				"detail": "%s %d toward %s" % [axis, axis_value, target_id],
				"axis": axis,
				"value": axis_value,
				"delta": axis_delta
			})
			if absi(axis_delta) >= 5:
				reasons.append("%s %d toward %s %s this course" % [
					axis, axis_value, target_id, "favours" if axis_delta > 0 else "resists"
				])

	for trait_value in actor.get("traits", []):
		var trait_id := str(trait_value)
		var trait_rule: Dictionary = DECISION_TRAIT_RULES.get(trait_id, {})
		if not trait_rule.has(decision_type):
			continue
		var trait_delta := int(trait_rule[decision_type])
		score += trait_delta
		trait_factors.append({"source": "trait", "detail": trait_id, "delta": trait_delta})
		reasons.append("%s outlook %s this course" % [
			trait_id, "favours" if trait_delta >= 0 else "resists"
		])

	for rule: Dictionary in template.get("world_state_rules", []):
		if not _check_world_state(state, rule):
			continue
		var world_delta := int(rule["delta"])
		score += world_delta
		world_state_factors.append({
			"source": "world_state",
			"detail": str(rule["detail"]),
			"field": str(rule["field"]),
			"value": _world_state_value(state, str(rule["field"])),
			"delta": world_delta
		})
		reasons.append(str(rule["detail"]))

	if str(candidate["target_kind"]) == "entity":
		var target_delta := 10 if not relationship.is_empty() else 5
		score += target_delta
		relationship_factors.append({
			"source": "target",
			"detail": "%s is a known figure" % target_id,
			"axis": "",
			"value": 0,
			"delta": target_delta
		})

	candidate["score"] = score
	candidate["eligible"] = true
	candidate["rejection_reason"] = "eligible"
	return candidate


func _build_fallback(state: WorldState, actor: Dictionary) -> Dictionary:
	var fallback := _evaluate_candidate(state, actor, FALLBACK_DECISION, "", {})
	fallback["eligible"] = true
	fallback["rejection_reason"] = "eligible"
	var reasons: Array[String] = fallback["reasons"]
	reasons.append("no intention reached the acting threshold of %d" % MINIMUM_DECISION_SCORE)
	return fallback


func _build_record(state: WorldState, actor: Dictionary, candidate: Dictionary) -> Dictionary:
	var actor_id := str(actor["id"])
	var decision_type := str(candidate["decision_type"])
	return {
		"id": "decision_%04d_%s_%s" % [state.year, actor_id, decision_type],
		"year": state.year,
		"actor_id": actor_id,
		"actor_name": str(actor.get("name", actor_id)),
		"actor_traits": actor.get("traits", []).duplicate(),
		"target_id": str(candidate["target_id"]),
		"target_kind": str(candidate["target_kind"]),
		"decision_type": decision_type,
		"base_priority": int(candidate["base_priority"]),
		"score": int(candidate["score"]),
		"priority": clampi(int(candidate["score"]), 0, 100),
		"trait_factors": candidate["trait_factors"],
		"relationship_factors": candidate["relationship_factors"],
		"knowledge_used": candidate["knowledge_used"],
		"world_state_factors": candidate["world_state_factors"],
		"reasons": candidate["reasons"],
		"considered": []
	}


func _outranks(candidate: Dictionary, best: Dictionary) -> bool:
	var candidate_score := int(candidate["score"])
	var best_score := int(best["score"])
	if candidate_score != best_score:
		return candidate_score > best_score
	var candidate_rank := DECISION_ORDER.find(str(candidate["decision_type"]))
	var best_rank := DECISION_ORDER.find(str(best["decision_type"]))
	if candidate_rank != best_rank:
		return candidate_rank < best_rank
	var candidate_target := str(candidate["target_id"])
	var best_target := str(best["target_id"])
	if candidate_target != best_target:
		return candidate_target < best_target
	return str(candidate["knowledge_id"]) < str(best["knowledge_id"])


func _beliefs_for(state: WorldState, actor_id: String) -> Array[Dictionary]:
	var beliefs: Array[Dictionary] = []
	var stored := state.get_all_knowledge(actor_id)
	var knowledge_ids: Array = stored.keys()
	knowledge_ids.sort()
	for knowledge_id_value in knowledge_ids:
		if beliefs.size() >= MAX_BELIEFS_CONSIDERED:
			break
		var record: Dictionary = stored[str(knowledge_id_value)]
		if bool(record.get("invalidated", false)):
			continue
		beliefs.append(record)
	return beliefs


func _relationship_targets_for(state: WorldState, actor_id: String) -> Array[String]:
	var targets: Array[String] = []
	for relationship_value in state.relationships.values():
		var relationship: Dictionary = relationship_value
		if str(relationship["source_id"]) != actor_id:
			continue
		var target_id := str(relationship["target_id"])
		if target_id not in targets:
			targets.append(target_id)
	targets.sort()
	if targets.size() > MAX_TARGETS_CONSIDERED:
		targets.resize(MAX_TARGETS_CONSIDERED)
	return targets


func _effective_confidence(belief: Dictionary) -> int:
	var confidence := float(int(belief.get("confidence", 0)))
	var freshness := float(int(belief.get("freshness", 100))) / 100.0
	var value := confidence * maxf(freshness, MIN_FRESHNESS_FACTOR)
	if bool(belief.get("distorted", false)):
		value *= DISTORTED_FACTOR
	if bool(belief.get("is_outdated", false)):
		value *= OUTDATED_FACTOR
	return clampi(int(round(value)), 0, 100)


func _is_doubtful(belief: Dictionary) -> bool:
	return (
		int(belief.get("confidence", 0)) < DOUBT_CONFIDENCE
		or bool(belief.get("is_outdated", false))
		or bool(belief.get("distorted", false))
	)


func _topic_matches(topics: Array, topic: String) -> bool:
	for topic_key in topics:
		if str(topic_key) in topic:
			return true
	return false


func _target_kind(state: WorldState, template: Dictionary, target_id: String) -> String:
	if str(template["target_mode"]) == "none" or target_id.is_empty():
		return "none"
	if state.notable_entities.has(target_id):
		return "entity"
	return "subject"


func _check_world_state(state: WorldState, condition: Dictionary) -> bool:
	return _compare(
		_world_state_value(state, str(condition["field"])),
		str(condition["op"]),
		int(condition["value"])
	)


func _compare(left: int, op: String, right: int) -> bool:
	match op:
		"gte":
			return left >= right
		"lte":
			return left <= right
		"eq":
			return left == right
		"gt":
			return left > right
		"lt":
			return left < right
	return false


func _world_state_value(state: WorldState, field: String) -> int:
	match field:
		"food_level":
			return state.food_level
		"stability_level":
			return state.stability_level
		"prosperity_level":
			return state.prosperity_level
		"military_level":
			return state.military_level
		"faith":
			return state.faith
		"divine_power":
			return state.divine_power
		"population":
			return state.population
		"followers":
			return state.followers
		"year":
			return state.year
	return 0
