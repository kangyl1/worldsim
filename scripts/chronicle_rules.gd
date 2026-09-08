class_name ChronicleRules
extends RefCounted

# Chronicle v1 — which occurrences were important enough to become history.
#
# Everything else in the simulation answers what happened. This answers a
# different question, and it is the one that makes a fifty-year run readable
# instead of merely long: of everything that happened, what SHAPED the world?
#
# The test comes from GDD section 36, and it is a test about the future rather
# than about drama:
#
#   Long-term memory should justify its existence by being capable of affecting
#   future behaviour, belief, relationships, or history.
#
# So a settlement starving is history, and the same settlement being slightly
# hungrier than last year is not. A refusal that pushed someone's trust into a
# lower band is history; the same refusal absorbed without changing anything is
# not. A divine act that pulled a settlement out of famine is history; rain on
# an already-fed field is an act the god took and nobody needed.
#
# What this layer is NOT:
#
#   - not a second simulation. It reads records other layers already wrote and
#     invents no occurrence of its own
#   - not an interpretation. "The King refused Mara's request" is history;
#     "the cruel King betrayed Westfield" is what somebody decided about it, and
#     lives in `interpretation_archive` where it can be disagreed with
#   - not a full event log. Most of what happens should leave no trace here
#   - not a decay model. Entries are immutable and permanent in v1. GDD 96 wants
#     forgetting to be gradual and legible one day; nothing here forecloses it,
#     because a record that carries its own year, source and causal links can
#     later be faded, contested or half-remembered without being rewritten

# --- History Scope Foundation v1 ---------------------------------------------
#
# Reality happens once. History may be viewed through many lenses.
#
# A record is STORED ONCE and belongs to as many scopes as it honestly belongs
# to. There is no world_history[], no location_history[] and no person_history[]
# holding copies; every view below is a FILTER over the one chronicle, and a
# test asserts that reading the views never changes how many records exist.
#
# `scopes` says WHICH KINDS of history a record is part of. It deliberately does
# NOT carry the ids — those are already on the record as `location_id`,
# `actor_id`, `target_id` and `subject_id`, and copying them into a second
# structure would create exactly the duplicate truth this layer exists to avoid.
# The ids are read back out through `locations_of()` and `persons_of()`.
const SCOPE_WORLD := "world"
const SCOPE_REGION := "region"
const SCOPE_LOCATION := "location"
const SCOPE_PERSON := "person"
const SCOPE_DIVINE := "divine"
const SCOPES := [SCOPE_WORLD, SCOPE_REGION, SCOPE_LOCATION, SCOPE_PERSON, SCOPE_DIVINE]

# A scope asks whose history this is and at what scale. A CATEGORY asks what
# kind of thing happened. Two different questions, kept in two fields.
#
# Derived from the objective record — its source and its event type — and never
# from the wording of a summary. Reading a category out of presentation would
# let the surface decide what the archive contains.
const CATEGORY_ENVIRONMENT := "environment"
const CATEGORY_CRISIS := "crisis"
const CATEGORY_SOCIAL := "social"
const CATEGORY_BELIEF := "belief"
const CATEGORY_DIVINE := "divine"
const CATEGORY_RECOVERY := "recovery"
const CATEGORIES := [
	CATEGORY_ENVIRONMENT, CATEGORY_CRISIS, CATEGORY_SOCIAL,
	CATEGORY_BELIEF, CATEGORY_DIVINE, CATEGORY_RECOVERY
]

# World history is a HIGHER BAR, not the same bar seen from further away. A
# settlement starving is major history for that settlement and no business of
# the world's, so clearing `IMPORTANCE_THRESHOLD` never implies world scale.
#
# Two conditions must both hold: the occurrence has to be world-scale in KIND
# (see `_is_world_scale`), and it has to clear this. Nothing local reaches it.
const WORLD_HISTORY_THRESHOLD := 70

const SOURCE_CONDITION := "settlement_condition"
const SOURCE_DIVINE := "divine_action"
const SOURCE_CONSEQUENCE := "consequence"
const SOURCE_INTERPRETATION := "interpretation"

# The floor. A settlement band runs 0-3, and 0 is the named crisis state:
# Critical food, Fractured stability, Destitute prosperity.
const CRISIS_BAND := 0

# Sparse on purpose. The scores below are set so that ordinary years record
# nothing at all: a quiet decade in a stable world SHOULD leave no history, and
# a chronicle with an entry every year is the full event log this layer exists
# to avoid. Raising this makes history rarer, not more selective — the factors
# are what decide what kind of thing counts.
const IMPORTANCE_THRESHOLD := 50

# What each factor is worth. Small, explicit, and inspectable: every point in a
# record's importance names where it came from, so Developer Mode can answer
# "why is this history" and "why is that not" without guessing.
#
# Nothing here scores drama. Each factor is a claim that the occurrence can
# reach forward: a crisis changes what everyone in a settlement will want, a
# band crossing changes how someone is treated, a reading that feeds intent
# scoring changes what its holder does next.
const FACTOR_SCORES := {
	# A settlement fell into a named crisis, or climbed out of one. The clearest
	# case in the whole system: the condition governs what mortals there want.
	"crisis_entered": 60,
	"crisis_lifted": 55,
	# A condition moved more than one band in a year. Not a crisis, but not
	# drift either.
	"condition_swing": 30,
	# The god's act objectively changed a settlement's condition. NOT "the god
	# acted" — that alone is worth nothing here.
	"divine_impact": 35,
	# The act landed on a settlement that was in crisis when it fell.
	"answered_a_crisis": 30,
	# A named person was party to it. A world where things happen to nobody in
	# particular has no history worth reading.
	"notable_mortal": 15,
	# The occurrence pushed a relationship across a presentation band — the
	# existing bands, not a new threshold invented for history.
	# Enough on its own. A band crossing is the point at which a relationship
	# stops being the same relationship — the presentation layer already draws
	# that line, and how one person regards another governs what they will try.
	"relationship_band_crossed": 50,
	# The occurrence is rare in this world's run so far. A refusal among many
	# acceptances says more than another acceptance does.
	"uncommon_occurrence": 20,
	# A reading that later reasoning actually consults. This is the GDD 36 test
	# stated literally: it can change future behaviour.
	# Also enough on its own, because it IS the GDD 36 test stated literally:
	# this reading is consulted when its holder decides what they want next.
	"changes_later_behaviour": 50,
	# The same condition in the same place, again. Repetition is what turns a
	# bad year into a pattern somebody has to answer.
	"reinforced": 20,
	# It happened in a place already living through a recorded crisis. This is
	# the difference between the brief's example and an ordinary conversation:
	# a ruler refusing aid during a famine is history, and the same refusal in a
	# fed and quiet year is two people disagreeing. It is also exactly the link
	# `parent_for()` draws, so what makes the occurrence important and what makes
	# it part of a story are the same fact.
	"during_open_crisis": 35
}

# Interpretation types that later intent scoring reads. Kept as a question asked
# of `IntentRules` rather than a copied list, so the two cannot drift apart.
const INTENT_FEEDBACK_SOURCE := "res://scripts/intent_rules.gd"

# How far back "again" reaches when deciding a condition was reinforced.
const REINFORCEMENT_WINDOW := 6

# Below this share of a run's social occurrences, a topic counts as uncommon.
const UNCOMMON_SHARE := 0.25


# Everything the year produced, scored. Returns both what was kept and what was
# not, because "why was this not history" is half of what makes the layer
# debuggable — but only the kept records are stored, and the rejections are the
# caller's to discard at the end of the year.
func select(
	state: WorldState,
	conditions_before: Dictionary,
	divine_actions: Array,
	consequences: Array,
	interpretations: Array
) -> Dictionary:
	var candidates: Array[Dictionary] = []
	candidates.append_array(_condition_candidates(state, conditions_before))
	candidates.append_array(_divine_candidates(state, divine_actions, conditions_before))
	candidates.append_array(_consequence_candidates(state, consequences))
	candidates.append_array(_interpretation_candidates(state, interpretations))

	var kept: Array[Dictionary] = []
	var rejected: Array[Dictionary] = []
	for candidate: Dictionary in candidates:
		if int(candidate["importance"]) >= IMPORTANCE_THRESHOLD:
			kept.append(candidate)
		else:
			rejected.append({
				"year": int(candidate["year"]),
				"summary": str(candidate["summary"]),
				"importance": int(candidate["importance"]),
				"factors": candidate["factors"],
				"source_record_type": str(candidate["source_record_type"]),
				"source_record_id": str(candidate["source_record_id"]),
				"reason": "scored %d, below the threshold of %d" % [
					int(candidate["importance"]), IMPORTANCE_THRESHOLD
				]
			})
	return {"kept": kept, "rejected": rejected}


# --- candidates ------------------------------------------------------------

func _condition_candidates(state: WorldState, before: Dictionary) -> Array[Dictionary]:
	# Read from the settlement bands themselves rather than from consequences,
	# because the yearly cycle and world drift move conditions without going
	# through a consequence record. Nothing is invented: this is the same state
	# the map and the player-facing panel read.
	var found: Array[Dictionary] = []
	var location_ids: Array = state.locations.keys()
	location_ids.sort()
	for location_id_value in location_ids:
		var location_id := str(location_id_value)
		var previous: Dictionary = before.get(location_id, {})
		if previous.is_empty():
			continue
		for band: String in WorldState.SETTLEMENT_BANDS:
			var was := int(previous.get(band, -1))
			var now := state.get_settlement_band(location_id, band)
			if was < 0 or was == now:
				continue
			var factors: Array[Dictionary] = []
			var entered := now == CRISIS_BAND and was > CRISIS_BAND
			var lifted := was == CRISIS_BAND and now > CRISIS_BAND
			if entered:
				factors.append(_factor("crisis_entered", "%s in %s" % [
					_band_label(band, now), state.location_name(location_id)
				]))
			if lifted:
				factors.append(_factor("crisis_lifted", "%s reached %s" % [
					state.location_name(location_id), _band_label(band, now)
				]))
			if absi(now - was) >= 2:
				factors.append(_factor("condition_swing", "%s moved %d bands" % [
					band, absi(now - was)
				]))
			if (entered or lifted) and _was_recently_recorded(state, location_id, band):
				factors.append(_factor("reinforced", "the same condition within %d years"
					% REINFORCEMENT_WINDOW))
			if factors.is_empty():
				continue
			var event_type := "crisis_entered" if entered else (
				"crisis_lifted" if lifted else "condition_changed")
			# ONE continuing episode, not one record per wobble.
			#
			# A settlement can cross the same threshold in the same band every
			# other year for decades — food dipping to Critical and recovering,
			# over and over — and writing each crossing as its own top-level
			# history turned a single long spell of instability into forty-five
			# separate "events". That is the event log this layer exists to
			# avoid, and it hid the entries that actually mattered among the
			# churn.
			#
			# So a transition is history when it is the FIRST of its kind for
			# that place and band in living memory. The fall is recorded, and so
			# is the recovery; the eleven relapses in between are the same
			# episode continuing. Once the place has been quiet for longer than
			# the reinforcement window, the next collapse is genuinely new and
			# is recorded again.
			#
			# Nothing is lost causally: `parent_for()` still hangs later
			# occurrences off the open crisis, so a flood or a refusal during
			# this episode still points at the entry that opened it.
			if _same_transition_recently(state, location_id, band, event_type):
				continue
			found.append(_candidate(state, {
				"event_type": event_type,
				"subject_id": location_id,
				"location_id": location_id,
				"summary": _condition_summary(state, location_id, band, was, now),
				"source_record_type": SOURCE_CONDITION,
				"source_record_id": "%s_%04d_%s" % [location_id, state.year, band],
				"factors": factors
			}))
	return found


func _divine_candidates(
	state: WorldState, divine_actions: Array, before: Dictionary
) -> Array[Dictionary]:
	# A divine act is not history because a god performed it. It is history when
	# it objectively changed the world, and more so when what it changed was a
	# settlement already in crisis. What the act MEANT is not scored here and
	# must not be: that belongs to whoever interpreted it.
	var found: Array[Dictionary] = []
	for record_value in divine_actions:
		var record: Dictionary = record_value
		var location_id := str(record["target_id"])
		var consequence := state.get_consequence(str(record["consequence_id"]))
		var changes: Array = consequence.get("state_changes", [])
		if changes.is_empty():
			# The god acted and the world is the same. Offered as a candidate so
			# Developer Mode can say why it is not history, and scored at
			# nothing so it never becomes history by accident.
			found.append(_candidate(state, {
				"event_type": "divine_action",
				"subject_id": location_id,
				"location_id": location_id,
				"year": int(record["year"]),
				"summary": _divine_summary(state, record, changes),
				"source_record_type": SOURCE_DIVINE,
				"source_record_id": str(record["id"]),
				"factors": [] as Array[Dictionary]
			}))
			continue
		var factors: Array[Dictionary] = [
			_factor("divine_impact", "%d objective change(s)" % changes.size())
		]
		if not _open_crisis_id(state, location_id).is_empty():
			factors.append(_factor("during_open_crisis",
				"%s was in a recorded crisis" % state.location_name(location_id)))
		var previous: Dictionary = before.get(location_id, {})
		for change_value in changes:
			var change: Dictionary = change_value
			var band := str(change["field"])
			if int(previous.get(band, 1)) == CRISIS_BAND and int(change["after"]) > CRISIS_BAND:
				factors.append(_factor("answered_a_crisis", "%s was at %s" % [
					state.location_name(location_id), _band_label(band, CRISIS_BAND)
				]))
				break
		found.append(_candidate(state, {
			"event_type": "divine_action",
			"subject_id": location_id,
			"location_id": location_id,
			"year": int(record["year"]),
			"summary": _divine_summary(state, record, changes),
			"source_record_type": SOURCE_DIVINE,
			"source_record_id": str(record["id"]),
			"factors": factors
		}))
	return found


func _consequence_candidates(state: WorldState, consequences: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in consequences:
		var record: Dictionary = record_value
		if str(record["source_type"]) != "execution":
			continue
		var claim := _claim_of(record)
		if claim.is_empty():
			continue
		var actor_id := str(record["actor_id"])
		var target_id := str(record["target_id"])
		var factors: Array[Dictionary] = []
		if _is_notable(state, actor_id) or _is_notable(state, target_id):
			factors.append(_factor("notable_mortal", _names(state, actor_id, target_id)))
		var result_type := str(record["result_type"])
		if _is_uncommon(state, result_type):
			factors.append(_factor("uncommon_occurrence", "%s is rare in this world" % result_type))
		var home := _home_of(state, actor_id)
		if not _open_crisis_id(state, home).is_empty():
			factors.append(_factor("during_open_crisis",
				"%s was in a recorded crisis" % state.location_name(home)))
		if factors.is_empty():
			continue
		found.append(_candidate(state, {
			"event_type": result_type,
			"subject_id": str(record["subject_id"]),
			"actor_id": actor_id,
			"target_id": target_id,
			"location_id": _home_of(state, actor_id),
			"summary": claim,
			"source_record_type": SOURCE_CONSEQUENCE,
			"source_record_id": str(record["id"]),
			"factors": factors
		}))
	return found


func _interpretation_candidates(state: WorldState, interpretations: Array) -> Array[Dictionary]:
	# An interpretation earns a place in objective history only through its
	# effect. The record says what the reading DID — moved a relationship far
	# enough to matter, or fed later reasoning — and never asserts that the
	# reading was correct.
	var found: Array[Dictionary] = []
	var feedback := _intent_feedback_types()
	for record_value in interpretations:
		var record: Dictionary = record_value
		var effect: Dictionary = record["applied_effect"]
		var factors: Array[Dictionary] = []
		if not effect.is_empty() and _crosses_band(effect):
			factors.append(_factor("relationship_band_crossed", "%s toward %s: %s to %s" % [
				str(effect["axis"]), _name_of(state, str(effect["target_id"])),
				PresentationRules.relationship_label(str(effect["axis"]), int(effect["before"])),
				PresentationRules.relationship_label(str(effect["axis"]), int(effect["after"]))
			]))
		if str(record["interpretation_type"]) in feedback:
			factors.append(_factor("changes_later_behaviour",
				"%s is read by intent scoring" % str(record["interpretation_type"])))
		if factors.is_empty():
			continue
		found.append(_candidate(state, {
			"event_type": "interpretation_took_effect",
			"subject_id": str(record["source_knowledge_id"]),
			"actor_id": str(record["observer_id"]),
			"target_id": str(effect.get("target_id", "")),
			"location_id": _home_of(state, str(record["observer_id"])),
			"summary": _interpretation_summary(state, record, effect),
			"source_record_type": SOURCE_INTERPRETATION,
			"source_record_id": str(record["id"]),
			"factors": factors
		}))
	return found


# --- scoring and shaping ---------------------------------------------------

func _factor(kind: String, detail: String) -> Dictionary:
	return {"kind": kind, "detail": detail, "score": int(FACTOR_SCORES.get(kind, 0))}


func _candidate(state: WorldState, fields: Dictionary) -> Dictionary:
	var factors: Array = fields.get("factors", [])
	var importance := 0
	for factor_value in factors:
		importance += int((factor_value as Dictionary)["score"])
	return {
		"id": "",
		# The year the thing HAPPENED, which is not always the year the chronicle
		# ran: a divine act is taken before the turn advances, so it carries its
		# own stamp rather than inheriting the tick's.
		"year": int(fields.get("year", state.year)),
		"event_type": str(fields["event_type"]),
		"subject_id": str(fields.get("subject_id", "")),
		"actor_id": str(fields.get("actor_id", "")),
		"target_id": str(fields.get("target_id", "")),
		"location_id": str(fields.get("location_id", "")),
		"summary": str(fields["summary"]),
		# The record this was drawn from. History points BACK at its source and
		# never copies it, so the source stays the thing that actually happened.
		"source_record_type": str(fields["source_record_type"]),
		"source_record_id": str(fields["source_record_id"]),
		"importance": importance,
		"factors": factors,
		"caused_by": [] as Array[String],
		"led_to": [] as Array[String],
		# Filled in by `classify()` once the record's causal parent is known.
		"scopes": [] as Array[String],
		"categories": [] as Array[String],
		"world_history": false
	}


# --- history scope ----------------------------------------------------------

# Which histories this record belongs to, which kind of thing it was, and
# whether it is any of the world's business.
#
# Called once, when the record is written and its causal parent is known.
# Classification READS the record and writes only these three fields: it never
# alters a summary, an importance, a factor, a source pointer or a causal link,
# and a test compares every objective field before and after.
func classify(state: WorldState, record: Dictionary, parent_id: String) -> Dictionary:
	var scopes: Array[String] = []
	var categories: Array[String] = []
	var source := str(record["source_record_type"])

	# LOCATION. The place the occurrence happened in, when there is one.
	if not locations_of(state, record).is_empty():
		scopes.append(SCOPE_LOCATION)

	# REGION. Supported by the schema and unreachable today: see
	# `region_of()`. Nothing is invented to fill it.
	if not region_of(state, record).is_empty():
		scopes.append(SCOPE_REGION)

	# PERSON. Only people the record itself names as having acted or been acted
	# upon. Perceiving something is not taking part in it.
	if not persons_of(state, record).is_empty():
		scopes.append(SCOPE_PERSON)

	# DIVINE. The god's own acts, and what those acts directly caused. A flood
	# that a standing order produced is divine history as well as local history;
	# inheritance stops at one step, so an ordinary quarrel years later does not
	# become an act of God because a drought once preceded it.
	if source == SOURCE_DIVINE:
		scopes.append(SCOPE_DIVINE)
		categories.append(CATEGORY_DIVINE)
		categories.append(CATEGORY_ENVIRONMENT)
	elif not parent_id.is_empty():
		var parent: Dictionary = state.get_chronicle(parent_id)
		if not parent.is_empty() and str(parent["source_record_type"]) == SOURCE_DIVINE:
			scopes.append(SCOPE_DIVINE)

	match source:
		SOURCE_CONDITION:
			match str(record["event_type"]):
				"crisis_entered":
					categories.append(CATEGORY_CRISIS)
				"crisis_lifted":
					categories.append(CATEGORY_RECOVERY)
		SOURCE_CONSEQUENCE:
			categories.append(CATEGORY_SOCIAL)
		SOURCE_INTERPRETATION:
			categories.append(CATEGORY_BELIEF)

	# WORLD, last, because it depends on nothing else here and is refused far
	# more often than it is granted.
	var qualifies := _is_world_scale(state, record) \
		and int(record["importance"]) >= WORLD_HISTORY_THRESHOLD
	if qualifies:
		scopes.append(SCOPE_WORLD)

	return {
		"scopes": scopes,
		"categories": categories,
		"world_history": qualifies
	}


# World-scale in KIND, before importance is even consulted.
#
# An occurrence confined to one settlement is that settlement's history however
# large it was there. What reaches the world is a condition that took hold
# EVERYWHERE at once — every settlement crossing the same way in the same year —
# which is the only thing the current model can honestly call world-scale.
#
# Consequence: in a quiet autonomous run this answers false for everything, and
# World History is empty. That is the view working, not a gap to be filled.
func _is_world_scale(state: WorldState, record: Dictionary) -> bool:
	if str(record["source_record_type"]) != SOURCE_CONDITION:
		return false
	var event_type := str(record["event_type"])
	if event_type != "crisis_entered" and event_type != "crisis_lifted":
		return false
	var location_ids: Array = state.locations.keys()
	if location_ids.size() < 2:
		return false
	# Every settlement, this year, the same way.
	for location_id_value in location_ids:
		var location_id := str(location_id_value)
		var matched := false
		for other_value in state.chronicle:
			var other: Dictionary = other_value
			if int(other["year"]) != int(record["year"]):
				continue
			if str(other["event_type"]) != event_type:
				continue
			if str(other["location_id"]) == location_id:
				matched = true
				break
		if location_id == str(record["location_id"]):
			continue
		if not matched:
			return false
	return true


# The settlements this record is history FOR. Read from the fields the record
# already carries; nothing is stored twice.
func locations_of(state: WorldState, record: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for key: String in ["location_id", "subject_id", "target_id"]:
		var candidate := str(record.get(key, ""))
		if candidate.is_empty() or found.has(candidate):
			continue
		if state.locations.has(candidate):
			found.append(candidate)
	return found


# The people this record is history FOR.
#
# Involvement, not awareness. `actor_id` and `target_id` are the people the
# record says did something or had something done to them; a bystander who
# merely perceived the occurrence is not in its history, and a test proves that
# perceiving an event adds nobody.
func persons_of(state: WorldState, record: Dictionary) -> Array[String]:
	var found: Array[String] = []
	for key: String in ["actor_id", "target_id"]:
		var candidate := str(record.get(key, ""))
		if candidate.is_empty() or found.has(candidate):
			continue
		if state.notable_entities.has(candidate):
			found.append(candidate)
	return found


# The region this record belongs to.
#
# KNOWN LIMITATION, reported rather than faked: the world model has no region
# entity. Locations carry an id, a name, a kind and a role, and nothing above
# them. Rather than invent a geography to fill a scope, this answers empty for
# every current record, `region` is never assigned, and the API is here so that
# world generation can supply real regions later without the chronicle changing.
func region_of(state: WorldState, record: Dictionary) -> String:
	for location_id: String in locations_of(state, record):
		var location: Dictionary = state.get_location(location_id)
		var region := str(location.get("region_id", ""))
		if not region.is_empty():
			return region
	return ""


# --- filtered views ---------------------------------------------------------
#
# Every one of these SELECTS from `state.chronicle`. None of them stores
# anything, and none may be turned into a second history.

func world_history(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if bool(record.get("world_history", false)):
			found.append(record)
	return found


func history_for_location(state: WorldState, location_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if locations_of(state, record).has(location_id):
			found.append(record)
	return found


func history_for_person(state: WorldState, entity_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if persons_of(state, record).has(entity_id):
			found.append(record)
	return found


func history_for_region(state: WorldState, region_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if region_of(state, record) == region_id:
			found.append(record)
	return found


func divine_history(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if (record.get("scopes", []) as Array).has(SCOPE_DIVINE):
			found.append(record)
	return found


func history_in_category(state: WorldState, category: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.chronicle:
		var record: Dictionary = record_value
		if (record.get("categories", []) as Array).has(category):
			found.append(record)
	return found


# --- causality -------------------------------------------------------------

# The strongest direct parent, not every dependency. A graph that links
# everything to everything explains nothing, so each record takes at most one
# parent and takes it only when the link is real.
func parent_for(state: WorldState, record: Dictionary) -> String:
	var source_type := str(record["source_record_type"])
	if source_type == SOURCE_INTERPRETATION:
		# The occurrence the reading was drawn from, if that occurrence is
		# itself history. A conclusion about something nobody recorded has no
		# historical parent.
		return _chronicle_id_for_source(state, str(record["subject_id"]))
	if source_type == SOURCE_CONSEQUENCE or source_type == SOURCE_DIVINE:
		# The condition that was pressing on the place when it happened. This is
		# what turns "Mara asked the King for aid" into part of a famine's story
		# rather than an isolated conversation.
		return _open_crisis_id(state, str(record["location_id"]))
	# A settlement falling into crisis is usually a root. It has a parent only
	# when the same place was already in a recorded crisis it never left.
	return ""


func _chronicle_id_for_source(state: WorldState, source_record_id: String) -> String:
	if source_record_id.is_empty():
		return ""
	for index in range(state.chronicle.size() - 1, -1, -1):
		var record: Dictionary = state.chronicle[index]
		if str(record["source_record_id"]) == source_record_id:
			return str(record["id"])
	return ""


func _open_crisis_id(state: WorldState, location_id: String) -> String:
	# The most recent recorded crisis in this place that has not been recorded
	# as lifted. Bounded by the reinforcement window so a famine forty years ago
	# does not adopt today's conversation as its child.
	if location_id.is_empty():
		return ""
	for index in range(state.chronicle.size() - 1, -1, -1):
		var record: Dictionary = state.chronicle[index]
		if str(record["location_id"]) != location_id:
			continue
		if state.year - int(record["year"]) > REINFORCEMENT_WINDOW:
			return ""
		if str(record["event_type"]) == "crisis_lifted":
			return ""
		if str(record["event_type"]) == "crisis_entered":
			return str(record["id"])
	return ""


# --- helpers ---------------------------------------------------------------

func _band_label(band: String, value: int) -> String:
	match band:
		"food":
			return WorldState.FOOD_LABELS[clampi(value, 0, WorldState.FOOD_LABELS.size() - 1)]
		"stability":
			return WorldState.STABILITY_LABELS[clampi(value, 0, WorldState.STABILITY_LABELS.size() - 1)]
		"prosperity":
			return WorldState.PROSPERITY_LABELS[clampi(value, 0, WorldState.PROSPERITY_LABELS.size() - 1)]
	return str(value)


func _condition_summary(
	state: WorldState, location_id: String, band: String, was: int, now: int
) -> String:
	# States the condition and the direction. No blame, no cause, no relief.
	return "%s's %s fell from %s to %s" % [
		state.location_name(location_id), band, _band_label(band, was), _band_label(band, now)
	] if now < was else "%s's %s rose from %s to %s" % [
		state.location_name(location_id), band, _band_label(band, was), _band_label(band, now)
	]


func _divine_summary(state: WorldState, record: Dictionary, changes: Array) -> String:
	# Names the intervention as an objective occurrence. The god acting IS an
	# objective fact of the world — the engine knows it happened — and saying so
	# here is not the same as saying what it meant to anybody. No mortal reads
	# this record; it is the chronicle's own view.
	var place := state.location_name(str(record["target_id"]))
	if changes.is_empty():
		return "Divine intervention in %s changed nothing that could be measured" % place
	var moved: Array[String] = []
	for change_value in changes:
		var change: Dictionary = change_value
		moved.append("%s %s to %s" % [
			str(change["field"]),
			_band_label(str(change["field"]), int(change["before"])),
			_band_label(str(change["field"]), int(change["after"]))
		])
	return "Divine intervention in %s moved %s" % [place, ", ".join(moved)]


func _interpretation_summary(
	state: WorldState, record: Dictionary, effect: Dictionary
) -> String:
	# What the reading DID, never that the reading was right. "Mara's reading of
	# the rain changed how she regards the King" is objective; "the rain was a
	# sign" is hers, and stays in her interpretation record.
	var who := _name_of(state, str(record["observer_id"]))
	if effect.is_empty():
		return "%s's reading of %s went on to shape what they wanted" % [
			who, str(record["topic"])
		]
	return "%s's reading of %s moved their %s toward %s into %s" % [
		who, str(record["topic"]), str(effect["axis"]),
		_name_of(state, str(effect["target_id"])),
		PresentationRules.relationship_label(str(effect["axis"]), int(effect["after"]))
	]


# The occurrence as the consequence layer stated it. Objective by construction:
# that layer is forbidden from writing a judgement, so history inherits its
# plainness for free rather than re-describing the event.
func _claim_of(record: Dictionary) -> String:
	var fact: Dictionary = record.get("pending_fact", {})
	if not fact.is_empty():
		return str(fact.get("claim", ""))
	return str(record.get("claim", ""))


func _crosses_band(effect: Dictionary) -> bool:
	var axis := str(effect["axis"])
	var before := PresentationRules.relationship_label(axis, int(effect["before"]))
	var after := PresentationRules.relationship_label(axis, int(effect["after"]))
	return not before.is_empty() and before != after


func _is_notable(state: WorldState, entity_id: String) -> bool:
	return not entity_id.is_empty() and state.notable_entities.has(entity_id)


func _name_of(state: WorldState, entity_id: String) -> String:
	var entity := state.get_notable_entity(entity_id)
	return str(entity.get("name", entity_id)) if not entity.is_empty() else entity_id


func _names(state: WorldState, actor_id: String, target_id: String) -> String:
	var parts: Array[String] = []
	for entity_id: String in [actor_id, target_id]:
		if _is_notable(state, entity_id):
			parts.append(_name_of(state, entity_id))
	return ", ".join(parts)


func _home_of(state: WorldState, entity_id: String) -> String:
	return state.get_home_location(entity_id) if not entity_id.is_empty() else ""


func _is_uncommon(state: WorldState, result_type: String) -> bool:
	# Rare against what this world has actually produced, not against a list
	# somebody guessed at. A refusal among many acceptances is worth recording;
	# in a world of constant refusals it would not be.
	var total := 0
	var matching := 0
	for record_value in state.consequence_archive:
		var record: Dictionary = record_value
		if str(record["source_type"]) != "execution":
			continue
		total += 1
		if str(record["result_type"]) == result_type:
			matching += 1
	if total < 8:
		return false
	return float(matching) / float(total) <= UNCOMMON_SHARE


# Has this place already crossed this threshold, in this direction, in this
# band, within living memory? Read from the chronicle itself, so the rule is
# about what history already holds rather than about a counter kept for it.
func _same_transition_recently(
	state: WorldState, location_id: String, band: String, event_type: String
) -> bool:
	for index in range(state.chronicle.size() - 1, -1, -1):
		var record: Dictionary = state.chronicle[index]
		if state.year - int(record["year"]) > REINFORCEMENT_WINDOW:
			return false
		if str(record["location_id"]) != location_id:
			continue
		if str(record["event_type"]) != event_type:
			continue
		# The band is carried in the source id: "<place>_<year>_<band>".
		if str(record["source_record_id"]).ends_with("_%s" % band):
			return true
	return false


func _was_recently_recorded(state: WorldState, location_id: String, band: String) -> bool:
	for index in range(state.chronicle.size() - 1, -1, -1):
		var record: Dictionary = state.chronicle[index]
		if state.year - int(record["year"]) > REINFORCEMENT_WINDOW:
			return false
		if str(record["location_id"]) == location_id \
			and str(record["source_record_id"]).ends_with("_%s" % band):
			return true
	return false


func _intent_feedback_types() -> Array[String]:
	var types: Array[String] = []
	for key_value in IntentRules.INTENT_INTERPRETATION_RULES.keys():
		var reading := str(key_value)
		var rule: Dictionary = IntentRules.INTENT_INTERPRETATION_RULES[reading]
		# Only readings that actually weight something. A registered reading
		# worth nothing changes no behaviour and earns no history.
		if not rule.is_empty():
			types.append(reading)
	return types
