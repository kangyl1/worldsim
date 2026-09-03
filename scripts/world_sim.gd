class_name WorldSimulation
extends RefCounted

signal state_changed

const ACTION_ORDER := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
const REPUTATION_ORDER := ["Merciful", "Silent", "Harsh", "Teacher", "Protector", "Unpredictable"]
const MAX_ACTIVE_BELIEFS := 3

# A relationship is directional: source traits shape the source's outlook, while
# target traits shape the impression the target makes. New traits only need data.
const TRAIT_RELATIONSHIP_RULES := {
	"ambitious": {
		"outlook": {"trust": -1, "hostility": 1},
		"impression": {"respect": 1, "hostility": 1},
		"toward_traits": {
			"ambitious": {"respect": 1, "hostility": 1},
			"loyal": {"trust": 1, "respect": 1}
		}
	},
	"compassionate": {
		"outlook": {"trust": 1, "fear": -1, "hostility": -1},
		"impression": {"trust": 1, "fear": -1, "hostility": -1}
	},
	"cruel": {
		"outlook": {"trust": -1, "hostility": 1},
		"impression": {"trust": -3, "fear": 3, "hostility": 2}
	},
	"loyal": {
		"outlook": {"trust": 1, "respect": 1, "hostility": -1},
		"impression": {"trust": 1, "respect": 1}
	}
}

const BELIEF_DEFINITIONS := {
	"answered_prayer": {"threshold": 3, "name": "God answers sincere prayer."},
	"sacred_rain": {"threshold": 3, "name": "Rain is sacred."},
	"blessed_land": {"threshold": 3, "name": "The land bears God's blessing."},
	"chosen_mortal": {"threshold": 3, "name": "God speaks through chosen mortals."},
	"self_reliance": {"threshold": 3, "name": "Mortals must solve their own problems."},
	"divine_silence": {"threshold": 3, "name": "God tests the faithful through silence."},
	"naturalism": {"threshold": 3, "name": "Not every strange event is divine."}
}

const ACTIONS := {
	"send_rain": {
		"title": "SEND RAIN",
		"cost": 2,
		"hint": "Answer the skyward prayers"
	},
	"bless_harvest": {
		"title": "BLESS HARVEST",
		"cost": 1,
		"hint": "Strengthen the coming yield"
	},
	"speak_mortal": {
		"title": "SPEAK THROUGH A MORTAL",
		"cost": 1,
		"hint": "Give Mara a divine message"
	},
	"do_nothing": {
		"title": "DO NOTHING",
		"cost": 0,
		"hint": "Let the world interpret your silence"
	}
}

const EVENTS := {
	"drought": {
		"title": "THE LONG DROUGHT",
		"description": "For three months, no rain has fallen. Wells are drying up. Farmers have gathered outside the old shrine and are asking an unknown god for help.",
		"ascii": "       _\n      /_\\\n   o  | |  o\n  /|\\ | | /|\\\n  / \\ |_| / \\"
	},
	"good_harvest": {
		"title": "A PROMISING HARVEST",
		"description": "Heavy heads of grain bend in the fields. The people wonder whether fortune, labour, or an unseen hand has favoured Aster.",
		"ascii": "  \\ | /   \\ | /\n --\\|/-- --\\|/--\n    |       |\n   / \\     / \\"
	},
	"unrest": {
		"title": "VOICES IN THE SQUARE",
		"description": "Empty cupboards have sharpened old grudges. A crowd gathers before the storehouse. Some demand justice; others demand a sign.",
		"ascii": "  o  o  o  o\n /|\\/|\\/|\\/|\\\n / \\/ \\/ \\/ \\"
	}
}

# What each event makes perceivable, and how widely. Conditions are checked
# against world state AFTER the event handler and clamping have run, so an event
# the world absorbed offers nothing to notice.
#
# These templates say what CAN be perceived. They no longer say who learns it:
# that is Selective Perception's question, and every claim here is about one
# named settlement, so all three are local to it. Someone living elsewhere finds
# out the way anyone finds out about a distant place — by being told.
const EVENT_KNOWLEDGE := {
	"drought": {
		"id": "aster_food_shortage",
		"subject_id": "aster",
		"topic": "food_shortage",
		"claim": "Aster does not have enough food",
		"observability": "local",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"conditions": [{"field": "food_level", "op": "lte", "value": 1}]
	},
	"unrest": {
		"id": "aster_unrest",
		"subject_id": "aster",
		"topic": "danger_unrest",
		"claim": "Order is breaking down in Aster",
		"observability": "local",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"conditions": [{"field": "stability_level", "op": "lte", "value": 0}]
	},
	"good_harvest": {
		"id": "aster_surplus",
		"subject_id": "aster",
		"topic": "surplus",
		"claim": "Aster's stores are full again",
		"observability": "local",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"conditions": [{"field": "food_level", "op": "gte", "value": 2}]
	}
}

var state := WorldState.new()
var interpretation_system := InterpretationSystem.new()
var intent_rules := IntentRules.new()
var action_rules := ActionRules.new()
var execution_rules := ExecutionRules.new()
var perception_rules := PerceptionRules.new()
var knowledge_rules := KnowledgeRules.new()
var debug_logging_enabled: bool = true


func get_current_event() -> Dictionary:
	return EVENTS[state.current_event_id]


func get_action(action_id: String) -> Dictionary:
	return ACTIONS[action_id]


func can_resolve(action_id: String) -> bool:
	if state.action_taken or not ACTIONS.has(action_id):
		return false
	return state.divine_power >= int(ACTIONS[action_id]["cost"])


func resolve_action(action_id: String) -> Dictionary:
	if state.action_taken:
		return {"ok": false, "message": "The world is already interpreting your choice."}
	if not ACTIONS.has(action_id):
		return {"ok": false, "message": "That action is unknown."}

	var action: Dictionary = ACTIONS[action_id]
	var cost := int(action["cost"])
	if state.divine_power < cost:
		return {"ok": false, "message": "Insufficient Divine Power. Choose another response."}

	state.divine_power -= cost
	state.action_counts[action_id] += 1
	var immediate_result := _apply_immediate_action(action_id)
	var interpretation := interpretation_system.choose(state, action_id, state.current_event_id)
	var previous_reputation := state.reputation
	var new_flags := _apply_interpretation(interpretation)
	var belief_formed := _apply_belief_pressure(interpretation)
	_update_reputation(action_id, str(interpretation["reputation_hint"]))

	state.last_result = immediate_result
	state.last_interpretation = str(interpretation["interpretation"])
	state.last_interpretation_id = str(interpretation["id"])
	state.interpretation_history.append(state.last_interpretation_id)
	state.previous_action_id = action_id
	state.action_taken = true
	state.add_history(str(interpretation["history_text"]))
	if not belief_formed.is_empty():
		state.add_history("From these events, a belief spread: \"%s\"" % belief_formed)
	state.clamp_values()

	var result := {
		"ok": true,
		"message": state.last_result,
		"interpretation": state.last_interpretation,
		"interpretation_id": state.last_interpretation_id,
		"belief_tag": str(interpretation["belief_tag"]),
		"belief_strength": int(interpretation["belief_strength"]),
		"belief_formed": belief_formed,
		"reputation_hint": str(interpretation["reputation_hint"]),
		"reputation_changed": previous_reputation != state.reputation,
		"history_text": str(interpretation["history_text"]),
		"new_flags": new_flags
	}
	_log_interpretation(action_id, interpretation, new_flags, previous_reputation, belief_formed)
	state_changed.emit()
	return result


func advance_year() -> Dictionary:
	if not state.action_taken:
		return {"ok": false, "message": "Choose a divine response before advancing time."}

	state.year += 1
	state.divine_power = mini(state.divine_power + 2, state.max_divine_power)
	state.last_relationship_changes = tick_relationships()
	state.last_knowledge_shares = tick_knowledge()
	state.last_intents = tick_intents()
	state.last_actions = tick_action_selection()
	state.last_executions = tick_action_execution()
	_process_population()
	_process_world_drift()
	_select_next_event()
	state.action_taken = false
	state.last_result = "A new year begins. The people watch for meaning."
	state.last_interpretation = ""
	state.last_interpretation_id = ""
	state.clamp_values()
	state.last_perceptions = tick_perception()
	state_changed.emit()
	return {"ok": true, "message": state.last_result}


func tick_relationships() -> Array[Dictionary]:
	var tick_changes: Array[Dictionary] = []
	for record_value in state.relationships.values():
		var record: Dictionary = record_value
		var source: Dictionary = state.notable_entities.get(record["source_id"], {})
		var target: Dictionary = state.notable_entities.get(record["target_id"], {})
		if source.is_empty() or target.is_empty():
			continue
		var changes := _relationship_trait_changes(source, target)
		if changes.is_empty():
			continue
		var before := record.duplicate(true)
		var after := state.change_relationship(str(record["source_id"]), str(record["target_id"]), changes)
		tick_changes.append({
			"relationship_id": record["id"],
			"source_id": record["source_id"],
			"target_id": record["target_id"],
			"source_traits": source["traits"].duplicate(),
			"target_traits": target["traits"].duplicate(),
			"changes": changes,
			"before": _relationship_axes(before),
			"after": _relationship_axes(after)
		})
	return tick_changes


func evaluate_knowledge_share(
	source_id: String,
	target_id: String,
	knowledge_id: String,
	skip_willingness: bool = false
) -> Dictionary:
	return knowledge_rules.evaluate_transfer(
		state, source_id, target_id, knowledge_id, skip_willingness
	)


func share_knowledge(source_id: String, target_id: String, knowledge_id: String) -> Dictionary:
	var evaluation := evaluate_knowledge_share(source_id, target_id, knowledge_id)
	evaluation["shared"] = false
	if not bool(evaluation["allowed"]):
		_log_knowledge_share(evaluation)
		return evaluation
	var existing := state.get_knowledge(target_id, knowledge_id)
	if (
		not existing.is_empty()
		and not bool(existing.get("is_outdated", false))
		and int(existing["confidence"]) >= int(evaluation["received_confidence"])
	):
		evaluation["allowed"] = false
		evaluation["reason"] = "receiver_more_confident"
		_log_knowledge_share(evaluation)
		return evaluation
	var received_record := knowledge_rules.build_received_record(
		state,
		source_id,
		target_id,
		knowledge_id,
		evaluation
	)
	if received_record.is_empty():
		evaluation["allowed"] = false
		evaluation["reason"] = "record_build_failed"
		return evaluation
	state.learn_knowledge(target_id, received_record)
	evaluation["shared"] = true
	evaluation["record"] = state.get_knowledge(target_id, knowledge_id)
	state.knowledge_events.append({
		"type": "rumor_shared",
		"year": state.year,
		"source_id": source_id,
		"target_id": target_id,
		"knowledge_id": knowledge_id,
		"confidence": evaluation["received_confidence"],
		"distorted": evaluation["distorted"]
	})
	_log_knowledge_share(evaluation)
	return evaluation


func tick_knowledge() -> Array[Dictionary]:
	state.age_knowledge()
	var attempts: Array[Dictionary] = []
	var source_ids: Array = state.notable_entities.keys()
	source_ids.sort()
	for source_index in source_ids.size():
		if attempts.size() >= KnowledgeRules.MAX_YEARLY_SHARES:
			break
		# At most half of the notable entities try to speak in a given year.
		var source_id := str(source_ids[source_index])
		var source_schedule := _stable_id_value(source_id)
		if (state.year + source_schedule) % 2 != 0:
			continue
		var knowledge_ids: Array = state.get_all_knowledge(source_id).keys()
		if knowledge_ids.is_empty():
			continue
		knowledge_ids.sort()
		var target_ids := _knowledge_targets_for(source_id)
		if target_ids.is_empty():
			continue
		var knowledge_id := str(knowledge_ids[(state.year + source_schedule) % knowledge_ids.size()])
		var target_rotation := int(state.year / 2.0) + source_schedule
		var target_id := str(target_ids[target_rotation % target_ids.size()])
		attempts.append(share_knowledge(source_id, target_id, knowledge_id))
	return attempts


func tick_intents() -> Array[Dictionary]:
	# Intentions only: this pass records what actors want, and changes nothing
	# else in the world. Nobody attempts anything here.
	var made: Array[Dictionary] = []
	var actor_ids: Array = state.notable_entities.keys()
	actor_ids.sort()
	for actor_index in actor_ids.size():
		if made.size() >= IntentRules.MAX_INTENTS_PER_YEAR:
			break
		# At most half of the notable entities form an intention in a given year.
		var actor_id := str(actor_ids[actor_index])
		var actor_schedule := _stable_id_value(actor_id)
		if (state.year + actor_schedule) % 2 != 0:
			continue
		var intent := intent_rules.choose_intent(state, actor_id)
		if intent.is_empty():
			continue
		made.append(state.record_intent(intent))
	return made


func observable_fact() -> Dictionary:
	# What the world is currently showing anyone who looks. It is a property of
	# the world, not of the observer: the same fact, or nothing, for everyone.
	# An event the world absorbed makes nothing observable.
	var template: Dictionary = EVENT_KNOWLEDGE.get(state.current_event_id, {})
	if template.is_empty():
		return {}
	for condition: Dictionary in template.get("conditions", []):
		if not _event_condition_met(condition):
			return {}
	return {
		"id": str(template["id"]),
		"event_id": state.current_event_id,
		"subject_id": str(template["subject_id"]),
		"topic": str(template["topic"]),
		"claim": str(template["claim"]),
		"confidence": int(template["confidence"]),
		"truth_state": str(template["truth_state"]),
		"objective_truth_state": str(template["truth_state"]),
		"fresh_for_years": int(template["fresh_for_years"]),
		"observability": str(template.get("observability", PerceptionRules.DEFAULT_OBSERVABILITY)),
		# World events have no named participants yet. Events generated by what
		# mortals do to each other will, and direct perception is waiting for them.
		"participants": template.get("participants", [])
	}


func tick_perception() -> Array[Dictionary]:
	# An event happening is not the same as a mortal knowing it happened.
	#
	# Two phases, so no observer is affected by who looked first: every chance
	# to notice is judged against the same world, and only then does anyone
	# learn anything. One observer coming to know a thing must never change
	# whether another could see it for themselves.
	var opportunities: Array[Dictionary] = []
	var fact := observable_fact()
	if fact.is_empty():
		return opportunities
	var entity_ids: Array = state.notable_entities.keys()
	entity_ids.sort()
	for entity_id_value in entity_ids:
		opportunities.append(perception_rules.evaluate(state, fact, str(entity_id_value)))
	for opportunity: Dictionary in opportunities:
		if not bool(opportunity["perceived"]):
			continue
		# Perception supplies the observation; the knowledge system owns what
		# happens to it from here — ageing, distortion, transmission and all.
		var record := state.learn_direct_knowledge(
			str(opportunity["observer_id"]),
			perception_rules.perceived_claim(fact, opportunity)
		)
		if record.is_empty():
			opportunity["perceived"] = false
			opportunity["reason"] = "could_not_be_stored"
			continue
		opportunity["knowledge_id"] = str(record["id"])
		state.record_perception(opportunity)
	_log_perception(opportunities)
	return opportunities

func _event_condition_met(condition: Dictionary) -> bool:
	var left := _event_state_value(str(condition["field"]))
	var right := int(condition["value"])
	match str(condition["op"]):
		"gte":
			return left >= right
		"lte":
			return left <= right
		"eq":
			return left == right
	return false


func _event_state_value(field: String) -> int:
	match field:
		"food_level":
			return state.food_level
		"stability_level":
			return state.stability_level
		"prosperity_level":
			return state.prosperity_level
		"military_level":
			return state.military_level
		"faith":
			return state.faith
		"population":
			return state.population
	return 0


func _log_perception(opportunities: Array[Dictionary]) -> void:
	if not debug_logging_enabled or opportunities.is_empty():
		return
	var saw: Array[String] = []
	var missed: Array[String] = []
	for opportunity: Dictionary in opportunities:
		if bool(opportunity["perceived"]):
			saw.append("%s(%d)" % [str(opportunity["observer_id"]), int(opportunity["confidence"])])
		else:
			missed.append("%s(%s)" % [str(opportunity["observer_id"]), str(opportunity["reason"])])
	var first: Dictionary = opportunities[0]
	print("[Worldsim][Year %d][Perception] event=%s fact=%s %s | saw=%s | missed=%s" % [
		state.year,
		str(first["event_id"]),
		str(first["topic_id"]),
		str(first["observability"]),
		"none" if saw.is_empty() else ", ".join(saw),
		"none" if missed.is_empty() else ", ".join(missed)
	])

func tick_action_selection() -> Array[Dictionary]:
	# One attempt per want formed this year, and nothing is attempted. This pass
	# records what each actor is about to try; whether it works, and what it
	# changes, belong to Action Execution, which does not exist yet.
	var selected: Array[Dictionary] = []
	for intent: Dictionary in state.last_intents:
		var action := action_rules.choose_action(state, intent)
		if action.is_empty():
			continue
		selected.append(state.record_action(action))
	return selected


func tick_action_execution() -> Array[Dictionary]:
	# Two phases, so nobody gains anything from sorting first. Every attempt is
	# decided against the world as it stood when the year's executions began,
	# and only then are the immediate effects applied together.
	#
	# Immediate effects only. No relationship moves, no statistic changes, no
	# history is written: this pass records what came of each attempt and stops.
	var planned: Array[Dictionary] = []
	var observable := observable_fact()
	for action: Dictionary in state.last_actions:
		var record := execution_rules.plan(state, action, observable)
		if record.is_empty():
			continue
		planned.append(record)
	var results: Array[Dictionary] = []
	for record: Dictionary in planned:
		results.append(state.record_execution(execution_rules.apply(state, record)))
	return results


func execute_mortal_action(action: Dictionary) -> Dictionary:
	var record := execution_rules.plan(state, action, observable_fact())
	if record.is_empty():
		return {}
	return state.record_execution(execution_rules.apply(state, record))


func plan_mortal_action(action: Dictionary) -> Dictionary:
	return execution_rules.plan(state, action, observable_fact())


func evaluate_mortal_actions(intent: Dictionary) -> Array[Dictionary]:
	return action_rules.evaluate_actions(state, intent)


func choose_mortal_action(intent: Dictionary) -> Dictionary:
	return action_rules.choose_action(state, intent)


func evaluate_intents(actor_id: String) -> Array[Dictionary]:
	return intent_rules.evaluate_intents(state, actor_id)


func choose_intent(actor_id: String) -> Dictionary:
	return intent_rules.choose_intent(state, actor_id)


func _knowledge_targets_for(source_id: String) -> Array[String]:
	var targets: Array[String] = []
	for relationship_value in state.relationships.values():
		var relationship: Dictionary = relationship_value
		if str(relationship["source_id"]) == source_id:
			var target_id := str(relationship["target_id"])
			if target_id not in targets:
				targets.append(target_id)
	targets.sort()
	return targets


func _stable_id_value(entity_id: String) -> int:
	var value := 0
	for character_index in entity_id.length():
		value += entity_id.unicode_at(character_index)
	return value


func _relationship_trait_changes(source: Dictionary, target: Dictionary) -> Dictionary:
	var totals := {"trust": 0, "fear": 0, "respect": 0, "hostility": 0}
	var source_traits: Array = source.get("traits", [])
	var target_traits: Array = target.get("traits", [])
	for source_trait_value in source_traits:
		var source_trait := str(source_trait_value)
		var rule: Dictionary = TRAIT_RELATIONSHIP_RULES.get(source_trait, {})
		_add_relationship_changes(totals, rule.get("outlook", {}))
		var affinities: Dictionary = rule.get("toward_traits", {})
		for target_trait_value in target_traits:
			_add_relationship_changes(totals, affinities.get(str(target_trait_value), {}))
	for target_trait_value in target_traits:
		var target_rule: Dictionary = TRAIT_RELATIONSHIP_RULES.get(str(target_trait_value), {})
		_add_relationship_changes(totals, target_rule.get("impression", {}))
	var non_zero := {}
	for axis: String in WorldState.RELATIONSHIP_AXES:
		if int(totals[axis]) != 0:
			non_zero[axis] = totals[axis]
	return non_zero


func _add_relationship_changes(totals: Dictionary, changes: Dictionary) -> void:
	for axis: String in WorldState.RELATIONSHIP_AXES:
		totals[axis] = int(totals[axis]) + int(changes.get(axis, 0))


func _relationship_axes(record: Dictionary) -> Dictionary:
	var result := {}
	for axis: String in WorldState.RELATIONSHIP_AXES:
		result[axis] = record[axis]
	return result


func _apply_immediate_action(action_id: String) -> String:
	match action_id:
		"send_rain":
			return _resolve_send_rain()
		"bless_harvest":
			return _resolve_bless_harvest()
		"speak_mortal":
			return _resolve_speak_mortal()
		"do_nothing":
			return "No divine sign appears. Mortals must decide what the silence means."
	return "The world waits."


func _resolve_send_rain() -> String:
	state.intervention_counts["rain_during_drought"] += int(state.current_event_id == "drought")
	if state.current_event_id == "drought":
		state.food_level += 2
		state.faith += 5
		state.followers += 16
		if state.food_level <= 1:
			state.stability_level += 1
		return "Rain reaches the Grey River and the empty wells begin to fill."
	state.food_level += 1
	state.faith += 2
	state.followers += 6
	return "Unexpected rain passes over Aster and changes the season's course."


func _resolve_bless_harvest() -> String:
	var improvement := 2 if state.current_event_id == "good_harvest" else 1
	state.food_level += improvement
	state.population_growth_bonus += 4
	state.faith += 3
	state.followers += 8
	state.intervention_counts["blessed_harvest"] += 1
	if state.prosperity_level <= 1:
		state.prosperity_level += 1
		return "Full granaries begin lifting Aster out of poverty."
	return "The fields yield more grain than their soil should allow."


func _resolve_speak_mortal() -> String:
	state.mara_exists = true
	state.faith += 5
	state.followers += 12
	state.intervention_counts["mortal_voice"] += 1
	if state.current_event_id == "unrest":
		state.stability_level += 1
	return "Mara speaks with an unfamiliar certainty, and the crowd turns to listen."


func _apply_interpretation(interpretation: Dictionary) -> Array[String]:
	var new_flags: Array[String] = []
	var effects: Dictionary = interpretation.get("effects", {})
	state.food_level += int(effects.get("food", 0))
	state.stability_level += int(effects.get("stability", 0))
	state.prosperity_level += int(effects.get("prosperity", 0))
	state.faith += int(effects.get("faith", 0))
	state.followers += int(effects.get("followers", 0))
	state.population_growth_bonus += int(effects.get("population_growth_bonus", 0))
	for flag: String in interpretation.get("flags", []):
		if not bool(state.world_flags.get(flag, false)):
			state.world_flags[flag] = true
			new_flags.append(flag)
	if state.world_flags["mara_is_prophet"]:
		state.prophet_created = true
	if bool(interpretation.get("useful_silence", false)):
		state.useful_silence_outcomes += 1
	return new_flags


func _apply_belief_pressure(interpretation: Dictionary) -> String:
	var tag := str(interpretation["belief_tag"])
	var strength := int(interpretation["belief_strength"])
	state.belief_pressure[tag] = int(state.belief_pressure.get(tag, 0)) + strength
	var definition: Dictionary = BELIEF_DEFINITIONS[tag]
	var belief_name := str(definition["name"])
	var newly_formed := ""
	if state.belief_pressure[tag] >= int(definition["threshold"]) and tag not in state.known_beliefs:
		state.known_beliefs.append(tag)
		newly_formed = belief_name
	_refresh_active_beliefs()
	return newly_formed


func _refresh_active_beliefs() -> void:
	var ranked_tags: Array[String] = []
	for tag: String in state.known_beliefs:
		var inserted := false
		for index in ranked_tags.size():
			if int(state.belief_pressure[tag]) > int(state.belief_pressure[ranked_tags[index]]):
				ranked_tags.insert(index, tag)
				inserted = true
				break
		if not inserted:
			ranked_tags.append(tag)
	state.beliefs.clear()
	for index in mini(ranked_tags.size(), MAX_ACTIVE_BELIEFS):
		state.beliefs.append(str(BELIEF_DEFINITIONS[ranked_tags[index]]["name"]))


func _update_reputation(action_id: String, reputation_hint: String) -> void:
	match action_id:
		"send_rain":
			state.reputation_pressure["Merciful"] += 1
			state.reputation_pressure["Protector"] += 1
		"bless_harvest":
			state.reputation_pressure["Merciful"] += 1
		"speak_mortal":
			state.reputation_pressure["Teacher"] += 1
		"do_nothing":
			state.reputation_pressure["Silent"] += 2
	state.reputation_pressure[reputation_hint] += 2

	var helpful_actions := int(state.action_counts["send_rain"]) + int(state.action_counts["bless_harvest"])
	var silent_actions := int(state.action_counts["do_nothing"])
	if helpful_actions >= 2 and silent_actions >= 2:
		state.reputation_pressure["Unpredictable"] += 2
	if not state.previous_action_id.is_empty() and state.previous_action_id != action_id:
		state.reputation_pressure["Unpredictable"] += 1

	var strongest := "Unknown"
	# A label only emerges after several compatible observations.
	var strongest_score := 4
	for candidate: String in REPUTATION_ORDER:
		var score := int(state.reputation_pressure[candidate])
		if score > strongest_score:
			strongest = candidate
			strongest_score = score
	if strongest != state.reputation:
		state.reputation_changes.append("%s -> %s" % [state.reputation, strongest])
		state.reputation = strongest


func _process_population() -> void:
	var growth := 1 + state.population_growth_bonus
	match state.food_level:
		0:
			growth -= 8
		1:
			growth -= 2
		2:
			growth += 3
		3:
			growth += 7
	if state.stability_level == 0:
		growth -= 5
	state.population += growth
	state.population_growth_bonus = 0


func _process_world_drift() -> void:
	if state.food_level > 0:
		state.food_level -= 1
	if state.food_level == 0:
		state.prosperity_level -= 1
	elif state.food_level >= 2 and state.stability_level >= 2:
		state.prosperity_level += 1
	if state.stability_level == 0:
		state.followers -= 5


func _select_next_event() -> void:
	var cycle := ["drought", "good_harvest", "unrest"]
	state.current_event_id = cycle[(state.year - 12) % cycle.size()]
	match state.current_event_id:
		"drought":
			_begin_drought()
		"good_harvest":
			_begin_good_harvest()
		"unrest":
			_begin_unrest()


func _begin_drought() -> void:
	if state.world_flags["wells_built"]:
		state.world_flag_use_counts["wells_built"] += 1
		if state.world_flags["irrigation_known"]:
			state.world_flag_use_counts["irrigation_known"] += 1
			state.population_growth_bonus += 1
		state.add_history("The wells built during the Great Silence allowed Aster to withstand another drought.")
		return
	state.food_level -= 1
	if state.food_level <= 0:
		state.population -= 8
		state.stability_level -= 1
		state.add_history("Drought struck empty stores, driving hungry families from Aster and weakening public order.")
	elif state.faith >= 55:
		state.followers += 5
		state.add_history("As the skies dried again, growing numbers gathered at the shrine to pray.")
	else:
		state.add_history("Cloudless skies returned, and the Grey River began to shrink.")


func _begin_good_harvest() -> void:
	state.food_level += 1
	if state.prosperity_level <= 1:
		state.prosperity_level += 1
		state.population_growth_bonus += 3
	if state.world_flags["irrigation_known"]:
		state.world_flag_use_counts["irrigation_known"] += 1
		state.food_level += 1
		state.add_history("Channels first cut by Aster's farmers turned mild weather into a harvest large enough to restore trade.")
	elif state.belief_pressure["naturalism"] >= 3:
		state.add_history("The fields ripened, and villagers debated whether skill or providence deserved the credit.")
	else:
		state.add_history("The fields ripened beneath a mild and generous sun, offering Aster a path out of poverty.")


func _begin_unrest() -> void:
	state.stability_level -= 1
	if state.prosperity_level == 0:
		state.stability_level -= 1
	if state.world_flags["local_council_empowered"]:
		state.world_flag_use_counts["local_council_empowered"] += 1
		state.stability_level += 1
		state.add_history("The elders who once ended unrest without divine aid negotiated another peaceful settlement.")
	elif state.world_flags["mara_is_prophet"] and state.faith >= 45:
		state.world_flag_use_counts["mara_is_prophet"] += 1
		state.stability_level += 1
		state.add_history("Mara invoked her earlier revelation and calmed a crowd angered by Aster's poverty.")
	elif state.world_flags["king_claims_divine_favor"]:
		state.world_flag_use_counts["king_claims_divine_favor"] += 1
		if state.faith >= 45:
			state.stability_level += 1
			state.add_history("The king invoked his claimed divine favour and persuaded the crowd to stand down.")
		else:
			state.stability_level -= 1
			state.add_history("The king invoked divine favour, but a sceptical crowd treated the claim as proof of corruption.")
	else:
		state.add_history("Poor conditions sharpened old grievances, drawing an angry crowd into Aster's square.")


func _log_interpretation(
	action_id: String,
	interpretation: Dictionary,
	new_flags: Array[String],
	previous_reputation: String,
	belief_formed: String
) -> void:
	if not debug_logging_enabled:
		return
	var tag := str(interpretation["belief_tag"])
	print("[Worldsim][Year %d] action=%s event=%s interpretation=%s weight=%d" % [
		state.year,
		action_id,
		state.current_event_id,
		interpretation["id"],
		interpretation["selected_weight"]
	])
	print("  belief=%s +%d => %d%s" % [
		tag,
		interpretation["belief_strength"],
		state.belief_pressure[tag],
		" (formed: %s)" % belief_formed if not belief_formed.is_empty() else ""
	])
	if not new_flags.is_empty():
		print("  world_flags_created=%s" % ", ".join(new_flags))
	if previous_reputation != state.reputation:
		print("  reputation=%s -> %s" % [previous_reputation, state.reputation])


func _log_knowledge_share(result: Dictionary) -> void:
	if not debug_logging_enabled:
		return
	print("[Worldsim][Year %d][Knowledge] %s -> %s knowledge=%s result=%s score=%d/%d" % [
		state.year,
		result["source_id"],
		result["target_id"],
		result["knowledge_id"],
		result["reason"],
		result["share_score"],
		result["share_score_required"]
	])
	if bool(result.get("shared", false)):
		print("  confidence=%d -> %d distorted=%s traits=%s" % [
			result["source_confidence"],
			result["received_confidence"],
			result["distorted"],
			", ".join(result["trait_effects"])
		])
