class_name ActionRules
extends RefCounted

# Mortal Action Selection v1.
#
# An intent says what a mortal WANTS. An action says what they will ATTEMPT.
# See GDD Part II, section 31. This file answers the second question only, and
# it answers it by SELECTION, not execution: choosing to ask the King for help
# does not mean the King agrees, that food moves, that a relationship shifts, or
# that anything at all happens. Execution and consequences are later systems and
# must not be built here.
#
# Where the gating law placed capability, it belongs here and nowhere earlier:
#
#   Intent  -> gate on relevance, weight on disposition, never gate on capability
#   Action  -> capability is a hard gate
#
# Capability filters ACTIONS. It must never reach back and invalidate the want.
# Mara wanting to help Westfield with nothing to give stays wanting to help; her
# selected action becomes WAIT, and the record says why.
#
# Deferred, deliberately, because the world has no data to support them
# honestly:
#
#   GO      -> entities have no location, so there is no origin to move from.
#              Movement would have to be invented. Reserved, not implemented.
#   role    -> entities carry "kind", which is "person" for everyone, and an
#              unused "data" dictionary. There is no role to weight execution
#              with yet. GDD section 14 describes roles; the code has none.
#   causes  -> world_flags (king_claims_divine_favor, mara_is_prophet,
#              local_council_empowered) are the closest thing to causes that
#              could be supported or opposed. v1 keeps SUPPORT and OPPOSE aimed
#              at people; flags are the natural expansion.
#   style   -> gentle, public, secret, deceptive. Traits choose the action here,
#              not the manner of it. The record has room to grow a style field
#              without reshaping anything.

const MAX_ACTION_TARGETS := 3
const FALLBACK_ACTION := "wait"

# Fixed order gives argmax a deterministic tie-break before target and topic.
# WAIT sits last so any real attempt outranks it on an exact tie.
const ACTION_ORDER := ["give", "ask", "tell", "support", "oppose", "observe", "wait"]

# Which executions a want can reach for. Unsupported pairings are left out
# rather than listed for symmetry: DISTANCE wants withdrawal, and withdrawal has
# no honest execution until GO exists, so it waits instead of being bent into
# OPPOSE. A WAIT intent produces WAIT; someone who actively wants to look into
# something already has an intent for that, and it is LEARN.
const INTENT_ACTIONS := {
	"help": ["give", "ask", "tell", "support", "wait"],
	"protect": ["give", "ask", "tell", "support", "oppose", "observe", "wait"],
	"acquire": ["ask", "observe", "wait"],
	"learn": ["ask", "observe", "wait"],
	"influence": ["ask", "tell", "support", "oppose", "wait"],
	"connect": ["ask", "tell", "support", "wait"],
	"distance": ["wait"],
	"resolve": ["ask", "tell", "support", "oppose", "observe", "wait"],
	"preserve": ["give", "ask", "tell", "support", "oppose", "wait"],
	"wait": ["wait"]
}

# Traits chose the want already. Here they lean on the method: a cautious person
# asks and watches, a compassionate one gives and stands alongside. None of
# these is violent, and none of them scripts a character.
const ACTION_TRAIT_RULES := {
	"compassionate": {"give": 20, "support": 14, "ask": 8, "tell": 6, "oppose": -14},
	"loyal": {"support": 18, "tell": 10, "give": 8, "ask": 6, "oppose": -10},
	"ambitious": {"ask": 14, "support": 12, "oppose": 8, "give": -8, "wait": -6},
	"cruel": {"oppose": 12, "give": -18, "support": -10},
	"cautious": {"observe": 20, "wait": 10, "ask": 8, "give": -6, "oppose": -12},
	"gullible": {"tell": 8, "observe": -12},
	"deceitful": {"tell": 10, "ask": 6, "oppose": 6, "support": -6, "give": -8}
}

# target_mode:
#   "relationship"  -> someone the actor has a directed relationship toward
#   "subject"       -> whatever the driving belief is about
#   "none"          -> no target
# requires:
#   "resource"      -> the actor must control something transferable
#   "knowledge"     -> the actor must hold a belief worth passing on
#   "uncertainty"   -> there must be something genuinely unresolved
const ACTION_CANDIDATES := {
	# Hand over something the actor controls. Nothing in the world models a
	# resource anyone owns, so this is generated and then refused every time.
	# It is kept because the refusal is the point: it shows capability filtering
	# an action without touching the want, and it becomes live the moment
	# settlement or personal resources exist.
	"give": {
		"base_priority": 18,
		"target_mode": "relationship",
		"requires": "resource",
		"resource_type": "food",
		"axis_weights": {"trust": 0.3, "respect": 0.1, "hostility": -0.4, "fear": -0.1}
	},
	# Request help, resources, or an answer. This is what lets someone who can
	# do nothing themselves still pursue what they want, through someone else.
	"ask": {
		"base_priority": 18,
		"target_mode": "relationship",
		"requires": "",
		"axis_weights": {"trust": 0.35, "respect": 0.25, "hostility": -0.3, "fear": -0.3}
	},
	# Pass on something believed. Believed, not true: a false belief makes a
	# perfectly valid thing to tell someone.
	"tell": {
		"base_priority": 15,
		"target_mode": "relationship",
		"requires": "knowledge",
		"axis_weights": {"trust": 0.3, "respect": 0.2, "hostility": -0.35, "fear": -0.15}
	},
	"support": {
		"base_priority": 14,
		"target_mode": "relationship",
		"requires": "",
		"axis_weights": {"trust": 0.3, "respect": 0.35, "hostility": -0.45, "fear": -0.15}
	},
	# Act against a direction, not against a person's body. Objecting, refusing
	# support, obstructing. There is no violence in this vocabulary.
	"oppose": {
		"base_priority": 13,
		"target_mode": "relationship",
		"requires": "",
		"axis_weights": {"hostility": 0.45, "trust": -0.3, "fear": -0.2, "respect": -0.15}
	},
	# Look harder without intervening. Scores on what is still unresolved, so a
	# confident belief makes a poor reason to go watching.
	"observe": {
		"base_priority": 12,
		"target_mode": "subject",
		"requires": "uncertainty",
		"axis_weights": {}
	},
	"wait": {
		"base_priority": 8,
		"target_mode": "none",
		"requires": "",
		"axis_weights": {}
	}
}

# A want leans toward the execution that most directly serves it. Warning
# someone is the archetypal way to protect them; changing a mind means speaking;
# understanding means watching. These lean, they do not script: every listed
# action still has to survive capability and out-score its rivals.
const INTENT_ACTION_AFFINITY := {
	"help": {"give": 8, "ask": 6},
	"protect": {"tell": 10, "oppose": 4},
	"acquire": {"ask": 8},
	"learn": {"observe": 8, "ask": 6},
	"influence": {"tell": 12, "support": 4},
	"connect": {"tell": 8, "support": 6},
	"resolve": {"tell": 8, "ask": 6},
	"preserve": {"support": 8, "oppose": 6}
}

var intent_rules := IntentRules.new()


func choose_action(state: WorldState, intent: Dictionary) -> Dictionary:
	if intent.is_empty():
		return {}
	var actor := state.get_notable_entity(str(intent.get("actor_id", "")))
	if actor.is_empty():
		return {}
	var evaluated := evaluate_actions(state, intent)
	var considered: Array[Dictionary] = []
	var best: Dictionary = {}
	var viable_attempts := 0
	for candidate: Dictionary in evaluated:
		considered.append({
			"action_type": candidate["action_type"],
			"target_id": candidate["target_id"],
			"score": candidate["score"],
			"viable": candidate["viable"],
			"reason": candidate["rejection_reason"]
		})
		if not bool(candidate["viable"]):
			continue
		if str(candidate["action_type"]) != FALLBACK_ACTION:
			viable_attempts += 1
		if best.is_empty() or _outranks(candidate, best):
			best = candidate
	if best.is_empty():
		# WAIT is always viable, so this should be unreachable. Build it anyway
		# rather than return a record with no action in it.
		best = _evaluate_candidate(state, actor, intent, FALLBACK_ACTION, "", {})

	var selection := "argmax"
	if str(best["action_type"]) == FALLBACK_ACTION:
		if str(intent.get("intent_type", "")) == "wait":
			selection = "intended_wait"
		elif viable_attempts == 0:
			selection = "fallback_no_viable_action"
	var record := _build_record(state, actor, intent, best, selection)
	record["considered"] = considered
	return record


func evaluate_actions(state: WorldState, intent: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var actor := state.get_notable_entity(str(intent.get("actor_id", "")))
	if actor.is_empty():
		return results
	var intent_type := str(intent.get("intent_type", ""))
	# Only executions this want can reach for are ever considered. An action
	# outside its intent's list is not scored badly; it does not exist.
	var compatible: Array = INTENT_ACTIONS.get(intent_type, [FALLBACK_ACTION])
	var targets := _relationship_targets_for(state, str(actor["id"]))
	var topic := _topic_for(state, intent)
	for action_type: String in ACTION_ORDER:
		if action_type not in compatible:
			continue
		var template: Dictionary = ACTION_CANDIDATES[action_type]
		match str(template["target_mode"]):
			"relationship":
				if targets.is_empty():
					# Still record the candidate so the reason it was impossible
					# is on the record. An actor who knows nobody must be able to
					# show that this is why they could not act.
					results.append(_evaluate_candidate(state, actor, intent, action_type, "", topic))
				for target_id: String in targets:
					results.append(_evaluate_candidate(state, actor, intent, action_type, target_id, topic))
			"subject":
				results.append(_evaluate_candidate(
					state, actor, intent, action_type, str(topic.get("subject_id", "")), topic
				))
			_:
				results.append(_evaluate_candidate(state, actor, intent, action_type, "", topic))
	return results


func _evaluate_candidate(
	state: WorldState,
	actor: Dictionary,
	intent: Dictionary,
	action_type: String,
	target_id: String,
	topic: Dictionary
) -> Dictionary:
	var template: Dictionary = ACTION_CANDIDATES[action_type]
	var actor_id := str(actor["id"])
	var target_mode := str(template["target_mode"])
	var trait_factors: Array[Dictionary] = []
	var relationship_factors: Array[Dictionary] = []
	var knowledge_factors: Array[Dictionary] = []
	var target_factors: Array[Dictionary] = []
	var reasons: Array[String] = []
	var candidate := {
		"action_type": action_type,
		"target_id": target_id,
		"target_kind": _target_kind(state, actor_id, target_mode, target_id),
		"topic_id": "",
		"resource_type": "",
		"base_priority": int(template["base_priority"]),
		"score": 0,
		"viable": false,
		"rejection_reason": "",
		"trait_factors": trait_factors,
		"relationship_factors": relationship_factors,
		"knowledge_factors": knowledge_factors,
		"target_factors": target_factors,
		"reasons": reasons
	}

	# --- capability: the hard gate, and the only one at this layer ------------
	var requirement := str(template["requires"])
	match requirement:
		"resource":
			if not _controls_resource(state, actor_id, str(template.get("resource_type", ""))):
				candidate["rejection_reason"] = "no_controlled_resource"
				return candidate
			candidate["resource_type"] = str(template.get("resource_type", ""))
		"knowledge":
			if topic.is_empty():
				candidate["rejection_reason"] = "no_communicable_knowledge"
				return candidate
			# The belief must still be held. A retracted one cannot be passed on.
			var held := state.get_knowledge(actor_id, str(topic["id"]))
			if held.is_empty() or bool(held.get("invalidated", false)):
				candidate["rejection_reason"] = "no_communicable_knowledge"
				return candidate
			# There is nothing to tell someone who already knows it as well as
			# you do. This mirrors how knowledge sharing already refuses a
			# receiver who is the more confident of the two.
			var target_belief := state.get_knowledge(target_id, str(topic["id"]))
			if not target_belief.is_empty() \
				and not bool(target_belief.get("invalidated", false)) \
				and int(target_belief["confidence"]) >= int(held["confidence"]):
				candidate["rejection_reason"] = "target_already_knows"
				return candidate
			candidate["topic_id"] = str(topic["id"])
		"uncertainty":
			if topic.is_empty():
				candidate["rejection_reason"] = "no_uncertainty"
				return candidate
			candidate["topic_id"] = str(topic["id"])

	if target_mode != "none":
		if target_id.is_empty():
			candidate["rejection_reason"] = _no_target_reason(action_type)
			return candidate
		if target_id == actor_id and target_mode == "relationship":
			candidate["rejection_reason"] = "self_target"
			return candidate

	if action_type == "ask":
		# An ask carries whatever prompted it, and asking for material aid is
		# asking for the one resource the world actually models.
		if not topic.is_empty():
			candidate["topic_id"] = str(topic["id"])
		if str(intent.get("intent_type", "")) in ["acquire", "help"]:
			candidate["resource_type"] = "food"

	var score := int(template["base_priority"])
	var relationship := state.get_relationship(actor_id, target_id)

	# --- what is known ------------------------------------------------------
	if not topic.is_empty() and (requirement in ["knowledge", "uncertainty"] or action_type == "ask"):
		var weighed := intent_rules.effective_confidence(topic)
		var knowledge_delta := 0
		if action_type == "ask":
			# You ask because of something you believe, not out of nowhere.
			knowledge_delta = int(round(weighed * 0.35))
			reasons.append("asks on the strength of \"%s\" (weighed as %d)" % [
				str(topic.get("claim", topic["id"])), weighed
			])
		elif requirement == "knowledge":
			knowledge_delta = int(round(weighed * 0.4))
			# Word is worth more where it has not reached yet.
			if state.get_knowledge(target_id, str(topic["id"])).is_empty():
				knowledge_delta += 15
				reasons.append("%s has not heard this yet" % target_id)
			reasons.append("has something to say: \"%s\" (weighed as %d)" % [
				str(topic.get("claim", topic["id"])), weighed
			])
		else:
			# Uncertainty, not confidence, is what makes watching worth doing.
			knowledge_delta = int(round((100 - weighed) * 0.35))
			reasons.append("is still unsure of \"%s\" (weighed as %d)" % [
				str(topic.get("claim", topic["id"])), weighed
			])
		score += knowledge_delta
		knowledge_factors.append({
			"source": "knowledge",
			"detail": str(topic["id"]),
			"knowledge_id": str(topic["id"]),
			"claim": str(topic.get("claim", "")),
			"topic": str(topic.get("topic", "")),
			"confidence": int(topic.get("confidence", 0)),
			"effective_confidence": weighed,
			"delta": knowledge_delta
		})

	# --- who they would act through -----------------------------------------
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
				reasons.append("%s %d toward %s %s this approach" % [
					axis, axis_value, target_id, "favours" if axis_delta > 0 else "resists"
				])

	# --- disposition --------------------------------------------------------
	for trait_value in actor.get("traits", []):
		var trait_id := str(trait_value)
		var trait_rule: Dictionary = ACTION_TRAIT_RULES.get(trait_id, {})
		if not trait_rule.has(action_type):
			continue
		var trait_delta := int(trait_rule[action_type])
		score += trait_delta
		trait_factors.append({"source": "trait", "detail": trait_id, "delta": trait_delta})
		reasons.append("%s outlook %s this approach" % [
			trait_id, "favours" if trait_delta >= 0 else "resists"
		])

	# --- the recourse of someone who cannot act directly --------------------
	# This is what ASK is for. Where the want could in principle have been met
	# by handing something over, and the actor controls nothing, asking someone
	# who might is the way a powerless person still pursues what they want.
	if action_type == "ask" and "give" in INTENT_ACTIONS.get(str(intent.get("intent_type", "")), []):
		if not _controls_resource(state, actor_id, "food"):
			score += 12
			target_factors.append({
				"source": "capability",
				"detail": "has nothing to give, so must ask",
				"delta": 12
			})
			reasons.append("cannot act directly, so must ask someone who can")

	# --- what this want leans toward ----------------------------------------
	var affinity: Dictionary = INTENT_ACTION_AFFINITY.get(str(intent.get("intent_type", "")), {})
	if affinity.has(action_type):
		var affinity_delta := int(affinity[action_type])
		score += affinity_delta
		target_factors.append({
			"source": "intent",
			"detail": "%s leans toward %s" % [str(intent.get("intent_type", "")), action_type],
			"delta": affinity_delta
		})

	# --- acting on the thing actually wanted --------------------------------
	if not target_id.is_empty() and target_id == str(intent.get("target_id", "")):
		score += 10
		target_factors.append({
			"source": "target",
			"detail": "%s is what the intent is aimed at" % target_id,
			"delta": 10
		})
		reasons.append("this is the person the want is already aimed at")

	candidate["score"] = score
	candidate["viable"] = true
	candidate["rejection_reason"] = "viable"
	return candidate


func _build_record(
	state: WorldState,
	actor: Dictionary,
	intent: Dictionary,
	candidate: Dictionary,
	selection: String
) -> Dictionary:
	var actor_id := str(actor["id"])
	var action_type := str(candidate["action_type"])
	if action_type == FALLBACK_ACTION:
		var reasons: Array[String] = candidate["reasons"]
		match selection:
			"intended_wait":
				reasons.append("the want itself was to hold back")
			"fallback_no_viable_action":
				reasons.append("no viable way to act on %s was available" % str(
					intent.get("intent_type", "this want")
				))
	return {
		"id": "action_%04d_%s_%s" % [state.year, actor_id, action_type],
		"year": state.year,
		"actor_id": actor_id,
		"actor_name": str(actor.get("name", actor_id)),
		# The want this attempt serves. Selection never edits it.
		"intent_id": str(intent.get("id", "")),
		"intent_type": str(intent.get("intent_type", "")),
		"action_type": action_type,
		# Who the attempt is aimed at, which is often not what the want is about:
		# helping a starving village can mean asking a person for grain.
		"target_id": str(candidate["target_id"]),
		"target_kind": str(candidate["target_kind"]),
		# What the attempt concerns, carried down from the want.
		"subject_id": str(intent.get("target_id", "")),
		"topic_id": str(candidate["topic_id"]),
		"resource_type": str(candidate["resource_type"]),
		"base_priority": int(candidate["base_priority"]),
		"score": int(candidate["score"]),
		"selection": selection,
		"viable": bool(candidate["viable"]),
		"trait_factors": candidate["trait_factors"],
		"relationship_factors": candidate["relationship_factors"],
		"knowledge_factors": candidate["knowledge_factors"],
		"target_factors": candidate["target_factors"],
		"reasons": candidate["reasons"],
		"considered": []
	}


# Nothing in the world models a resource a mortal controls. Kingdom food levels
# belong to the realm, not to any person, and inventing an owner here would be
# inventing a simulation system inside an action-selection pass. Until
# settlement or personal resources exist, this is honestly false for everyone.
func _controls_resource(_state: WorldState, _actor_id: String, _resource_type: String) -> bool:
	return false


# The belief an attempt would be built on. The want's own driving belief comes
# first, because that keeps cause and effect visible across the two layers.
func _topic_for(state: WorldState, intent: Dictionary) -> Dictionary:
	var actor_id := str(intent.get("actor_id", ""))
	for factor_value in intent.get("knowledge_used", []):
		var factor: Dictionary = factor_value
		var record := state.get_knowledge(actor_id, str(factor.get("knowledge_id", "")))
		if not record.is_empty() and not bool(record.get("invalidated", false)):
			return record
	# A want with no belief behind it can still draw on what the actor knows.
	return _strongest_belief(state, actor_id)


func _strongest_belief(state: WorldState, actor_id: String) -> Dictionary:
	var best: Dictionary = {}
	var stored := state.get_all_knowledge(actor_id)
	var knowledge_ids: Array = stored.keys()
	knowledge_ids.sort()
	for knowledge_id_value in knowledge_ids:
		var record: Dictionary = stored[str(knowledge_id_value)]
		if bool(record.get("invalidated", false)):
			continue
		if best.is_empty() or int(record["confidence"]) > int(best["confidence"]):
			best = record
	return best


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
	if targets.size() > MAX_ACTION_TARGETS:
		targets.resize(MAX_ACTION_TARGETS)
	return targets


func _no_target_reason(action_type: String) -> String:
	match action_type:
		"support":
			return "no_support_target"
		"oppose":
			return "no_oppose_target"
		"observe":
			return "no_uncertainty"
	return "no_social_target"


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


func _outranks(candidate: Dictionary, best: Dictionary) -> bool:
	var candidate_score := int(candidate["score"])
	var best_score := int(best["score"])
	if candidate_score != best_score:
		return candidate_score > best_score
	var candidate_rank := ACTION_ORDER.find(str(candidate["action_type"]))
	var best_rank := ACTION_ORDER.find(str(best["action_type"]))
	if candidate_rank != best_rank:
		return candidate_rank < best_rank
	var candidate_target := str(candidate["target_id"])
	var best_target := str(best["target_id"])
	if candidate_target != best_target:
		return candidate_target < best_target
	return str(candidate["topic_id"]) < str(best["topic_id"])
