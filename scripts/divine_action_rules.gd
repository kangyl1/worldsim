class_name DivineActionRules
extends RefCounted

# The one place that says how a divine power enters the world.
#
# Roadmap item 12 migrates the god's powers, one at a time, off a bespoke path
# that decided what its own act meant and onto the same road a mortal act
# travels. Send Rain proved the road works. This file is what stops the second
# migration from being another copy of the first.
#
# The law the road exists to enforce:
#
#   The player decides what God does.
#   The simulation decides what objectively happens.
#   Mortals decide what it means.
#
# so a divine power registers WHAT IT DID and WHAT ANYONE THERE COULD SEE, and
# registers nothing at all about belief, faith, reputation or meaning. There is
# deliberately no field here for any of those: an entry that wanted one would be
# a power deciding its own reception again.

# How an act is handled once it has changed the world.
#
#   PIPELINE_SHARED  act -> consequence -> event -> perception -> knowledge ->
#                    interpretation. Nothing along it decides what the act meant.
#   PIPELINE_LEGACY  `DivineReceptionSystem` reads one collective meaning out of
#                    the act and writes belief, reputation and history from it.
#
# The two must never both run for one power, or the world reacts twice to one
# event. `pipeline_for()` is the only thing in the project that answers which.
const PIPELINE_SHARED := "shared"
const PIPELINE_LEGACY := "legacy"

# HOW STRONGLY. The shared vocabulary, and only the vocabulary — what each level
# actually DOES is the power's own business, converted in its resolver. A shared
# `effect * intensity` multiplier would make every power behave alike, which is
# the opposite of the point: rain converts intensity into water, a blessing into
# abundance, and a future Smite would convert it into destructive force while a
# future Divine Voice might convert it into reach rather than damage.
#
# Four named levels, never a raw number in front of the player. The player
# thinks in divine force; Developer Mode shows the arithmetic.
const INTENSITY_GENTLE := "gentle"
const INTENSITY_NORMAL := "normal"
const INTENSITY_STRONG := "strong"
const INTENSITY_OVERWHELMING := "overwhelming"
const INTENSITIES := [
	INTENSITY_GENTLE, INTENSITY_NORMAL, INTENSITY_STRONG, INTENSITY_OVERWHELMING
]
# What an act is when nobody said otherwise. Existing callers — and every test
# written before this milestone — keep their behaviour through this.
const DEFAULT_INTENSITY := INTENSITY_NORMAL

# HOW LONG. Separate from intensity on purpose: gentle rain forever and
# overwhelming rain once are different histories, and collapsing them into one
# "power" number would lose that.
const MODE_ONCE := "once"
const MODE_SUSTAINED := "sustained"
const MODE_UNTIL_STOPPED := "until_stopped"
const MODES := [MODE_ONCE, MODE_SUSTAINED, MODE_UNTIL_STOPPED]
const DEFAULT_MODE := MODE_ONCE

# How long a finite `sustained` order may run. Small on purpose: indefinite
# intervention is what `until_stopped` is for.
const MIN_SUSTAINED_YEARS := 1
const MAX_SUSTAINED_YEARS := 10

# THE REGISTRATION SURFACE. Migrating a power is: flip its `pipeline` to
# PIPELINE_SHARED, make sure its objective effect writes no belief or faith, and
# optionally design interpretation candidates for its topic later.
#
# `occurrence` is the mortal-facing fact the act leaves behind, and is
# independent of the divine action record. The record says the god caused rain
# in Aster; the occurrence says rain fell on Aster. Mortals get the second one.
# A power with no `occurrence` changes the world silently and offers nobody
# anything to notice, which is a real option and is what silence uses.
#
#   topic          what KIND of occurrence this is. Interpretation keys off it,
#                  and a topic with no candidates designed yet is simply not
#                  interpreted — see `interpretation_rules.gd`
#   claim          one "%s" slot, filled with the settlement's display name.
#                  States the occurrence. Never states a cause, a motive or a
#                  judgement: "Rain fell on Aster", never "God answered Aster"
#   observability  who could notice, in Selective Perception's vocabulary
#   confidence     how firmly someone who was there holds it
const DIVINE_ACTIONS := {
	"send_rain": {
		"pipeline": PIPELINE_SHARED,
		"modes": [MODE_ONCE, MODE_SUSTAINED, MODE_UNTIL_STOPPED],
		"occurrence": {
			"topic": "weather_rain",
			"claim": "Rain fell on %s",
			"observability": "local",
			"confidence": 90
		}
	},
	"bless_harvest": {
		"pipeline": PIPELINE_SHARED,
		"modes": [MODE_ONCE, MODE_SUSTAINED, MODE_UNTIL_STOPPED],
		"occurrence": {
			"topic": "harvest_yield",
			"claim": "%s's fields yielded more than their soil should allow",
			"observability": "local",
			"confidence": 90
		}
	},
	# Smite DESTROYS. It does not kill: Take Life is a separate power and is not
	# built. A smite may one day end lives, but only as a consequence of the
	# destruction, never as its definition — and nothing in the world currently
	# models a life ending, so v1 destroys only what the simulation actually
	# holds.
	#
	# ONE-SHOT ONLY, deliberately, even though the intervention machinery would
	# carry a standing order without complaint. A permanent destructive field
	# raises questions nothing here can answer — is it one strike a year, is it
	# perceived afresh each time, does it ever stop being news — and an
	# unanswered semantic is worse than a missing feature. A sustained smite is
	# REFUSED rather than quietly performed once.
	"smite": {
		"pipeline": PIPELINE_SHARED,
		"modes": [MODE_ONCE],
		"occurrence": {
			"topic": "divine_destruction",
			"claim": "A destructive force struck %s",
			"observability": "local",
			"confidence": 95
		}
	},
	"speak_mortal": {
		"pipeline": PIPELINE_LEGACY,
		"occurrence": {
			"topic": "mortal_speech",
			"claim": "A voice in %s spoke with an unfamiliar certainty",
			"observability": "local",
			"confidence": 90
		}
	},
	# Silence is an act. It costs nothing, changes nothing, and leaves nobody
	# anything to point at — so it registers no occurrence, and the consequence
	# layer records that nothing observable happened.
	"do_nothing": {
		"pipeline": PIPELINE_LEGACY,
		"occurrence": {}
	}
}


# The registered powers, as this instance sees them. DIVINE_ACTIONS above is the
# declared, reviewable table and stays constant; this is the working copy every
# lookup reads, so a power can also be registered at runtime.
#
# That seam exists for ONE reason: it is what lets a test send a power the
# simulation has never heard of down the pipeline and prove no branch anywhere
# names it. It is not a plugin system and should not grow into one — a real
# power belongs in the table above, where it can be read and reviewed.
var actions: Dictionary = DIVINE_ACTIONS.duplicate(true)


# Add or replace a power. `entry` takes the same shape as a DIVINE_ACTIONS
# value: a `pipeline`, and an `occurrence` if the act leaves anything to notice.
func register(action_id: String, entry: Dictionary) -> void:
	if action_id.is_empty():
		return
	actions[action_id] = entry.duplicate(true)


# Which durations this power supports. **Not every power takes every mode**, and
# that is the point of asking the registry rather than assuming: a future Smite
# would list `once` alone, because a sustained smiting is a different design
# question nobody has answered. A power that lists nothing supports `once`.
func modes_for(action_id: String) -> Array[String]:
	var entry: Dictionary = actions.get(action_id, {})
	var declared: Array = entry.get("modes", [MODE_ONCE])
	var supported: Array[String] = []
	for mode_value in declared:
		supported.append(str(mode_value))
	return supported


func supports_mode(action_id: String, mode: String) -> bool:
	return mode in modes_for(action_id)


func is_persistent_mode(mode: String) -> bool:
	return mode == MODE_SUSTAINED or mode == MODE_UNTIL_STOPPED


# Anything unrecognised falls back to the default rather than failing, so a
# stale interface selection cannot strand the player.
func normalise_intensity(intensity: String) -> String:
	return intensity if intensity in INTENSITIES else DEFAULT_INTENSITY


func normalise_mode(action_id: String, mode: String) -> String:
	return mode if supports_mode(action_id, mode) else DEFAULT_MODE


# Asking a power for a duration it does not have is REFUSED, not quietly
# reshaped. `normalise_mode` still exists for callers that name no mode at all
# and get the default; this is for the caller who names one the power cannot do.
#
# The distinction matters most for a one-shot power. Silently turning "smite
# this place every year until I say stop" into a single strike would perform
# something the player did not ask for and hide that it had done so.
func mode_error(action_id: String, mode: String) -> String:
	if mode.is_empty() or supports_mode(action_id, mode):
		return ""
	if mode not in MODES:
		return "That is not a way an act can be carried out."
	return "%s cannot be carried out that way; it happens once or not at all." % action_id


# A finite order must say how long it runs, in range. REJECTED rather than
# clamped: silently turning a 9999-year order into a 10-year one means the
# player asked for one thing and the world quietly did another, and a divine
# sandbox should never do that. `once` and `until_stopped` carry no duration and
# ignore the field.
func is_valid_duration(mode: String, duration_years: int) -> bool:
	if mode != MODE_SUSTAINED:
		return true
	return duration_years >= MIN_SUSTAINED_YEARS and duration_years <= MAX_SUSTAINED_YEARS


func duration_error(mode: String, duration_years: int) -> String:
	if is_valid_duration(mode, duration_years):
		return ""
	return "A sustained act must run between %d and %d years; %d was asked for." % [
		MIN_SUSTAINED_YEARS, MAX_SUSTAINED_YEARS, duration_years
	]


func is_divine_action(action_id: String) -> bool:
	return actions.has(action_id)


# Which road this act takes. The ONE routing decision in the project: no other
# file may branch on an action id to answer it.
#
# An unregistered id answers LEGACY, because legacy is the behaviour that
# already existed and an unknown power must not be quietly granted the new road.
func pipeline_for(action_id: String) -> String:
	var entry: Dictionary = actions.get(action_id, {})
	return str(entry.get("pipeline", PIPELINE_LEGACY))


func is_shared_pipeline(action_id: String) -> bool:
	return pipeline_for(action_id) == PIPELINE_SHARED


# What anyone present could see. Empty when the act leaves nothing to notice.
func occurrence_for(action_id: String) -> Dictionary:
	var entry: Dictionary = actions.get(action_id, {})
	var occurrence: Dictionary = entry.get("occurrence", {})
	return occurrence.duplicate(true)


func has_occurrence(action_id: String) -> bool:
	return not occurrence_for(action_id).is_empty()


func topic_for(action_id: String) -> String:
	return str(occurrence_for(action_id).get("topic", ""))


# Every topic a divine act can put in front of a mortal, migrated or not.
#
# Interpretation asks for this rather than keeping its own hand-written list,
# which would be a second place to remember when a power is added. Registering a
# power is not designing its meaning: a topic appears here the moment the act
# can be seen, and stays uninterpreted until somebody writes candidates for it.
func occurrence_topics() -> Array[String]:
	var topics: Array[String] = []
	var action_ids: Array = actions.keys()
	action_ids.sort()
	for action_id_value in action_ids:
		var topic := topic_for(str(action_id_value))
		if not topic.is_empty() and topic not in topics:
			topics.append(topic)
	return topics


func shared_pipeline_actions() -> Array[String]:
	var migrated: Array[String] = []
	var action_ids: Array = actions.keys()
	action_ids.sort()
	for action_id_value in action_ids:
		var action_id := str(action_id_value)
		if is_shared_pipeline(action_id):
			migrated.append(action_id)
	return migrated
