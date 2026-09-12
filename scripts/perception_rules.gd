class_name PerceptionRules
extends RefCounted

# Selective Perception v1.
#
# An event happening is not the same as a mortal knowing it happened. Three
# things stay separate:
#
#   Event       -> what objectively occurred
#   Perception  -> who had a plausible chance to notice it
#   Knowledge   -> what they now believe they learned
#
# This file answers the middle question only. It decides who is eligible and
# how clearly they saw it; the knowledge system still owns storage, ageing,
# distortion and transmission, and interpretation still owns what any of it
# MEANS. A perception says "I saw rain fall after the prayer". It must never
# say "the god answered us" — that is theology, and it belongs to the
# interpretation layer (GDD sections 12 and 26).
#
# Nothing here is written against a particular mortal, settlement or event.
# Eligibility is decided from reusable properties: the event's observability,
# its subject, its named participants, and where an observer lives.
#
# Deliberately NOT built here: hallucination and misperception. The architecture
# allows an event to expose a simplified claim, which is all v1 needs. False
# beliefs still arise the way they already do, through rumor distortion.

const OBSERVABILITY_MODES := ["direct", "local", "public", "hidden"]
const DEFAULT_OBSERVABILITY := "local"

# How clearly a claim survives each pathway. The event template says how plain
# the thing is to state at all; the pathway can only make it less certain, never
# more. That keeps the template the boundary on what can be known (GDD 14).
const PATHWAY_CLARITY := {
	"direct": 1.0,
	"local": 0.9,
	"public": 0.7,
	"hidden": 0.0
}

const PATHWAY_REASONS := {
	"direct": "was part of it",
	"local": "lives in %s and saw it",
	"public": "it was plain for anyone to see",
	"hidden": "it was not there to be seen"
}

# How the loss of clarity reads on the record. Being in a thing costs nothing;
# watching it costs a little; hearing that it is simply visible costs more.
const PATHWAY_COST_REASONS := {
	"local": "seen from nearby rather than taken part in",
	"public": "merely visible, not witnessed closely",
	"hidden": "barely perceptible at all"
}


# One observer's chance at one event. Reads the world and changes nothing, so
# the caller can evaluate every observer against the same snapshot before any
# of them learns anything.
func evaluate(state: WorldState, raw_fact: Dictionary, observer_id: String) -> Dictionary:
	# Resolved here rather than demanded of every caller. An occurrence that
	# says where it happened is left exactly as it is; one that does not has
	# its location worked out from its subject — the subject itself when that
	# is a place, and the person's own settlement when it is somebody. That is
	# what keeps every fact written before this distinction existed working
	# unchanged, without letting a person-subject occurrence through with
	# nowhere attached.
	var fact := state.normalise_occurrence(raw_fact)
	var observer := state.get_notable_entity(observer_id)
	var opportunity := {
		"event_id": str(fact.get("event_id", "")),
		"observer_id": observer_id,
		"observer_name": str(observer.get("name", observer_id)),
		"subject_id": str(fact.get("subject_id", "")),
		# What it was about, and where it happened, kept apart all the way
		# through so a later reader cannot mistake one for the other.
		"subject_type": str(fact.get("subject_type", "")),
		"location_id": str(fact.get("location_id", "")),
		"topic_id": str(fact.get("id", "")),
		"observability": _mode_of(fact),
		"eligible": false,
		"perceived": false,
		"confidence": 0,
		"reason": "",
		"factors": [] as Array[Dictionary],
		"reasons": [] as Array[String],
		"knowledge_id": ""
	}
	if observer.is_empty():
		opportunity["reason"] = "unknown_observer"
		return opportunity
	# The tick already offers chances to the living only. This says the same
	# thing again here, so the answer is honest for any caller asking directly
	# — including one written later that forgets the loop ever filtered.
	if not state.is_alive(observer_id):
		opportunity["reason"] = "not_among_the_living"
		return opportunity

	var mode := str(opportunity["observability"])
	var participants: Array = fact.get("participants", [])
	var home := str(observer.get("home_location_id", ""))
	# WHERE it happened, not what it was about. Comparing a home against the
	# SUBJECT worked only while every local occurrence was about a place; a
	# force striking Mara has subject `mara`, and no observer's home is ever a
	# person, so nobody would have perceived it at all.
	var where := str(opportunity["location_id"])
	var pathway := ""

	# Being part of something always beats being near it. A participant
	# perceives whatever they took part in, whatever its scope.
	if observer_id in participants:
		pathway = "direct"
	else:
		match mode:
			"direct", "hidden":
				opportunity["reason"] = "not_a_participant"
				return opportunity
			"local":
				if home.is_empty():
					opportunity["reason"] = "no_home_location"
					return opportunity
				if where.is_empty():
					opportunity["reason"] = "occurrence_has_no_location"
					return opportunity
				if home != where:
					opportunity["reason"] = "elsewhere"
					return opportunity
				pathway = "local"
			"public":
				pathway = "public"
			_:
				opportunity["reason"] = "unknown_observability"
				return opportunity

	opportunity["eligible"] = true
	var reasons: Array[String] = opportunity["reasons"]
	var factors: Array[Dictionary] = opportunity["factors"]

	# The event's own plainness is the ceiling.
	var template_confidence := clampi(int(fact.get("confidence", 0)), 0, 100)
	factors.append({
		"source": "event",
		"detail": "the event is plain enough to state at %d" % template_confidence,
		"delta": template_confidence
	})
	var carried := int(round(template_confidence * float(PATHWAY_CLARITY[pathway])))
	if carried != template_confidence:
		factors.append({
			"source": "pathway",
			"detail": str(PATHWAY_COST_REASONS.get(pathway, pathway)),
			"delta": carried - template_confidence
		})
	var pathway_reason := str(PATHWAY_REASONS[pathway])
	reasons.append(pathway_reason % home if pathway_reason.contains("%s") else pathway_reason)

	opportunity["confidence"] = clampi(carried, 0, 100)
	if opportunity["confidence"] <= 0:
		opportunity["reason"] = "too_faint_to_notice"
		return opportunity
	opportunity["perceived"] = true
	opportunity["reason"] = pathway
	return opportunity


# The claim an observer comes away with. It is built from the event's template,
# never from world statistics the event did not expose: a mortal may learn that
# a settlement lacks food, and never that its food level is exactly 23.
func perceived_claim(fact: Dictionary, opportunity: Dictionary) -> Dictionary:
	return {
		"id": str(fact["id"]),
		"subject_id": str(fact.get("subject_id", "")),
		"topic": str(fact.get("topic", "unknown")),
		"claim": str(fact.get("claim", "")),
		"confidence": int(opportunity["confidence"]),
		"truth_state": str(fact.get("truth_state", "unknown")),
		"objective_truth_state": str(fact.get("objective_truth_state", fact.get("truth_state", "unknown"))),
		"fresh_for_years": int(fact.get("fresh_for_years", WorldState.DEFAULT_KNOWLEDGE_FRESH_YEARS)),
		# Who it was between. This widens nothing knowable: a social claim
		# already names both parties in its text ("The King refused Mara's
		# request"), so carrying them as ids only spares whoever reads the
		# record from parsing prose. It is the same category of field as
		# subject_id, which this claim has always carried.
		#
		# It exists so the interpretation layer can read the observer's OWN
		# belief and nothing else. Without it, working out who was involved
		# would mean reaching back into the consequence archive, which is a
		# record the mortal has no part in.
		"participants": (fact.get("participants", []) as Array).duplicate()
	}


func _mode_of(fact: Dictionary) -> String:
	var mode := str(fact.get("observability", DEFAULT_OBSERVABILITY))
	return mode if mode in OBSERVABILITY_MODES else DEFAULT_OBSERVABILITY
