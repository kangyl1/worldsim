class_name WorldState
extends RefCounted

const FOOD_LABELS := ["Critical", "Low", "Adequate", "Abundant"]
const STABILITY_LABELS := ["Fractured", "Uneasy", "Stable", "United"]
const PROSPERITY_LABELS := ["Destitute", "Poor", "Modest", "Thriving"]
const MILITARY_LABELS := ["Weak", "Limited", "Capable", "Strong"]
const RELATIONSHIP_AXES := ["trust", "fear", "respect", "hostility"]
const RELATIONSHIP_MIN := 0
const RELATIONSHIP_MAX := 100
const KNOWLEDGE_TRUTH_STATES := ["true", "false", "unknown", "outdated"]
const KNOWLEDGE_CONFIDENCE_MIN := 0
const KNOWLEDGE_CONFIDENCE_MAX := 100
const DEFAULT_KNOWLEDGE_FRESH_YEARS := 3
const MAX_STORED_INTENTS := 40
const MAX_STORED_ACTIONS := 40
const MAX_STORED_EXECUTIONS := 40
const MAX_STORED_PERCEPTIONS := 40
const MAX_STORED_CONSEQUENCES := 40
const MAX_STORED_INTERPRETATIONS := 40
const MAX_STORED_DIVINE_ACTIONS := 40
# How many interpretation ids a belief keeps for inspection. The links explain a
# belief; they are not what makes it one, so a bound costs nothing.
const MAX_BELIEF_SOURCES := 8
# Selective memory (GDD section 36). Social occurrences accumulate one belief per
# interaction, so a mortal cannot carry everything they ever learned. What goes
# first is what could least change their behaviour: retracted claims, then stale
# ones they were never sure of.
const MAX_KNOWLEDGE_PER_ENTITY := 12
# Version 0.1 keeps one region and three settlements, per the GDD prototype
# scope. Locations carry identity only: no statistics are stored here, because
# the simulation still tracks kingdom-wide values. Per-settlement state can be
# added later without the interface changing shape.
# Local conditions a settlement carries. Every one of them exists because a god
# can notice it, understand it, and eventually do something about it. Anything
# that fails those three tests does not belong here, and this list must not grow
# into domain management: settlements are places, not political actors.
const SETTLEMENT_BANDS := ["food", "stability", "prosperity"]

# How much water is in the ground here. The one environmental pressure the
# simulation carries, added for Send Rain and deliberately not generalised: no
# fire, wind or blessing pressure exists, and none should until a power needs it.
#
# This is NOT a hydrology model. There are no rivers, no elevation, no drainage
# and no seasons. It is a single bounded number per settlement that remembers
# how much rain a place has had, so that the same power applied again can mean
# something different from the first time.
const WATER_MIN := 0
const WATER_MAX := 100
# Where an untended settlement settles. Not "correct" — just the level the
# world drifts back toward when nobody interferes.
const WATER_BASELINE := 35

# The qualitative states the number resolves to. SIMULATION semantics, because
# consequences key off them; the player-facing wording lives in
# `presentation_rules.gd`, which maps these ids to labels.
const WATER_DRY := "dry"
const WATER_NORMAL := "normal"
const WATER_WET := "wet"
const WATER_SATURATED := "saturated"
const WATER_FLOODED := "flooded"
const WATER_STATES := [WATER_DRY, WATER_NORMAL, WATER_WET, WATER_SATURATED, WATER_FLOODED]
# Upper bound of each state, in order. Prototype tuning, not final balance.
const WATER_THRESHOLDS := [
	{"state": WATER_DRY, "max": 20},
	{"state": WATER_NORMAL, "max": 50},
	{"state": WATER_WET, "max": 70},
	{"state": WATER_SATURATED, "max": 85},
	{"state": WATER_FLOODED, "max": 100}
]

var year: int = 12
var military_level: int = 0

# Kingdom-wide views of local conditions. Settlements own the truth; these read
# as a population-weighted view of it, and writing one broadcasts to every
# settlement. That keeps a single source of truth while letting the world still
# be described, blessed or ruined as a whole.
var food_level: int:
	get:
		return _weighted_band("food")
	set(value):
		_broadcast_band("food", value)

var stability_level: int:
	get:
		return _weighted_band("stability")
	set(value):
		_broadcast_band("stability", value)

var prosperity_level: int:
	get:
		return _weighted_band("prosperity")
	set(value):
		_broadcast_band("prosperity", value)

# The realm is exactly the people in it. Writing a total spreads the difference
# across settlements in proportion, so nobody can disagree about how many there
# are.
var population: int:
	get:
		var total := 0
		for location_value in locations.values():
			total += int(location_value.get("population", 0))
		return maxi(total, 0)
	set(value):
		_distribute_population(value)
var faith: int = 34
var followers: int = 412
var divine_power: int = 6
var max_divine_power: int = 8
var reputation: String = "Unknown"

var current_event_id: String = "drought"
# Which settlement this year's event is about. Events are local now, and so is
# the divine response to them.
# Set by the seed to the first location that exists, and by the event selector
# every year after. Deliberately not a named settlement: a world assembled
# differently should not have to edit this line.
var current_event_location_id: String = ""
# Where the player last aimed a divine act. Kept apart from the event location
# on purpose: the world decides where events happen, and the god decides where
# to act, and the two need not agree.
var last_divine_target_id: String = ""
# Water thresholds crossed since the player's turn began. Current turn only —
# the ground drifts back a little every year, so a flood reached at the moment
# of the rain may already have eased by the time anything reads the level, and
# the crossing still happened.
var last_water_events: Array[Dictionary] = []
var action_taken: bool = false
var last_result: String = ""
# The POPULACE's reading of a divine act, owned by DivineReceptionSystem. Not
# the mortal interpretation layer: that is `interpretations` below, and the two
# are deliberately separate stores answering different questions.
var last_interpretation: String = ""
var last_interpretation_id: String = ""
var population_growth_bonus: int = 0
var prophet_created: bool = false
var mara_exists: bool = false
var previous_action_id: String = ""
var useful_silence_outcomes: int = 0

var history: Array[String] = [
	"Year 12 - The people prayed for help.",
	"Year 11 - The river began to recede.",
	"Year 8 - Aster was founded beside the Grey River.",
	"Year 1 - The world began."
]
var beliefs: Array[String] = []
var known_beliefs: Array[String] = []
var belief_pressure := {
	"answered_prayer": 0,
	"sacred_rain": 0,
	"blessed_land": 0,
	"chosen_mortal": 0,
	"self_reliance": 0,
	"divine_silence": 0,
	"naturalism": 0
}
var intervention_counts := {
	"rain_during_drought": 0,
	"blessed_harvest": 0,
	"mortal_voice": 0
}
var action_counts := {
	"send_rain": 0,
	"bless_harvest": 0,
	"speak_mortal": 0,
	"do_nothing": 0
}
var world_flags := {
	"wells_built": false,
	"mara_is_prophet": false,
	"king_claims_divine_favor": false,
	"irrigation_known": false,
	"local_council_empowered": false
}
var world_flag_use_counts := {
	"wells_built": 0,
	"mara_is_prophet": 0,
	"king_claims_divine_favor": 0,
	"irrigation_known": 0,
	"local_council_empowered": 0
}
var reputation_pressure := {
	"Merciful": 0,
	"Silent": 0,
	"Harsh": 0,
	"Teacher": 0,
	"Protector": 0,
	"Unpredictable": 0
}
var reputation_changes: Array[String] = []
var interpretation_history: Array[String] = []
var notable_entities: Dictionary = {}
var locations: Dictionary = {}
var relationships: Dictionary = {}
var last_relationship_changes: Array[Dictionary] = []
var last_knowledge_shares: Array[Dictionary] = []
var knowledge_events: Array[Dictionary] = []
var last_intents: Array[Dictionary] = []
var intents: Array[Dictionary] = []
var intent_archive: Array[Dictionary] = []
var last_actions: Array[Dictionary] = []
var selected_actions: Array[Dictionary] = []
var action_archive: Array[Dictionary] = []
var last_executions: Array[Dictionary] = []
var executions: Array[Dictionary] = []
var execution_archive: Array[Dictionary] = []
# Every chance to notice this year, taken or missed. Missed ones are kept only
# for the current year: who failed to notice something is worth inspecting now,
# not worth remembering forever.
var last_perceptions: Array[Dictionary] = []
var perceptions: Array[Dictionary] = []
var perception_archive: Array[Dictionary] = []
# What the GOD did, as an objective act. Deliberately separate from the
# consequence it caused and from what any mortal made of it: the engine may
# know the player's intent, and mortals may not.
var last_divine_action: Dictionary = {}
var divine_actions: Array[Dictionary] = []
var divine_action_archive: Array[Dictionary] = []
var last_interpretations: Array[Dictionary] = []
var interpretations: Array[Dictionary] = []
var interpretation_archive: Array[Dictionary] = []
var last_consequences: Array[Dictionary] = []
var consequences: Array[Dictionary] = []
var consequence_archive: Array[Dictionary] = []
# Facts waiting for the year's perception pass. Consequences put things here;
# nothing reads them until perception decides who noticed.
var pending_perception_facts: Array[Dictionary] = []
# Chronicle v1 — what was important enough to become history.
#
# Deliberately NOT capped and NOT pruned, unlike every other archive here. The
# other stores are working memory for layers that only ever look at the last few
# years, and they forget cheaply. This one is the record of how the world became
# what it is, and a chronicle that quietly drops its oldest entries is worse
# than no chronicle: the causal links would dangle and nobody could tell why.
#
# GDD 96 wants history to fade one day, gradually and legibly, through stages
# rather than by deletion. That is a later system and needs its own pass. An
# entry carrying its own year, source and links can be faded, contested or
# half-remembered later without any of this being rewritten.
#
# Entries are immutable once written, with ONE exception: `led_to` grows as
# later records name an earlier one as their cause. Nothing else may change.
var chronicle: Array[Dictionary] = []

# What each mortal has come to accept about the world, across years.
#
# Kept apart from `knowledge` for a reason that matters: knowledge is capped and
# pruned, so the FACTS a belief grew from will eventually be forgotten. The
# belief must not go with them. Somebody who concluded that something intervenes
# when people are in need does not stop believing it because they can no longer
# recall which particular year it rained.
#
# Per-mortal, always. There is no realm belief, no shared creed and no
# membership here, and two mortals living through the same decade are expected
# to end up disagreeing.
# Named `mortal_beliefs` and not `beliefs`, because `beliefs` above is the
# LEGACY realm-level doctrine list that `DivineReceptionSystem` writes. The two
# are unrelated and must stay that way: one is a kingdom-wide string the old
# divine path appends to, this one is what individual people accept. Belief
# Formation v1 neither reads nor writes the legacy list, nor `faith`, nor
# `followers`.
var mortal_beliefs: Array[Dictionary] = []
# What this year's readings did to them. Current year only — a debugging view,
# not a second archive.
var last_belief_updates: Array[Dictionary] = []
# The world as mortals last lived it, before the god's current turn. A mortal's
# own settlement is directly-lived context, so remembering whether their own
# wells were dry is theirs to have — and it must be the state BEFORE any divine
# act relieved it, or nobody could ever notice that relief arrived.
var conditions_before_turn: Dictionary = {}
# Why something did NOT become history. Current year only, on purpose: this is
# a debugging aid, and keeping it forever would rebuild the exhaustive event log
# the Chronicle exists to avoid.
var last_chronicle_rejections: Array[Dictionary] = []
var last_chronicle_entries: Array[Dictionary] = []

var history_archive: Array[String] = [
	"Year 12 - The people prayed for help.",
	"Year 11 - The river began to recede.",
	"Year 8 - Aster was founded beside the Grey River.",
	"Year 1 - The world began."
]


func _init() -> void:
	# Seed content, and only seed content. Everything below names the three
	# settlements and two mortals the simulation is currently exercised with;
	# no RULE anywhere may name them. A generated world populates the same
	# structures through the same calls.
	add_location("aster", "Aster", "capital", "Seat of the kingdom", {
		"food": 0, "stability": 1, "prosperity": 2, "population": 240
	})
	add_location("westfield", "Westfield", "farming_village", "Agriculture", {
		"food": 2, "stability": 2, "prosperity": 1, "population": 150
	})
	add_location("frontier", "Frontier", "frontier_settlement", "Border watch", {
		"food": 1, "stability": 0, "prosperity": 1, "population": 96
	})
	# These IDs are stable handles for later knowledge, rumor, and consequence data.
	add_notable_entity("aster_king", "The King", "person", ["ambitious"], {}, "aster")
	add_notable_entity("mara", "Mara", "person", ["compassionate", "loyal"], {}, "westfield")
	# Where the first year's event lands, taken from what exists rather than
	# named. The event selector replaces it every year from then on.
	var seeded := get_location_ids()
	current_event_location_id = seeded[0] if not seeded.is_empty() else ""
	set_relationship("aster_king", "mara", {
		"trust": 35,
		"fear": 0,
		"respect": 20,
		"hostility": 5
	})
	set_relationship("mara", "aster_king", {
		"trust": 45,
		"fear": 10,
		"respect": 15,
		"hostility": 10
	})


func food_name() -> String:
	return FOOD_LABELS[food_level]


func stability_name() -> String:
	return STABILITY_LABELS[stability_level]


func prosperity_name() -> String:
	return PROSPERITY_LABELS[prosperity_level]


func military_name() -> String:
	return MILITARY_LABELS[military_level]


func add_history(text: String) -> void:
	var entry := "Year %d - %s" % [year, text]
	history.push_front(entry)
	history_archive.append(entry)
	if history.size() > 18:
		history.resize(18)


# home_location_id is an association, not a position: it answers "what
# settlement is this mortal normally part of?" and nothing else. There is no
# travel, no coordinates and no schedule behind it. An entity with no home
# perceives no local events, which is honest rather than silently generous.
func add_notable_entity(
	entity_id: String,
	display_name: String,
	entity_kind: String,
	traits: Array = [],
	data: Dictionary = {},
	home_location_id: String = ""
) -> bool:
	if entity_id.is_empty() or notable_entities.has(entity_id):
		return false
	var unique_traits: Array[String] = []
	for trait_value in traits:
		var trait_id := str(trait_value)
		if not trait_id.is_empty() and trait_id not in unique_traits:
			unique_traits.append(trait_id)
	notable_entities[entity_id] = {
		"id": entity_id,
		"name": display_name,
		"kind": entity_kind,
		"traits": unique_traits,
		"home_location_id": home_location_id if locations.has(home_location_id) else "",
		"data": data.duplicate(true),
		"knowledge": {}
	}
	return true


func set_home_location(entity_id: String, location_id: String) -> bool:
	if not notable_entities.has(entity_id):
		return false
	if not location_id.is_empty() and not locations.has(location_id):
		return false
	notable_entities[entity_id]["home_location_id"] = location_id
	return true


func get_home_location(entity_id: String) -> String:
	return str(notable_entities.get(entity_id, {}).get("home_location_id", ""))


# --- Locality ---------------------------------------------------------------
#
# The questions any system should ask about a place, phrased so that a location
# nobody wrote by hand can answer them: who lives here, is anyone here at all,
# and could an event here be noticed by anybody?
#
# `home_location_id` is an ASSOCIATION, not a position. There is no travel and
# no current-position state, and none may be built on these without a design
# pass. For v1, where a mortal is associated is what decides whether a local
# occurrence is theirs to notice.
#
# Note what "resident" means here: a NOTABLE entity, one the simulation holds a
# record for. A settlement's `population` is a count of people the simulation
# does not model individually, and it is deliberately not the same question. A
# place with a population of four hundred and no notable resident has nobody who
# can perceive, want, act or believe — and that is a legitimate world state, not
# a gap to be filled.


# Notable entities associated with this place. Sorted, so callers are
# deterministic without each having to sort.
func residents_of(location_id: String) -> Array[String]:
	var residents: Array[String] = []
	for entity_id_value in notable_entities:
		var entity_id := str(entity_id_value)
		if str(notable_entities[entity_id].get("home_location_id", "")) == location_id:
			residents.append(entity_id)
	residents.sort()
	return residents


func resident_count(location_id: String) -> int:
	return residents_of(location_id).size()


func has_residents(location_id: String) -> bool:
	return not residents_of(location_id).is_empty()


# Places somebody is actually associated with. Not every location has anyone,
# and nothing here creates one to fix that.
func locations_with_residents() -> Array[String]:
	var found: Array[String] = []
	for location_id: String in get_location_ids():
		if has_residents(location_id):
			found.append(location_id)
	return found


# Places where an event could happen and nobody would be there to notice it.
# A real world state, and worth being able to see rather than wonder about.
func locations_without_residents() -> Array[String]:
	var found: Array[String] = []
	for location_id: String in get_location_ids():
		if not has_residents(location_id):
			found.append(location_id)
	return found


# Could a LOCAL occurrence here be perceived by anybody at all?
#
# Answered from association alone, which is what Selective Perception uses for
# `local` observability. It is not a promise that any particular event will be
# noticed: the perception rules still decide that, event by event.
func has_local_perception_coverage(location_id: String) -> bool:
	return has_residents(location_id)


# One row per place, for diagnostics. Says what is true, and says plainly where
# nobody is — a dead zone should be visible rather than mysterious.
func locality_coverage() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for location_id: String in get_location_ids():
		var residents := residents_of(location_id)
		rows.append({
			"location_id": location_id,
			"name": location_name(location_id),
			"has_settlement_state": locations.has(location_id),
			"population": get_settlement_population(location_id),
			"resident_count": residents.size(),
			"residents": residents,
			"local_events_perceivable": has_local_perception_coverage(location_id)
		})
	return rows


func add_location(
	location_id: String,
	display_name: String,
	location_kind: String,
	role: String,
	conditions: Dictionary = {}
) -> bool:
	if location_id.is_empty() or locations.has(location_id):
		return false
	var record := {
		"id": location_id,
		"name": display_name,
		"kind": location_kind,
		"role": role,
		"population": maxi(int(conditions.get("population", 0)), 0)
	}
	for band: String in SETTLEMENT_BANDS:
		record[band] = clampi(int(conditions.get(band, 1)), 0, FOOD_LABELS.size() - 1)
	# Generic across any settlement, including ones this file has never heard of.
	record["water"] = clampi(int(conditions.get("water", WATER_BASELINE)), WATER_MIN, WATER_MAX)
	locations[location_id] = record
	return true


# --- Water pressure ---------------------------------------------------------

func get_water(location_id: String) -> int:
	if not locations.has(location_id):
		return 0
	return int(locations[location_id].get("water", WATER_BASELINE))


func set_water(location_id: String, value: int) -> bool:
	if not locations.has(location_id):
		return false
	locations[location_id]["water"] = clampi(value, WATER_MIN, WATER_MAX)
	return true


# Returns the value actually reached, after clamping. A settlement already at
# the ceiling absorbs more rain and stays flooded rather than overflowing into
# a number nothing can read.
func change_water(location_id: String, delta: int) -> int:
	if not locations.has(location_id):
		return 0
	set_water(location_id, get_water(location_id) + delta)
	return get_water(location_id)


func water_state(location_id: String) -> String:
	return water_state_for(get_water(location_id))


func water_state_for(value: int) -> String:
	var clamped := clampi(value, WATER_MIN, WATER_MAX)
	for threshold: Dictionary in WATER_THRESHOLDS:
		if clamped <= int(threshold["max"]):
			return str(threshold["state"])
	return WATER_FLOODED


func get_settlement_band(location_id: String, band: String) -> int:
	if not locations.has(location_id) or band not in SETTLEMENT_BANDS:
		return 0
	return int(locations[location_id][band])


func set_settlement_band(location_id: String, band: String, value: int) -> bool:
	if not locations.has(location_id) or band not in SETTLEMENT_BANDS:
		return false
	locations[location_id][band] = clampi(value, 0, FOOD_LABELS.size() - 1)
	return true


func change_settlement_band(location_id: String, band: String, delta: int) -> int:
	if not set_settlement_band(location_id, band, get_settlement_band(location_id, band) + delta):
		return 0
	return get_settlement_band(location_id, band)


func get_settlement_population(location_id: String) -> int:
	return int(locations.get(location_id, {}).get("population", 0))


func change_settlement_population(location_id: String, delta: int) -> int:
	if not locations.has(location_id):
		return 0
	locations[location_id]["population"] = maxi(
		int(locations[location_id]["population"]) + delta, 0
	)
	return int(locations[location_id]["population"])


# Where a condition is most pronounced. Events use this to find the settlement
# their year is actually about, without naming any settlement in code.
func settlement_with_lowest(band: String) -> String:
	var chosen := ""
	var lowest := 0
	for location_id: String in get_location_ids():
		var value := get_settlement_band(location_id, band)
		if chosen.is_empty() or value < lowest:
			chosen = location_id
			lowest = value
	return chosen


func _weighted_band(band: String) -> int:
	# Weighted by the people who live with the condition, so a hungry hamlet
	# does not read the same as a hungry capital.
	var total_population := 0
	var weighted := 0
	for location_value in locations.values():
		var location: Dictionary = location_value
		var residents := int(location.get("population", 0))
		total_population += residents
		weighted += int(location.get(band, 0)) * residents
	if total_population <= 0:
		return 0
	return clampi(int(round(float(weighted) / float(total_population))), 0, FOOD_LABELS.size() - 1)


func _broadcast_band(band: String, value: int) -> void:
	for location_id_value in locations:
		set_settlement_band(str(location_id_value), band, value)


func _distribute_population(total: int) -> void:
	var target := maxi(total, 0)
	var location_ids := get_location_ids()
	if location_ids.is_empty():
		return
	var current := population
	if current <= 0:
		locations[location_ids[0]]["population"] = target
		return
	var assigned := 0
	for index in location_ids.size():
		var location_id := location_ids[index]
		if index == location_ids.size() - 1:
			locations[location_id]["population"] = maxi(target - assigned, 0)
			return
		var share := int(round(
			float(get_settlement_population(location_id)) / float(current) * float(target)
		))
		locations[location_id]["population"] = maxi(share, 0)
		assigned += share


func location_name(location_id: String) -> String:
	return str(locations.get(location_id, {}).get("name", location_id))


func get_location(location_id: String) -> Dictionary:
	return locations.get(location_id, {}).duplicate(true)


# Every location, in the order they were added.
#
# There used to be a hardcoded `LOCATION_ORDER` naming the three seeded
# settlements, with anything else appended alphabetically after them. Insertion
# order gives the identical sequence for the seeded world and needs no list to
# maintain, so a settlement that did not exist when this file was written takes
# its place in the world like any other.
#
# The order is not cosmetic: `settlement_with_lowest()` breaks ties by taking
# the first it meets, so event placement depends on it. It must stay stable and
# deterministic, which insertion order is.
func get_location_ids() -> Array[String]:
	var ordered: Array[String] = []
	for location_id_value in locations.keys():
		ordered.append(str(location_id_value))
	return ordered


func get_notable_entity(entity_id: String) -> Dictionary:
	return notable_entities.get(entity_id, {}).duplicate(true)


func set_relationship(source_id: String, target_id: String, values: Dictionary = {}) -> bool:
	if source_id == target_id or not notable_entities.has(source_id) or not notable_entities.has(target_id):
		return false
	var record := {
		"id": relationship_id(source_id, target_id),
		"source_id": source_id,
		"target_id": target_id,
		"trust": 50,
		"fear": 0,
		"respect": 0,
		"hostility": 0,
		"last_changed_year": year,
		"data": {}
	}
	for axis: String in RELATIONSHIP_AXES:
		record[axis] = clampi(int(values.get(axis, record[axis])), RELATIONSHIP_MIN, RELATIONSHIP_MAX)
	record["data"] = values.get("data", {}).duplicate(true)
	relationships[record["id"]] = record
	return true


func get_relationship(source_id: String, target_id: String) -> Dictionary:
	return relationships.get(relationship_id(source_id, target_id), {}).duplicate(true)


func change_relationship(source_id: String, target_id: String, changes: Dictionary) -> Dictionary:
	var record_id := relationship_id(source_id, target_id)
	if not relationships.has(record_id):
		return {}
	var record: Dictionary = relationships[record_id]
	for axis: String in RELATIONSHIP_AXES:
		if changes.has(axis):
			record[axis] = clampi(int(record[axis]) + int(changes[axis]), RELATIONSHIP_MIN, RELATIONSHIP_MAX)
	record["last_changed_year"] = year
	return record.duplicate(true)


func relationship_id(source_id: String, target_id: String) -> String:
	return "%s::%s" % [source_id, target_id]


func learn_knowledge(entity_id: String, knowledge_data: Dictionary) -> Dictionary:
	if not notable_entities.has(entity_id):
		return {}
	var knowledge_id := str(knowledge_data.get("id", ""))
	if knowledge_id.is_empty():
		return {}
	var entity: Dictionary = notable_entities[entity_id]
	var stored_knowledge: Dictionary = entity["knowledge"]
	var existing: Dictionary = stored_knowledge.get(knowledge_id, {})
	var record := _normalise_knowledge_record(entity_id, knowledge_data, existing)
	stored_knowledge[knowledge_id] = record
	entity["knowledge"] = stored_knowledge
	notable_entities[entity_id] = entity
	knowledge_events.append({
		"type": "knowledge_updated" if not existing.is_empty() else "knowledge_learned",
		"entity_id": entity_id,
		"knowledge_id": knowledge_id,
		"year": year,
		"confidence": record["confidence"],
		"source_id": record["source_id"]
	})
	return record.duplicate(true)


func learn_direct_knowledge(entity_id: String, knowledge_data: Dictionary) -> Dictionary:
	var direct_data := knowledge_data.duplicate(true)
	direct_data["confidence"] = clampi(
		int(direct_data.get("confidence", 95)),
		KNOWLEDGE_CONFIDENCE_MIN,
		KNOWLEDGE_CONFIDENCE_MAX
	)
	direct_data["source_id"] = entity_id
	direct_data["source_type"] = "direct"
	direct_data["origin_source_id"] = entity_id
	direct_data["transmission_count"] = 0
	direct_data["last_updated_year"] = year
	return learn_knowledge(entity_id, direct_data)


func get_knowledge(entity_id: String, knowledge_id: String) -> Dictionary:
	if not notable_entities.has(entity_id):
		return {}
	return notable_entities[entity_id]["knowledge"].get(knowledge_id, {}).duplicate(true)


func get_all_knowledge(entity_id: String) -> Dictionary:
	if not notable_entities.has(entity_id):
		return {}
	return notable_entities[entity_id]["knowledge"].duplicate(true)


func has_knowledge(entity_id: String, knowledge_id: String) -> bool:
	return not get_knowledge(entity_id, knowledge_id).is_empty()


func does_entity_believe(entity_id: String, knowledge_id: String, minimum_confidence: int = 1) -> bool:
	var record := get_knowledge(entity_id, knowledge_id)
	if record.is_empty() or bool(record.get("invalidated", false)):
		return false
	return int(record["confidence"]) >= clampi(
		minimum_confidence,
		KNOWLEDGE_CONFIDENCE_MIN,
		KNOWLEDGE_CONFIDENCE_MAX
	)


func get_knowledge_confidence(entity_id: String, knowledge_id: String) -> int:
	var record := get_knowledge(entity_id, knowledge_id)
	return 0 if record.is_empty() else int(record["confidence"])


func update_knowledge(entity_id: String, knowledge_id: String, changes: Dictionary) -> Dictionary:
	var existing := get_knowledge(entity_id, knowledge_id)
	if existing.is_empty():
		return {}
	var updated := existing.duplicate(true)
	for key in changes:
		if str(key) != "id" and str(key) != "owner_id":
			updated[key] = changes[key]
	updated["id"] = knowledge_id
	updated["last_updated_year"] = int(changes.get("last_updated_year", year))
	return learn_knowledge(entity_id, updated)


func invalidate_knowledge(entity_id: String, knowledge_id: String) -> bool:
	var updated := update_knowledge(entity_id, knowledge_id, {
		"invalidated": true,
		"confidence": 0
	})
	return not updated.is_empty()


func remove_knowledge(entity_id: String, knowledge_id: String) -> bool:
	if not notable_entities.has(entity_id):
		return false
	var entity: Dictionary = notable_entities[entity_id]
	var stored_knowledge: Dictionary = entity["knowledge"]
	if not stored_knowledge.erase(knowledge_id):
		return false
	entity["knowledge"] = stored_knowledge
	notable_entities[entity_id] = entity
	knowledge_events.append({
		"type": "knowledge_removed",
		"entity_id": entity_id,
		"knowledge_id": knowledge_id,
		"year": year
	})
	return true


func record_intent(record: Dictionary) -> Dictionary:
	# Broad Intents are intentions only. Recording one must never alter world
	# statistics, relationships, or knowledge. What a mortal wants and what a
	# mortal attempts are separate layers; the second does not exist yet.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	intents.append(stored)
	intent_archive.append(stored)
	if intents.size() > MAX_STORED_INTENTS:
		intents = intents.slice(intents.size() - MAX_STORED_INTENTS)
	return stored.duplicate(true)


func get_intent(intent_id: String) -> Dictionary:
	for record: Dictionary in intent_archive:
		if str(record["id"]) == intent_id:
			return record.duplicate(true)
	return {}


func get_intents_for(actor_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in intent_archive:
		if str(record["actor_id"]) == actor_id:
			matches.append(record.duplicate(true))
	return matches


func record_action(record: Dictionary) -> Dictionary:
	# Selected actions are attempts nobody has made yet. Recording one must
	# never alter world statistics, relationships, or knowledge: choosing to ask
	# the King for help is not the King answering. Execution is a later system.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	selected_actions.append(stored)
	action_archive.append(stored)
	if selected_actions.size() > MAX_STORED_ACTIONS:
		selected_actions = selected_actions.slice(selected_actions.size() - MAX_STORED_ACTIONS)
	return stored.duplicate(true)


func get_action_record(action_id: String) -> Dictionary:
	for record: Dictionary in action_archive:
		if str(record["id"]) == action_id:
			return record.duplicate(true)
	return {}


func get_actions_for(actor_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in action_archive:
		if str(record["actor_id"]) == actor_id:
			matches.append(record.duplicate(true))
	return matches


func get_action_for_intent(intent_id: String) -> Dictionary:
	for record: Dictionary in action_archive:
		if str(record["intent_id"]) == intent_id:
			return record.duplicate(true)
	return {}


func record_execution(record: Dictionary) -> Dictionary:
	# An execution result is what immediately came of an attempt, and nothing
	# more. Recording one must not cascade: what a refused request or a
	# delivered warning goes on to change belongs to the Consequence Engine,
	# which does not exist yet.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	executions.append(stored)
	execution_archive.append(stored)
	if executions.size() > MAX_STORED_EXECUTIONS:
		executions = executions.slice(executions.size() - MAX_STORED_EXECUTIONS)
	return stored.duplicate(true)


func get_execution(execution_id: String) -> Dictionary:
	for record: Dictionary in execution_archive:
		if str(record["id"]) == execution_id:
			return record.duplicate(true)
	return {}


func get_executions_for(actor_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in execution_archive:
		if str(record["actor_id"]) == actor_id:
			matches.append(record.duplicate(true))
	return matches


func get_execution_for_action(action_id: String) -> Dictionary:
	for record: Dictionary in execution_archive:
		if str(record["action_id"]) == action_id:
			return record.duplicate(true)
	return {}


func record_perception(record: Dictionary) -> Dictionary:
	# Only perceptions that actually happened are kept. A record of everyone who
	# failed to notice something would grow without limit and teach nothing
	# after the year it belonged to.
	if record.is_empty() or not bool(record.get("perceived", false)):
		return {}
	var stored := record.duplicate(true)
	perceptions.append(stored)
	perception_archive.append(stored)
	if perceptions.size() > MAX_STORED_PERCEPTIONS:
		perceptions = perceptions.slice(perceptions.size() - MAX_STORED_PERCEPTIONS)
	return stored.duplicate(true)


func get_perceptions_for(observer_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in perception_archive:
		if str(record["observer_id"]) == observer_id:
			matches.append(record.duplicate(true))
	return matches


func record_consequence(record: Dictionary) -> Dictionary:
	# What objectively came of something. A consequence never carries a
	# relationship, faith or reputation delta: those are reactions, and
	# reactions belong to interpretation.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	consequences.append(stored)
	consequence_archive.append(stored)
	if consequences.size() > MAX_STORED_CONSEQUENCES:
		consequences = consequences.slice(consequences.size() - MAX_STORED_CONSEQUENCES)
	return stored.duplicate(true)


func record_divine_action(record: Dictionary) -> Dictionary:
	# What the player did, and what it cost. NOT what it meant, and not what
	# changed — the change is the consequence's business, and the meaning is
	# every mortal's own.
	#
	# The game may hold this record in full while no mortal can read it. That
	# gap is deliberate: a mortal sees rain, never "the god chose to send rain
	# because Aster was starving".
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	divine_actions.append(stored)
	divine_action_archive.append(stored)
	if divine_actions.size() > MAX_STORED_DIVINE_ACTIONS:
		divine_actions = divine_actions.slice(
			divine_actions.size() - MAX_STORED_DIVINE_ACTIONS
		)
	last_divine_action = stored.duplicate(true)
	return stored.duplicate(true)


func get_divine_action(record_id: String) -> Dictionary:
	for record: Dictionary in divine_action_archive:
		if str(record["id"]) == record_id:
			return record.duplicate(true)
	return {}


func record_interpretation(record: Dictionary) -> Dictionary:
	# What ONE mortal made of ONE occurrence they already knew about.
	#
	# Kept apart from knowledge on purpose. A fact and what someone takes it to
	# mean are two records: "the King refused Mara's request" stays exactly as
	# it was learned, and "the King is unwilling to help Westfield" lives here.
	# Overwriting the first with the second would destroy the only copy of what
	# actually happened, and the engine knowing the truth must never quietly
	# correct the mortal.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	interpretations.append(stored)
	interpretation_archive.append(stored)
	if interpretations.size() > MAX_STORED_INTERPRETATIONS:
		interpretations = interpretations.slice(
			interpretations.size() - MAX_STORED_INTERPRETATIONS
		)
	return stored.duplicate(true)


# `episode` distinguishes one spell of a recurring condition from the next.
# Zero for everything whose id is already unique per occurrence, so social
# interpretation ids are unchanged.
func interpretation_id(observer_id: String, knowledge_id: String, episode: int = 0) -> String:
	if episode <= 0:
		return "interpretation_%s_%s" % [observer_id, knowledge_id]
	return "interpretation_%s_%s_%d" % [observer_id, knowledge_id, episode]


func has_interpretation(observer_id: String, knowledge_id: String, episode: int = 0) -> bool:
	# One mortal reaches one conclusion about one occurrence, once. Without this
	# a fact still believed next year would be re-interpreted every year, and a
	# single refusal would grind a relationship down forever.
	#
	# "Once" means once per SPELL. A famine that lifts and returns years later
	# is a second thing to have an opinion about; a famine that simply continues
	# is not.
	var wanted := interpretation_id(observer_id, knowledge_id, episode)
	for record: Dictionary in interpretation_archive:
		if str(record["id"]) == wanted:
			return true
	return false


func get_interpretation(record_id: String) -> Dictionary:
	for record: Dictionary in interpretation_archive:
		if str(record["id"]) == record_id:
			return record.duplicate(true)
	return {}


func get_interpretations_for(observer_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in interpretation_archive:
		if str(record["observer_id"]) == observer_id:
			matches.append(record.duplicate(true))
	return matches


func get_consequence(consequence_id: String) -> Dictionary:
	for record: Dictionary in consequence_archive:
		if str(record["id"]) == consequence_id:
			return record.duplicate(true)
	return {}


func get_consequences_for(actor_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in consequence_archive:
		if str(record["actor_id"]) == actor_id or str(record["target_id"]) == actor_id:
			matches.append(record.duplicate(true))
	return matches


func get_consequence_for_source(source_id: String) -> Dictionary:
	for record: Dictionary in consequence_archive:
		if str(record["source_id"]) == source_id:
			return record.duplicate(true)
	return {}


func prune_memory(entity_id: String) -> Array[String]:
	# Forgetting, deliberately. A mortal keeps what could still matter: what is
	# retracted goes first, then what is stale and was never firmly held.
	# Nothing learned this year is ever dropped.
	var forgotten: Array[String] = []
	if not notable_entities.has(entity_id):
		return forgotten
	var stored: Dictionary = notable_entities[entity_id]["knowledge"]
	if stored.size() <= MAX_KNOWLEDGE_PER_ENTITY:
		return forgotten
	var candidates: Array[Dictionary] = []
	for knowledge_id_value in stored:
		var record: Dictionary = stored[str(knowledge_id_value)]
		if int(record.get("last_updated_year", year)) >= year:
			continue
		candidates.append({
			"id": str(knowledge_id_value),
			"invalidated": bool(record.get("invalidated", false)),
			"outdated": bool(record.get("is_outdated", false)),
			"confidence": int(record.get("confidence", 0)),
			"last_updated_year": int(record.get("last_updated_year", year))
		})
	candidates.sort_custom(_weakest_memory_first)
	var excess := stored.size() - MAX_KNOWLEDGE_PER_ENTITY
	for candidate: Dictionary in candidates:
		if forgotten.size() >= excess:
			break
		if remove_knowledge(entity_id, str(candidate["id"])):
			forgotten.append(str(candidate["id"]))
	return forgotten


func _weakest_memory_first(left: Dictionary, right: Dictionary) -> bool:
	if bool(left["invalidated"]) != bool(right["invalidated"]):
		return bool(left["invalidated"])
	if bool(left["outdated"]) != bool(right["outdated"]):
		return bool(left["outdated"])
	if int(left["confidence"]) != int(right["confidence"]):
		return int(left["confidence"]) < int(right["confidence"])
	if int(left["last_updated_year"]) != int(right["last_updated_year"]):
		return int(left["last_updated_year"]) < int(right["last_updated_year"])
	return str(left["id"]) < str(right["id"])


func age_knowledge() -> Array[Dictionary]:
	var aged_records: Array[Dictionary] = []
	for entity_id_value in notable_entities:
		var entity_id := str(entity_id_value)
		var entity: Dictionary = notable_entities[entity_id]
		var stored_knowledge: Dictionary = entity["knowledge"]
		for knowledge_id_value in stored_knowledge:
			var knowledge_id := str(knowledge_id_value)
			var record: Dictionary = stored_knowledge[knowledge_id]
			if bool(record.get("invalidated", false)):
				continue
			var age := maxi(year - int(record["last_updated_year"]), 0)
			record["freshness"] = clampi(100 - age * 20, 0, 100)
			if age > int(record["fresh_for_years"]):
				if str(record["truth_state"]) != "outdated":
					record["objective_truth_state"] = record["truth_state"]
				record["truth_state"] = "outdated"
				record["is_outdated"] = true
				record["confidence"] = clampi(
					int(record["confidence"]) - 3,
					KNOWLEDGE_CONFIDENCE_MIN,
					KNOWLEDGE_CONFIDENCE_MAX
				)
				aged_records.append({
					"entity_id": entity_id,
					"knowledge_id": knowledge_id,
					"confidence": record["confidence"],
					"age": age
				})
			stored_knowledge[knowledge_id] = record
		entity["knowledge"] = stored_knowledge
		notable_entities[entity_id] = entity
	for entity_id_value in notable_entities:
		prune_memory(str(entity_id_value))
	return aged_records


func _normalise_knowledge_record(
	entity_id: String,
	knowledge_data: Dictionary,
	existing: Dictionary
) -> Dictionary:
	var truth_state := str(knowledge_data.get("truth_state", existing.get("truth_state", "unknown")))
	if truth_state not in KNOWLEDGE_TRUTH_STATES:
		truth_state = "unknown"
	var objective_truth := str(knowledge_data.get(
		"objective_truth_state",
		existing.get("objective_truth_state", truth_state if truth_state != "outdated" else "unknown")
	))
	if objective_truth not in ["true", "false", "unknown"]:
		objective_truth = "unknown"
	var learned_year := int(knowledge_data.get(
		"year_learned",
		existing.get("year_learned", year)
	))
	# Which SPELL of an ongoing condition this is.
	#
	# A world condition carries a stable id per settlement ("westfield_food_shortage")
	# and is refreshed every year it holds, so without this a mortal would
	# conclude something about a recurring famine exactly once in their life.
	# A gap in the refreshes means the condition lifted and came back, which is
	# a new situation to have an opinion about; an unbroken run of years is one
	# situation, and concluding about it once is the point of the rule.
	#
	# Social occurrences already carry the year in their id, so every one of
	# them is its own episode and nothing here changes them.
	var previous_update := int(existing.get("last_updated_year", year))
	var episode := int(existing.get("episode", 0))
	if not existing.is_empty() and year > previous_update + 1:
		episode += 1
	return {
		"id": str(knowledge_data["id"]),
		"owner_id": entity_id,
		"subject_id": str(knowledge_data.get("subject_id", existing.get("subject_id", ""))),
		"topic": str(knowledge_data.get("topic", existing.get("topic", "unknown"))),
		"claim": str(knowledge_data.get("claim", existing.get("claim", ""))),
		# Who a social occurrence was between, carried as ids so the reader does
		# not have to parse the claim's prose for names it already states.
		# Preserved across updates like subject_id: a rumor that refreshes this
		# record must not strip who it was about.
		"participants": (knowledge_data.get(
			"participants", existing.get("participants", [])
		) as Array).duplicate(),
		"confidence": clampi(
			int(knowledge_data.get("confidence", existing.get("confidence", 50))),
			KNOWLEDGE_CONFIDENCE_MIN,
			KNOWLEDGE_CONFIDENCE_MAX
		),
		"truth_state": truth_state,
		"objective_truth_state": objective_truth,
		"source_id": str(knowledge_data.get("source_id", existing.get("source_id", entity_id))),
		"source_type": str(knowledge_data.get("source_type", existing.get("source_type", "unknown"))),
		"origin_source_id": str(knowledge_data.get(
			"origin_source_id",
			existing.get("origin_source_id", knowledge_data.get("source_id", entity_id))
		)),
		"year_learned": learned_year,
		"last_updated_year": int(knowledge_data.get("last_updated_year", year)),
		"episode": episode,
		"fresh_for_years": maxi(int(knowledge_data.get(
			"fresh_for_years",
			existing.get("fresh_for_years", DEFAULT_KNOWLEDGE_FRESH_YEARS)
		)), 0),
		"freshness": clampi(int(knowledge_data.get("freshness", 100)), 0, 100),
		"is_outdated": bool(knowledge_data.get("is_outdated", truth_state == "outdated")),
		"invalidated": bool(knowledge_data.get("invalidated", false)),
		"transmission_count": maxi(int(knowledge_data.get("transmission_count", 0)), 0),
		"distorted": bool(knowledge_data.get("distorted", false)),
		"data": knowledge_data.get("data", existing.get("data", {})).duplicate(true)
	}


func clamp_values() -> void:
	# Clamped per settlement. Clamping the aggregate would broadcast it back
	# down and flatten every local difference the world just built up.
	for location_id_value in locations:
		var location_id := str(location_id_value)
		for band: String in SETTLEMENT_BANDS:
			set_settlement_band(location_id, band, get_settlement_band(location_id, band))
		locations[location_id]["population"] = maxi(
			int(locations[location_id]["population"]), 0
		)
	if population < 1:
		locations[get_location_ids()[0]]["population"] = 1
	military_level = clampi(military_level, 0, MILITARY_LABELS.size() - 1)
	faith = clampi(faith, 0, 100)
	followers = clampi(followers, 0, population)
	divine_power = clampi(divine_power, 0, max_divine_power)


# --- Chronicle -------------------------------------------------------------

func chronicle_id(year_value: int, source_record_id: String) -> String:
	return "hist_%04d_%s" % [year_value, source_record_id]


# Write one record into history. Returns it as stored.
#
# The source record is NOT touched: history points back at what happened and
# never edits it. If a chronicle entry could rewrite its own source, the
# objective record would stop being objective.
func record_chronicle(entry: Dictionary) -> Dictionary:
	var stored := entry.duplicate(true)
	stored["id"] = chronicle_id(int(stored["year"]), str(stored["source_record_id"]))
	if has_chronicle(str(stored["id"])):
		return get_chronicle(str(stored["id"]))
	chronicle.append(stored)
	return stored


func has_chronicle(record_id: String) -> bool:
	for record: Dictionary in chronicle:
		if str(record["id"]) == record_id:
			return true
	return false


func get_chronicle(record_id: String) -> Dictionary:
	for record: Dictionary in chronicle:
		if str(record["id"]) == record_id:
			return record
	return {}


# The one permitted mutation of an existing entry: an earlier record learning
# that a later one came out of it. The link is a pair of ids, never copied prose.
func link_chronicle(parent_id: String, child_id: String) -> bool:
	if parent_id.is_empty() or child_id.is_empty() or parent_id == child_id:
		return false
	var parent := get_chronicle(parent_id)
	var child := get_chronicle(child_id)
	if parent.is_empty() or child.is_empty():
		return false
	var led_to: Array = parent["led_to"]
	if child_id not in led_to:
		led_to.append(child_id)
	var caused_by: Array = child["caused_by"]
	if parent_id not in caused_by:
		caused_by.append(parent_id)
	return true


func chronicle_for_location(location_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in chronicle:
		if str(record["location_id"]) == location_id:
			found.append(record)
	return found


# --- Beliefs ---------------------------------------------------------------

func belief_id(holder_id: String, proposition: String, subject_id: String) -> String:
	if subject_id.is_empty():
		return "belief_%s_%s" % [holder_id, proposition]
	return "belief_%s_%s_%s" % [holder_id, proposition, subject_id]


# One belief per holder per proposition per subject. Repeated evidence updates
# the belief that already exists rather than stacking another copy of it: a
# mortal does not hold the same conviction twice.
func record_belief(entry: Dictionary) -> Dictionary:
	var record_id := belief_id(
		str(entry["holder_id"]), str(entry["proposition"]), str(entry["subject_id"])
	)
	for index in range(mortal_beliefs.size()):
		if str(mortal_beliefs[index]["id"]) == record_id:
			var existing: Dictionary = mortal_beliefs[index]
			for field: String in [
				"confidence", "support", "contradiction", "last_updated_year",
				"source_interpretation_ids", "status"
			]:
				existing[field] = entry[field]
			return existing
	var stored := entry.duplicate(true)
	stored["id"] = record_id
	mortal_beliefs.append(stored)
	return stored


func get_belief(holder_id: String, proposition: String, subject_id: String = "") -> Dictionary:
	var record_id := belief_id(holder_id, proposition, subject_id)
	for record: Dictionary in mortal_beliefs:
		if str(record["id"]) == record_id:
			return record
	return {}


func has_belief(holder_id: String, proposition: String, subject_id: String = "") -> bool:
	return not get_belief(holder_id, proposition, subject_id).is_empty()


func get_beliefs_for(holder_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in mortal_beliefs:
		if str(record["holder_id"]) == holder_id:
			found.append(record)
	return found


# What a settlement's condition was before the current turn. Empty before the
# first year turns, which callers must read as "no memory of it", not as zero.
func condition_before_turn(location_id: String, band: String) -> int:
	var bands: Dictionary = conditions_before_turn.get(location_id, {})
	return int(bands.get(band, -1))
