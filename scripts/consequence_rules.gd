class_name ConsequenceRules
extends RefCounted

# Consequence Engine v1.
#
# One question only:
#
#   What objectively changed because this happened?
#
# Not what it meant. Not how anybody felt about it. A refusal is a refusal; it
# is not a betrayal until somebody decides it was, and deciding that is the
# interpretation layer's job, not this one's.
#
# **This file must never become a table of scripted emotional reactions.** No
# trust delta, no hostility delta, no faith delta, no reputation delta. If a
# consequence seems to need one, the reaction belongs downstream:
#
#   King refuses Mara
#     -> objectively: a refusal occurred, privately, between two people
#     -> Mara perceives it
#     -> Mara interprets it        (betrayal? caution? necessity?)
#     -> her beliefs and future wants may change
#
# The route back into the simulation is deliberately indirect. A consequence
# emits an EVENT, perception decides who noticed, and knowledge stores what they
# took from it. That is what keeps a private refusal private, lets it spread
# later by rumor if it spreads at all, and stops any of this becoming an
# automatic cascade from a slight to a war.
#
# Mortal and divine acts enter here through the same door. A god who causes rain
# produces "rain fell on Westfield" — a thing that happened, with no motive
# attached. Whether that reads as mercy, weather or favouritism is for mortals
# to work out.

const TYPE_STATE_CHANGE := "state_change"
const TYPE_SOCIAL := "social_occurrence"
const TYPE_INFORMATION := "information_occurrence"
const TYPE_NO_EFFECT := "no_effect"

const SOURCE_EXECUTION := "execution"
const SOURCE_DIVINE := "divine_action"

# What objectively occurred, per execution result. Everything absent from this
# table is a no-effect: an attempt that was blocked, fell short, or was never
# going to move anything.
#
# Claims describe the occurrence and stop there. "%s refused %s's request" is
# something that happened. "%s abandoned %s" would be a judgement, and no claim
# in this table may read like one.
const EXECUTION_CONSEQUENCES := {
	"request_accepted": {
		"consequence_type": TYPE_SOCIAL,
		"topic": "request_accepted",
		"claim": "%s agreed to %s's request",
		"subject_claim": "%s agreed to %s's request concerning %s",
		"perspective": "target_first",
		"observability": "direct",
		"confidence": 95
	},
	"request_refused": {
		"consequence_type": TYPE_SOCIAL,
		"topic": "request_refused",
		"claim": "%s refused %s's request",
		"subject_claim": "%s refused %s's request concerning %s",
		"perspective": "target_first",
		"observability": "direct",
		"confidence": 95
	},
	"support_expressed": {
		"consequence_type": TYPE_SOCIAL,
		"topic": "support_given",
		"claim": "%s stood with %s",
		"subject_claim": "%s stood with %s over %s",
		"perspective": "actor_first",
		"observability": "direct",
		"confidence": 95
	},
	"opposition_expressed": {
		"consequence_type": TYPE_SOCIAL,
		"topic": "opposition_given",
		"claim": "%s stood against %s",
		"subject_claim": "%s stood against %s over %s",
		"perspective": "actor_first",
		"observability": "direct",
		"confidence": 95
	}
}

# TELL and OBSERVE already moved knowledge while they executed. Naming them here
# would mean a second route to the same fact, so they are deliberately absent
# and resolve to a no-effect: the effect happened, and it happened once.
const ALREADY_APPLIED := ["claim_delivered", "observation_made"]


# What objectively came of one execution. Reads the world and changes nothing,
# so every execution in a year can be judged against the same snapshot before
# any of them takes effect.
func plan_execution(state: WorldState, execution: Dictionary) -> Dictionary:
	if execution.is_empty():
		return {}
	var result_type := str(execution.get("result_type", ""))
	var record := _new_record(state, SOURCE_EXECUTION, str(execution.get("id", "")), {
		"actor_id": str(execution.get("actor_id", "")),
		"target_id": str(execution.get("target_id", "")),
		"subject_id": str(execution.get("subject_id", "")),
		"result_type": result_type
	})
	var reasons: Array[String] = record["reasons"]

	if result_type in ALREADY_APPLIED:
		record["consequence_type"] = TYPE_NO_EFFECT
		reasons.append("the effect happened while it was carried out, and happened once")
		return record
	var template: Dictionary = EXECUTION_CONSEQUENCES.get(result_type, {})
	if template.is_empty():
		record["consequence_type"] = TYPE_NO_EFFECT
		reasons.append("nothing in the world moved because of this")
		return record

	record["consequence_type"] = str(template["consequence_type"])
	record["pending_fact"] = _social_fact(state, execution, template)
	reasons.append("it happened, between the two of them and nobody else")
	return record


# The objective side of a divine act. What it changed is already in the world by
# the time this runs; this records that it happened and gives mortals something
# to notice.
# The contract between a divine act and this layer. The caller supplies what
# objectively changed and, if the act left anything anyone could see, the
# occurrence template describing it — both from `divine_action_rules.gd`, which
# is where a power is registered.
#
# This layer answers ONE question, the same one it answers for a mortal act:
# what objectively changed or occurred? It is not told, and must never be told,
# whether mortals liked it, whether they will think a god caused it, whether
# faith should rise, or whether it was mercy or punishment. Those are questions
# for a mortal, several layers downstream.
func plan_divine(
	state: WorldState,
	action_id: String,
	location_id: String,
	state_changes: Array,
	occurrence: Dictionary = {}
) -> Dictionary:
	var template: Dictionary = occurrence
	var record := _new_record(state, SOURCE_DIVINE, action_id, {
		"actor_id": "",
		"target_id": "",
		"subject_id": location_id,
		"result_type": action_id
	})
	var reasons: Array[String] = record["reasons"]
	for change_value in state_changes:
		record["state_changes"].append(change_value)
	if template.is_empty():
		# The act left nothing to notice. It may still have changed the world;
		# what it did not do is give anybody something to point at.
		record["consequence_type"] = TYPE_STATE_CHANGE if not state_changes.is_empty() else TYPE_NO_EFFECT
		reasons.append("nothing happened that anyone there could see")
		return record
	record["consequence_type"] = TYPE_STATE_CHANGE if not state_changes.is_empty() else TYPE_SOCIAL
	record["pending_fact"] = {
		"id": "%s_%04d_%s" % [location_id, state.year, str(template["topic"])],
		"event_id": action_id,
		"subject_id": location_id,
		"topic": str(template["topic"]),
		"claim": str(template["claim"]) % state.location_name(location_id),
		"confidence": int(template["confidence"]),
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": WorldState.DEFAULT_KNOWLEDGE_FRESH_YEARS,
		"observability": str(template["observability"]),
		"participants": []
	}
	# What happened, never why. A mortal who sees rain has seen rain.
	reasons.append("something happened that anyone there could see")
	return record


# Turns a planned consequence into what it leaves behind: an event for perception
# to hand out, and nothing else. No relationship moves here, and none may.
func apply(state: WorldState, record: Dictionary) -> Dictionary:
	var fact: Dictionary = record.get("pending_fact", {})
	if not fact.is_empty():
		state.pending_perception_facts.append(fact)
		record["events_created"].append(str(fact["id"]))
		# Keep what this occurrence STATED, so the record can describe itself
		# after the fact has been handed to perception. The claim is objective by
		# construction — this layer is forbidden from writing a judgement — and
		# retaining it is not a second route to the fact: `pending_fact` is still
		# erased, so nobody can learn it from here.
		record["claim"] = str(fact["claim"])
	record.erase("pending_fact")
	return record


func _new_record(
	state: WorldState,
	source_type: String,
	source_id: String,
	fields: Dictionary
) -> Dictionary:
	return {
		# Named for who it happened to and what happened, not for the record it
		# came from — that is what source_id is for.
		"id": "consequence_%04d_%s_%s" % [
			state.year,
			str(fields["actor_id"]) if not str(fields["actor_id"]).is_empty() else source_id,
			str(fields["result_type"])
		],
		"year": state.year,
		"source_type": source_type,
		"source_id": source_id,
		"actor_id": str(fields["actor_id"]),
		"target_id": str(fields["target_id"]),
		"subject_id": str(fields["subject_id"]),
		"consequence_type": TYPE_NO_EFFECT,
		"result_type": str(fields["result_type"]),
		# Objective changes only, with what the value was and what it became.
		"state_changes": [] as Array[Dictionary],
		"events_created": [] as Array[String],
		"reasons": [] as Array[String],
		"claim": "",
		"pending_fact": {}
	}


func _social_fact(
	state: WorldState,
	execution: Dictionary,
	template: Dictionary
) -> Dictionary:
	var actor_id := str(execution.get("actor_id", ""))
	var target_id := str(execution.get("target_id", ""))
	var subject_id := str(execution.get("subject_id", ""))
	var actor_name := _label_for(state, actor_id)
	var target_name := _label_for(state, target_id)
	var first := target_name if str(template["perspective"]) == "target_first" else actor_name
	var second := actor_name if str(template["perspective"]) == "target_first" else target_name
	# WORDING ONLY. The subject clause exists to say what the exchange was
	# ABOUT, which is worth saying when it was about somebody else — "Mara
	# refused the King's request concerning Renald". When the intent's subject
	# happens to BE one of the two people already named, the clause names them a
	# third time and the sentence collapses into "The King refused Mara's
	# request concerning The King".
	#
	# The occurrence is unchanged: `subject_id` is still recorded exactly as
	# selection chose it, and every other field is untouched. This picks which
	# of the two claim templates already in the table reads correctly.
	var claim := ""
	var subject_is_a_participant := subject_id == actor_id or subject_id == target_id
	if subject_id.is_empty() or subject_is_a_participant:
		claim = str(template["claim"]) % [first, second]
	else:
		claim = str(template["subject_claim"]) % [first, second, _label_for(state, subject_id)]
	return {
		# Stable and distinct: one occurrence, between these two, this year.
		"id": "%s_%04d_%s_%s" % [str(template["topic"]), state.year, actor_id, target_id],
		"event_id": str(execution.get("result_type", "")),
		"subject_id": subject_id,
		"topic": str(template["topic"]),
		"claim": claim,
		"confidence": int(template["confidence"]),
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": WorldState.DEFAULT_KNOWLEDGE_FRESH_YEARS,
		# Private by default. Nobody who was not part of it learns it for free,
		# and there is no visibility model that would honestly say otherwise.
		"observability": str(template["observability"]),
		"participants": [actor_id, target_id]
	}


func _label_for(state: WorldState, entity_id: String) -> String:
	if entity_id.is_empty():
		return "someone"
	var entity := state.get_notable_entity(entity_id)
	if not entity.is_empty():
		return str(entity.get("name", entity_id))
	if state.locations.has(entity_id):
		return state.location_name(entity_id)
	return entity_id
