class_name ExecutionRules
extends RefCounted

# Mortal Action Execution v1.
#
# Three layers, three questions, and they must not merge:
#
#   Intent           -> what does this mortal want?
#   Action Selection -> what do they choose to try?
#   Execution        -> did that attempt happen, and what came of it immediately?
#   Consequences     -> what does that result change?  NOT BUILT.
#
# This file answers the third question and stops. A refused request does not
# make anyone resentful, an accepted one does not move grain, and a delivered
# warning does not change anyone's mind about anything. Those are consequences,
# and the engine that owns them does not exist yet.
#
# Execution is evaluated in two phases so that no actor gains anything from
# being earlier in the tick. Phase one reads the world as it stood when the
# year's executions began and decides every outcome; phase two applies the
# immediate effects together. Nothing in `plan` may mutate state.
#
# The effect boundary, per action:
#
#   give    -> blocked today                 -> resource transfer, once ownership exists
#   ask     -> request accepted or refused   -> obligation, standing, resentment
#   tell    -> claim delivered through the   -> what the receiver later believes
#              existing knowledge system         and wants because of it
#   support -> support expressed             -> standing, alliance, reputation
#   oppose  -> opposition expressed          -> friction, factions, retaliation
#   observe -> observation made, or nothing  -> what the observer later believes
#   wait    -> nothing attempted             -> none
#
# Only two actions apply any immediate effect at all, and both do it through the
# knowledge system rather than around it: TELL delivers a claim, OBSERVE records
# something the world genuinely made observable. Neither reads
# objective_truth_state, so a false belief travels exactly as a true one does.

const OUTCOME_SUCCESS := "success"
const OUTCOME_FAILURE := "failure"
const OUTCOME_BLOCKED := "blocked"

# A request costs the target something, so it needs real standing to be granted.
# A merely cordial relationship is not enough, which is why the King refusing
# Mara is the ordinary case rather than the surprising one.
const ASK_ACCEPTANCE_THRESHOLD := 30

# Read from the TARGET's view of the ACTOR. The King is deciding how he feels
# about Mara, not how Mara feels about him. Fear counts toward granting a
# request: someone who fears you is likelier to say yes, which is a different
# thing from wanting to.
const ASK_ACCEPTANCE_WEIGHTS := {
	"trust": 0.5,
	"respect": 0.3,
	"fear": 0.2,
	"hostility": -0.7
}

# The target's disposition, not the asker's. Whether you grant a request is
# something about you.
const ASK_TARGET_TRAIT_RULES := {
	"compassionate": 12,
	"loyal": 10,
	"gullible": 6,
	"deceitful": -4,
	"cautious": -6,
	"ambitious": -6,
	"cruel": -12
}


var knowledge_rules := KnowledgeRules.new()


# Phase one. Decides an outcome by reading the world; changes nothing. The
# returned plan carries an "effect" describing what phase two should apply.
#
# `observable` is what the world is showing this year, computed once for the
# whole tick: what can be seen is a property of the world, not of who is
# looking, and every observer this year sees the same thing or nothing.
func plan(state: WorldState, action: Dictionary, observable: Dictionary = {}) -> Dictionary:
	if action.is_empty():
		return {}
	var actor := state.get_notable_entity(str(action.get("actor_id", "")))
	if actor.is_empty():
		return {}
	var action_type := str(action.get("action_type", ""))
	var context := {
		"factors": [] as Array[Dictionary],
		"reasons": [] as Array[String],
		"effect": {}
	}
	var verdict: Dictionary
	match action_type:
		"give":
			verdict = _plan_give(state, action, context)
		"ask":
			verdict = _plan_ask(state, actor, action, context)
		"tell":
			verdict = _plan_tell(state, action, context)
		"support":
			verdict = _plan_expression(state, action, context, "support_expressed")
		"oppose":
			verdict = _plan_expression(state, action, context, "opposition_expressed")
		"observe":
			verdict = _plan_observe(action, context, observable)
		"wait":
			verdict = _plan_wait(action, context)
		_:
			verdict = {"outcome": OUTCOME_BLOCKED, "result_type": "unknown_action"}
	return _build_record(state, actor, action, verdict, context)


# Phase two. Applies the immediate effect a plan asked for, and records exactly
# what was applied. Anything not listed here did not happen.
func apply(state: WorldState, record: Dictionary) -> Dictionary:
	var effect: Dictionary = record.get("pending_effect", {})
	var applied: Array[Dictionary] = []
	match str(effect.get("type", "")):
		"deliver_knowledge":
			var delivered := state.learn_knowledge(
				str(effect["target_id"]), effect["record"]
			)
			if delivered.is_empty():
				record["outcome"] = OUTCOME_BLOCKED
				record["result_type"] = "delivery_failed"
			else:
				state.knowledge_events.append({
					"type": "claim_told",
					"year": state.year,
					"source_id": str(effect["source_id"]),
					"target_id": str(effect["target_id"]),
					"knowledge_id": str(effect["knowledge_id"]),
					"confidence": int(delivered["confidence"]),
					"distorted": bool(delivered.get("distorted", false))
				})
				applied.append({
					"type": "knowledge_delivered",
					"entity_id": str(effect["target_id"]),
					"knowledge_id": str(effect["knowledge_id"]),
					"confidence": int(delivered["confidence"])
				})
		"record_observation":
			var learned := state.learn_direct_knowledge(
				str(effect["actor_id"]), effect["record"]
			)
			if not learned.is_empty():
				applied.append({
					"type": "observation_recorded",
					"entity_id": str(effect["actor_id"]),
					"knowledge_id": str(learned["id"]),
					"confidence": int(learned["confidence"])
				})
	record["effects_applied"] = applied
	record.erase("pending_effect")
	return record


# --- per action --------------------------------------------------------------


func _plan_give(_state: WorldState, _action: Dictionary, context: Dictionary) -> Dictionary:
	# Nothing in the world models a resource a mortal controls, so a give can
	# never actually be attempted. Blocked is not failure: she did not try and
	# fall short, she had nothing to try with.
	var reasons: Array[String] = context["reasons"]
	reasons.append("there is nothing they control to hand over")
	return {"outcome": OUTCOME_BLOCKED, "result_type": "no_controlled_resource"}


func _plan_ask(
	state: WorldState,
	actor: Dictionary,
	action: Dictionary,
	context: Dictionary
) -> Dictionary:
	var actor_id := str(actor["id"])
	var target_id := str(action.get("target_id", ""))
	var target := state.get_notable_entity(target_id)
	var reasons: Array[String] = context["reasons"]
	if target.is_empty():
		reasons.append("there is no longer anyone there to ask")
		return {"outcome": OUTCOME_BLOCKED, "result_type": "target_gone"}

	# The direction that matters is the target's view of the actor. Selection
	# read the other edge, and the two are not interchangeable.
	var standing := state.get_relationship(target_id, actor_id)
	if standing.is_empty():
		reasons.append("%s has no reason to grant anything to %s" % [target_id, actor_id])
		return {"outcome": OUTCOME_FAILURE, "result_type": "no_standing_with_target"}

	var factors: Array[Dictionary] = context["factors"]
	var acceptance := 0
	for axis: String in WorldState.RELATIONSHIP_AXES:
		var axis_value := int(standing[axis])
		if axis_value == 0:
			continue
		var axis_delta := int(round(axis_value * float(ASK_ACCEPTANCE_WEIGHTS[axis])))
		if axis_delta == 0:
			continue
		acceptance += axis_delta
		factors.append({
			"source": "standing",
			"detail": "%s %d from %s toward %s" % [axis, axis_value, target_id, actor_id],
			"axis": axis,
			"value": axis_value,
			"delta": axis_delta
		})
	for trait_value in target.get("traits", []):
		var trait_id := str(trait_value)
		if not ASK_TARGET_TRAIT_RULES.has(trait_id):
			continue
		var trait_delta := int(ASK_TARGET_TRAIT_RULES[trait_id])
		acceptance += trait_delta
		factors.append({
			"source": "target_trait",
			"detail": "%s is %s" % [target_id, trait_id],
			"delta": trait_delta
		})
	context["score"] = acceptance
	reasons.append("%s weighs the request at %d against a threshold of %d" % [
		target_id, acceptance, ASK_ACCEPTANCE_THRESHOLD
	])
	if acceptance >= ASK_ACCEPTANCE_THRESHOLD:
		# Accepted, and that is all. Nothing is granted here: what an accepted
		# request obliges is a consequence, and the record is what will carry it.
		reasons.append("the request was granted, though nothing has been done yet")
		return {"outcome": OUTCOME_SUCCESS, "result_type": "request_accepted"}
	reasons.append("the request was heard and turned down")
	return {"outcome": OUTCOME_FAILURE, "result_type": "request_refused"}


func _plan_tell(state: WorldState, action: Dictionary, context: Dictionary) -> Dictionary:
	var actor_id := str(action.get("actor_id", ""))
	var target_id := str(action.get("target_id", ""))
	var knowledge_id := str(action.get("topic_id", ""))
	var reasons: Array[String] = context["reasons"]
	if state.get_notable_entity(target_id).is_empty():
		reasons.append("there is no longer anyone there to tell")
		return {"outcome": OUTCOME_BLOCKED, "result_type": "target_gone"}
	# The belief may have gone since selection. A claim nobody holds any more
	# cannot be passed on.
	var held := state.get_knowledge(actor_id, knowledge_id)
	if held.is_empty() or bool(held.get("invalidated", false)):
		reasons.append("they no longer hold the claim they meant to pass on")
		return {"outcome": OUTCOME_BLOCKED, "result_type": "missing_required_belief"}

	# Willingness was settled at selection: choosing to speak is Action
	# Selection's question, and re-asking it here would let ambient rumor rules
	# overrule a deliberate act. Transmission and acceptance still apply in full.
	var evaluation := knowledge_rules.evaluate_transfer(
		state, actor_id, target_id, knowledge_id, true
	)
	var factors: Array[Dictionary] = context["factors"]
	factors.append({
		"source": "transmission",
		"detail": "held at %d, would arrive at %d" % [
			int(evaluation["source_confidence"]), int(evaluation["received_confidence"])
		],
		"delta": 0
	})
	if bool(evaluation.get("distorted", false)):
		reasons.append("the claim would arrive distorted")

	match str(evaluation["reason"]):
		"accepted":
			pass
		"source_not_confident":
			reasons.append("they are too unsure of it now to say it")
			return {"outcome": OUTCOME_FAILURE, "result_type": "too_unsure_to_speak"}
		"target_rejected":
			reasons.append("%s heard it and did not believe it" % target_id)
			return {"outcome": OUTCOME_FAILURE, "result_type": "claim_not_believed"}
		"invalidated_knowledge":
			return {"outcome": OUTCOME_BLOCKED, "result_type": "missing_required_belief"}
		"no_relationship":
			reasons.append("there is no way to reach %s" % target_id)
			return {"outcome": OUTCOME_BLOCKED, "result_type": "no_route_to_target"}
		_:
			reasons.append("the words did not carry")
			return {"outcome": OUTCOME_FAILURE, "result_type": "claim_not_delivered"}

	var existing := state.get_knowledge(target_id, knowledge_id)
	if (
		not existing.is_empty()
		and not bool(existing.get("is_outdated", false))
		and int(existing["confidence"]) >= int(evaluation["received_confidence"])
	):
		reasons.append("%s already held it at least as firmly" % target_id)
		return {"outcome": OUTCOME_FAILURE, "result_type": "target_already_knew"}

	var received := knowledge_rules.build_received_record(
		state, actor_id, target_id, knowledge_id, evaluation
	)
	if received.is_empty():
		return {"outcome": OUTCOME_BLOCKED, "result_type": "delivery_failed"}
	context["effect"] = {
		"type": "deliver_knowledge",
		"source_id": actor_id,
		"target_id": target_id,
		"knowledge_id": knowledge_id,
		"record": received
	}
	# Delivered is not believed. Success here means the words arrived and the
	# knowledge system processed them; how firmly they landed is its business.
	reasons.append("the claim reached %s at confidence %d" % [
		target_id, int(evaluation["received_confidence"])
	])
	return {"outcome": OUTCOME_SUCCESS, "result_type": "claim_delivered"}


func _plan_expression(
	state: WorldState,
	action: Dictionary,
	context: Dictionary,
	result_type: String
) -> Dictionary:
	# Standing with someone, or against them, is the act itself. Whether it
	# changes anything is a consequence, so nothing is applied here. Opposing is
	# objecting, refusing, obstructing. There is no violence in this vocabulary
	# and none may be added without a design pass of its own.
	var target_id := str(action.get("target_id", ""))
	var reasons: Array[String] = context["reasons"]
	if state.get_notable_entity(target_id).is_empty():
		reasons.append("there is no longer anyone there")
		return {"outcome": OUTCOME_BLOCKED, "result_type": "target_gone"}
	reasons.append("it was said plainly, and nothing has come of it yet")
	return {"outcome": OUTCOME_SUCCESS, "result_type": result_type}


func _plan_observe(
	action: Dictionary,
	context: Dictionary,
	observable: Dictionary
) -> Dictionary:
	# Looking harder is not a way of reading the world's mind. The only honest
	# observation is one the world is currently making observable, through the
	# same event-perception path it already uses to teach everyone. Where the
	# world is showing nothing, watching yields nothing.
	var actor_id := str(action.get("actor_id", ""))
	var subject_id := str(action.get("target_id", ""))
	var reasons: Array[String] = context["reasons"]
	if observable.is_empty() or str(observable.get("subject_id", "")) != subject_id:
		reasons.append("there was nothing about %s to be seen this year" % _or_subject(subject_id))
		return {"outcome": OUTCOME_FAILURE, "result_type": "nothing_to_see"}
	context["effect"] = {
		"type": "record_observation",
		"actor_id": actor_id,
		"record": observable
	}
	reasons.append("they saw it for themselves: \"%s\"" % str(observable.get("claim", "")))
	return {"outcome": OUTCOME_SUCCESS, "result_type": "observation_made"}


func _plan_wait(action: Dictionary, context: Dictionary) -> Dictionary:
	# Two kinds of stillness, kept apart. One is a choice; the other is what is
	# left when there was no way to act.
	var reasons: Array[String] = context["reasons"]
	if str(action.get("selection", "")) == "fallback_no_viable_action":
		reasons.append("there was no way to act on what they wanted")
		return {"outcome": OUTCOME_SUCCESS, "result_type": "unable_to_act"}
	reasons.append("they held back on purpose")
	return {"outcome": OUTCOME_SUCCESS, "result_type": "deliberately_waited"}


# --- record ------------------------------------------------------------------


func _build_record(
	state: WorldState,
	actor: Dictionary,
	action: Dictionary,
	verdict: Dictionary,
	context: Dictionary
) -> Dictionary:
	var actor_id := str(actor["id"])
	return {
		"id": "execution_%04d_%s_%s" % [state.year, actor_id, str(action.get("action_type", ""))],
		"year": state.year,
		"actor_id": actor_id,
		"actor_name": str(actor.get("name", actor_id)),
		# The chain this result belongs to. Execution never edits either record.
		"intent_id": str(action.get("intent_id", "")),
		"action_id": str(action.get("id", "")),
		"action_type": str(action.get("action_type", "")),
		"target_id": str(action.get("target_id", "")),
		"target_kind": str(action.get("target_kind", "")),
		"subject_id": str(action.get("subject_id", "")),
		"topic_id": str(action.get("topic_id", "")),
		"resource_type": str(action.get("resource_type", "")),
		"outcome": str(verdict["outcome"]),
		"result_type": str(verdict["result_type"]),
		"score": int(context.get("score", 0)),
		"factors": context["factors"],
		"reasons": context["reasons"],
		# Filled by apply(). Anything not listed here did not happen.
		"effects_applied": [] as Array[Dictionary],
		"pending_effect": context["effect"]
	}


func _or_subject(subject_id: String) -> String:
	return "it" if subject_id.is_empty() else subject_id
