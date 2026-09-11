class_name BeliefRules
extends RefCounted

# Belief Formation v1 — what a mortal has come to accept, across years.
#
# Three layers that must never collapse into each other:
#
#   Knowledge        what they think happened      "Rain fell on Aster"
#   Interpretation   what they made of ONE event   "that rain may have been help"
#   Belief           what they now accept          "something intervenes when we
#                                                   are in need"           <- here
#
# Knowledge is about an occurrence. An interpretation is about an occurrence.
# A belief is about the WORLD, and it is the first thing in the simulation that
# is not tied to a single event. It is what survives when the fact that started
# it has been forgotten — which is exactly why it is stored separately from
# knowledge, whose cap will eventually prune the evidence out from under it.
#
# What this layer is NOT:
#
#   - not a religion. A mortal believing something intervenes is a person with
#     an opinion. No doctrine, no worship, no membership, no prophet, no church
#   - not collective. Beliefs are per-mortal, and two people living through the
#     same decade are expected to end up disagreeing
#   - not contagious. Beliefs do not spread. Facts spread, and the person who
#     receives a fact reaches their own conclusion about it
#   - not a peek behind perception. Belief is built from the mortal's OWN
#     interpretation records and nothing else. The engine knows the player sent
#     the rain; no belief may be founded on that
#   - not the realm's `faith` or `followers`. Those are legacy kingdom numbers
#     with known coupling problems, and this layer neither reads nor writes them

# The propositions a mortal can come to hold. Deliberately tiny, and every one
# of them is something the EXISTING interpretation types can actually produce —
# no speculative ontology, and nothing here that the world cannot currently
# generate evidence for.
#
# Two are about the world, two are about a particular person. That split is
# deliberate: it proves the layer is not shaped around Send Rain, and the
# subject-scoped ones are what a later social or political system would build on.
const DIVINE_INTERVENTION_EXISTS := "divine_intervention_exists"
const DIVINE_HELP_FOLLOWS_NEED := "divine_help_follows_need"
const IS_SUPPORTIVE := "is_supportive"
const IS_UNRELIABLE := "is_unreliable"
# Added with the world-condition readings. Both earn their place by being
# supported by SEVERAL interpretation types across two topics, and by changing
# what their holder later wants — a mortal who has concluded their home is
# unsafe wants to protect and preserve, which is a want the gating law already
# admits. A proposition only one reading feeds and nothing acts on would be
# ontology for its own sake.
const HOME_IS_UNSAFE := "home_is_unsafe"
const CONDITIONS_ARE_IMPROVING := "conditions_are_improving"
# Subject-scoped, and about a PLACE rather than a person: this settlement is
# getting something the others are not. Added with Bless Harvest because two
# interpretation types feed it and it changes what its holder wants — somebody
# who believes their home is favoured wants to preserve it. It is a private
# conviction about a location, NOT a doctrine, a chosen people or a membership.
const PLACE_IS_FAVOURED := "place_is_favoured"

const PROPOSITIONS := [
	DIVINE_INTERVENTION_EXISTS,
	DIVINE_HELP_FOLLOWS_NEED,
	IS_SUPPORTIVE,
	IS_UNRELIABLE,
	HOME_IS_UNSAFE,
	CONDITIONS_ARE_IMPROVING,
	PLACE_IS_FAVOURED
]

# Propositions about a particular person. Their belief record carries a
# subject_id, and a mortal may hold opposite views of two different people.
const SUBJECT_SCOPED := [IS_SUPPORTIVE, IS_UNRELIABLE, PLACE_IS_FAVOURED]

# What each conclusion is evidence FOR and AGAINST. One table, so that adding a
# future interpretation type means one entry here rather than a check scattered
# through the simulation.
#
# `weight` is the evidential strength of that reading for that proposition, not
# the confidence change: how far confidence actually moves also depends on how
# sure the mortal was of the reading itself.
#
# Note what is absent. `rain_natural_weather` CONTRADICTS the divine
# propositions, because deciding the weather was just weather is a real
# conclusion about the world and not an absence of one. But nothing here treats
# a crisis that went unanswered as contradiction: the mortal has to have
# actually interpreted something. Absence of evidence is not evidence, and
# building that in would be inference this layer has no business doing.
const SUPPORTS := {
	"rain_divine_help": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 14},
		{"proposition": DIVINE_HELP_FOLLOWS_NEED, "weight": 16}
	],
	"rain_divine_favour": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 12}
	],
	"support_stood_with_me": [
		{"proposition": IS_SUPPORTIVE, "weight": 14}
	],
	"acceptance_willing_to_help": [
		{"proposition": IS_SUPPORTIVE, "weight": 12}
	],
	"refusal_unwilling_to_help": [
		{"proposition": IS_UNRELIABLE, "weight": 14}
	],
	"opposition_stood_against_me": [
		{"proposition": IS_UNRELIABLE, "weight": 10}
	],
	# The world conditions. Both home readings feed the same proposition from
	# two different topics, which is what makes it a belief about the PLACE
	# rather than a memory of one bad year.
	"home_is_in_danger": [
		{"proposition": HOME_IS_UNSAFE, "weight": 15}
	],
	"home_is_recovering": [
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 14}
	],
	"shortage_will_pass": [
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 10}
	],
	"unrest_will_settle": [
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 10}
	],
	# Standing water where you live is evidence the place cannot keep you safe,
	# however it got there.
	# A place that was struck is a place that can be struck.
	"destruction_is_ruin": [
		{"proposition": HOME_IS_UNSAFE, "weight": 18}
	],
	# Concluding nothing mortal did it is evidence that something acts, and
	# evidence that home is not safe. It is NOT evidence about whether help
	# follows need — a destructive act says nothing either way about that.
	"destruction_was_not_mortal": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 20},
		{"proposition": HOME_IS_UNSAFE, "weight": 14}
	],
	"flood_is_disaster": [
		{"proposition": HOME_IS_UNSAFE, "weight": 16}
	],
	"harvest_divine_help": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 14},
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 8}
	],
	"harvest_divine_favour": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 12},
		{"proposition": PLACE_IS_FAVOURED, "weight": 16}
	],
	"yield_is_beyond_explanation": [
		{"proposition": PLACE_IS_FAVOURED, "weight": 8}
	],
	"flood_divine_excess": [
		{"proposition": HOME_IS_UNSAFE, "weight": 14},
		# Still evidence that something intervenes. Reading a flood as sent is
		# not doubt about intervention — it is doubt about its restraint.
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 10}
	]
}

const CONTRADICTS = {
	"rain_natural_weather": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 8},
		{"proposition": DIVINE_HELP_FOLLOWS_NEED, "weight": 10}
	],
	"refusal_unwilling_to_help": [
		{"proposition": IS_SUPPORTIVE, "weight": 12}
	],
	"acceptance_willing_to_help": [
		{"proposition": IS_UNRELIABLE, "weight": 10}
	],
	"support_stood_with_me": [
		{"proposition": IS_UNRELIABLE, "weight": 8}
	],
	# Coming through it is evidence against the place being unsafe, and a year
	# of danger is evidence against things improving. Each is a real conclusion
	# the mortal reached, never an absence of one.
	"home_is_recovering": [
		{"proposition": HOME_IS_UNSAFE, "weight": 12}
	],
	"home_is_in_danger": [
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 12}
	],
	# The belief revision path this milestone exists to open. Somebody who came
	# to believe help arrives when the need is greatest, and then watched far
	# more arrive than anyone needed, has been given a reason to doubt it. The
	# belief is not deleted because a flood happened — the flood had to be
	# perceived, known and INTERPRETED that way first.
	"flood_divine_excess": [
		{"proposition": DIVINE_HELP_FOLLOWS_NEED, "weight": 18}
	],
	"flood_is_disaster": [
		{"proposition": CONDITIONS_ARE_IMPROVING, "weight": 14}
	],
	# Deciding a remarkable harvest was simply a good season is a real
	# conclusion about the world, and it is evidence against something having
	# sent it.
	"harvest_is_good_fortune": [
		{"proposition": DIVINE_INTERVENTION_EXISTS, "weight": 8},
		{"proposition": PLACE_IS_FAVOURED, "weight": 8}
	]
}

const CONFIDENCE_MIN := 0
const CONFIDENCE_MAX := 100

# What one piece of evidence can do. A single reading must never carry someone
# from nothing to certainty — the whole point is that belief accumulates — so
# the movement from any one interpretation is capped well below the threshold
# at which the belief starts influencing anything.
const MAX_SINGLE_MOVE := 20

# Where a belief stops being a notion and starts being something the mortal
# reasons from. Below this it is recorded and inspectable but changes nothing.
const ESTABLISHED_CONFIDENCE := 45

# A belief that has taken contradicting evidence more recently than supporting
# evidence. Worth a status of its own because "held at 50 and rising" and "held
# at 50 and falling" are different situations to debug.
const STATUS_FORMING := "forming"
const STATUS_HELD := "held"
const STATUS_WEAKENING := "weakening"


# Everything this year's readings did to what their holders accept.
#
# Consumes interpretation records and nothing else: not the divine action
# archive, not objective truth, not the realm's faith. If this function could
# see that a god caused the rain, every belief it formed would be the engine's
# conclusion wearing a mortal's name.
func update_from_interpretations(
	state: WorldState, interpretations: Array
) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for record_value in interpretations:
		var record: Dictionary = record_value
		var reading := str(record["interpretation_type"])
		var holder_id := str(record["observer_id"])
		if holder_id.is_empty():
			continue
		for entry_value in SUPPORTS.get(reading, []):
			var entry: Dictionary = entry_value
			var update := _apply_evidence(state, record, entry, true)
			if not update.is_empty():
				updates.append(update)
		for entry_value in CONTRADICTS.get(reading, []):
			var entry: Dictionary = entry_value
			var update := _apply_evidence(state, record, entry, false)
			if not update.is_empty():
				updates.append(update)
	return updates


func _apply_evidence(
	state: WorldState, record: Dictionary, entry: Dictionary, supporting: bool
) -> Dictionary:
	var holder_id := str(record["observer_id"])
	var proposition := str(entry["proposition"])
	var subject_id := _subject_for(proposition, record)
	# A subject-scoped proposition with nobody to be about is not a belief.
	if proposition in SUBJECT_SCOPED and subject_id.is_empty():
		return {}
	# Nobody forms a belief about themselves from their own conduct.
	if subject_id == holder_id:
		return {}

	var existing := state.get_belief(holder_id, proposition, subject_id)
	# Contradicting evidence for something they have never entertained is not a
	# belief in the negative; it is simply nothing happening.
	if existing.is_empty() and not supporting:
		return {}

	var before := int(existing.get("confidence", 0)) if not existing.is_empty() else 0
	var move := _movement(int(entry["weight"]), int(record["confidence"]), before, supporting)
	if move == 0:
		return {}
	var after := clampi(before + move, CONFIDENCE_MIN, CONFIDENCE_MAX)

	# Every point of the change names where it came from, so Developer Mode can
	# answer "why does this mortal believe this" without guessing.
	var factors: Array[Dictionary] = [
		{
			"kind": "supporting_interpretation" if supporting else "contradicting_interpretation",
			"detail": str(record["interpretation_type"]),
			"interpretation_id": str(record["id"]),
			"delta": move
		},
		{
			"kind": "interpretation_confidence",
			"detail": "held at %d" % int(record["confidence"]),
			"interpretation_id": str(record["id"]),
			"delta": 0
		},
		{
			"kind": "existing_belief_confidence",
			"detail": "stood at %d" % before,
			"interpretation_id": "",
			"delta": 0
		}
	]
	var stored := state.record_belief({
		"holder_id": holder_id,
		"proposition": proposition,
		"subject_id": subject_id,
		"confidence": after,
		"support": int(existing.get("support", 0)) + int(supporting),
		"contradiction": int(existing.get("contradiction", 0)) + int(not supporting),
		"first_year": int(existing.get("first_year", state.year)),
		"last_updated_year": state.year,
		"source_interpretation_ids": _extended_sources(existing, str(record["id"])),
		"status": _status(after, supporting)
	})
	return {
		"year": state.year,
		"belief_id": str(stored["id"]),
		"holder_id": holder_id,
		"proposition": proposition,
		"subject_id": subject_id,
		"change": "formed" if existing.is_empty() else (
			"reinforced" if move > 0 else "weakened"),
		"before": before,
		"after": after,
		"delta": move,
		"factors": factors
	}


# How far one piece of evidence moves a belief.
#
# Three inputs, all of them the mortal's own: how strong this reading is as
# evidence, how sure they were of the reading, and how firmly they already hold
# the proposition. The third is what makes formation gradual in both directions
# — a belief already near certainty gains little from one more confirmation,
# and one they barely hold has little to lose.
func _movement(weight: int, reading_confidence: int, current: int, supporting: bool) -> int:
	# Hearsay moves a belief less than something they were sure of.
	var scaled := int(round(float(weight) * float(clampi(reading_confidence, 0, 100)) / 100.0))
	if scaled <= 0:
		return 1 if supporting else 0
	# Diminishing returns near the ends, so nothing sprints to certainty and
	# nothing is demolished by a single doubt.
	var room := float(CONFIDENCE_MAX - current) if supporting else float(current)
	var damped := int(round(float(scaled) * (0.4 + 0.6 * room / float(CONFIDENCE_MAX))))
	damped = clampi(damped, 1, MAX_SINGLE_MOVE)
	return damped if supporting else -damped


func _status(confidence: int, supporting: bool) -> String:
	if confidence < ESTABLISHED_CONFIDENCE:
		return STATUS_FORMING
	return STATUS_HELD if supporting else STATUS_WEAKENING


func _subject_for(proposition: String, record: Dictionary) -> String:
	if proposition not in SUBJECT_SCOPED:
		return ""
	# Who the reading was about, from the observer's own side.
	var target_id := str(record.get("target_id", ""))
	if not target_id.is_empty():
		return target_id
	var actor_id := str(record.get("actor_id", ""))
	if not actor_id.is_empty():
		return actor_id
	# A world occurrence has no second party, so what the reading was ABOUT is
	# the place it happened in. That is how a belief can be held about a
	# SETTLEMENT — "somewhere is being favoured" — rather than only about a
	# person. Without this, a place-scoped proposition could never find its
	# subject and was silently discarded.
	return str(record.get("subject_id", ""))


func _extended_sources(existing: Dictionary, interpretation_id: String) -> Array:
	# Bounded, and the newest kept. The links are for inspection, not for
	# recomputation: a belief does not need its whole history to be a belief,
	# which is the reason it survives its evidence being pruned.
	var sources: Array = existing.get("source_interpretation_ids", []).duplicate()
	if interpretation_id not in sources:
		sources.append(interpretation_id)
	if sources.size() > WorldState.MAX_BELIEF_SOURCES:
		sources = sources.slice(sources.size() - WorldState.MAX_BELIEF_SOURCES)
	return sources


# --- what beliefs are allowed to do ----------------------------------------

# A belief is established once it is firm enough to reason from. Below that it
# is a notion: recorded, inspectable, and influencing nothing.
func is_established(belief: Dictionary) -> bool:
	return int(belief.get("confidence", 0)) >= ESTABLISHED_CONFIDENCE


func established_for(state: WorldState, holder_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for belief: Dictionary in state.get_beliefs_for(holder_id):
		if is_established(belief):
			found.append(belief)
	return found


func confidence_in(
	state: WorldState, holder_id: String, proposition: String, subject_id: String = ""
) -> int:
	var belief := state.get_belief(holder_id, proposition, subject_id)
	return int(belief.get("confidence", 0)) if not belief.is_empty() else 0


# Which propositions a reading is evidence for. Asked by intent scoring so it
# can tell whether a belief and a recent interpretation are the SAME evidence
# counted twice.
func propositions_supported_by(reading: String) -> Array[String]:
	var found: Array[String] = []
	for entry_value in SUPPORTS.get(reading, []):
		found.append(str((entry_value as Dictionary)["proposition"]))
	return found
