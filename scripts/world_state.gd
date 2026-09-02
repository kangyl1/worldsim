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
const MAX_STORED_DECISIONS := 40

var year: int = 12
var population: int = 486
var food_level: int = 0
var stability_level: int = 1
var prosperity_level: int = 1
var military_level: int = 0
var faith: int = 34
var followers: int = 412
var divine_power: int = 6
var max_divine_power: int = 8
var reputation: String = "Unknown"

var current_event_id: String = "drought"
var action_taken: bool = false
var last_result: String = ""
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
var relationships: Dictionary = {}
var last_relationship_changes: Array[Dictionary] = []
var last_knowledge_shares: Array[Dictionary] = []
var knowledge_events: Array[Dictionary] = []
var last_event_knowledge: Array[Dictionary] = []
var last_decisions: Array[Dictionary] = []
var decisions: Array[Dictionary] = []
var decision_archive: Array[Dictionary] = []
var history_archive: Array[String] = [
	"Year 12 - The people prayed for help.",
	"Year 11 - The river began to recede.",
	"Year 8 - Aster was founded beside the Grey River.",
	"Year 1 - The world began."
]


func _init() -> void:
	# These IDs are stable handles for later knowledge, rumor, and consequence data.
	add_notable_entity("aster_king", "The King", "person", ["ambitious"])
	add_notable_entity("mara", "Mara", "person", ["compassionate", "loyal"])
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


func add_notable_entity(
	entity_id: String,
	display_name: String,
	entity_kind: String,
	traits: Array = [],
	data: Dictionary = {}
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
		"data": data.duplicate(true),
		"knowledge": {}
	}
	return true


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


func record_decision(record: Dictionary) -> Dictionary:
	# Decisions are intentions only. Recording one must never alter world
	# statistics, relationships, or knowledge.
	if record.is_empty():
		return {}
	var stored := record.duplicate(true)
	decisions.append(stored)
	decision_archive.append(stored)
	if decisions.size() > MAX_STORED_DECISIONS:
		decisions = decisions.slice(decisions.size() - MAX_STORED_DECISIONS)
	return stored.duplicate(true)


func get_decision(decision_id: String) -> Dictionary:
	for record: Dictionary in decision_archive:
		if str(record["id"]) == decision_id:
			return record.duplicate(true)
	return {}


func get_decisions_for(actor_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for record: Dictionary in decision_archive:
		if str(record["actor_id"]) == actor_id:
			matches.append(record.duplicate(true))
	return matches


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
	return {
		"id": str(knowledge_data["id"]),
		"owner_id": entity_id,
		"subject_id": str(knowledge_data.get("subject_id", existing.get("subject_id", ""))),
		"topic": str(knowledge_data.get("topic", existing.get("topic", "unknown"))),
		"claim": str(knowledge_data.get("claim", existing.get("claim", ""))),
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
	population = maxi(population, 1)
	food_level = clampi(food_level, 0, FOOD_LABELS.size() - 1)
	stability_level = clampi(stability_level, 0, STABILITY_LABELS.size() - 1)
	prosperity_level = clampi(prosperity_level, 0, PROSPERITY_LABELS.size() - 1)
	military_level = clampi(military_level, 0, MILITARY_LABELS.size() - 1)
	faith = clampi(faith, 0, 100)
	followers = clampi(followers, 0, population)
	divine_power = clampi(divine_power, 0, max_divine_power)
