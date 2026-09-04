class_name IntentRules
extends RefCounted

# Broad Intent Model v1.
#
# An intent answers "what does this person want to accomplish?" — never "what
# do they attempt?". Action Selection owns the second question and does not
# exist yet. See GDD Part II, sections 30 and 31.
#
# This file produces INTENTIONS ONLY. Nothing here may change world statistics,
# relationships, or knowledge. Scoring reads believed information and never
# consults objective_truth_state, so an entity acting on a false rumor is
# expected behaviour rather than a bug.
#
# The gating law, settled with the user:
#
#   gate on relevance of the evidence,
#   weight on disposition,
#   never gate on capability.
#
# A belief about a surplus cannot produce HELP, because the evidence is not
# about suffering — that is relevance. Hostility and distrust reduce scores but
# never bar an intent — that is disposition. Having no food, no army and no
# influence does NOT bar HELP, because an intent with no available action is a
# valid outcome (GDD section 30); capability belongs to Action Selection.
#
# Decision Engine v1 templates retired here, kept as seeds for Action Selection:
#
#   send_aid          -> HELP wanted it; "donate food" is one execution of it.
#                        Its own-food and prosperity requirements were capability
#                        checks and now belong to Action Selection.
#   warn_ally         -> no single intent. The want is PROTECT (or HELP); the
#                        means is "share what I know with them". Its trust floor
#                        was an action-appropriateness check.
#   investigate       -> LEARN, one-to-one.
#   exploit_weakness  -> no single intent. It arises from ACQUIRE, INFLUENCE or
#                        PRESERVE depending on motive; the exploitation is an
#                        execution style the Action layer chooses from traits.
#                        Its military requirement was a capability check.
#   wait_and_observe  -> WAIT, which can now also be chosen on merit.

const MINIMUM_INTENT_SCORE := 30
const MAX_BELIEFS_CONSIDERED := 3
const MAX_TARGETS_CONSIDERED := 3
const MAX_INTENTS_PER_YEAR := 2
const MIN_FRESHNESS_FACTOR := 0.5
const DISTORTED_FACTOR := 0.85
const OUTDATED_FACTOR := 0.75
const DOUBT_CONFIDENCE := 55
const FALLBACK_INTENT := "wait"

# Fixed order gives argmax a deterministic tie-break before target/knowledge id.
# WAIT sits last so a genuine want always outranks it on an exact tie.
const INTENT_ORDER := [
	"help",
	"protect",
	"acquire",
	"learn",
	"influence",
	"connect",
	"distance",
	"resolve",
	"preserve",
	"wait"
]

# Topic families. Relevance gates match on substrings, so "danger_unrest" is
# deliberately both a threat and an erosion: order breaking down in the square
# endangers people and erodes a ruler's position at the same time. Which of the
# two a mortal reaches for is decided by their traits, not by the fact.
const HARDSHIP_TOPICS := [
	"food_shortage", "shortage", "starving", "famine", "hunger", "suffering",
	"plague", "poverty"
]
const THREAT_TOPICS := ["danger", "threat", "attack", "raid", "betrayal", "wolves", "violence"]
const EROSION_TOPICS := [
	"unrest", "instability", "weakness", "weak", "succession", "ruler_health",
	"rival", "decline"
]
const DOCTRINE_TOPICS := ["claim", "faith", "doctrine", "ritual", "prophecy", "heresy", "belief"]

# Traits weight intents; they never gate them. A cruel noble can still intend to
# help, it simply costs points against a rival want. Traits must not decide HOW
# an intent is pursued either — that is the Action layer's job (GDD section 32).
const INTENT_TRAIT_RULES := {
	"compassionate": {
		"help": 25, "resolve": 18, "connect": 12, "protect": 10,
		"acquire": -8, "distance": -10, "preserve": -4, "wait": -4
	},
	"loyal": {
		"protect": 25, "preserve": 12, "connect": 10, "resolve": 10, "help": 8,
		"distance": -15, "acquire": -4
	},
	"ambitious": {
		"influence": 22, "acquire": 20, "preserve": 18, "learn": 5, "connect": 5,
		"help": -10, "resolve": -5, "wait": -6
	},
	"cruel": {
		"acquire": 8, "distance": 6,
		"help": -20, "resolve": -14, "connect": -12, "protect": -10
	},
	"cautious": {
		"learn": 20, "distance": 18, "wait": 14, "preserve": 14, "protect": 8,
		"resolve": 6, "acquire": 4, "influence": -6
	},
	"gullible": {"connect": 6, "learn": -15, "wait": -5},
	"deceitful": {
		"influence": 14, "acquire": 8, "distance": 6, "preserve": 6,
		"protect": -12, "help": -8, "resolve": -8, "connect": -6
	}
}

# target_mode:
#   "subject"       -> the subject_id carried by the triggering belief
#   "relationship"  -> an entity this actor has a directed relationship toward
#   "self"          -> the actor; what is at stake is named by the belief
#   "none"          -> no target
# requires_belief:
#   true            -> the intent must be triggered by something believed
#   false           -> an ordinary-life want that needs no crisis to exist
# confidence_mode:
#   "direct"        -> stronger belief scores higher
#   "inverse"       -> weaker belief scores higher (doubt motivates enquiry)
const INTENT_CANDIDATES := {
	# Improve another's condition, where harm is already present.
	"help": {
		"base_priority": 20,
		"target_mode": "subject",
		"requires_belief": true,
		"topics": HARDSHIP_TOPICS,
		"min_confidence": 35,
		"confidence_mode": "direct",
		"confidence_weight": 0.6,
		"axis_weights": {"trust": 0.25, "respect": 0.1, "hostility": -0.35, "fear": -0.1},
		# Motivation, not capability: hardship at home pulls attention inward,
		# and comfort makes another's need easier to hold in mind. Neither of
		# these may ever bar the intent.
		"world_state_rules": [
			{"field": "food_level", "op": "lte", "value": 0, "delta": -10, "detail": "their own stores are empty"},
			{"field": "prosperity_level", "op": "gte", "value": 2, "delta": 6, "detail": "the realm is prosperous"}
		]
	},
	# Prevent harm from an identified threat.
	"protect": {
		"base_priority": 18,
		"target_mode": "subject",
		"requires_belief": true,
		"topics": THREAT_TOPICS,
		"min_confidence": 30,
		"confidence_mode": "direct",
		"confidence_weight": 0.6,
		"axis_weights": {"trust": 0.4, "respect": 0.2, "hostility": -0.45, "fear": -0.1},
		"world_state_rules": [
			{"field": "stability_level", "op": "lte", "value": 1, "delta": 4, "detail": "the realm is uneasy"}
		]
	},
	# Gain something materially or positionally lacking. Driven by the actor's
	# own want, not by the sight of someone else's plenty — coveting what a
	# weaker neighbour holds is an execution the Action layer may choose, and
	# must not be smuggled in here as a want.
	"acquire": {
		"base_priority": 14,
		"target_mode": "none",
		"requires_belief": false,
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {},
		"world_state_rules": [
			{"field": "food_level", "op": "lte", "value": 0, "delta": 14, "detail": "their own stores are empty"},
			{"field": "food_level", "op": "lte", "value": 1, "delta": 6, "detail": "food is short"},
			{"field": "prosperity_level", "op": "lte", "value": 0, "delta": 8, "detail": "the realm is destitute"},
			{"field": "prosperity_level", "op": "lte", "value": 1, "delta": 3, "detail": "the realm is poor"}
		]
	},
	# Reduce uncertainty. Any topic qualifies; doubt is what makes it relevant.
	"learn": {
		"base_priority": 14,
		"target_mode": "subject",
		"requires_belief": true,
		"topics": [],
		"min_confidence": 5,
		"confidence_mode": "inverse",
		"confidence_weight": 0.5,
		"requires_doubt": true,
		"axis_weights": {},
		"world_state_rules": []
	},
	# Change another's behaviour, belief, or support. Hostility is deliberately
	# absent from the weights: people try to sway enemies as readily as friends,
	# and the difference shows up in how, not whether.
	"influence": {
		"base_priority": 15,
		"target_mode": "subject",
		"requires_belief": true,
		"topics": EROSION_TOPICS + DOCTRINE_TOPICS,
		"min_confidence": 30,
		"confidence_mode": "direct",
		"confidence_weight": 0.5,
		"axis_weights": {"respect": 0.3, "trust": 0.15, "fear": 0.1},
		"world_state_rules": [
			{"field": "stability_level", "op": "lte", "value": 1, "delta": 5, "detail": "the realm is uneasy"}
		]
	},
	# Strengthen or create a bond. Ordinary life: it needs no crisis, so its
	# weights are kept modest — a want the world gave evidence for should
	# normally outrank one that needed none. Ordinary life is the floor mortals
	# stand on, not a ceiling that hides what is happening to them.
	"connect": {
		"base_priority": 10,
		"target_mode": "relationship",
		"requires_belief": false,
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {"trust": 0.4, "respect": 0.3, "hostility": -0.4, "fear": -0.2},
		"world_state_rules": []
	},
	# Reduce exposure, obligation, or involvement.
	"distance": {
		"base_priority": 12,
		"target_mode": "relationship",
		"requires_belief": false,
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {"fear": 0.45, "hostility": 0.35, "trust": -0.35, "respect": -0.1},
		"world_state_rules": []
	},
	# End an active quarrel. The only evidence v1 has for a quarrel is the
	# actor's own hostility toward someone; with none, RESOLVE simply scores too
	# low to be chosen, which is the honest outcome rather than an invented one.
	"resolve": {
		"base_priority": 11,
		"target_mode": "relationship",
		"requires_belief": false,
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {"hostility": 0.5, "trust": 0.15, "respect": 0.15, "fear": -0.1},
		"world_state_rules": []
	},
	# Hold to an existing condition, role, belief, or order under erosion. The
	# target is the actor, because what is being kept is theirs; the belief in
	# knowledge_used names what is wearing it away.
	"preserve": {
		"base_priority": 15,
		"target_mode": "self",
		"requires_belief": true,
		"topics": EROSION_TOPICS + DOCTRINE_TOPICS,
		"min_confidence": 30,
		"confidence_mode": "direct",
		"confidence_weight": 0.5,
		"axis_weights": {},
		"world_state_rules": [
			{"field": "stability_level", "op": "lte", "value": 1, "delta": 8, "detail": "the realm is uneasy"},
			{"field": "prosperity_level", "op": "gte", "value": 2, "delta": 4, "detail": "there is much to lose"}
		]
	},
	# Choose not to intervene yet. WAIT is a real want, not only the residue of
	# failure: a settled world and weak information are reasons to hold still.
	# Its base is deliberately low so its wins must be earned by conditions.
	"wait": {
		"base_priority": 10,
		"target_mode": "none",
		"requires_belief": false,
		"topics": [],
		"min_confidence": 0,
		"confidence_mode": "direct",
		"confidence_weight": 0.0,
		"axis_weights": {},
		"doubt_bonus": {"per_belief": 5, "max": 10},
		"world_state_rules": [
			{"field": "food_level", "op": "gte", "value": 2, "delta": 6, "detail": "there is no pressing need"},
			{"field": "stability_level", "op": "gte", "value": 2, "delta": 6, "detail": "the realm is settled"}
		]
	}
}


func choose_intent(state: WorldState, actor_id: String) -> Dictionary:
	var actor := state.get_notable_entity(actor_id)
	if actor.is_empty():
		return {}
	var evaluated := evaluate_intents(state, actor_id)
	var considered: Array[Dictionary] = []
	var best: Dictionary = {}
	for candidate: Dictionary in evaluated:
		considered.append({
			"intent_type": candidate["intent_type"],
			"target_id": candidate["target_id"],
			"score": candidate["score"],
			"eligible": candidate["eligible"],
			"reason": candidate["rejection_reason"]
		})
		if not bool(candidate["eligible"]):
			continue
		if int(candidate["score"]) < MINIMUM_INTENT_SCORE:
			continue
		if best.is_empty() or _outranks(candidate, best):
			best = candidate
	var selection := "argmax"
	if best.is_empty():
		best = _build_fallback(state, actor)
		selection = "fallback"
	var record := _build_record(state, actor, best, selection)
	record["considered"] = considered
	return record


func evaluate_intents(state: WorldState, actor_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var actor := state.get_notable_entity(actor_id)
	if actor.is_empty():
		return results
	var beliefs := _beliefs_for(state, actor_id)
	var relationship_targets := _relationship_targets_for(state, actor_id)
	for intent_type: String in INTENT_ORDER:
		var template: Dictionary = INTENT_CANDIDATES[intent_type]
		var target_mode := str(template["target_mode"])
		if not bool(template.get("requires_belief", true)):
			# Ordinary-life wants: evaluated once per target, with no belief.
			match target_mode:
				"relationship":
					for target_id: String in relationship_targets:
						results.append(_evaluate_candidate(state, actor, intent_type, target_id, {}))
				"self":
					results.append(_evaluate_candidate(state, actor, intent_type, actor_id, {}))
				_:
					results.append(_evaluate_candidate(state, actor, intent_type, "", {}))
			continue
		for belief: Dictionary in beliefs:
			match target_mode:
				"relationship":
					for target_id: String in relationship_targets:
						results.append(_evaluate_candidate(state, actor, intent_type, target_id, belief))
				"self":
					results.append(_evaluate_candidate(state, actor, intent_type, actor_id, belief))
				_:
					results.append(_evaluate_candidate(
						state, actor, intent_type, str(belief.get("subject_id", "")), belief
					))
	return results


func _evaluate_candidate(
	state: WorldState,
	actor: Dictionary,
	intent_type: String,
	target_id: String,
	belief: Dictionary
) -> Dictionary:
	var template: Dictionary = INTENT_CANDIDATES[intent_type]
	var actor_id := str(actor["id"])
	var target_mode := str(template["target_mode"])
	var needs_belief := bool(template.get("requires_belief", true))
	var trait_factors: Array[Dictionary] = []
	var relationship_factors: Array[Dictionary] = []
	var knowledge_used: Array[Dictionary] = []
	var world_state_factors: Array[Dictionary] = []
	var reasons: Array[String] = []
	var candidate := {
		"intent_type": intent_type,
		"target_id": target_id,
		"target_kind": _target_kind(state, actor_id, target_mode, target_id),
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

	# Outward-facing targets must exist and must not be the actor. A "self"
	# target is the actor by definition and is exempt.
	if target_mode == "subject" or target_mode == "relationship":
		if target_id.is_empty():
			candidate["rejection_reason"] = "no_target"
			return candidate
		if target_id == actor_id:
			candidate["rejection_reason"] = "self_target"
			return candidate

	var weighed_confidence := 0
	if needs_belief:
		if belief.is_empty():
			candidate["rejection_reason"] = "no_matching_belief"
			return candidate
		if bool(belief.get("invalidated", false)):
			candidate["rejection_reason"] = "invalidated_knowledge"
			return candidate
		# Relevance gate: evidence about the wrong kind of thing cannot produce
		# this want. This is the only class of hard gate the model permits.
		var topics: Array = template["topics"]
		if not topics.is_empty() and not _topic_matches(topics, str(belief.get("topic", ""))):
			candidate["rejection_reason"] = "topic_mismatch"
			return candidate
		if bool(template.get("requires_doubt", false)) and not _is_doubtful(belief):
			candidate["rejection_reason"] = "belief_not_in_doubt"
			return candidate
		weighed_confidence = effective_confidence(belief)
		if weighed_confidence < int(template["min_confidence"]):
			candidate["rejection_reason"] = "confidence_too_low"
			return candidate

	var score := int(template["base_priority"])
	var relationship := state.get_relationship(actor_id, target_id)

	if not belief.is_empty() and float(template["confidence_weight"]) != 0.0:
		var basis := weighed_confidence
		if str(template["confidence_mode"]) == "inverse":
			basis = 100 - weighed_confidence
		var knowledge_delta := int(round(basis * float(template["confidence_weight"])))
		score += knowledge_delta
		knowledge_used.append(_knowledge_factor(belief, weighed_confidence, knowledge_delta))
		if str(template["confidence_mode"]) == "inverse":
			reasons.append("doubts \"%s\" (confidence %d, weighed as %d)" % [
				str(belief.get("claim", belief["id"])), int(belief["confidence"]), weighed_confidence
			])
		else:
			reasons.append("believes \"%s\" (confidence %d, weighed as %d)" % [
				str(belief.get("claim", belief["id"])), int(belief["confidence"]), weighed_confidence
			])
		if bool(belief.get("is_outdated", false)):
			reasons.append("that belief is outdated and counts for less")
		if bool(belief.get("distorted", false)):
			reasons.append("that belief reached them distorted")

	# Weak information is itself a reason to hold still.
	var doubt_bonus: Dictionary = template.get("doubt_bonus", {})
	if not doubt_bonus.is_empty() and belief.is_empty():
		var gained := 0
		var cap := int(doubt_bonus["max"])
		for held: Dictionary in _beliefs_for(state, actor_id):
			if gained >= cap:
				break
			if not _is_doubtful(held):
				continue
			var doubt_delta := mini(int(doubt_bonus["per_belief"]), cap - gained)
			gained += doubt_delta
			score += doubt_delta
			knowledge_used.append(_knowledge_factor(
				held, effective_confidence(held), doubt_delta
			))
			reasons.append("is unsure of \"%s\"" % str(held.get("claim", held["id"])))

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
		var trait_rule: Dictionary = INTENT_TRAIT_RULES.get(trait_id, {})
		if not trait_rule.has(intent_type):
			continue
		var trait_delta := int(trait_rule[intent_type])
		score += trait_delta
		trait_factors.append({"source": "trait", "detail": trait_id, "delta": trait_delta})
		reasons.append("%s outlook %s this course" % [
			trait_id, "favours" if trait_delta >= 0 else "resists"
		])

	var home_id := str(actor.get("home_location_id", ""))
	for rule: Dictionary in template.get("world_state_rules", []):
		if not _check_world_state(state, rule, home_id):
			continue
		var world_delta := int(rule["delta"])
		score += world_delta
		world_state_factors.append({
			"source": "world_state",
			"detail": str(rule["detail"]),
			"field": str(rule["field"]),
			"value": _world_state_value(state, str(rule["field"]), home_id),
			"delta": world_delta
		})
		reasons.append(str(rule["detail"]))

	# A target the actor can actually name is worth more than a bare subject id.
	var target_delta := _target_bonus(str(candidate["target_kind"]), relationship)
	if target_delta != 0:
		score += target_delta
		relationship_factors.append({
			"source": "target",
			"detail": "%s is a known %s" % [target_id, str(candidate["target_kind"])],
			"axis": "",
			"value": 0,
			"delta": target_delta
		})

	candidate["score"] = score
	candidate["eligible"] = true
	candidate["rejection_reason"] = "eligible"
	return candidate


func _build_fallback(state: WorldState, actor: Dictionary) -> Dictionary:
	var fallback := _evaluate_candidate(state, actor, FALLBACK_INTENT, "", {})
	fallback["eligible"] = true
	fallback["rejection_reason"] = "eligible"
	var reasons: Array[String] = fallback["reasons"]
	reasons.append("no intention reached the acting threshold of %d" % MINIMUM_INTENT_SCORE)
	return fallback


func _build_record(
	state: WorldState,
	actor: Dictionary,
	candidate: Dictionary,
	selection: String
) -> Dictionary:
	var actor_id := str(actor["id"])
	var intent_type := str(candidate["intent_type"])
	return {
		"id": "intent_%04d_%s_%s" % [state.year, actor_id, intent_type],
		"year": state.year,
		"actor_id": actor_id,
		"actor_name": str(actor.get("name", actor_id)),
		"actor_traits": actor.get("traits", []).duplicate(),
		"target_id": str(candidate["target_id"]),
		"target_kind": str(candidate["target_kind"]),
		"intent_type": intent_type,
		# "argmax" means the intent won on merit; "fallback" means nothing
		# reached the threshold. WAIT can arrive by either route, and the two
		# must stay distinguishable.
		"selection": selection,
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


func _knowledge_factor(belief: Dictionary, weighed_confidence: int, delta: int) -> Dictionary:
	return {
		"knowledge_id": str(belief["id"]),
		"subject_id": str(belief.get("subject_id", "")),
		"topic": str(belief.get("topic", "")),
		"claim": str(belief.get("claim", "")),
		"confidence": int(belief["confidence"]),
		"effective_confidence": weighed_confidence,
		"freshness": int(belief.get("freshness", 100)),
		"is_outdated": bool(belief.get("is_outdated", false)),
		"distorted": bool(belief.get("distorted", false)),
		"truth_state": str(belief.get("truth_state", "unknown")),
		"delta": delta
	}


func _outranks(candidate: Dictionary, best: Dictionary) -> bool:
	var candidate_score := int(candidate["score"])
	var best_score := int(best["score"])
	if candidate_score != best_score:
		return candidate_score > best_score
	var candidate_rank := INTENT_ORDER.find(str(candidate["intent_type"]))
	var best_rank := INTENT_ORDER.find(str(best["intent_type"]))
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


# Public: Action Selection weighs the same beliefs with the same discounts.
func effective_confidence(belief: Dictionary) -> int:
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


# Target kinds are open by design. "group" and "topic" are reserved for
# factions and knowledge-topic targets; adding either means teaching this
# function to recognise them, not reshaping the intent model.
func _target_kind(
	state: WorldState,
	actor_id: String,
	target_mode: String,
	target_id: String
) -> String:
	if target_mode == "none" or target_id.is_empty():
		return "none"
	if target_id == actor_id:
		return "self"
	if state.notable_entities.has(target_id):
		return str(state.notable_entities[target_id].get("kind", "entity"))
	if state.locations.has(target_id):
		return "settlement"
	return "subject"


func _target_bonus(target_kind: String, relationship: Dictionary) -> int:
	match target_kind:
		"none", "self", "subject":
			return 0
		"settlement":
			return 5
	return 10 if not relationship.is_empty() else 5


func _check_world_state(state: WorldState, condition: Dictionary, home_id: String = "") -> bool:
	return _compare(
		_world_state_value(state, str(condition["field"]), home_id),
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


# Local conditions are read from where the actor lives. A mortal knows whether
# there is food where they are without being told, and that is the one place the
# intent layer may touch settlement truth: it is their own directly-lived
# context, not a report about somewhere else. Anything about ANOTHER settlement
# must still reach them as belief.
func _world_state_value(state: WorldState, field: String, home_id: String = "") -> int:
	var band := ""
	match field:
		"food_level":
			band = "food"
		"stability_level":
			band = "stability"
		"prosperity_level":
			band = "prosperity"
	if not band.is_empty():
		if not home_id.is_empty() and state.locations.has(home_id):
			return state.get_settlement_band(home_id, band)
		# No home means no local context: fall back to how the realm reads.
		return _kingdom_band(state, band)
	match field:
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


func _kingdom_band(state: WorldState, band: String) -> int:
	match band:
		"food":
			return state.food_level
		"stability":
			return state.stability_level
		"prosperity":
			return state.prosperity_level
	return 0
