class_name FeedbackRules
extends RefCounted

# Situational Choices & Theatrical Feedback v1 — what the player is told, and how.
#
# The simulation had grown deeper than the game could show. Mortals reached
# conclusions, formed convictions, drifted apart and changed their minds, and
# almost none of it reached the screen: a migrated divine act reported one flat
# sentence and the year turned. The depth existed only in Developer Mode.
#
# The rule this layer exists to serve:
#
#   Hide machinery, not drama.
#
# Exact trust values, belief arithmetic, intent weights and interpretation
# scores stay where they were. What a mortal CONCLUDED, what they came to
# believe, what changed between two people — that is drama, and the player is
# God rather than a detective.
#
# What this layer is NOT:
#
#   - not a second decision engine. It reads records the simulation already
#     wrote and decides only what to show and how to word it. It changes no
#     state, and a test asserts a full year of feedback leaves the world byte
#     for byte identical
#   - not a second history. It may READ the Chronicle to judge significance, and
#     it writes nothing back. Chronicle asks "was this historically important";
#     this asks "should the player notice it now", and the two may disagree
#   - not a generator. Every line comes from a deterministic template chosen by
#     simulation state. There is no randomness and no free prose: a line the
#     state does not support must not exist
#   - not omniscience. An unperceived event, a raw score and a truth flag are
#     all still invisible

const PRIORITY_HIGH := 3
const PRIORITY_MEDIUM := 2
const PRIORITY_LOW := 1

# The three voices of GDD section 97. Presentation categories, not mechanics.
#
#   CHARACTER    one mortal's own words, grounded in their own reading
#   CHRONICLER   short narration of a development
#   WORLD        collective texture — crowds, sayings, what people repeat
const VOICE_CHARACTER := "character"
const VOICE_CHRONICLER := "chronicler"
const VOICE_WORLD := "world"

# A year shows a handful of things or it shows nothing. A wall of text is the
# Developer Mode this layer exists to avoid, and a quiet year must be allowed to
# stay quiet — the contrast is what makes a loud one land.
const MAX_DEVELOPMENTS := 3

# What one mortal says when they have reached a particular conclusion.
#
# Keyed by interpretation type, so the mapping is generic: no mortal is written
# as the believer and no mortal as the sceptic, and which of them says which
# line is decided entirely by which reading each of them actually reached.
#
# Short on purpose. "He heard us." carries more than a paragraph would, and a
# conclusion with no line here simply produces no speech rather than an invented
# one.
const CHARACTER_LINES := {
	"rain_divine_help": "He heard us.",
	"rain_divine_favour": "Somebody is being favoured. It is not us.",
	"rain_natural_weather": "Rain is rain.",
	"home_is_in_danger": "This place cannot hold much longer.",
	"shortage_will_pass": "We have seen lean years before.",
	"home_is_recovering": "We came through it.",
	"surplus_is_ordinary_luck": "A good year. They happen.",
	"elsewhere_is_struggling": "They are going hungry over there.",
	"elsewhere_is_unstable": "That place is coming apart.",
	"instability_is_an_opening": "There is room to move now.",
	"unrest_will_settle": "Tempers are short. It passes.",
	"refusal_unwilling_to_help": "Again he turns us away.",
	"refusal_confirms_distrust": "I expected nothing else.",
	"refusal_had_their_reasons": "Perhaps he could not.",
	"refusal_being_pressured": "I am asked for more than I have.",
	"refusal_gave_the_only_answer": "There was no other answer to give.",
	"acceptance_willing_to_help": "They did not have to say yes.",
	"acceptance_confirms_trust": "I was right to ask.",
	"acceptance_took_on_a_burden": "It falls to me, then.",
	"support_stood_with_me": "They stood with me.",
	"support_tied_myself_to_them": "I have tied myself to them now.",
	"opposition_stood_against_me": "They stood against me.",
	"opposition_from_a_rival": "That is who they are.",
	"opposition_said_what_i_had_to": "It had to be said.",
	"unclear_what_happened": "I do not know what to make of it.",
	"ground_cannot_take_more": "The ground cannot take any more.",
	"elsewhere_is_waterlogged": "They have had more rain than they can use.",
	"flood_is_disaster": "The water has taken everything.",
	"flood_divine_excess": "Enough. Why will it not stop?",
	"elsewhere_is_flooded": "That whole place is under water.",
	"harvest_is_good_fortune": "A good season. They happen.",
	"harvest_divine_help": "The fields gave more than they hold.",
	"yield_is_beyond_explanation": "This is not what the land does.",
	"harvest_divine_favour": "Something has settled on this place.",
	"elsewhere_had_a_good_year": "They brought in a good harvest.",
	"elsewhere_is_thriving": "They are doing far better than we are."
}

# Which conclusions are worth interrupting the player for. The rest are real and
# recorded, and simply not news.
const NOTABLE_INTERPRETATIONS := [
	"rain_divine_help", "rain_divine_favour", "home_is_in_danger",
	"home_is_recovering", "refusal_unwilling_to_help", "refusal_confirms_distrust",
	"instability_is_an_opening", "opposition_stood_against_me",
	"flood_is_disaster", "flood_divine_excess", "ground_cannot_take_more",
	"harvest_divine_help", "harvest_divine_favour", "yield_is_beyond_explanation"
]

# What a belief reads as once somebody holds it. Plain sentences: the player
# should learn what a mortal now accepts, never the number behind it.
const BELIEF_SENTENCES = {
	"divine_intervention_exists": "%s now believes that something answers when the world is desperate.",
	"divine_help_follows_need": "%s now believes help arrives when the need is greatest.",
	"is_supportive": "%s now believes %s can be relied upon.",
	"is_unreliable": "%s no longer believes %s can be relied upon.",
	"place_is_favoured": "%s now believes %s is being favoured over other places.",
	"home_is_unsafe": "%s now believes this place cannot keep them safe.",
	"conditions_are_improving": "%s now believes the worst has passed."
}

const BELIEF_LOST_SENTENCES = {
	"divine_intervention_exists": "%s is no longer sure anything answers.",
	"divine_help_follows_need": "%s is no longer sure that help follows need.",
	"is_supportive": "%s is no longer sure %s can be relied upon.",
	"is_unreliable": "%s is no longer certain %s will fail them.",
	"place_is_favoured": "%s is no longer sure %s is favoured at all.",
	"home_is_unsafe": "%s is no longer certain this place is unsafe.",
	"conditions_are_improving": "%s is no longer sure the worst has passed."
}

# How a mortal act reads as a phrase. The verb stays one of the seven
# primitives; only its wording changes with who and what it is about.
const ACTION_PHRASES := {
	"ask": "Ask %s",
	"tell": "Tell %s",
	"support": "Stand with %s",
	"oppose": "Object to %s",
	"observe": "Watch %s",
	"give": "Offer %s something",
	"wait": "Wait"
}

# What a topic is ABOUT, in words. Used to finish a situational phrase without
# inventing a subject the simulation does not hold.
const TOPIC_PHRASES := {
	"food_shortage": "about the shortage in %s",
	"danger_unrest": "about the unrest in %s",
	"surplus": "about the harvest in %s",
	"weather_rain": "about the rain over %s",
	"request_refused": "about the refusal",
	"request_accepted": "about the agreement",
	"support_given": "about who stood with whom",
	"opposition_given": "about the objection"
}


# --- situational choice labels ---------------------------------------------

# One action record, phrased for a person to read.
#
# The primitive vocabulary stays seven verbs. What changes is the sentence: the
# same `ask` is "Ask the King for help with Westfield's shortage" the first time
# and "Ask the King again" once the record shows it has been asked before.
#
# Everything in the phrase comes from the action record and the world it names.
# No subject is invented, and a verb whose parameters say nothing extra reads
# plainly rather than being dressed up.
func label_for_action(state: WorldState, action: Dictionary) -> String:
	if action.is_empty():
		return ""
	var action_type := str(action.get("action_type", ""))
	var actor_id := str(action.get("actor_id", ""))
	var target_id := str(action.get("target_id", ""))
	var topic_id := str(action.get("topic_id", ""))
	var subject_id := str(action.get("subject_id", ""))

	if action_type == "wait":
		return "Wait"
	var template := str(ACTION_PHRASES.get(action_type, "%s"))
	if target_id.is_empty():
		return template % "no one"
	var phrase := template % _name_of(state, target_id)

	# What it is about, if the record says. `subject_id` may name a settlement
	# or a person depending on the topic, so it is resolved rather than assumed.
	var about := _topic_phrase(state, topic_id, subject_id)
	if not about.is_empty():
		phrase += " " + about

	# And whether this has happened before between these two. Only counted when
	# the record shows it: no arbitrary stages, no escalation the history does
	# not support.
	var repeats := repeated_attempts(state, actor_id, target_id, action_type)
	if repeats >= 3:
		phrase += ", as before"
	elif repeats >= 1:
		phrase += " again"
	return phrase + "."


# How many times this actor has already tried this verb on this target. Read
# from the execution archive, so it is real history rather than a counter kept
# for presentation.
func repeated_attempts(
	state: WorldState, actor_id: String, target_id: String, action_type: String
) -> int:
	var seen := 0
	for record: Dictionary in state.execution_archive:
		if str(record["actor_id"]) == actor_id \
			and str(record["target_id"]) == target_id \
			and str(record["action_type"]) == action_type:
			seen += 1
	return seen


func _topic_phrase(state: WorldState, topic_id: String, subject_id: String) -> String:
	if topic_id.is_empty() or not TOPIC_PHRASES.has(topic_id):
		return ""
	var template := str(TOPIC_PHRASES[topic_id])
	if not template.contains("%s"):
		return template
	if subject_id.is_empty():
		return ""
	return template % _name_of(state, subject_id)


# --- the year's developments -----------------------------------------------

# What the player should be told about the year that just passed.
#
# Reads this year's records, scores each candidate into a priority class, and
# returns at most MAX_DEVELOPMENTS of the highest. Nothing is written anywhere.
func developments(state: WorldState) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	candidates.append_array(_water_developments(state))
	candidates.append_array(_abundance_developments(state))
	candidates.append_array(_history_developments(state))
	candidates.append_array(_belief_developments(state))
	candidates.append_array(_relationship_developments(state))
	candidates.append_array(_social_developments(state))
	candidates.append_array(_reaction_developments(state))

	# Deterministic: priority first, then the order they were gathered. No
	# randomness anywhere in this file.
	#
	# One line per subject per category. A settlement whose food AND prosperity
	# both collapsed in the same year is ONE crisis to a person living through
	# it, and printing it twice is the cosmetic variety this layer is supposed
	# to avoid.
	var ordered: Array[Dictionary] = []
	var seen: Array[String] = []
	for level in [PRIORITY_HIGH, PRIORITY_MEDIUM, PRIORITY_LOW]:
		for candidate: Dictionary in candidates:
			if int(candidate["priority"]) != level:
				continue
			var key := "%s|%s|%s" % [
				str(candidate["category"]), str(candidate["actor_id"]),
				str(candidate["target_id"])
			]
			if key in seen:
				continue
			seen.append(key)
			ordered.append(candidate)
	if ordered.size() > MAX_DEVELOPMENTS:
		ordered = ordered.slice(0, MAX_DEVELOPMENTS)
	return ordered


# HIGH. Whatever the Chronicle already judged worth remembering is, by
# definition, worth the player noticing. Read only — nothing is written back,
# and the Chronicle's own selection is untouched.
# HIGH. What the ground itself has become. A settlement crossing into
# saturation or flood is the clearest possible statement that a force has been
# applied past the point of helping, and the player should not have to infer it.
#
# Read from the world's own condition, so a place that floods without any god
# involved reads exactly the same.
func _water_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	# Read from the crossings the world recorded when they happened, not from
	# the level now: the ground drains a little every year, so a flood reached
	# at the moment of the rain may already read as merely saturated by the time
	# anybody looks. A settlement that has simply been under water for years
	# crosses nothing and is not news again.
	for event_value in state.last_water_events:
		var event: Dictionary = event_value
		var location_id := str(event["location_id"])
		var water_state := str(event["water_state"])
		if water_state not in [WorldState.WATER_SATURATED, WorldState.WATER_FLOODED]:
			continue
		var place := state.location_name(location_id)
		var flooded := water_state == WorldState.WATER_FLOODED
		found.append(_item(state, {
			"priority": PRIORITY_HIGH,
			"category": "water_%s" % water_state,
			"voice": VOICE_CHRONICLER,
			"headline": "FLOODING IN %s" % place.to_upper() if flooded
				else "%s IS SATURATED" % place.to_upper(),
			"body": "Water is standing where the fields used to be." if flooded
				else "The ground can take no more.",
			"source_record_type": "settlement_water",
			"source_record_id": "%s_water" % location_id,
			"actor_id": location_id,
			"context": {"water_state": water_state, "newly_reached": true}
		}))
	return found


# HIGH. A settlement whose output has stopped looking like something its land
# could do. The counterpart of the water crossings, and deliberately not
# phrased as a warning: abundance is not a countdown to disaster.
func _abundance_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for event_value in state.last_abundance_events:
		var event: Dictionary = event_value
		var location_id := str(event["location_id"])
		var abundance_state := str(event["abundance_state"])
		if abundance_state not in [
			WorldState.ABUNDANCE_EXTRAORDINARY, WorldState.ABUNDANCE_SUSTAINED
		]:
			continue
		var place := state.location_name(location_id)
		var sustained := abundance_state == WorldState.ABUNDANCE_SUSTAINED
		found.append(_item(state, {
			"priority": PRIORITY_HIGH,
			"category": "abundance_%s" % abundance_state,
			"voice": VOICE_CHRONICLER,
			"headline": "THE FIELDS OF %s DO NOT FAIL" % place.to_upper() if sustained
				else "AN IMPOSSIBLE HARVEST IN %s" % place.to_upper(),
			"body": "Year after year, more comes in than the land should give." if sustained
				else "The stores are fuller than the fields can account for.",
			"source_record_type": "settlement_abundance",
			"source_record_id": "%s_abundance" % location_id,
			"actor_id": location_id,
			"context": {"abundance_state": abundance_state, "newly_reached": true}
		}))
	return found


func _history_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.last_chronicle_entries:
		var record: Dictionary = record_value
		var event_type := str(record["event_type"])
		var headline := ""
		match event_type:
			"crisis_entered":
				headline = "%s — CRISIS" % state.location_name(str(record["location_id"])).to_upper()
			"crisis_lifted":
				headline = "%s RECOVERS" % state.location_name(str(record["location_id"])).to_upper()
			"divine_action":
				headline = "THE WORLD ANSWERS"
			_:
				continue
		found.append(_item(state, {
			"priority": PRIORITY_HIGH,
			"category": event_type,
			"voice": VOICE_CHRONICLER,
			"headline": headline,
			"body": str(record["summary"]),
			"source_record_type": "chronicle",
			"source_record_id": str(record["id"]),
			"actor_id": str(record["location_id"]),
			"context": {"chronicle_importance": int(record["importance"])}
		}))
	return found


# HIGH. A conviction taking hold or coming apart. Only the crossing — the
# arithmetic that got there stays in Developer Mode, and a belief drifting
# within its band is not news.
func _belief_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var threshold := int(BeliefRules.ESTABLISHED_CONFIDENCE)
	for update_value in state.last_belief_updates:
		var update: Dictionary = update_value
		var before := int(update["before"])
		var after := int(update["after"])
		var proposition := str(update["proposition"])
		var holder := _name_of(state, str(update["holder_id"]))
		var subject := _name_of(state, str(update["subject_id"]))
		if before < threshold and after >= threshold:
			found.append(_item(state, {
				"priority": PRIORITY_HIGH,
				"category": "belief_formed",
				"voice": VOICE_CHRONICLER,
				"headline": "A BELIEF TAKES ROOT",
				"body": _belief_sentence(BELIEF_SENTENCES, proposition, holder, subject),
				"source_record_type": "belief",
				"source_record_id": str(update["belief_id"]),
				"actor_id": str(update["holder_id"]),
				"target_id": str(update["subject_id"]),
				"context": {"crossed_held_threshold": true, "belief_held": true}
			}))
		elif before >= threshold and after < threshold:
			found.append(_item(state, {
				"priority": PRIORITY_HIGH,
				"category": "belief_broken",
				"voice": VOICE_CHRONICLER,
				"headline": "DOUBT RETURNS",
				"body": _belief_sentence(BELIEF_LOST_SENTENCES, proposition, holder, subject),
				"source_record_type": "belief",
				"source_record_id": str(update["belief_id"]),
				"actor_id": str(update["holder_id"]),
				"target_id": str(update["subject_id"]),
				"context": {"crossed_held_threshold": true, "belief_held": false}
			}))
	return found


# HIGH. Only a crossing of an existing presentation band, which is the point at
# which a relationship stops being the same relationship. A movement of one or
# two inside a band is noise and must never be announced.
func _relationship_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for change_value in state.last_relationship_changes:
		var change: Dictionary = change_value
		var before: Dictionary = change["before"]
		var after: Dictionary = change["after"]
		for axis: String in WorldState.RELATIONSHIP_AXES:
			var was := PresentationRules.relationship_label(axis, int(before.get(axis, 0)))
			var now := PresentationRules.relationship_label(axis, int(after.get(axis, 0)))
			if was.is_empty() or was == now:
				continue
			var rising := int(after.get(axis, 0)) > int(before.get(axis, 0))
			found.append(_item(state, {
				"priority": PRIORITY_HIGH,
				"category": "relationship_band_crossed",
				"voice": VOICE_CHRONICLER,
				"headline": "%s & %s" % [
					_name_of(state, str(change["source_id"])).to_upper(),
					_name_of(state, str(change["target_id"])).to_upper()
				],
				"body": _relationship_sentence(
					state, str(change["source_id"]), str(change["target_id"]), axis, rising
				),
				"source_record_type": "relationship",
				"source_record_id": str(change["relationship_id"]),
				"actor_id": str(change["source_id"]),
				"target_id": str(change["target_id"]),
				"context": {"relationship_band_crossed": true, "axis": axis, "band": now}
			}))
	return found


# MEDIUM. What one mortal asked of another and what came of it, phrased as a
# scene rather than as a result type — and phrased DIFFERENTLY once the archive
# shows it has happened before between these two.
func _social_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.last_executions:
		var record: Dictionary = record_value
		var result_type := str(record["result_type"])
		if result_type not in ["request_refused", "request_accepted"]:
			continue
		var actor_id := str(record["actor_id"])
		var target_id := str(record["target_id"])
		if not _is_notable(state, actor_id) or not _is_notable(state, target_id):
			continue
		var actor := _name_of(state, actor_id)
		var target := _name_of(state, target_id)
		# Prior attempts EXCLUDING this one, so the first refusal reads plainly.
		var repeats := maxi(repeated_attempts(state, actor_id, target_id, str(record["action_type"])) - 1, 0)
		var refused := result_type == "request_refused"
		var headline := ""
		var body := ""
		if refused and repeats >= 2:
			headline = "%s REFUSES — AGAIN" % target.to_upper()
			body = "%s asks no differently, and is answered no differently." % actor
			# Only claim the relationship has changed if it actually has.
			if _holds_unreliable_belief(state, actor_id, target_id):
				body += "\n%s no longer expects his help." % actor
		elif refused:
			headline = "%s REFUSES" % target.to_upper()
			body = "%s's request is denied." % actor
		else:
			headline = "%s AGREES" % target.to_upper()
			body = "%s's request is accepted." % actor
		found.append(_item(state, {
			"priority": PRIORITY_MEDIUM,
			"category": result_type,
			"voice": VOICE_CHRONICLER,
			"headline": headline,
			"body": body,
			"source_record_type": "execution",
			"source_record_id": str(record["id"]),
			"actor_id": actor_id,
			"target_id": target_id,
			"context": {
				"repeated_occurrence": repeats > 0,
				"prior_attempts": repeats,
				"belief_unreliable": _holds_unreliable_belief(state, actor_id, target_id)
			}
		}))
	return found


# MEDIUM. What somebody made of what happened, in their own words. Only
# conclusions worth interrupting for, and only ones with a line written for
# them — an unmapped reading produces silence rather than invention.
func _reaction_developments(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record_value in state.last_interpretations:
		var record: Dictionary = record_value
		var reading := str(record["interpretation_type"])
		if reading not in NOTABLE_INTERPRETATIONS:
			continue
		if not CHARACTER_LINES.has(reading):
			continue
		found.append(_item(state, {
			"priority": PRIORITY_MEDIUM,
			"category": "interpretation",
			"voice": VOICE_CHARACTER,
			"headline": _name_of(state, str(record["observer_id"])).to_upper(),
			"body": "\"%s\"" % str(CHARACTER_LINES[reading]),
			"source_record_type": "interpretation",
			"source_record_id": str(record["id"]),
			"actor_id": str(record["observer_id"]),
			"context": {"interpretation_type": reading}
		}))
	return found


# --- the player's own act --------------------------------------------------

# Immediate feedback for a divine action: what the god did, and what changed,
# in the qualitative language the rest of the player interface uses.
#
# Reads the SHARED-pipeline records. Nothing here consults the legacy reception
# path, and nothing here decides what the act meant.
func divine_feedback(state: WorldState, result: Dictionary) -> Dictionary:
	if result.is_empty() or not bool(result.get("ok", false)):
		return {}
	var record := state.get_divine_action(str(result.get("divine_action_id", "")))
	if record.is_empty():
		return {}
	var location_id := str(record["target_id"])
	var consequence := state.get_consequence(str(record["consequence_id"]))
	var lines: Array[String] = []
	for change_value in consequence.get("state_changes", []):
		var change: Dictionary = change_value
		# Qualitative, matching the rest of the player interface. The exact
		# band numbers stay in Developer Mode.
		lines.append("%s in %s is now %s." % [
			str(change["field"]).capitalize(),
			state.location_name(location_id),
			_band_label(str(change["field"]), int(change["after"])).to_lower()
		])
	# A standing order announces itself once, when it is given. What it does in
	# later years is told by the world crossing thresholds, not by repeating
	# this headline every single year.
	var standing := state.get_intervention(
		state.intervention_id(str(record["action_type"]), location_id)
	)
	if not standing.is_empty() and bool(standing["active"]) \
		and int(standing["started_year"]) == int(record["year"]):
		var duration_line := "It will continue until you command otherwise."
		if str(standing["mode"]) == DivineActionRules.MODE_SUSTAINED:
			duration_line = "It will continue for %d more year(s)." % int(standing["remaining_years"])
		lines.append(duration_line)
		return {
			"headline": "YOU OPEN THE HEAVENS" if str(record["action_type"]) == "send_rain"
				else "YOU BLESS THE FIELDS OF %s" % state.location_name(location_id).to_upper(),
			"body": str(record["result"]),
			"changes": lines,
			"pipeline": str(record["pipeline"]),
			"water_state": state.water_state(location_id)
		}
	# The same power, worded by what it has come to. The escalation is read from
	# the ground rather than from a counter: a first rain on dry soil and a
	# fourth on standing water are the same act and are not the same event.
	var headline := "YOU %s" % str(record["action_type"]).replace("_", " ").to_upper()
	# Blessings escalate by how unfailing the fields have become, and the top of
	# that scale is not a warning: a place that keeps producing is a place that
	# keeps producing.
	var abundance_state := state.abundance_state(location_id)
	if str(record["action_type"]) == "bless_harvest":
		if abundance_state == WorldState.ABUNDANCE_SUSTAINED:
			headline = "THE FIELDS OF %s DO NOT FAIL" % state.location_name(location_id).to_upper()
		elif abundance_state == WorldState.ABUNDANCE_EXTRAORDINARY:
			headline += " — AGAIN"
		lines.append("The yield in %s is %s." % [
			state.location_name(location_id),
			PresentationRules.abundance_label(abundance_state).to_lower()
		])
		return {
			"headline": headline, "body": str(record["result"]), "changes": lines,
			"pipeline": str(record["pipeline"]), "water_state": state.water_state(location_id)
		}
	var water_state := state.water_state(location_id)
	if water_state == WorldState.WATER_FLOODED:
		headline += " — AND THE WATER RISES"
	elif water_state == WorldState.WATER_SATURATED:
		headline += " — AGAIN"
	if not lines.is_empty() or water_state in [
		WorldState.WATER_SATURATED, WorldState.WATER_FLOODED
	]:
		lines.append("The ground in %s is %s." % [
			state.location_name(location_id),
			PresentationRules.water_label(water_state).to_lower()
		])
	return {
		"headline": headline,
		"body": str(record["result"]),
		"changes": lines,
		"pipeline": str(record["pipeline"]),
		"water_state": water_state
	}


# --- helpers ---------------------------------------------------------------

func _item(state: WorldState, fields: Dictionary) -> Dictionary:
	return {
		"year": state.year,
		"priority": int(fields["priority"]),
		"category": str(fields["category"]),
		"voice": str(fields["voice"]),
		"headline": str(fields["headline"]),
		"body": str(fields["body"]),
		"source_record_type": str(fields["source_record_type"]),
		"source_record_id": str(fields["source_record_id"]),
		"actor_id": str(fields.get("actor_id", "")),
		"target_id": str(fields.get("target_id", "")),
		# Why this was surfaced, for Developer Mode. Flags only — no scores.
		"context": (fields.get("context", {}) as Dictionary).duplicate(true)
	}


func _belief_sentence(
	table: Dictionary, proposition: String, holder: String, subject: String
) -> String:
	var template := str(table.get(proposition, "%s has changed their mind."))
	if template.count("%s") >= 2:
		return template % [holder, subject]
	return template % holder


func _relationship_sentence(
	state: WorldState, source_id: String, target_id: String, axis: String, rising: bool
) -> String:
	var source := _name_of(state, source_id)
	var target := _name_of(state, target_id)
	match axis:
		"trust":
			return "%s trusts %s more than before." % [source, target] if rising \
				else "%s's trust in %s is weakening." % [source, target]
		"hostility":
			return "%s is hardening against %s." % [source, target] if rising \
				else "%s's resentment of %s is cooling." % [source, target]
		"fear":
			return "%s has begun to fear %s." % [source, target] if rising \
				else "%s fears %s less than before." % [source, target]
		"respect":
			return "%s thinks better of %s than before." % [source, target] if rising \
				else "%s thinks less of %s than before." % [source, target]
	return "%s regards %s differently now." % [source, target]


# Whether this mortal actually holds the conviction a stronger line would claim.
# Presentation may amplify what is true; it may never assert what is not.
func _holds_unreliable_belief(
	state: WorldState, holder_id: String, subject_id: String
) -> bool:
	var belief := state.get_belief(holder_id, BeliefRules.IS_UNRELIABLE, subject_id)
	if belief.is_empty():
		return false
	return int(belief["confidence"]) >= int(BeliefRules.ESTABLISHED_CONFIDENCE)


func _is_notable(state: WorldState, entity_id: String) -> bool:
	return not entity_id.is_empty() and state.notable_entities.has(entity_id)


func _name_of(state: WorldState, entity_id: String) -> String:
	if entity_id.is_empty():
		return ""
	var entity := state.get_notable_entity(entity_id)
	if not entity.is_empty():
		return str(entity.get("name", entity_id))
	# Not a person: settlements are named too, and a topic's subject may be one.
	var place := state.location_name(entity_id)
	return place if not place.is_empty() else entity_id


func _band_label(band: String, value: int) -> String:
	match band:
		"food":
			return WorldState.FOOD_LABELS[clampi(value, 0, WorldState.FOOD_LABELS.size() - 1)]
		"stability":
			return WorldState.STABILITY_LABELS[clampi(value, 0, WorldState.STABILITY_LABELS.size() - 1)]
		"prosperity":
			return WorldState.PROSPERITY_LABELS[clampi(value, 0, WorldState.PROSPERITY_LABELS.size() - 1)]
	return str(value)
