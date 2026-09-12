class_name PresentationRules
extends RefCounted

# One-way presentation: NUMBER -> LABEL. Nothing here may be read back into
# simulation logic, and nothing here mutates state. Developer Mode deliberately
# bypasses this file and renders raw values instead.
#
# Bands are inclusive upper bounds, listed low to high, and must end at 100.

const TRUST_BANDS := [
	{"max": 14, "label": "None"},
	{"max": 34, "label": "Low"},
	{"max": 54, "label": "Cautious"},
	{"max": 74, "label": "Strong"},
	{"max": 100, "label": "Deep"}
]

const FEAR_BANDS := [
	{"max": 9, "label": "Almost none"},
	{"max": 29, "label": "Uneasy"},
	{"max": 49, "label": "Afraid"},
	{"max": 74, "label": "Strong fear"},
	{"max": 100, "label": "Terrified"}
]

const RESPECT_BANDS := [
	{"max": 14, "label": "None"},
	{"max": 34, "label": "Limited"},
	{"max": 54, "label": "Moderate"},
	{"max": 74, "label": "High"},
	{"max": 100, "label": "Revered"}
]

const HOSTILITY_BANDS := [
	{"max": 9, "label": "Almost none"},
	{"max": 29, "label": "Resentful"},
	{"max": 49, "label": "Hostile"},
	{"max": 74, "label": "Deep hatred"},
	{"max": 100, "label": "Mortal enemy"}
]

const FAITH_BANDS := [
	{"max": 9, "label": "Absent"},
	{"max": 24, "label": "Weak"},
	{"max": 44, "label": "Growing"},
	{"max": 64, "label": "Strong"},
	{"max": 84, "label": "Devout"},
	{"max": 100, "label": "Dominant"}
]

# How sure the mortal feels. Never a statement about whether they are right.
const CONFIDENCE_BANDS := [
	{"max": 19, "label": "Barely credits it"},
	{"max": 39, "label": "Unsure"},
	{"max": 59, "label": "Leans toward it"},
	{"max": 79, "label": "Fairly sure"},
	{"max": 94, "label": "Certain of it"},
	{"max": 100, "label": "Absolutely convinced"}
]

const AXIS_BANDS := {
	"trust": TRUST_BANDS,
	"fear": FEAR_BANDS,
	"respect": RESPECT_BANDS,
	"hostility": HOSTILITY_BANDS
}

const VALUE_MIN := 0
const VALUE_MAX := 100


static func trust_label(value: int) -> String:
	return label_for(value, TRUST_BANDS)


static func fear_label(value: int) -> String:
	return label_for(value, FEAR_BANDS)


static func respect_label(value: int) -> String:
	return label_for(value, RESPECT_BANDS)


static func hostility_label(value: int) -> String:
	return label_for(value, HOSTILITY_BANDS)


static func faith_label(value: int) -> String:
	return label_for(value, FAITH_BANDS)


static func confidence_label(value: int) -> String:
	return label_for(value, CONFIDENCE_BANDS)


static func relationship_label(axis: String, value: int) -> String:
	if not AXIS_BANDS.has(axis):
		return ""
	return label_for(value, AXIS_BANDS[axis])


# How much water is in the ground, in words. The simulation decides the STATE
# (see `WorldState.water_state`); this only decides what to call it, and the
# exact number stays in Developer Mode like every other raw value.
const WATER_LABELS := {
	"dry": "Dry",
	"normal": "Stable",
	"wet": "Wet",
	"saturated": "Saturated",
	"flooded": "Flooded"
}


const ABUNDANCE_LABELS := {
	"ordinary": "Ordinary",
	"abundant": "Abundant",
	"extraordinary": "Extraordinary",
	"sustained_extraordinary": "Unfailing"
}


static func abundance_label(abundance_state: String) -> String:
	return str(ABUNDANCE_LABELS.get(abundance_state, abundance_state.capitalize()))


static func water_label(water_state: String) -> String:
	return str(WATER_LABELS.get(water_state, water_state.capitalize()))


static func label_for(value: int, bands: Array) -> String:
	# Out-of-range values clamp rather than falling through to an empty label.
	var clamped := clampi(value, VALUE_MIN, VALUE_MAX)
	for band: Dictionary in bands:
		if clamped <= int(band["max"]):
			return str(band["label"])
	return str(bands[bands.size() - 1]["label"])


# --- historical presentation -------------------------------------------------
#
# History is structured like an archive underneath and presented like a
# chronicle on the surface. This is the surface, and it is deliberately small:
# a strength band and a restrained title, both derived from fields the record
# already holds. No prose is generated, nothing is invented, and the objective
# summary remains available underneath for any view that wants the plain fact.
#
# THE ABSOLUTE RULE: exaggeration may amplify presentation; it may NEVER
# fabricate causality. Nothing here may say a flood was punishment, a harvest
# was mercy, a settlement deserved anything, or that any act was intended,
# deserved, foretold or judged. Those are mortal accounts and belong to the
# interpretation and belief layers, where they can be disagreed with. A test
# greps every string this file can produce for that vocabulary.

const HISTORY_MUNDANE := "mundane"
const HISTORY_NOTABLE := "notable"
const HISTORY_MAJOR := "major"
const HISTORY_LEGENDARY := "legendary"

# Presentation strength follows the record's own importance. The quiet entries
# are what make the loud ones land, so most history is mundane on purpose.
const HISTORY_STRENGTH_BANDS := [
	{"max": 59, "label": HISTORY_MUNDANE},
	{"max": 79, "label": HISTORY_NOTABLE},
	{"max": 99, "label": HISTORY_MAJOR},
	{"max": 100000, "label": HISTORY_LEGENDARY}
]

# Titles by what OBJECTIVELY happened. A type with no entry has no title, and
# the caller shows the record's plain summary instead — which is the honest
# default rather than a gap.
const HISTORY_TITLES := {
	"crisis_entered": "THE HARD YEARS IN %s",
	"crisis_lifted": "THE RECOVERY OF %s",
	"divine_action": "THE HAND OF GOD OVER %s"
}


static func history_strength(importance: int) -> String:
	for band: Dictionary in HISTORY_STRENGTH_BANDS:
		if importance <= int(band["max"]):
			return str(band["label"])
	return HISTORY_LEGENDARY


# A title only where the record is strong enough to carry one. A mundane year
# gets no headline: it is a line of history, not an event in a legend.
static func history_title(event_type: String, place_name: String, importance: int) -> String:
	if history_strength(importance) == HISTORY_MUNDANE:
		return ""
	if not HISTORY_TITLES.has(event_type):
		return ""
	if place_name.is_empty():
		return ""
	return str(HISTORY_TITLES[event_type]) % place_name.to_upper()


# A Personal Chronicle is told closer in than world history: it is one life
# rather than one world, so its register is intimate rather than monumental.
# Same absolute rule, though — these state what the record holds and nothing
# about why, whose fault it was, or what it meant.
const PERSONAL_TITLES := {
	"interpretation_took_effect": "WHAT %s CAME TO THINK",
	"request_accepted": "AN UNDERSTANDING WITH %s",
	"request_refused": "A REFUSAL BETWEEN %s AND ANOTHER",
	"support_expressed": "%s STOOD WITH ANOTHER"
}


static func personal_title(event_type: String, person_name: String, importance: int) -> String:
	if history_strength(importance) == HISTORY_MUNDANE:
		return ""
	if not PERSONAL_TITLES.has(event_type):
		return ""
	if person_name.is_empty():
		return ""
	return str(PERSONAL_TITLES[event_type]) % person_name.to_upper()


# --- belief turning points ---------------------------------------------------
#
# What a conviction changing sounds like, said from the holder's side.
#
# Built from exactly two facts the record holds — which proposition, and which
# transition — plus the name of whoever or wherever it concerns. There is
# nowhere for a motive to enter: the tables below contain no "because", no cause
# and no judgement, and a test greps every sentence they can produce. The record
# knows that a belief became established; it does not know why, and neither may
# this.
const BELIEF_PHRASES := {
	"divine_intervention_exists": "that something answers",
	"divine_help_follows_need": "that help arrives when it is needed",
	"home_is_unsafe": "that home stood in danger",
	"conditions_are_improving": "that conditions were improving",
	"is_supportive": "that %s stood with them",
	"is_unreliable": "that %s could not be relied on",
	"place_is_favoured": "that %s was favoured"
}

const BELIEF_TRANSITIONS := {
	"established": "%s became convinced %s.",
	"weakening": "%s began to doubt %s.",
	"steadied": "%s was sure again %s.",
	"lapsed": "%s no longer held %s."
}


static func belief_sentence(
	proposition: String, transition: String, holder_name: String, subject_name: String
) -> String:
	if not BELIEF_PHRASES.has(proposition) or not BELIEF_TRANSITIONS.has(transition):
		return ""
	var phrase := str(BELIEF_PHRASES[proposition])
	if phrase.contains("%s"):
		if subject_name.is_empty():
			return ""
		phrase = phrase % subject_name
	return str(BELIEF_TRANSITIONS[transition]) % [holder_name, phrase]


# --- topics in words ---------------------------------------------------------
#
# Topic ids are simulation vocabulary: `food_shortage` is how the code refers to
# a settlement running short, and it has no business appearing in a sentence
# anybody reads. Summaries were printing them raw, so history said "The King's
# reading of food_shortage" — technically true and plainly an id leak.
#
# The fallback matters as much as the table: an unregistered topic loses its
# underscores rather than arriving intact, so a topic added later reads
# awkwardly at worst and never leaks a literal id.
const TOPIC_PHRASES := {
	"food_shortage": "the shortage",
	"danger_unrest": "the unrest",
	"surplus": "the surplus",
	"weather_rain": "the rain",
	"flooding": "the flood",
	"water_saturation": "the sodden ground",
	"harvest_yield": "the harvest",
	"extraordinary_harvest": "the unfailing fields",
	"mortal_speech": "what was said",
	"request_accepted": "the agreement",
	"request_refused": "the refusal",
	"support_given": "the support offered",
	"opposition_given": "the opposition"
}


static func topic_phrase(topic: String) -> String:
	if topic.is_empty():
		return "what had happened"
	if TOPIC_PHRASES.has(topic):
		return str(TOPIC_PHRASES[topic])
	return topic.replace("_", " ")


# --- physical condition -------------------------------------------------------
#
# One number underneath, a word on the surface. Raw damage is Developer Mode's;
# the player is told how somebody is, not what they score.
const PHYSICAL_LABELS := {
	"healthy": "Unhurt",
	"hurt": "Hurt",
	"seriously_injured": "Seriously injured",
	"critical": "Gravely injured",
	"dead": "Dead"
}

# What a change of physical state sounds like. States the transition and stops:
# there is no anatomy here to describe, so nothing may describe one.
const PHYSICAL_SENTENCES = {
	"hurt": "%s was hurt.",
	"seriously_injured": "%s was seriously injured.",
	"critical": "%s was gravely injured.",
	"dead": "%s died."
}


static func physical_label(condition: String) -> String:
	return str(PHYSICAL_LABELS.get(condition, condition.replace("_", " ")))


static func physical_sentence(condition: String, person_name: String) -> String:
	if person_name.is_empty() or not PHYSICAL_SENTENCES.has(condition):
		return ""
	return str(PHYSICAL_SENTENCES[condition]) % person_name


# --- occurrence subjects ------------------------------------------------------
#
# What an occurrence was about, said in words. A place needs no "in": the
# settlement IS the subject. A person does, because where it happened to them
# is a separate fact and the sentence loses it otherwise.
static func occurrence_subject_phrase(
	subject_type: String, subject_name: String, location_name: String
) -> String:
	if subject_name.is_empty():
		return ""
	if subject_type != WorldState.SUBJECT_PERSON:
		return subject_name
	if location_name.is_empty() or location_name == subject_name:
		return subject_name
	return "%s in %s" % [subject_name, location_name]
