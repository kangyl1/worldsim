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
		"description": "For three months, no rain has fallen. %s's wells are drying up. Farmers have gathered outside the old shrine and are asking an unknown god for help.",
		"ascii": "       _\n      /_\\\n   o  | |  o\n  /|\\ | | /|\\\n  / \\ |_| / \\"
	},
	"good_harvest": {
		"title": "A PROMISING HARVEST",
		"description": "Heavy heads of grain bend in the fields. The people wonder whether fortune, labour, or an unseen hand has favoured %s.",
		"ascii": "  \\ | /   \\ | /\n --\\|/-- --\\|/--\n    |       |\n   / \\     / \\"
	},
	"unrest": {
		"title": "VOICES IN THE SQUARE",
		"description": "Empty cupboards have sharpened old grudges in %s. A crowd gathers before the storehouse. Some demand justice; others demand a sign.",
		"ascii": "  o  o  o  o\n /|\\/|\\/|\\/|\\\n / \\/ \\/ \\/ \\"
	}
}

# What each event makes perceivable, and how widely. Conditions are checked
# against the SUBJECT SETTLEMENT after the event handler and clamping have run,
# so an event a place absorbed offers nothing to notice.
#
# Nothing here names a settlement. The same three templates serve Aster,
# Westfield, the Frontier and anywhere added later: the claim is a format
# string, and the knowledge id is built from the settlement it concerns, so
# "Westfield does not have enough food" and "Aster does not have enough food"
# are separate beliefs that can be held, aged and spread independently.
#
# These templates say what CAN be perceived. They do not say who learns it:
# that is Selective Perception's question, and every claim is local to its
# settlement. Someone living elsewhere finds out by being told.
const EVENT_KNOWLEDGE := {
	"drought": {
		"id_suffix": "food_shortage",
		"topic": "food_shortage",
		"claim": "%s does not have enough food",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"observability": "local",
		"conditions": [{"band": "food", "op": "lte", "value": 1}]
	},
	"unrest": {
		"id_suffix": "unrest",
		"topic": "danger_unrest",
		"claim": "Order is breaking down in %s",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"observability": "local",
		"conditions": [{"band": "stability", "op": "lte", "value": 0}]
	},
	"good_harvest": {
		"id_suffix": "surplus",
		"topic": "surplus",
		"claim": "%s's stores are full again",
		"confidence": 90,
		"truth_state": "true",
		"fresh_for_years": 3,
		"observability": "local",
		"conditions": [{"band": "food", "op": "gte", "value": 2}]
	}
}

var state := WorldState.new()
var divine_reception_system := DivineReceptionSystem.new()
var interpretation_rules := InterpretationRules.new()

# Which road a divine act takes is registered in `divine_action_rules.gd` and
# asked for here. Nothing in this file may branch on an action id to decide it:
# one power's migration must not mean hunting for `if action_id == ...` across
# the simulation. This is roadmap item 12, one power at a time.
var divine_action_rules := DivineActionRules.new()

# What the player is offered, and what it costs them. Separate from the causal
# registry on purpose: how a power is presented and priced is an economy and
# interface question, while `divine_action_rules.gd` answers only how the act
# enters the world. A power needs an entry in both, and neither belongs in the
# other.
#
# A var rather than a const for the same narrow reason the registry is: a test
# can offer a power the catalogue was not written with.
var actions: Dictionary = ACTIONS.duplicate(true)
var intent_rules := IntentRules.new()
var action_rules := ActionRules.new()
var execution_rules := ExecutionRules.new()
var perception_rules := PerceptionRules.new()
var consequence_rules := ConsequenceRules.new()
var chronicle_rules := ChronicleRules.new()
var belief_rules := BeliefRules.new()
# Presentation only. It reads records and writes nothing; see feedback_rules.gd.
var feedback_rules := FeedbackRules.new()

# How much water one Send Rain puts into the ground, and how fast the ground
# gives it back. Prototype tuning, chosen to make the sandbox provable rather
# than balanced: rain adds more than a year returns, so a player who keeps
# raining on one place will eventually flood it — roughly four consecutive
# years from the baseline — and a player who stops will see it drain back over
# about a decade.
const RAIN_WATER_GAIN := 22
const WATER_DRIFT_PER_YEAR := 6

# What a settlement's water level does to its harvest when rain arrives, keyed
# by the state it was in BEFORE the rain fell.
#
# This is the heart of the milestone. Send Rain has no idea whether it is
# "appropriate": it applies the same force every time, and whether that force
# helps or ruins depends entirely on what the ground was already holding.
const RAIN_OUTCOMES := {
	WorldState.WATER_DRY: {"food": 2, "stability": 0},
	WorldState.WATER_NORMAL: {"food": 0, "stability": 0},
	WorldState.WATER_WET: {"food": 0, "stability": 0},
	WorldState.WATER_SATURATED: {"food": -1, "stability": 0},
	WorldState.WATER_FLOODED: {"food": -2, "stability": -1}
}

# What a settlement crossing into a state makes newly perceivable. Objective
# occurrences, stated as conditions of the WORLD — a place can reach these
# without any god involved, and the claims say nothing about who caused them.
const WATER_KNOWLEDGE := {
	WorldState.WATER_SATURATED: {
		"id_suffix": "water_saturation",
		"topic": "water_saturation",
		"claim": "The ground around %s can hold no more water",
		"confidence": 90,
		"observability": "local"
	},
	WorldState.WATER_FLOODED: {
		"id_suffix": "flooding",
		"topic": "flooding",
		"claim": "Floodwater is standing in %s",
		"confidence": 95,
		"observability": "local"
	}
}
var knowledge_rules := KnowledgeRules.new()
var debug_logging_enabled: bool = true


func get_current_event() -> Dictionary:
	# Events name the settlement they are happening in. One definition serves
	# every settlement rather than one definition per place.
	var event: Dictionary = EVENTS[state.current_event_id].duplicate(true)
	event["location_id"] = state.current_event_location_id
	event["location_name"] = state.location_name(state.current_event_location_id)
	if str(event["description"]).contains("%s"):
		event["description"] = str(event["description"]) % event["location_name"]
	return event


func get_action(action_id: String) -> Dictionary:
	return actions[action_id]


func offer_action(action_id: String, entry: Dictionary) -> void:
	# Put a power in front of the player. Its causal handling is registered
	# separately, in `divine_action_rules.gd`.
	actions[action_id] = entry.duplicate(true)


func can_resolve(action_id: String) -> bool:
	if state.action_taken or not actions.has(action_id):
		return false
	return state.divine_power >= int(actions[action_id]["cost"])


# `target_location_id` is the settlement the PLAYER chose.
#
# It defaults to wherever the year's event landed, which is what every
# unmigrated power still relies on and what every existing caller expects. But a
# player who wants to rain on a quiet settlement while another one starves is
# allowed to: divine power is a force applied where the god chooses, not a
# response the simulation approves of. Nothing here consults whether the target
# needs it, and nothing picks a better one.
func resolve_action(action_id: String, target_location_id: String = "") -> Dictionary:
	if state.action_taken:
		return {"ok": false, "message": "The world is already interpreting your choice."}
	if not actions.has(action_id):
		return {"ok": false, "message": "That action is unknown."}

	var action: Dictionary = actions[action_id]
	var cost := int(action["cost"])
	if state.divine_power < cost:
		return {"ok": false, "message": "Insufficient Divine Power. Choose another response."}

	# A fresh turn: last turn's crossings are no longer news.
	state.last_water_events = []
	state.divine_power -= cost
	# Tolerant of a power the tally was not written with, so registering one does
	# not mean editing a counter dictionary in `world_state.gd` as well.
	state.action_counts[action_id] = int(state.action_counts.get(action_id, 0)) + 1
	# The chosen target, or the year's event if the caller named none. An
	# unknown id falls back rather than failing, so a stale selection cannot
	# strand the player.
	var location_id := target_location_id
	if location_id.is_empty() or not state.locations.has(location_id):
		location_id = state.current_event_location_id
	state.last_divine_target_id = location_id
	var before := _settlement_snapshot(location_id)
	var immediate_result := _apply_immediate_action(action_id, location_id)
	# The same consequence pipeline mortals use. What the act changed is already
	# in the world; this records that it happened and gives mortals something to
	# notice. No motive is attached: "rain fell" is the fact, and what it means
	# is theirs to decide.
	var divine_consequence := consequence_rules.plan_divine(
		state, action_id, location_id, _settlement_changes(location_id, before),
		divine_action_rules.occurrence_for(action_id)
	)
	# Read before applying: apply() hands the fact to perception and erases it
	# from the record, so the claim has to be taken while it is still there.
	var planned_fact: Dictionary = divine_consequence.get("pending_fact", {})
	var occurrence_claim := str(planned_fact.get("claim", ""))
	var applied_consequence := state.record_consequence(
		consequence_rules.apply(state, divine_consequence)
	)
	# What the god did, kept apart from what it changed and from what anyone
	# will make of it. Recorded for BOTH paths: the record is about the act.
	var divine_record := state.record_divine_action({
		"id": "divine_%04d_%s_%s" % [state.year, action_id, location_id],
		"year": state.year,
		"action_type": action_id,
		"target_id": location_id,
		"subject_id": state.current_event_id,
		"parameters": {"event_id": state.current_event_id},
		"power_cost": cost,
		"result": immediate_result,
		"consequence_id": str(applied_consequence.get("id", "")),
		# Which road this power takes. The whole point of the flag is that both
		# roads must never run for one act.
		"pipeline": divine_action_rules.pipeline_for(action_id),
		# What mortals were offered, if anything. Named here so the record can
		# point at the rest of the chain without absorbing it.
		"occurrence_topic": divine_action_rules.topic_for(action_id)
	})
	state.previous_action_id = action_id
	state.action_taken = true
	state.last_result = immediate_result

	if divine_action_rules.is_shared_pipeline(action_id):
		# MIGRATED. Nothing here decides what the act meant. The consequence is
		# already queued as a fact; perception will choose who notices it next
		# tick, and each of them will reach their own conclusion — including the
		# conclusion that it was only weather.
		#
		# No collective interpretation, no belief pressure, no reputation. The
		# history line states the occurrence and stops, exactly as a mortal
		# consequence claim does.
		state.last_interpretation = ""
		state.last_interpretation_id = ""
		# States the occurrence and stops. "Rain fell on Aster" is what happened;
		# "the god answered Aster" would be what somebody decided it meant, and
		# the log is not the place that gets decided.
		if not occurrence_claim.is_empty():
			state.add_history(occurrence_claim)
		state.clamp_values()
		var shared_result := {
			"ok": true,
			"message": state.last_result,
			"pipeline": DivineActionRules.PIPELINE_SHARED,
			"divine_action_id": str(divine_record["id"]),
			"consequence_id": str(applied_consequence.get("id", "")),
			# Deliberately absent: interpretation, belief and reputation are not
			# this layer's to report any more.
			"interpretation": "",
			"interpretation_id": "",
			"belief_tag": "",
			"belief_strength": 0,
			"belief_formed": "",
			"reputation_hint": "",
			"reputation_changed": false,
			"history_text": occurrence_claim,
			"new_flags": [] as Array[String]
		}
		_log_divine_action(divine_record)
		state_changed.emit()
		return shared_result

	# LEGACY, for every power not yet migrated. One collective meaning, read out
	# of the act itself. Untouched on purpose; see `divine_action_rules.gd`.
	var interpretation := divine_reception_system.choose(state, action_id, state.current_event_id)
	var previous_reputation := state.reputation
	var new_flags := _apply_interpretation(interpretation)
	var belief_formed := _apply_belief_pressure(interpretation)
	_update_reputation(action_id, str(interpretation["reputation_hint"]))

	state.last_interpretation = str(interpretation["interpretation"])
	state.last_interpretation_id = str(interpretation["id"])
	state.interpretation_history.append(state.last_interpretation_id)
	state.add_history(str(interpretation["history_text"]))
	if not belief_formed.is_empty():
		state.add_history("From these events, a belief spread: \"%s\"" % belief_formed)
	state.clamp_values()

	var result := {
		"ok": true,
		"message": state.last_result,
		"pipeline": DivineActionRules.PIPELINE_LEGACY,
		"divine_action_id": str(divine_record["id"]),
		"consequence_id": str(applied_consequence.get("id", "")),
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


func _log_divine_action(record: Dictionary) -> void:
	if not debug_logging_enabled:
		return
	print("[Worldsim][Year %d][Divine] %s -> %s via %s pipeline (cost %d) | %s" % [
		int(record["year"]), str(record["action_type"]), str(record["target_id"]),
		str(record["pipeline"]), int(record["power_cost"]), str(record["result"])
	])


func advance_year() -> Dictionary:
	if not state.action_taken:
		return {"ok": false, "message": "Choose a divine response before advancing time."}

	state.year += 1
	state.divine_power = mini(state.divine_power + 2, state.max_divine_power)
	# The world as it stood before this year moved it. History reads settlement
	# conditions directly, because the yearly cycle and world drift change them
	# without ever writing a consequence record, and a famine nobody recorded is
	# still a famine.
	var conditions_before := _settlement_conditions()
	state.last_relationship_changes = tick_relationships()
	state.last_knowledge_shares = tick_knowledge()
	state.last_intents = tick_intents()
	state.last_actions = tick_action_selection()
	state.last_executions = tick_action_execution()
	state.last_consequences = tick_consequences()
	_process_population()
	_process_water_drift()
	_process_world_drift()
	_select_next_event()
	state.action_taken = false
	state.last_result = "A new year begins. The people watch for meaning."
	state.last_interpretation = ""
	state.last_interpretation_id = ""
	state.clamp_values()
	state.last_perceptions = tick_perception()
	# Interpretation runs AFTER perception and LAST in the year, and both halves
	# of that matter.
	#
	# After perception, because a mortal cannot decide what an occurrence meant
	# before they know it happened. Last in the year, because intents were
	# formed near the top of this tick and must not be reachable from here: a
	# conclusion drawn now changes what someone wants NEXT year, never what they
	# already wanted this one. That is the existing one-step-per-year causal
	# rule, and it is why nothing here creates an action.
	state.last_interpretations = tick_interpretations()
	# Belief updates on this year's readings, and only on them.
	#
	# After interpretation, because a belief is built from conclusions and there
	# are none until they are drawn. Before the chronicle, because a belief
	# becoming established is the kind of thing history may care about. And far
	# enough down the tick that nothing formed here can reach an intent already
	# chosen near the top of it: a belief formed now changes what someone wants
	# NEXT year, which is the same one-step-per-year rule interpretation follows.
	state.last_belief_updates = tick_beliefs()
	# History runs LAST, after everything it reads has settled.
	#
	# It is a record layer, not an actor. Nothing it writes is read by anything
	# this year or any other year's reasoning: no intent consults the chronicle,
	# no action is gated on it, no relationship moves because of it. Placing it
	# last is what makes that easy to keep true — by the time it runs, every
	# decision the year contained has already been made.
	state.last_chronicle_entries = tick_chronicle(conditions_before)
	# The world as mortals have just finished living it, kept for the turn that
	# follows. The god acts BEFORE the year turns, so a snapshot taken at the top
	# of this function would already contain the relief the god just provided —
	# which is how the first version of this silently never fired. Taken here, it
	# is the shortage people actually lived through before anything answered it.
	state.conditions_before_turn = _settlement_conditions()
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
	var location_id := state.current_event_location_id
	for condition: Dictionary in template.get("conditions", []):
		if not _event_condition_met(location_id, condition):
			return {}
	return {
		"id": "%s_%s" % [location_id, str(template["id_suffix"])],
		"event_id": state.current_event_id,
		"subject_id": location_id,
		"topic": str(template["topic"]),
		"claim": str(template["claim"]) % state.location_name(location_id),
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
	# Everything there was to notice this year: what the world did, and what
	# mortals and gods did to each other. Consequence events are private by
	# default, so most of these reach nobody but the people involved.
	var facts: Array[Dictionary] = []
	var world_fact := observable_fact()
	if not world_fact.is_empty():
		facts.append(world_fact)
	facts.append_array(state.pending_perception_facts)
	state.pending_perception_facts = []
	if facts.is_empty():
		return opportunities
	var entity_ids: Array = state.notable_entities.keys()
	entity_ids.sort()
	for fact: Dictionary in facts:
		for entity_id_value in entity_ids:
			opportunities.append(perception_rules.evaluate(state, fact, str(entity_id_value)))
	for opportunity: Dictionary in opportunities:
		if not bool(opportunity["perceived"]):
			continue
		var source_fact := _fact_for(facts, str(opportunity["topic_id"]))
		if source_fact.is_empty():
			continue
		# Perception supplies the observation; the knowledge system owns what
		# happens to it from here — ageing, distortion, transmission and all.
		var record := state.learn_direct_knowledge(
			str(opportunity["observer_id"]),
			perception_rules.perceived_claim(source_fact, opportunity)
		)
		if record.is_empty():
			opportunity["perceived"] = false
			opportunity["reason"] = "could_not_be_stored"
			continue
		opportunity["knowledge_id"] = str(record["id"])
		state.record_perception(opportunity)
	_log_perception(opportunities)
	return opportunities


func _fact_for(facts: Array[Dictionary], knowledge_id: String) -> Dictionary:
	for fact: Dictionary in facts:
		if str(fact["id"]) == knowledge_id:
			return fact
	return {}

func _event_condition_met(location_id: String, condition: Dictionary) -> bool:
	var left := state.get_settlement_band(location_id, str(condition["band"]))
	var right := int(condition["value"])
	match str(condition["op"]):
		"gte":
			return left >= right
		"lte":
			return left <= right
		"eq":
			return left == right
	return false


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


func tick_consequences() -> Array[Dictionary]:
	# What objectively came of the year's attempts, and nothing about what any
	# of it meant. Two phases again, so no consequence can change whether
	# another one exists.
	#
	# Consequences do not reach into relationships, faith or reputation. They
	# emit events, perception decides who noticed, and the meaning is worked out
	# later by whoever noticed. That indirection is the whole design.
	var planned: Array[Dictionary] = []
	for execution: Dictionary in state.last_executions:
		var record := consequence_rules.plan_execution(state, execution)
		if record.is_empty():
			continue
		planned.append(record)
	var applied: Array[Dictionary] = []
	for record: Dictionary in planned:
		applied.append(state.record_consequence(consequence_rules.apply(state, record)))
	return applied


# Every settlement's conditions right now. A plain snapshot; nothing is derived
# and nothing is judged.
func _settlement_conditions() -> Dictionary:
	var snapshot := {}
	for location_id_value in state.locations.keys():
		var location_id := str(location_id_value)
		var bands := {}
		for band: String in WorldState.SETTLEMENT_BANDS:
			bands[band] = state.get_settlement_band(location_id, band)
		# The ground too, so a threshold crossing can be told apart from a
		# settlement that has simply been under water for years.
		bands["water"] = state.get_water(location_id)
		snapshot[location_id] = bands
	return snapshot


# Which of this year's occurrences were important enough to become history.
#
# Consumes records the simulation already wrote — conditions, divine acts,
# consequences, interpretations — and writes only to the chronicle. It creates
# no event, changes no state, and moves nothing anybody will react to.
func tick_chronicle(conditions_before: Dictionary) -> Array[Dictionary]:
	var selection := chronicle_rules.select(
		state,
		conditions_before,
		_divine_actions_this_year(),
		state.last_consequences,
		state.last_interpretations
	)
	state.last_chronicle_rejections = selection["rejected"]
	var written: Array[Dictionary] = []
	for candidate_value in selection["kept"]:
		var candidate: Dictionary = candidate_value
		# Written first, so a parent recorded earlier this year is already
		# findable when the next record looks for its cause.
		var parent_id := chronicle_rules.parent_for(state, candidate)
		var stored := state.record_chronicle(candidate)
		if not parent_id.is_empty():
			state.link_chronicle(parent_id, str(stored["id"]))
		written.append(stored)
	_log_chronicle(written, selection["rejected"])
	return written


# The acts the god has taken that history has not yet considered.
#
# A divine act is resolved BEFORE the turn advances, so it carries the year the
# player took it and the tick that shows its results carries the next one. Asking
# for "acts stamped with this year" therefore finds nothing, which is how the
# first version of this silently chronicled no divine action at all. Asking what
# has not been considered yet has no such edge.
# What this year's conclusions did to what their holders accept.
#
# Reads interpretation records and nothing else. It does not see the divine
# action archive, objective truth, or the realm's faith — a belief founded on
# any of those would be the engine's conclusion wearing a mortal's name.
func tick_beliefs() -> Array[Dictionary]:
	var updates := belief_rules.update_from_interpretations(state, state.last_interpretations)
	_log_beliefs(updates)
	return updates


func _log_beliefs(updates: Array[Dictionary]) -> void:
	if not debug_logging_enabled or updates.is_empty():
		return
	print("[BELIEF %d] %d update(s)" % [state.year, updates.size()])
	for update: Dictionary in updates:
		print("  %-9s %-14s %-28s %d -> %d" % [
			str(update["change"]), str(update["holder_id"]),
			str(update["proposition"]), int(update["before"]), int(update["after"])
		])


func _divine_actions_this_year() -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in state.divine_action_archive:
		if state.year - int(record["year"]) > 1:
			continue
		if state.has_chronicle(state.chronicle_id(int(record["year"]), str(record["id"]))):
			continue
		found.append(record)
	return found


func tick_interpretations() -> Array[Dictionary]:
	# What the year's occurrences MEANT to the people who know about them.
	#
	# Two phases, as everywhere else in this simulation: every mortal reaches
	# their conclusion against the world as it stood, and only then does anyone's
	# relationship move. Without that, whoever was iterated first would colour
	# what the next one made of the same event.
	var reached: Array[Dictionary] = []
	var observer_ids: Array = state.notable_entities.keys()
	observer_ids.sort()
	for observer_id_value in observer_ids:
		var observer_id := str(observer_id_value)
		for knowledge: Dictionary in interpretation_rules.pending_for(state, observer_id):
			var record := interpretation_rules.interpret(state, observer_id, knowledge)
			if record.is_empty():
				continue
			reached.append(record)
	var applied: Array[Dictionary] = []
	for record: Dictionary in reached:
		applied.append(state.record_interpretation(
			interpretation_rules.apply(state, record)
		))
	_log_interpretations(applied)
	return applied


func _log_interpretations(records: Array[Dictionary]) -> void:
	if not debug_logging_enabled or records.is_empty():
		return
	for record: Dictionary in records:
		var effect: Dictionary = record["applied_effect"]
		var effect_text := "none"
		if not effect.is_empty():
			effect_text = "%s->%s %s %+d" % [
				str(effect["source_id"]), str(effect["target_id"]),
				str(effect["axis"]), int(effect["amount"])
			]
		print("[Worldsim][Year %d][Interpretation] %s read %s as %s (score %d) | %s" % [
			state.year,
			str(record["observer_id"]),
			str(record["source_knowledge_id"]),
			str(record["interpretation_type"]),
			int(record["score"]),
			effect_text
		])


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


func _settlement_snapshot(location_id: String) -> Dictionary:
	var snapshot := {}
	for band: String in WorldState.SETTLEMENT_BANDS:
		snapshot[band] = state.get_settlement_band(location_id, band)
	return snapshot


func _settlement_changes(location_id: String, before: Dictionary) -> Array:
	# Before and after, not a delta. What a value was is part of explaining why
	# what it became matters.
	var changes: Array = []
	for band: String in WorldState.SETTLEMENT_BANDS:
		var after := state.get_settlement_band(location_id, band)
		if after == int(before[band]):
			continue
		changes.append({
			"subject_id": location_id,
			"field": band,
			"before": int(before[band]),
			"after": after
		})
	return changes


func _apply_immediate_action(action_id: String, location_id: String) -> String:
	match action_id:
		"send_rain":
			return _resolve_send_rain(location_id)
		"bless_harvest":
			return _resolve_bless_harvest()
		"speak_mortal":
			return _resolve_speak_mortal()
		"do_nothing":
			return "No divine sign appears. Mortals must decide what the silence means."
	return "The world waits."


# Divine acts land where the year's event is happening. A god who sends rain
# during a drought in Westfield helps Westfield, not an average of the realm.
# Faith and followers remain the whole kingdom's, because belief travels.
# MIGRATED to the shared causal pipeline. Rain changes the world and nothing
# else: no faith, no followers, no reputation, no belief. Those were the act
# deciding that mortals believed in it, which is the thing this migration
# exists to stop — belief now has to come from a mortal noticing the rain and
# concluding something about it, and it may equally conclude the weather did it.
#
# Consequence: faith and followers no longer respond to rain at all, because no
# route from a mortal's interpretation to kingdom faith exists yet. That is a
# deliberate gap, recorded rather than papered over, and it closes when the
# remaining powers migrate. The other three powers still move faith directly.
# Rain is a force, not an answer.
#
# It used to ask whether a drought was running and hand out food accordingly,
# which made the power a correct response to a situation. Now it does the same
# thing every time — it puts water in the ground — and what that WAS depends on
# what the ground was already holding. The god is not prevented from ruining a
# harvest by watering a field that was already drowning.
func _resolve_send_rain(location_id: String) -> String:
	var place := state.location_name(location_id)
	var before_state := state.water_state(location_id)
	state.intervention_counts["rain_during_drought"] += int(state.current_event_id == "drought")

	state.change_water(location_id, RAIN_WATER_GAIN)
	var after_state := state.water_state(location_id)

	# The harvest answers to what the ground was like when the rain arrived.
	var outcome: Dictionary = RAIN_OUTCOMES.get(before_state, {})
	var food := int(outcome.get("food", 0))
	var stability := int(outcome.get("stability", 0))
	if food != 0:
		state.change_settlement_band(location_id, "food", food)
	if stability != 0:
		state.change_settlement_band(location_id, "stability", stability)

	# Whatever the ground has newly become, said plainly. No cause is named and
	# no judgement is offered: mortals decide what it meant.
	if before_state != after_state:
		_offer_water_fact(location_id, after_state)
	match after_state:
		WorldState.WATER_FLOODED:
			return "Rain falls on %s until the water has nowhere left to go." % place
		WorldState.WATER_SATURATED:
			return "Rain falls on %s. The ground is already soaked." % place
		WorldState.WATER_WET:
			return "Rain falls on %s and the fields drink their fill." % place
	return "Rain falls on %s and the dry soil begins to recover." % place


# A settlement's condition becoming perceivable. Generic: any location reaching
# the state offers the fact, whoever or whatever put it there.
func _offer_water_fact(location_id: String, water_state: String) -> void:
	# Recorded whether or not anybody can perceive it: the crossing is a fact
	# about the ground, and presentation reads this rather than the level, which
	# drift may already have moved.
	state.last_water_events.append({
		"location_id": location_id,
		"water_state": water_state,
		"year": state.year
	})
	var template: Dictionary = WATER_KNOWLEDGE.get(water_state, {})
	if template.is_empty():
		return
	state.pending_perception_facts.append({
		"id": "%s_%s" % [location_id, str(template["id_suffix"])],
		"event_id": str(template["topic"]),
		"subject_id": location_id,
		"topic": str(template["topic"]),
		"claim": str(template["claim"]) % state.location_name(location_id),
		"confidence": int(template["confidence"]),
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": WorldState.DEFAULT_KNOWLEDGE_FRESH_YEARS,
		"observability": str(template["observability"]),
		"participants": []
	})


# Water leaves the ground on its own. Slower than rain puts it in, so a player
# who keeps intervening can outpace it and flood a place — which is the point —
# and a player who stops will watch it drain back to baseline over about a
# decade. Deterministic, and applied to every settlement equally.
func _process_water_drift() -> void:
	for location_id: String in state.get_location_ids():
		var current := state.get_water(location_id)
		if current == WorldState.WATER_BASELINE:
			continue
		var before_state := state.water_state(location_id)
		var step := mini(WATER_DRIFT_PER_YEAR, absi(current - WorldState.WATER_BASELINE))
		state.change_water(location_id, -step if current > WorldState.WATER_BASELINE else step)
		var after_state := state.water_state(location_id)
		# Draining into a state is as objective as raining into one.
		if before_state != after_state:
			_offer_water_fact(location_id, after_state)


func _resolve_bless_harvest() -> String:
	var location_id := state.current_event_location_id
	var place := state.location_name(location_id)
	var improvement := 2 if state.current_event_id == "good_harvest" else 1
	state.change_settlement_band(location_id, "food", improvement)
	state.population_growth_bonus += 4
	state.faith += 3
	state.followers += 8
	state.intervention_counts["blessed_harvest"] += 1
	if state.get_settlement_band(location_id, "prosperity") <= 1:
		state.change_settlement_band(location_id, "prosperity", 1)
		return "Full granaries begin lifting %s out of poverty." % place
	return "The fields around %s yield more grain than their soil should allow." % place


func _resolve_speak_mortal() -> String:
	state.mara_exists = true
	state.faith += 5
	state.followers += 12
	state.intervention_counts["mortal_voice"] += 1
	if state.current_event_id == "unrest":
		state.change_settlement_band(state.current_event_location_id, "stability", 1)
	return "Mara speaks with an unfamiliar certainty, and the crowd turns to listen."


func _apply_interpretation(interpretation: Dictionary) -> Array[String]:
	var new_flags: Array[String] = []
	var effects: Dictionary = interpretation.get("effects", {})
	# Local, because the act they are interpreting was local. Reading the
	# kingdom view and adding to it would broadcast one number back over every
	# settlement and flatten the whole world.
	var location_id := state.current_event_location_id
	state.change_settlement_band(location_id, "food", int(effects.get("food", 0)))
	state.change_settlement_band(location_id, "stability", int(effects.get("stability", 0)))
	state.change_settlement_band(location_id, "prosperity", int(effects.get("prosperity", 0)))
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
	# Ordinary life in every settlement. Order follows the belly: a fed place
	# settles, a starving one comes apart. Wealth follows plenty and order, and
	# scarcity wears it away. Nothing here is an economy — it is the slow
	# background against which an event becomes worth noticing.
	for location_id: String in state.get_location_ids():
		var food := state.get_settlement_band(location_id, "food")
		var stability := state.get_settlement_band(location_id, "stability")
		if food >= 2:
			state.change_settlement_band(location_id, "stability", 1)
		elif food == 0:
			state.change_settlement_band(location_id, "stability", -1)
		# More mouths than a place keeps at its means. Without this a fed
		# settlement climbs to plenty and stays there forever, because nothing
		# in the world costs anything: growth is the cost. It uses only what
		# already exists — how many live there, and how well the place is doing.
		if state.get_settlement_population(location_id) > _supportable_population(location_id):
			state.change_settlement_band(location_id, "food", -1)
		if state.get_settlement_band(location_id, "food") == 0:
			state.change_settlement_band(location_id, "prosperity", -1)
		elif food >= 2 and stability >= 2:
			state.change_settlement_band(location_id, "prosperity", 1)
		elif food <= 1:
			state.change_settlement_band(location_id, "prosperity", -1)
	# Followers are the kingdom's, so they answer to the realm as a whole.
	if state.stability_level == 0:
		state.followers -= 5

# Which condition each event is about. An event is surfaced where it matters
# most, which is where that condition is thinnest: a dry year is news in the
# settlement with the emptiest stores, and a good harvest is news in the one
# that needed it. No settlement is named here, so the same rule serves any
# settlement the world later gains.
# Roughly how many people a settlement keeps fed at its current means. One
# number with one plain meaning, not an economy.
const POPULATION_PER_PROSPERITY := 80

const EVENT_BANDS := {
	"drought": "food",
	"good_harvest": "food",
	"unrest": "stability"
}

# What each year's weather does to every settlement, before the event singles
# one of them out. Splitting these apart is what keeps the world from either
# draining away or drifting up to uniform plenty: the season balances across the
# cycle, while the story stays local.
const EVENT_WEATHER := {
	"drought": {"food": -1},
	"good_harvest": {"food": 1},
	"unrest": {"stability": -1}
}


func _select_next_event() -> void:
	var cycle := ["drought", "good_harvest", "unrest"]
	state.current_event_id = cycle[(state.year - 12) % cycle.size()]
	state.current_event_location_id = event_location_for(state.current_event_id)
	_apply_event_weather(state.current_event_id)
	match state.current_event_id:
		"drought":
			_begin_drought()
		"good_harvest":
			_begin_good_harvest()
		"unrest":
			_begin_unrest()


func _supportable_population(location_id: String) -> int:
	return POPULATION_PER_PROSPERITY * (state.get_settlement_band(location_id, "prosperity") + 1)


func _apply_event_weather(event_id: String) -> void:
	# The season falls on everyone. Nobody is spared a dry year for living in
	# the wrong settlement, and nobody is singled out for one either.
	var weather: Dictionary = EVENT_WEATHER.get(event_id, {})
	for location_id: String in state.get_location_ids():
		for band_value in weather:
			state.change_settlement_band(location_id, str(band_value), int(weather[band_value]))


func event_location_for(event_id: String) -> String:
	var band := str(EVENT_BANDS.get(event_id, "food"))
	var chosen := state.settlement_with_lowest(band)
	return state.current_event_location_id if chosen.is_empty() else chosen


func _begin_drought() -> void:
	var location_id := state.current_event_location_id
	var place := state.location_name(location_id)
	if state.world_flags["wells_built"]:
		state.world_flag_use_counts["wells_built"] += 1
		if state.world_flags["irrigation_known"]:
			state.world_flag_use_counts["irrigation_known"] += 1
			state.population_growth_bonus += 1
		state.add_history("The wells built during the Great Silence allowed %s to withstand another drought." % place)
		return
	if state.get_settlement_band(location_id, "food") <= 0:
		state.change_settlement_population(location_id, -8)
		state.change_settlement_band(location_id, "stability", -1)
		state.add_history("Drought struck empty stores, driving hungry families from %s and weakening public order." % place)
	elif state.faith >= 55:
		state.followers += 5
		state.add_history("As the skies dried over %s, growing numbers gathered at the shrine to pray." % place)
	else:
		state.add_history("Cloudless skies returned to %s, and its water began to shrink." % place)


func _begin_good_harvest() -> void:
	var location_id := state.current_event_location_id
	var place := state.location_name(location_id)
	if state.get_settlement_band(location_id, "prosperity") <= 1:
		state.change_settlement_band(location_id, "prosperity", 1)
		state.population_growth_bonus += 3
	if state.world_flags["irrigation_known"]:
		state.world_flag_use_counts["irrigation_known"] += 1
		state.change_settlement_band(location_id, "food", 1)
		state.add_history("Channels first cut by %s's farmers turned mild weather into a harvest large enough to restore trade." % place)
	elif state.belief_pressure["naturalism"] >= 3:
		state.add_history("The fields around %s ripened, and villagers debated whether skill or providence deserved the credit." % place)
	else:
		state.add_history("The fields ripened beneath a mild and generous sun, offering %s a path out of poverty." % place)


func _begin_unrest() -> void:
	var location_id := state.current_event_location_id
	var place := state.location_name(location_id)
	if state.get_settlement_band(location_id, "prosperity") == 0:
		state.change_settlement_band(location_id, "stability", -1)
	if state.world_flags["local_council_empowered"]:
		state.world_flag_use_counts["local_council_empowered"] += 1
		state.change_settlement_band(location_id, "stability", 1)
		state.add_history("The elders who once ended unrest without divine aid negotiated another peaceful settlement in %s." % place)
	elif state.world_flags["mara_is_prophet"] and state.faith >= 45:
		state.world_flag_use_counts["mara_is_prophet"] += 1
		state.change_settlement_band(location_id, "stability", 1)
		state.add_history("Mara invoked her earlier revelation and calmed a crowd angered by %s's poverty." % place)
	elif state.world_flags["king_claims_divine_favor"]:
		state.world_flag_use_counts["king_claims_divine_favor"] += 1
		if state.faith >= 45:
			state.change_settlement_band(location_id, "stability", 1)
			state.add_history("The king invoked his claimed divine favour and persuaded the crowd in %s to stand down." % place)
		else:
			state.change_settlement_band(location_id, "stability", -1)
			state.add_history("The king invoked divine favour, but a sceptical crowd in %s treated the claim as proof of corruption." % place)
	else:
		state.add_history("Poor conditions sharpened old grievances, drawing an angry crowd into %s's square." % place)


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


func _log_chronicle(written: Array[Dictionary], rejected: Array) -> void:
	if not debug_logging_enabled:
		return
	if written.is_empty() and rejected.is_empty():
		return
	print("[CHRONICLE %d] %d recorded, %d considered and left out"
		% [state.year, written.size(), rejected.size()])
	for record: Dictionary in written:
		var kinds: Array[String] = []
		for factor_value in record["factors"]:
			kinds.append(str((factor_value as Dictionary)["kind"]))
		print("  %s  [%d]  %s  (%s)%s" % [
			str(record["id"]), int(record["importance"]), str(record["summary"]),
			", ".join(kinds),
			"  caused_by %s" % str(record["caused_by"]) if not record["caused_by"].is_empty() else ""
		])
