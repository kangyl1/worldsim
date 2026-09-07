class_name InterpretationRules
extends RefCounted

# Interpretation v1 — what a mortal decided an occurrence MEANT.
#
# The layer that was missing. Consequences say what objectively happened,
# perception says who could notice, knowledge says what they now hold, and
# nothing until now asked what any of it meant to them.
#
# The boundary this exists to protect:
#
#   Consequence      what happened
#   Perception       who could notice
#   Knowledge        what they believe happened
#   Interpretation   what they think it meant      <- here
#   Relationship     the downstream result of that meaning
#
# A refusal does not lower trust. A refusal is an occurrence; a mortal decides
# it means the other party is unwilling to help; THAT is what lowers trust, and
# only for the mortal who reached it. Someone else holding the same fact may
# decide it meant something else, or nothing worth changing their mind over.
# `scripts/consequence_rules.gd` must never grow a `request_refused -> trust -10`
# table, because that would be this layer's job done in the wrong place.
#
# Everything here reads the OBSERVER'S OWN knowledge record and their existing
# state. It never reads `objective_truth_state`, never consults the consequence
# archive, and never learns anything the mortal was not told. A false or
# distorted belief therefore produces a sincere interpretation of something that
# did not happen, which is correct: the engine knowing better must not quietly
# correct them.

# The social occurrences v1 understands. These are the topics
# `consequence_rules.gd` already emits; no new occurrence is invented here.
const SOCIAL_TOPICS := [
	"request_accepted", "request_refused", "support_given", "opposition_given"
]

# Occurrences with no second mortal in them. Rain does not happen BETWEEN two
# people, so there is no role to take and no relationship for the conclusion to
# land on — what changes is what the observer now thinks the world is like.
#
# The engine knows the god sent it. The mortal does not, and nothing here may
# tell them: "it rained" is the fact, and "someone sent it" is one of several
# things a person might make of that. Being wrong is allowed and expected.
#
# The list is not written here. `divine_action_rules.gd` registers the powers,
# and a topic becomes a world topic the moment an act can be seen — which is not
# the same as its meaning having been designed. A registered topic with no
# entry in WORLD_CANDIDATES is held as a fact and left uninterpreted, because
# reaching for `unclear_what_happened` there would be inventing a conclusion to
# fill a gap in the design rather than because a mortal was actually unsure.
var divine_action_rules := DivineActionRules.new()

# Where the observer stood in relation to a world occurrence. Not a role in the
# social sense — nobody did this to anybody — but it still matters enormously
# whether you watched your own wells fill or heard about it later.
const STANCE_WITNESS := "witness"
const STANCE_DISTANT := "distant"

# Where the observer stood in the occurrence. Roles come from the claim itself:
# the participants list names two people, and which one the observer is decides
# what the occurrence was like to live through.
const ROLE_ACTOR := "actor"
const ROLE_TARGET := "target"
const ROLE_BYSTANDER := "bystander"

# For an ASK the actor is the one who asked and the target is the one who
# answered; for SUPPORT and OPPOSITION the actor is the one who spoke and the
# target is the one it was about. `consequence_rules.gd` builds the claim from
# the same two ids, so these stay in step by construction.

# Below the floor a mortal does not trust the report enough to draw a conclusion
# from it. Rumor distortion is what usually puts them here.
const UNCERTAIN_CONFIDENCE := 40

# The bounded-ripple rule in numbers. One interpretation moves ONE axis by at
# most this much, and a mortal reaches one conclusion per occurrence. Roughly
# ten similar occurrences to cross a relationship band, which keeps a single
# refusal from becoming a feud (GDD section 35).
const MAX_EFFECT_MAGNITUDE := 3

# What a mortal can conclude, per occurrence and per role.
#
# Several candidates may fit; the one with the highest score wins, and the score
# is built from the observer's own state. That is what makes the same fact mean
# different things to different people: Mara, who already trusts the King, and
# Mara, who already does not, are not looking at the same refusal.
#
# `effect` is the observer's relationship TOWARD the other party. An empty
# effect is a real and common answer — plenty of things are noted and change
# nothing.
const CANDIDATES := {
	"request_refused": {
		ROLE_ACTOR: [
			{
				"id": "refusal_confirms_distrust",
				"meaning": "%s would not help, which is what I already expected of them.",
				"effect": {"axis": "trust", "amount": -3},
				"base_score": 30,
				"factors": [
					{"kind": "trust_below", "value": 35, "score": 25},
					{"kind": "hostility_at_least", "value": 20, "score": 10}
				]
			},
			{
				"id": "refusal_unwilling_to_help",
				"meaning": "%s is unwilling to help.",
				"effect": {"axis": "trust", "amount": -2},
				"base_score": 50,
				"factors": [
					{"kind": "trait", "value": "compassionate", "score": 8}
				]
			},
			{
				"id": "refusal_had_their_reasons",
				"meaning": "%s must have had reasons I do not know.",
				"effect": {},
				"base_score": 30,
				"factors": [
					{"kind": "trust_at_least", "value": 60, "score": 25},
					{"kind": "trait", "value": "cautious", "score": 10},
					{"kind": "trait", "value": "loyal", "score": 8}
				]
			}
		],
		ROLE_TARGET: [
			{
				"id": "refusal_being_pressured",
				"meaning": "%s is pressing me over something I have already answered.",
				"effect": {"axis": "hostility", "amount": 1},
				"base_score": 40,
				"factors": [
					{"kind": "trait", "value": "ambitious", "score": 15},
					{"kind": "hostility_at_least", "value": 20, "score": 10}
				]
			},
			{
				"id": "refusal_gave_the_only_answer",
				"meaning": "I gave %s the answer the situation allowed.",
				"effect": {},
				"base_score": 45,
				"factors": [
					{"kind": "trust_at_least", "value": 50, "score": 10}
				]
			}
		],
		ROLE_BYSTANDER: [
			{
				"id": "bystander_dispute_noted",
				"meaning": "Things between %s and %s are not going well.",
				"effect": {},
				"base_score": 40,
				"factors": []
			}
		]
	},
	"request_accepted": {
		ROLE_ACTOR: [
			{
				"id": "acceptance_confirms_trust",
				"meaning": "%s stands by me, as I believed they would.",
				"effect": {"axis": "trust", "amount": 3},
				"base_score": 30,
				"factors": [
					{"kind": "trust_at_least", "value": 60, "score": 25}
				]
			},
			{
				"id": "acceptance_willing_to_help",
				"meaning": "%s was willing to help.",
				"effect": {"axis": "trust", "amount": 2},
				"base_score": 50,
				"factors": []
			}
		],
		ROLE_TARGET: [
			{
				"id": "acceptance_took_on_a_burden",
				"meaning": "I have taken on what %s asked of me.",
				"effect": {},
				"base_score": 45,
				"factors": []
			}
		],
		ROLE_BYSTANDER: [
			{
				"id": "bystander_accord_noted",
				"meaning": "%s and %s are working together.",
				"effect": {},
				"base_score": 40,
				"factors": []
			}
		]
	},
	"support_given": {
		ROLE_TARGET: [
			{
				"id": "support_stood_with_me",
				"meaning": "%s stood with me when it counted.",
				"effect": {"axis": "trust", "amount": 2},
				"base_score": 50,
				"factors": [
					{"kind": "trait", "value": "loyal", "score": 8}
				]
			}
		],
		ROLE_ACTOR: [
			{
				"id": "support_tied_myself_to_them",
				"meaning": "I have tied myself to %s by saying so aloud.",
				"effect": {},
				"base_score": 45,
				"factors": []
			}
		],
		ROLE_BYSTANDER: [
			{
				"id": "bystander_accord_noted",
				"meaning": "%s and %s are working together.",
				"effect": {},
				"base_score": 40,
				"factors": []
			}
		]
	},
	"opposition_given": {
		ROLE_TARGET: [
			{
				"id": "opposition_from_a_rival",
				"meaning": "%s opposes me, as rivals do.",
				"effect": {"axis": "hostility", "amount": 3},
				"base_score": 30,
				"factors": [
					{"kind": "hostility_at_least", "value": 25, "score": 25}
				]
			},
			{
				"id": "opposition_stood_against_me",
				"meaning": "%s stood against me.",
				"effect": {"axis": "hostility", "amount": 2},
				"base_score": 50,
				"factors": []
			}
		],
		ROLE_ACTOR: [
			{
				"id": "opposition_said_what_i_had_to",
				"meaning": "I said what I could not leave unsaid about %s.",
				"effect": {},
				"base_score": 45,
				"factors": []
			}
		],
		ROLE_BYSTANDER: [
			{
				"id": "bystander_dispute_noted",
				"meaning": "Things between %s and %s are not going well.",
				"effect": {},
				"base_score": 40,
				"factors": []
			}
		]
	}
}

# What a mortal can make of something that happened to the WORLD rather than
# between people. Keyed by topic, then by whether they saw it themselves.
#
# Deliberately four readings and no theology. "Something beyond us acted" is a
# conclusion ONE person reached. It is stored, and nothing else happens to it:
# it founds no shared creed, writes no settled teaching, and raises nobody up.
# Whether such conclusions ever add up to a faith is a later system's question,
# and that system must be able to answer NO.
#
# The naturalistic reading is not a wrong answer the simulation tolerates: for
# a mortal with no history of divine events it is the SENSIBLE one, and it wins
# on score. The god must be able to act and go unnoticed as a cause.
const WORLD_CANDIDATES := {
	"weather_rain": {
		STANCE_WITNESS: [
			{
				"id": "rain_natural_weather",
				"meaning": "The rain came as rain does.",
				"effect": {},
				"base_score": 50,
				"factors": [
					{"kind": "trait", "value": "cautious", "score": 12},
					{"kind": "no_prior_divine_reading", "value": true, "score": 14},
					# Rain that arrived when nothing was wrong is unremarkable,
					# and this is what keeps a believer able to say so. Without
					# it, someone who had once read a rain as help read EVERY
					# later rain as help, which is the theology lock-in this
					# design refuses: belief must bias a reading, never settle it.
					{"kind": "home_was_not_in_crisis", "value": true, "score": 18}
				]
			},
			{
				"id": "rain_divine_help",
				"meaning": "Something beyond us answered when the wells were dry.",
				"effect": {},
				"base_score": 34,
				"factors": [
					{"kind": "trait", "value": "compassionate", "score": 10},
					{"kind": "trait", "value": "gullible", "score": 16},
					# Reduced from 20 now that belief exists. Having concluded
					# this once and having come to ACCEPT it are the same
					# evidence in two forms, and at full strength they stacked
					# into a lock: once a mortal had read one rain as help, no
					# amount of ordinary weather could read as ordinary again.
					# The durable form carries the weight now.
					#
					# `home_was_helped` is gone from this candidate entirely.
					# Rain falling where you live is not evidence that anything
					# answered you; rain falling where you live WHILE YOUR WELLS
					# WERE DRY is, and that is the factor below.
					{"kind": "prior_divine_reading", "value": true, "score": 8},
					# The circumstance, not the cause. Rain that arrives while
					# your own wells are dry is the oldest reason people have
					# ever had for thinking something answered them, and it is
					# entirely mortal-visible: they lived through the shortage.
					#
					# This factor is what lets the FIRST divine reading happen.
					# Without it every rain candidate lost to plain weather for
					# every mortal in the seeded world, so a divine belief could
					# never begin: `prior_divine_reading` needed a prior divine
					# reading, and nothing could produce the first one.
					#
					# Deliberately worth 12 and not more. It is enough for a
					# compassionate mortal to reach 70 against weather's 64, and
					# not enough for an incurious one, who stays at 60 and calls
					# it weather. Two people, same rain, same crisis, different
					# conclusions — and no divine reading at all unless the
					# timing was genuinely remarkable.
					{"kind": "home_was_in_crisis", "value": true, "score": 22},
					# What they already accept about the world. Bias, never a
					# lock: an established belief adds 12, which moves the
					# argument without settling it, and someone who believes
					# this can still look at ordinary rain and call it ordinary.
					{
						"kind": "belief_at_least",
						"value": {
							"proposition": BeliefRules.DIVINE_HELP_FOLLOWS_NEED,
							"confidence": BeliefRules.ESTABLISHED_CONFIDENCE
						},
						"score": 12
					}
				]
			},
			{
				"id": "rain_divine_favour",
				"meaning": "%s is being favoured over the rest of us.",
				"effect": {},
				"base_score": 30,
				"factors": [
					{"kind": "trait", "value": "ambitious", "score": 16},
					{"kind": "elsewhere", "value": true, "score": 18},
					{"kind": "prior_divine_reading", "value": true, "score": 10},
					{
						"kind": "belief_at_least",
						"value": {
							"proposition": BeliefRules.DIVINE_INTERVENTION_EXISTS,
							"confidence": BeliefRules.ESTABLISHED_CONFIDENCE
						},
						"score": 10
					}
				]
			}
		],
		STANCE_DISTANT: [
			{
				"id": "rain_natural_weather",
				"meaning": "Rain fell somewhere else, as rain does.",
				"effect": {},
				"base_score": 50,
				"factors": [
					{"kind": "trait", "value": "cautious", "score": 12},
					{"kind": "no_prior_divine_reading", "value": true, "score": 10}
				]
			},
			{
				"id": "rain_divine_favour",
				"meaning": "%s is being favoured over the rest of us.",
				"effect": {},
				"base_score": 36,
				"factors": [
					{"kind": "trait", "value": "ambitious", "score": 18},
					{"kind": "prior_divine_reading", "value": true, "score": 14}
				]
			}
		]
	}
}

# Available whatever the occurrence and whatever the role. It only wins when the
# mortal's confidence in the underlying report is genuinely poor, which is how a
# distorted rumor stops short of moving a relationship.
const UNCERTAIN_CANDIDATE := {
	"id": "unclear_what_happened",
	"meaning": "I am not sure what really passed between %s and %s.",
	"effect": {},
	"base_score": 0,
	"factors": [
		{"kind": "confidence_below", "value": UNCERTAIN_CONFIDENCE, "score": 60}
	]
}


func is_social_topic(topic: String) -> bool:
	return topic in SOCIAL_TOPICS


func is_world_topic(topic: String) -> bool:
	return topic in divine_action_rules.occurrence_topics()


# Whether anybody has yet decided what this KIND of occurrence could mean. A
# power can enter the pipeline before its meanings are designed; until they are,
# mortals hold the fact and draw nothing from it.
func has_candidates(topic: String) -> bool:
	if is_social_topic(topic):
		return CANDIDATES.has(topic)
	return WORLD_CANDIDATES.has(topic)


func is_interpretable(topic: String) -> bool:
	return (is_social_topic(topic) or is_world_topic(topic)) and has_candidates(topic)


func pending_for(state: WorldState, observer_id: String) -> Array[Dictionary]:
	# Everything this mortal currently believes about a social occurrence and
	# has not yet drawn a conclusion from.
	#
	# Deliberately not gated on the year it arrived. A fact reaching someone by
	# rumor three years later is still new TO THEM, and they interpret it when
	# they get it. `has_interpretation()` is what stops a still-held belief being
	# re-interpreted every year.
	var pending: Array[Dictionary] = []
	var held := state.get_all_knowledge(observer_id)
	var knowledge_ids: Array = held.keys()
	knowledge_ids.sort()
	for knowledge_id_value in knowledge_ids:
		var knowledge_id := str(knowledge_id_value)
		var record: Dictionary = held[knowledge_id]
		if not is_interpretable(str(record.get("topic", ""))):
			continue
		if bool(record.get("invalidated", false)):
			continue
		if state.has_interpretation(observer_id, knowledge_id):
			continue
		pending.append(record)
	return pending


func role_of(observer_id: String, knowledge: Dictionary) -> String:
	var participants: Array = knowledge.get("participants", [])
	if participants.size() < 2:
		return ROLE_BYSTANDER
	if observer_id == str(participants[0]):
		return ROLE_ACTOR
	if observer_id == str(participants[1]):
		return ROLE_TARGET
	return ROLE_BYSTANDER


func other_party(observer_id: String, knowledge: Dictionary) -> String:
	# Who the interpretation is ABOUT, from this observer's side. A bystander has
	# no single other party, which is exactly why they change no relationship.
	var participants: Array = knowledge.get("participants", [])
	if participants.size() < 2:
		return ""
	var actor_id := str(participants[0])
	var target_id := str(participants[1])
	if observer_id == actor_id:
		return target_id
	if observer_id == target_id:
		return actor_id
	return ""


func stance_of(state: WorldState, observer_id: String, knowledge: Dictionary) -> String:
	# Did they stand in it, or hear about it? For a world occurrence the honest
	# divider is whether the place it happened is the place they live.
	var subject_id := str(knowledge.get("subject_id", ""))
	if subject_id.is_empty():
		return STANCE_DISTANT
	return STANCE_WITNESS if state.get_home_location(observer_id) == subject_id else STANCE_DISTANT


func interpret(state: WorldState, observer_id: String, knowledge: Dictionary) -> Dictionary:
	# One mortal, one occurrence they already know about, one conclusion.
	var topic := str(knowledge.get("topic", ""))
	if not is_interpretable(topic):
		return {}
	var observer := state.get_notable_entity(observer_id)
	if observer.is_empty():
		return {}
	# A world occurrence has no second party, so the axis is where they were
	# standing rather than what they did to whom.
	var world := is_world_topic(topic)
	var role := stance_of(state, observer_id, knowledge) if world else role_of(observer_id, knowledge)
	var by_role: Dictionary = (WORLD_CANDIDATES if world else CANDIDATES).get(topic, {})
	var defined: Array = by_role.get(role, [])
	var options: Array[Dictionary] = []
	options.append_array(defined)
	options.append(UNCERTAIN_CANDIDATE)
	if options.is_empty():
		return {}

	var context := _context(state, observer_id, observer, knowledge, role)
	var scored: Array[Dictionary] = []
	for candidate: Dictionary in options:
		scored.append(_score(candidate, context))

	# Deterministic argmax, ties broken by declaration order: the first
	# candidate written for a role is the plainer reading, so a tie resolves
	# toward the ordinary conclusion rather than the dramatic one. No dice.
	var best: Dictionary = scored[0]
	for index in range(1, scored.size()):
		if int(scored[index]["score"]) > int(best["score"]):
			best = scored[index]

	return _build_record(state, observer_id, knowledge, role, context, best, scored)


func _context(
	state: WorldState,
	observer_id: String,
	observer: Dictionary,
	knowledge: Dictionary,
	role: String
) -> Dictionary:
	# Everything scoring is allowed to see: this mortal's own belief, and this
	# mortal's own state. Nothing about the world they were not told.
	var other_id := other_party(observer_id, knowledge)
	var relationship := state.get_relationship(observer_id, other_id) if not other_id.is_empty() else {}
	# Has this mortal already decided, at some point, that something beyond the
	# world acted in it? Their OWN past conclusions, never the engine's record of
	# what the god actually did. Someone who has read a divine hand into events
	# before reads one in more readily; someone who never has does not start now.
	var prior_divine := false
	for past: Dictionary in state.get_interpretations_for(observer_id):
		if str(past["interpretation_type"]).begins_with("rain_divine"):
			prior_divine = true
			break
	var subject_id := str(knowledge.get("subject_id", ""))
	var observer_home := state.get_home_location(observer_id)
	# What they already accept. Only their OWN beliefs, and only the propositions
	# a candidate actually asks about.
	var belief_confidence := {}
	for proposition: String in BeliefRules.PROPOSITIONS:
		belief_confidence[proposition] = int(
			state.get_belief(observer_id, proposition, "").get("confidence", 0)
		)
	return {
		"prior_divine_reading": prior_divine,
		# Their own home as they last lived it, before the god's turn. -1 means
		# the world has not turned yet and they have no such memory of it.
		"home_was_in_crisis": not observer_home.is_empty()
			and state.condition_before_turn(observer_home, "food") == 0,
		"belief_confidence": belief_confidence,
		"subject_id": subject_id,
		"home_was_subject": not subject_id.is_empty() and state.get_home_location(observer_id) == subject_id,
		"observer_id": observer_id,
		"other_id": other_id,
		"role": role,
		"traits": (observer.get("traits", []) as Array).duplicate(),
		"confidence": int(knowledge.get("confidence", 0)),
		# Whether they were there. Being told a thing is not the same as living
		# it, and the record keeps the two apart.
		"participated": str(knowledge.get("source_type", "")) == "direct",
		"observer_home": state.get_home_location(observer_id),
		"has_relationship": not relationship.is_empty(),
		"trust": int(relationship.get("trust", 0)) if not relationship.is_empty() else 0,
		"hostility": int(relationship.get("hostility", 0)) if not relationship.is_empty() else 0
	}


func _score(candidate: Dictionary, context: Dictionary) -> Dictionary:
	# Explicit, inspectable, and deterministic. Every point of the final score
	# names where it came from, so Developer Mode can answer "why did Mara read
	# it that way" without guessing.
	var score := int(candidate["base_score"])
	var applied: Array[Dictionary] = []
	for factor: Dictionary in candidate["factors"]:
		if not _factor_holds(factor, context):
			continue
		score += int(factor["score"])
		applied.append({
			"kind": str(factor["kind"]),
			"value": factor["value"],
			"score": int(factor["score"])
		})
	return {
		"id": str(candidate["id"]),
		"meaning": str(candidate["meaning"]),
		"effect": (candidate["effect"] as Dictionary).duplicate(true),
		"base_score": int(candidate["base_score"]),
		"score": score,
		"factors": applied
	}


func _factor_holds(factor: Dictionary, context: Dictionary) -> bool:
	match str(factor["kind"]):
		"trait":
			return str(factor["value"]) in (context["traits"] as Array)
		"trust_at_least":
			return bool(context["has_relationship"]) and int(context["trust"]) >= int(factor["value"])
		"trust_below":
			return bool(context["has_relationship"]) and int(context["trust"]) < int(factor["value"])
		"hostility_at_least":
			return bool(context["has_relationship"]) and int(context["hostility"]) >= int(factor["value"])
		"confidence_below":
			return int(context["confidence"]) < int(factor["value"])
		"prior_divine_reading":
			return bool(context["prior_divine_reading"])
		"no_prior_divine_reading":
			return not bool(context["prior_divine_reading"])
		"home_was_helped":
			return bool(context["home_was_subject"])
		"home_was_not_in_crisis":
			return not bool(context["home_was_in_crisis"])
		"home_was_in_crisis":
			# Did they live through the shortage this occurrence answered? Their
			# OWN settlement's condition when the year began — directly-lived
			# context, the same thing intent scoring is already allowed to read,
			# and read from the year's start because the occurrence has since
			# relieved it.
			return bool(context["home_was_in_crisis"])
		"belief_at_least":
			# What this mortal already accepts, at or above a stated confidence.
			# Their own belief record and nothing else.
			var requirement: Dictionary = factor["value"]
			return int(context["belief_confidence"].get(
				str(requirement["proposition"]), 0
			)) >= int(requirement["confidence"])
		"elsewhere":
			return not bool(context["home_was_subject"])
		"participated":
			return bool(context["participated"])
	return false


func _build_record(
	state: WorldState,
	observer_id: String,
	knowledge: Dictionary,
	role: String,
	context: Dictionary,
	chosen: Dictionary,
	scored: Array[Dictionary]
) -> Dictionary:
	var knowledge_id := str(knowledge["id"])
	var other_id := str(context["other_id"])
	var participants: Array = knowledge.get("participants", [])
	var actor_id := str(participants[0]) if participants.size() > 0 else ""
	var target_id := str(participants[1]) if participants.size() > 1 else ""
	var considered: Array[Dictionary] = []
	for option: Dictionary in scored:
		considered.append({
			"id": option["id"],
			"score": option["score"],
			"chosen": option["id"] == chosen["id"]
		})
	var effect: Dictionary = chosen["effect"]
	var planned: Dictionary = {}
	if not effect.is_empty() and not other_id.is_empty():
		planned = {
			"target_id": other_id,
			"axis": str(effect["axis"]),
			# Clamped here rather than trusted from the table, so no future
			# candidate can quietly exceed the bounded-ripple limit.
			"amount": clampi(
				int(effect["amount"]), -MAX_EFFECT_MAGNITUDE, MAX_EFFECT_MAGNITUDE
			)
		}
	return {
		"id": state.interpretation_id(observer_id, knowledge_id),
		"year": state.year,
		"observer_id": observer_id,
		# The belief this was drawn from. The fact itself is untouched and stays
		# exactly where it was learned.
		"source_knowledge_id": knowledge_id,
		"topic": str(knowledge.get("topic", "")),
		"subject_id": str(knowledge.get("subject_id", "")),
		"actor_id": actor_id,
		"target_id": target_id,
		"role": role,
		"interpretation_type": str(chosen["id"]),
		"meaning": _meaning_text(state, chosen, context, actor_id, target_id),
		# How firmly it is held: no interpretation is surer than the report it
		# came from, and hearsay is held a little less firmly than being there.
		"confidence": _confidence(context),
		"score": int(chosen["score"]),
		"factors": chosen["factors"],
		"considered": considered,
		"planned_effect": planned,
		"applied_effect": {},
		"effect_reason": ""
	}


func _meaning_text(
	state: WorldState,
	chosen: Dictionary,
	context: Dictionary,
	actor_id: String,
	target_id: String
) -> String:
	var template := str(chosen["meaning"])
	var slots := template.count("%s")
	if slots == 0:
		return template
	if slots == 1:
		# A social reading names the other person; a world reading names the
		# place it happened, because there is no other person in it.
		var subject := str(context["other_id"])
		if subject.is_empty():
			subject = str(context["subject_id"])
		if subject.is_empty():
			subject = actor_id
		return template % _label_for(state, subject)
	return template % [_label_for(state, actor_id), _label_for(state, target_id)]


func _confidence(context: Dictionary) -> int:
	var confidence := int(context["confidence"])
	if not bool(context["participated"]):
		# Heard about rather than lived through. Held a little more loosely, and
		# that gap is what lets a witness and a listener differ.
		confidence = int(float(confidence) * 0.9)
	return clampi(confidence, 0, 100)


func _label_for(state: WorldState, entity_id: String) -> String:
	if entity_id.is_empty():
		return "someone"
	var entity := state.get_notable_entity(entity_id)
	if not entity.is_empty():
		return str(entity.get("name", entity_id))
	if state.locations.has(entity_id):
		return state.location_name(entity_id)
	return entity_id


func apply(state: WorldState, record: Dictionary) -> Dictionary:
	# The one place an interpretation is allowed to touch the world, and it may
	# only move the observer's own view of the other party.
	#
	# The change is directed and one-sided on purpose: Mara concluding something
	# about the King changes what MARA thinks of him, and nothing about what he
	# thinks of her. He was there too, and reached his own conclusion.
	var applied := record.duplicate(true)
	var planned: Dictionary = applied["planned_effect"]
	if planned.is_empty():
		applied["effect_reason"] = "no_effect_from_this_meaning"
		return applied
	var observer_id := str(applied["observer_id"])
	var other_id := str(planned["target_id"])
	var relationship := state.get_relationship(observer_id, other_id)
	if relationship.is_empty():
		# A missing edge means no relationship, not a neutral one — the same
		# rule Action Execution applies to ASK. Inventing one here would create
		# a tie out of a single overheard occurrence.
		applied["effect_reason"] = "no_relationship_edge"
		return applied
	var axis := str(planned["axis"])
	var before := int(relationship.get(axis, 0))
	var after_record := state.change_relationship(
		observer_id, other_id, {axis: int(planned["amount"])}
	)
	applied["applied_effect"] = {
		"source_id": observer_id,
		"target_id": other_id,
		"axis": axis,
		"amount": int(planned["amount"]),
		"before": before,
		"after": int(after_record.get(axis, before))
	}
	applied["effect_reason"] = "applied"
	return applied
