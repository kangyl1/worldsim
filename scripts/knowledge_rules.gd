class_name KnowledgeRules
extends RefCounted

const SHARE_SCORE_REQUIRED := 85
const BASE_ACCEPTANCE_CONFIDENCE := 30
const BASE_CONFIDENCE_LOSS := 18
const MINIMUM_SHARE_CONFIDENCE := 20
const MAX_YEARLY_SHARES := 2

# Trait effects are kept as data so later traits can participate without
# changing entity storage or the rumor-transfer API.
const TRAIT_RULES := {
	"loyal": {
		"trusted_share_bonus": 20,
		"trusted_at": 50
	},
	"deceitful": {
		"share_bonus": 5,
		"confidence_loss": 10,
		"distorts": true
	},
	"cautious": {
		"acceptance_delta": 25,
		"received_confidence_delta": -5
	},
	"gullible": {
		"acceptance_delta": -20,
		"received_confidence_delta": 5
	},
	"ambitious": {
		"interesting_topics": [
			"rival", "ruler", "weakness", "resources", "opportunity",
			"food_shortage", "military", "succession"
		],
		"interest_bonus": 15
	}
}


func evaluate_transfer(
	state: WorldState,
	source_id: String,
	target_id: String,
	knowledge_id: String
) -> Dictionary:
	var result := {
		"allowed": false,
		"reason": "invalid_request",
		"source_id": source_id,
		"target_id": target_id,
		"knowledge_id": knowledge_id,
		"share_score": 0,
		"share_score_required": SHARE_SCORE_REQUIRED,
		"acceptance_threshold": BASE_ACCEPTANCE_CONFIDENCE,
		"source_confidence": 0,
		"received_confidence": 0,
		"confidence_loss": 0,
		"distorted": false,
		"trait_effects": []
	}
	if source_id == target_id:
		result["reason"] = "same_entity"
		return result
	var source := state.get_notable_entity(source_id)
	var target := state.get_notable_entity(target_id)
	var knowledge := state.get_knowledge(source_id, knowledge_id)
	if source.is_empty() or target.is_empty() or knowledge.is_empty():
		return result
	if bool(knowledge.get("invalidated", false)):
		result["reason"] = "invalidated_knowledge"
		return result
	var source_confidence := int(knowledge["confidence"])
	result["source_confidence"] = source_confidence
	if source_confidence < MINIMUM_SHARE_CONFIDENCE:
		result["reason"] = "source_not_confident"
		return result

	var relationship := state.get_relationship(source_id, target_id)
	if relationship.is_empty():
		result["reason"] = "no_relationship"
		return result
	var trust := int(relationship["trust"])
	var fear := int(relationship["fear"])
	var respect := int(relationship["respect"])
	var hostility := int(relationship["hostility"])
	var share_score := (
		source_confidence
		+ int(trust * 0.45)
		+ int(respect * 0.15)
		- int(hostility * 0.75)
		- int(fear * 0.10)
	)
	var trait_effects: Array[String] = []
	var source_traits: Array = source.get("traits", [])
	var target_traits: Array = target.get("traits", [])
	for trait_value in source_traits:
		var trait_id := str(trait_value)
		var rule: Dictionary = TRAIT_RULES.get(trait_id, {})
		if trait_id == "loyal" and trust >= int(rule.get("trusted_at", 101)):
			share_score += int(rule.get("trusted_share_bonus", 0))
			trait_effects.append("loyal_trusted_share")
		elif trait_id == "ambitious" and _topic_interests_ambitious(rule, str(knowledge["topic"])):
			share_score += int(rule.get("interest_bonus", 0))
			trait_effects.append("ambitious_interest")
		else:
			share_score += int(rule.get("share_bonus", 0))
	result["share_score"] = share_score
	result["trait_effects"] = trait_effects
	if share_score < SHARE_SCORE_REQUIRED:
		result["reason"] = "source_unwilling"
		return result

	var confidence_loss := (
		BASE_CONFIDENCE_LOSS
		+ int(knowledge.get("transmission_count", 0)) * 4
		+ int(hostility / 10.0)
		+ int(fear / 20.0)
		- int(trust / 10.0)
		- int(respect / 25.0)
	)
	var acceptance_threshold := BASE_ACCEPTANCE_CONFIDENCE
	var received_delta := 0
	var distorted := bool(knowledge.get("distorted", false))
	for trait_value in source_traits:
		var trait_id := str(trait_value)
		var rule: Dictionary = TRAIT_RULES.get(trait_id, {})
		confidence_loss += int(rule.get("confidence_loss", 0))
		if bool(rule.get("distorts", false)):
			distorted = true
			trait_effects.append("deceitful_distortion")
	for trait_value in target_traits:
		var trait_id := str(trait_value)
		var rule: Dictionary = TRAIT_RULES.get(trait_id, {})
		acceptance_threshold += int(rule.get("acceptance_delta", 0))
		received_delta += int(rule.get("received_confidence_delta", 0))
		if rule.has("acceptance_delta"):
			trait_effects.append("%s_acceptance" % trait_id)
	confidence_loss = maxi(confidence_loss, 8)
	var received_confidence := clampi(
		source_confidence - confidence_loss + received_delta,
		WorldState.KNOWLEDGE_CONFIDENCE_MIN,
		mini(WorldState.KNOWLEDGE_CONFIDENCE_MAX, source_confidence - 1)
	)
	acceptance_threshold = clampi(
		acceptance_threshold,
		WorldState.KNOWLEDGE_CONFIDENCE_MIN,
		WorldState.KNOWLEDGE_CONFIDENCE_MAX
	)
	result["confidence_loss"] = source_confidence - received_confidence
	result["received_confidence"] = received_confidence
	result["acceptance_threshold"] = acceptance_threshold
	result["distorted"] = distorted
	result["trait_effects"] = trait_effects
	if received_confidence < acceptance_threshold:
		result["reason"] = "target_rejected"
		return result
	result["allowed"] = true
	result["reason"] = "accepted"
	return result


func build_received_record(
	state: WorldState,
	source_id: String,
	target_id: String,
	knowledge_id: String,
	evaluation: Dictionary
) -> Dictionary:
	if not bool(evaluation.get("allowed", false)):
		return {}
	var source_record := state.get_knowledge(source_id, knowledge_id)
	if source_record.is_empty():
		return {}
	var received := source_record.duplicate(true)
	received["owner_id"] = target_id
	received["confidence"] = int(evaluation["received_confidence"])
	received["source_id"] = source_id
	received["source_type"] = "rumor"
	received["year_learned"] = state.year
	received["last_updated_year"] = state.year
	received["transmission_count"] = int(source_record.get("transmission_count", 0)) + 1
	received["distorted"] = bool(evaluation["distorted"])
	received["freshness"] = source_record.get("freshness", 100)
	return received


func _topic_interests_ambitious(rule: Dictionary, topic: String) -> bool:
	for interesting_topic in rule.get("interesting_topics", []):
		if str(interesting_topic) in topic:
			return true
	return false
