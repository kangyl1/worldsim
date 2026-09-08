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


static func water_label(water_state: String) -> String:
	return str(WATER_LABELS.get(water_state, water_state.capitalize()))


static func label_for(value: int, bands: Array) -> String:
	# Out-of-range values clamp rather than falling through to an empty label.
	var clamped := clampi(value, VALUE_MIN, VALUE_MAX)
	for band: Dictionary in bands:
		if clamped <= int(band["max"]):
			return str(band["label"])
	return str(bands[bands.size() - 1]["label"])
