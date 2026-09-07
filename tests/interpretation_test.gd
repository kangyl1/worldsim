extends SceneTree

# Interpretation v1.
#
# The law under test: a consequence says what happened, and a mortal decides
# what it meant. Those are two records, reached by two layers, and the second
# one is the only thing allowed to move a relationship.
#
# Much of this suite is negative, because the valuable property is the set of
# things this layer refuses to do: it never reads objective truth, never
# invents knowledge nobody perceived, never rewrites the fact it was drawn
# from, and never turns one refusal into a feud.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 21

# Words that would mean the layer had started reading the engine's mind rather
# than the mortal's.
const FORBIDDEN_READS := ["objective_truth_state", "consequence_archive", "get_consequence"]

const INTENT_VOCABULARY := [
	"help", "protect", "acquire", "learn", "influence",
	"connect", "distance", "resolve", "preserve", "wait"
]
const ACTION_VOCABULARY := ["give", "ask", "tell", "support", "oppose", "observe", "wait"]

const WARM := {"trust": 75, "fear": 0, "respect": 60, "hostility": 0}
const COLD := {"trust": 10, "fear": 5, "respect": 10, "hostility": 45}
const NEUTRAL := {"trust": 45, "fear": 5, "respect": 30, "hostility": 10}

var completed := 0


func _init() -> void:
	_test_a_social_occurrence_becomes_an_interpretation()
	_test_the_same_occurrence_reads_differently_to_each_participant()
	_test_existing_state_changes_the_reading()
	_test_only_the_observers_own_edge_moves()
	_test_effects_stay_bounded()
	_test_one_conclusion_per_occurrence()
	_test_a_doubted_report_reaches_no_conclusion()
	_test_a_bystander_changes_no_relationship()
	_test_no_relationship_edge_means_no_effect()
	_test_interpretation_changes_a_later_intent_score()
	_test_the_full_causal_chain()
	_test_nothing_is_interpreted_that_was_never_perceived()
	_test_the_layer_never_reads_objective_truth()
	_test_a_false_belief_is_interpreted_sincerely()
	_test_the_original_consequence_is_untouched()
	_test_fact_and_meaning_stay_separate_records()
	_test_the_consequence_layer_still_decides_no_meaning()
	_test_no_new_vocabulary_is_invented()
	_test_no_history_and_no_same_year_recursion()
	_test_interpretation_cannot_reach_this_years_intents()
	_test_interpretation_is_deterministic()

	if completed != EXPECTED_TESTS:
		push_error("Interpretation suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("INTERPRETATION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("INTERPRETATION TEST PASSED: mortals decide what happened to them meant.")
	quit(0)


# --- helpers -----------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _social_fact(topic: String, actor_id: String, target_id: String, subject_id: String = "") -> Dictionary:
	# The same shape `consequence_rules.gd` emits for a social occurrence: a
	# private claim naming the two people it happened between.
	return {
		"id": "%s_0012_%s_%s" % [topic, actor_id, target_id],
		"event_id": topic,
		"subject_id": subject_id,
		"topic": topic,
		"claim": "%s and %s had dealings" % [actor_id, target_id],
		"confidence": 95,
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": 3,
		"observability": "direct",
		"participants": [actor_id, target_id]
	}


func _deliver(simulation: Object, fact: Dictionary) -> void:
	# Through the real pipeline: perception decides who could notice, the
	# knowledge system stores it, and only then may anyone interpret it.
	simulation.state.pending_perception_facts.append(fact)
	simulation.tick_perception()


func _interpretations_by(records: Array, observer_id: String) -> Array:
	var matches: Array = []
	for record: Dictionary in records:
		if str(record["observer_id"]) == observer_id:
			matches.append(record)
	return matches


func _first_for(records: Array, observer_id: String) -> Dictionary:
	var matches := _interpretations_by(records, observer_id)
	return matches[0] if not matches.is_empty() else {}


# --- what the layer does -----------------------------------------------------

func _test_a_social_occurrence_becomes_an_interpretation() -> void:
	var simulation := _sim()
	_deliver(simulation, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var reached: Array = simulation.tick_interpretations()
	assert(not reached.is_empty(), "a refusal both parties knew about produced no interpretation")
	var mara := _first_for(reached, "mara")
	assert(not mara.is_empty())
	# The record explains itself: who, from what, what they concluded, and why.
	for field: String in [
		"id", "year", "observer_id", "source_knowledge_id", "topic", "subject_id",
		"actor_id", "target_id", "role", "interpretation_type", "meaning",
		"confidence", "score", "factors", "considered", "planned_effect",
		"applied_effect", "effect_reason"
	]:
		assert(mara.has(field), "interpretation record is missing '%s'" % field)
	assert(str(mara["source_knowledge_id"]) == str(simulation.state.get_knowledge(
		"mara", "request_refused_0012_mara_aster_king")["id"]))
	assert(str(mara["subject_id"]) == "westfield", "the subject of the request was lost")
	print("  FORMED: a refusal both parties knew about became an interpretation.")
	completed += 1


func _test_the_same_occurrence_reads_differently_to_each_participant() -> void:
	# The property the whole layer exists for. One objective refusal, two people
	# who were both there, two different meanings — and neither is the engine's.
	var simulation := _sim()
	_deliver(simulation, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var reached: Array = simulation.tick_interpretations()
	var mara := _first_for(reached, "mara")
	var king := _first_for(reached, "aster_king")
	assert(not mara.is_empty() and not king.is_empty())
	assert(str(mara["role"]) == "actor", "Mara asked, so she is the actor")
	assert(str(king["role"]) == "target", "the King answered, so he is the target")
	assert(str(mara["interpretation_type"]) != str(king["interpretation_type"]),
		"both parties reached the same conclusion about a refusal")
	assert(str(mara["meaning"]) != str(king["meaning"]))
	print("  DIVERGED: Mara read '%s', the King read '%s'." % [
		str(mara["interpretation_type"]), str(king["interpretation_type"])
	])
	completed += 1


func _test_existing_state_changes_the_reading() -> void:
	# Same fact, same role, different prior relationship. A refusal from someone
	# already distrusted confirms what was suspected; the same refusal from
	# someone trusted is given the benefit of the doubt.
	var cold := _sim()
	cold.state.set_relationship("mara", "aster_king", COLD)
	_deliver(cold, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var cold_read := _first_for(cold.tick_interpretations(), "mara")

	var warm := _sim()
	warm.state.set_relationship("mara", "aster_king", WARM)
	_deliver(warm, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var warm_read := _first_for(warm.tick_interpretations(), "mara")

	# Both readings are named. Asserting only that they DIFFER passes even when
	# half the state dependency is broken, because one branch moving is enough
	# to make them unequal.
	assert(str(cold_read["interpretation_type"]) == "refusal_confirms_distrust",
		"distrust did not colour the refusal, read it as '%s'" % str(cold_read["interpretation_type"]))
	assert(str(warm_read["interpretation_type"]) == "refusal_had_their_reasons",
		"warmth did not colour the refusal, read it as '%s'" % str(warm_read["interpretation_type"]))
	assert(not cold_read["factors"].is_empty(), "the cold reading recorded no reason")
	assert(not warm_read["factors"].is_empty(), "the warm reading recorded no reason")
	print("  STATE: distrust read it as '%s', warmth as '%s'." % [
		str(cold_read["interpretation_type"]), str(warm_read["interpretation_type"])
	])
	completed += 1


func _test_only_the_observers_own_edge_moves() -> void:
	# Mara concluding something about the King changes what MARA thinks of him.
	# It says nothing about what he thinks of her: he was there too, and reached
	# his own conclusion separately.
	var simulation := _sim()
	simulation.state.set_relationship("mara", "aster_king", COLD)
	simulation.state.set_relationship("aster_king", "mara", NEUTRAL)
	var king_before: Dictionary = simulation.state.get_relationship("aster_king", "mara")
	_deliver(simulation, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var reached: Array = simulation.tick_interpretations()
	var mara := _first_for(reached, "mara")
	var applied: Dictionary = mara["applied_effect"]
	assert(not applied.is_empty(), "a distrusted refusal moved nothing at all")
	assert(str(applied["source_id"]) == "mara" and str(applied["target_id"]) == "aster_king")
	# The King's own edge moved only through the King's own interpretation.
	var king := _first_for(reached, "aster_king")
	var king_applied: Dictionary = king["applied_effect"]
	var king_after: Dictionary = simulation.state.get_relationship("aster_king", "mara")
	var expected_trust := int(king_before["trust"])
	if not king_applied.is_empty() and str(king_applied["axis"]) == "trust":
		expected_trust += int(king_applied["amount"])
	assert(int(king_after["trust"]) == expected_trust,
		"the King's view of Mara moved without the King interpreting anything")
	print("  DIRECTED: an interpretation moves only its own observer's edge.")
	completed += 1


func _test_effects_stay_bounded() -> void:
	# The bounded-ripple rule in numbers: one axis, small, per occurrence. No
	# single social moment may lurch a relationship across its whole range.
	var rules := InterpretationRules.new()
	var simulation := _sim()
	var topics: Array = InterpretationRules.SOCIAL_TOPICS
	var checked := 0
	for topic: String in topics:
		var by_role: Dictionary = InterpretationRules.CANDIDATES[topic]
		for role_value in by_role:
			for candidate: Dictionary in by_role[role_value]:
				var effect: Dictionary = candidate["effect"]
				if effect.is_empty():
					continue
				checked += 1
				assert(absi(int(effect["amount"])) <= InterpretationRules.MAX_EFFECT_MAGNITUDE,
					"candidate '%s' exceeds the bounded ripple limit" % str(candidate["id"]))
				assert(str(effect["axis"]) in ["trust", "fear", "respect", "hostility"])
				assert(effect.size() == 2, "an interpretation may move ONE axis, not several")
	assert(checked >= 6, "too few effectful candidates to be checking anything")
	# And the applied record is clamped regardless of what a table claims.
	_deliver(simulation, _social_fact("opposition_given", "aster_king", "mara"))
	for record: Dictionary in simulation.tick_interpretations():
		var planned: Dictionary = record["planned_effect"]
		if planned.is_empty():
			continue
		assert(absi(int(planned["amount"])) <= InterpretationRules.MAX_EFFECT_MAGNITUDE)
	assert(rules != null)
	print("  BOUNDED: %d effectful readings, each one axis and at most %d." % [
		checked, InterpretationRules.MAX_EFFECT_MAGNITUDE
	])
	completed += 1


func _test_one_conclusion_per_occurrence() -> void:
	# A belief still held next year is not a fresh event. Without this a single
	# refusal would grind a relationship down every year it was remembered.
	var simulation := _sim()
	_deliver(simulation, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var first: Array = simulation.tick_interpretations()
	assert(not first.is_empty())
	var trust_after_first: int = int(simulation.state.get_relationship("mara", "aster_king")["trust"])
	var again: Array = simulation.tick_interpretations()
	assert(again.is_empty(), "the same occurrence was interpreted twice")
	simulation.state.year += 1
	var next_year: Array = simulation.tick_interpretations()
	assert(next_year.is_empty(), "a remembered occurrence was re-interpreted a year later")
	assert(int(simulation.state.get_relationship("mara", "aster_king")["trust"]) == trust_after_first)
	print("  ONCE: one mortal, one occurrence, one conclusion.")
	completed += 1


func _test_a_doubted_report_reaches_no_conclusion() -> void:
	# Confidence in the underlying fact is an input. A badly distorted rumor
	# leaves someone unsure what happened, and unsure moves nothing.
	var simulation := _sim()
	var fact := _social_fact("request_refused", "mara", "aster_king", "westfield")
	simulation.state.add_notable_entity("witness", "A Witness", "person", [], {}, "aster")
	simulation.state.set_relationship("witness", "aster_king", NEUTRAL)
	var doubted := fact.duplicate(true)
	doubted["confidence"] = 15
	simulation.state.learn_knowledge("witness", doubted)
	var before: Dictionary = simulation.state.get_relationship("witness", "aster_king")
	var reached := _first_for(simulation.tick_interpretations(), "witness")
	assert(not reached.is_empty())
	assert(str(reached["interpretation_type"]) == "unclear_what_happened",
		"a barely-believed report still produced a confident conclusion")
	assert(reached["applied_effect"].is_empty())
	var after: Dictionary = simulation.state.get_relationship("witness", "aster_king")
	assert(int(after["trust"]) == int(before["trust"]))
	print("  DOUBT: a report held at 15 confidence concluded nothing.")
	completed += 1


func _test_a_bystander_changes_no_relationship() -> void:
	# Someone who hears about a quarrel they were not in notes it and stops
	# there. Third-party politics is a later system, not a side effect of this
	# one.
	var simulation := _sim()
	simulation.state.add_notable_entity("witness", "A Witness", "person", [], {}, "aster")
	simulation.state.set_relationship("witness", "aster_king", NEUTRAL)
	simulation.state.set_relationship("witness", "mara", NEUTRAL)
	simulation.state.learn_knowledge(
		"witness", _social_fact("request_refused", "mara", "aster_king", "westfield")
	)
	var before_king: Dictionary = simulation.state.get_relationship("witness", "aster_king")
	var before_mara: Dictionary = simulation.state.get_relationship("witness", "mara")
	var reached := _first_for(simulation.tick_interpretations(), "witness")
	assert(not reached.is_empty())
	assert(str(reached["role"]) == "bystander")
	assert(reached["applied_effect"].is_empty(), "a bystander moved a relationship")
	assert(int(simulation.state.get_relationship("witness", "aster_king")["trust"]) == int(before_king["trust"]))
	assert(int(simulation.state.get_relationship("witness", "mara")["trust"]) == int(before_mara["trust"]))
	print("  BYSTANDER: noticed the quarrel, changed nothing.")
	completed += 1


func _test_no_relationship_edge_means_no_effect() -> void:
	# A missing edge means no relationship, not a neutral one — the same rule
	# Action Execution applies to ASK. A single overheard occurrence must not
	# invent a tie between strangers.
	var simulation := _sim()
	simulation.state.add_notable_entity("stranger", "A Stranger", "person", [], {}, "aster")
	simulation.state.learn_knowledge(
		"stranger", _social_fact("opposition_given", "aster_king", "stranger")
	)
	var reached := _first_for(simulation.tick_interpretations(), "stranger")
	assert(not reached.is_empty())
	assert(str(reached["role"]) == "target")
	assert(reached["applied_effect"].is_empty())
	assert(str(reached["effect_reason"]) == "no_relationship_edge")
	assert(simulation.state.get_relationship("stranger", "aster_king").is_empty(),
		"an interpretation invented a relationship that did not exist")
	print("  NO EDGE: a stranger's conclusion created no relationship.")
	completed += 1


# --- the feedback loop -------------------------------------------------------

func _test_interpretation_changes_a_later_intent_score() -> void:
	# The point of the milestone. Nothing here scripts a future action: it
	# proves the INPUTS to later reasoning moved, and reasoning is still free to
	# do what it likes with them.
	var simulation := _sim()
	simulation.state.set_relationship("mara", "aster_king", NEUTRAL)
	var before: Dictionary = {}
	for candidate: Dictionary in simulation.intent_rules.evaluate_intents(simulation.state, "mara"):
		if str(candidate["target_id"]) == "aster_king":
			before[str(candidate["intent_type"])] = int(candidate["score"])
	assert(not before.is_empty(), "Mara scored no intents toward the King to begin with")

	# Several separate refusals, each its own occurrence, each interpreted once.
	for index in range(4):
		var fact := _social_fact("request_refused", "mara", "aster_king", "westfield")
		fact["id"] = "request_refused_%04d_mara_aster_king" % (12 + index)
		_deliver(simulation, fact)
		simulation.tick_interpretations()
		simulation.state.year += 1

	var after: Dictionary = {}
	for candidate: Dictionary in simulation.intent_rules.evaluate_intents(simulation.state, "mara"):
		if str(candidate["target_id"]) == "aster_king":
			after[str(candidate["intent_type"])] = int(candidate["score"])
	var moved := 0
	for intent_type: String in before:
		if int(after.get(intent_type, before[intent_type])) != int(before[intent_type]):
			moved += 1
	assert(moved > 0, "repeated refusals changed no later intent score at all")
	print("  FEEDBACK: %d of Mara's intent scores toward the King moved." % moved)
	completed += 1


func _test_the_full_causal_chain() -> void:
	# The Autonomous Feedback Loop, end to end and unscripted. No step below is
	# forced: the world is advanced and the chain is observed.
	var simulation := _sim()
	var stressed := false
	var perceived := false
	var intended := false
	var attempted := false
	var occurred := false
	var interpreted := false
	var relationship_moved := false
	var moved_by: String = ""

	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for location_id_value in simulation.state.locations:
			if simulation.state.get_settlement_band(str(location_id_value), "food") <= 1:
				stressed = true
		if not simulation.state.last_perceptions.is_empty():
			for opportunity: Dictionary in simulation.state.last_perceptions:
				if bool(opportunity["perceived"]):
					perceived = true
		if not simulation.state.last_intents.is_empty():
			intended = true
		if not simulation.state.last_actions.is_empty():
			attempted = true
		for consequence: Dictionary in simulation.state.last_consequences:
			if str(consequence["consequence_type"]) == "social_occurrence":
				occurred = true
		for record: Dictionary in simulation.state.last_interpretations:
			interpreted = true
			if not record["applied_effect"].is_empty():
				relationship_moved = true
				moved_by = str(record["interpretation_type"])

	assert(stressed, "no settlement ever came under pressure")
	assert(perceived, "nobody ever noticed anything")
	assert(intended, "nobody ever wanted anything")
	assert(attempted, "nobody ever tried anything")
	assert(occurred, "no social occurrence ever happened")
	assert(interpreted, "nothing was ever interpreted")
	assert(relationship_moved, "no interpretation ever changed a relationship")
	assert(not simulation.state.interpretation_archive.is_empty())
	print("  CHAIN: pressure -> noticed -> wanted -> tried -> occurred -> interpreted -> '%s' moved a relationship." % moved_by)
	completed += 1


# --- what the layer refuses to do --------------------------------------------

func _test_nothing_is_interpreted_that_was_never_perceived() -> void:
	# Perception is not bypassable. An occurrence nobody noticed means nothing
	# to anybody, however true it is.
	var simulation := _sim()
	var secret := _social_fact("request_refused", "mara", "aster_king", "westfield")
	secret["observability"] = "hidden"
	secret["participants"] = []
	simulation.state.pending_perception_facts.append(secret)
	simulation.tick_perception()
	assert(not simulation.state.has_knowledge("mara", str(secret["id"])),
		"a hidden occurrence was learned anyway")
	var reached: Array = simulation.tick_interpretations()
	assert(reached.is_empty(), "something nobody perceived was still interpreted")
	print("  UNSEEN: an occurrence nobody perceived meant nothing to anyone.")
	completed += 1


func _test_the_layer_never_reads_objective_truth() -> void:
	# Structural: the rules cannot even name the engine's own copies of truth.
	var source := FileAccess.get_file_as_string("res://scripts/interpretation_rules.gd")
	assert(not source.is_empty(), "could not read the interpretation rules to inspect them")
	var executable := ""
	for raw_line in source.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.begins_with("#") or line.is_empty():
			continue
		executable += line + "\n"
	for forbidden: String in FORBIDDEN_READS:
		assert(not executable.contains(forbidden),
			"interpretation names '%s' — that is the engine's knowledge, not the mortal's" % forbidden)
	print("  BLIND: the layer cannot name objective truth or the consequence archive.")
	completed += 1


func _test_a_false_belief_is_interpreted_sincerely() -> void:
	# The engine knowing better must not quietly correct the mortal. Someone who
	# believes a thing that did not happen reaches a real conclusion about it.
	var simulation := _sim()
	var untrue := _social_fact("request_refused", "mara", "aster_king", "westfield")
	untrue["truth_state"] = "false"
	untrue["objective_truth_state"] = "false"
	simulation.state.learn_knowledge("mara", untrue)
	var reached := _first_for(simulation.tick_interpretations(), "mara")
	assert(not reached.is_empty(), "a sincerely held falsehood produced no interpretation")
	assert(not reached["planned_effect"].is_empty(),
		"a false belief was quietly stripped of its consequences")
	# And the same claim held as TRUE reads identically: truth was not consulted.
	var control := _sim()
	control.state.learn_knowledge("mara", _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var control_read := _first_for(control.tick_interpretations(), "mara")
	assert(str(reached["interpretation_type"]) == str(control_read["interpretation_type"]),
		"the engine's view of truth changed how a mortal read their own belief")
	print("  SINCERE: a false belief was interpreted exactly like a true one.")
	completed += 1


func _test_the_original_consequence_is_untouched() -> void:
	# Interpretation reads; it does not rewrite what it read.
	var simulation := _sim()
	for year in range(8):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	assert(not simulation.state.consequence_archive.is_empty(), "no consequences to check against")
	var snapshot: Array = []
	for record: Dictionary in simulation.state.consequence_archive:
		snapshot.append(record.duplicate(true))
	simulation.tick_interpretations()
	assert(simulation.state.consequence_archive.size() == snapshot.size(),
		"interpretation added or removed a consequence")
	for index in range(snapshot.size()):
		assert(str(simulation.state.consequence_archive[index]) == str(snapshot[index]),
			"interpretation mutated the consequence it was drawn from")
	print("  IMMUTABLE: %d consequences unchanged by being interpreted." % snapshot.size())
	completed += 1


func _test_fact_and_meaning_stay_separate_records() -> void:
	# The objective claim and what someone took it to mean are two records. The
	# first must survive the second exactly as it was learned.
	var simulation := _sim()
	var fact := _social_fact("request_refused", "mara", "aster_king", "westfield")
	_deliver(simulation, fact)
	var believed_before: Dictionary = simulation.state.get_knowledge("mara", str(fact["id"]))
	var reached := _first_for(simulation.tick_interpretations(), "mara")
	var believed_after: Dictionary = simulation.state.get_knowledge("mara", str(fact["id"]))
	assert(str(believed_before["claim"]) == str(believed_after["claim"]),
		"the fact was overwritten with what it was taken to mean")
	assert(int(believed_before["confidence"]) == int(believed_after["confidence"]))
	assert(str(believed_after["topic"]) == "request_refused")
	assert(str(reached["meaning"]) != str(believed_after["claim"]),
		"the meaning is just a copy of the claim")
	# The meaning lives in its own store, and knowledge gained no new entry.
	assert(simulation.state.get_all_knowledge("mara").size() == 1,
		"interpreting a fact quietly added a second belief")
	assert(not simulation.state.get_interpretations_for("mara").is_empty())
	print("  SEPARATE: the fact stands, and the meaning lives elsewhere.")
	completed += 1


func _test_the_consequence_layer_still_decides_no_meaning() -> void:
	# The boundary this milestone was built to protect. Consequences may not
	# grow a reaction table now that something downstream exists to consume one.
	var source := FileAccess.get_file_as_string("res://scripts/consequence_rules.gd")
	assert(not source.is_empty())
	# Executable lines only. The file names the very deltas it promises never to
	# write, in a comment saying it does not write them, and a naive grep reads
	# that promise as a violation.
	var executable := ""
	for raw_line in source.split("\n"):
		var line: String = raw_line.strip_edges()
		if line.begins_with("#") or line.is_empty():
			continue
		executable += line + "\n"
	for axis: String in ["trust", "hostility", "fear", "respect"]:
		assert(not executable.contains(axis),
			"consequence_rules names '%s' — reactions belong to interpretation" % axis)
	# Behavioural: a social occurrence alone moves nothing until it is read.
	var simulation := _sim()
	simulation.state.set_relationship("mara", "aster_king", NEUTRAL)
	var before: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	_deliver(simulation, _social_fact("request_refused", "mara", "aster_king", "westfield"))
	var after_perception: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	assert(int(after_perception["trust"]) == int(before["trust"]),
		"knowing about a refusal moved trust before anyone interpreted it")
	simulation.tick_interpretations()
	var after_interpretation: Dictionary = simulation.state.get_relationship("mara", "aster_king")
	assert(int(after_interpretation["trust"]) != int(before["trust"]),
		"interpreting the refusal moved nothing, so the loop is not closed")
	print("  BOUNDARY: the occurrence moved nothing; the meaning did.")
	completed += 1


func _test_no_new_vocabulary_is_invented() -> void:
	# v1 adds a layer, not a wider world. No new intent, no new verb, and none
	# of religion, doctrine, factions or politics.
	var simulation := _sim()
	for year in range(20):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	for intent: Dictionary in simulation.state.intent_archive:
		assert(str(intent["intent_type"]) in INTENT_VOCABULARY,
			"a new intent type appeared: %s" % str(intent["intent_type"]))
	for action: Dictionary in simulation.state.action_archive:
		assert(str(action["action_type"]) in ACTION_VOCABULARY,
			"a new action verb appeared: %s" % str(action["action_type"]))
	var source := FileAccess.get_file_as_string("res://scripts/interpretation_rules.gd")
	for forbidden: String in [
		"religion", "doctrine", "prophet", "faction", "ideology", "politic",
		"apostle", "prayer", "divine_token"
	]:
		assert(not source.to_lower().contains(forbidden),
			"interpretation v1 reached into '%s', which is later work" % forbidden)
	print("  SCOPE: %d intents and %d actions, all in the existing vocabulary." % [
		simulation.state.intent_archive.size(), simulation.state.action_archive.size()
	])
	completed += 1


func _test_no_history_and_no_same_year_recursion() -> void:
	# History comes after this loop works, not from it. And an interpretation
	# must not set off another action inside the same year: the world advances
	# one causal step per year, which is what keeps it readable.
	var simulation := _sim()
	for year in range(6):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var history_before: int = simulation.state.history_archive.size()
	var actions_before: int = simulation.state.action_archive.size()
	var executions_before: int = simulation.state.execution_archive.size()
	var consequences_before: int = simulation.state.consequence_archive.size()
	simulation.state.pending_perception_facts.append(
		_social_fact("opposition_given", "aster_king", "mara")
	)
	simulation.tick_perception()
	simulation.tick_interpretations()
	assert(simulation.state.history_archive.size() == history_before,
		"interpretation wrote a history entry")
	assert(simulation.state.action_archive.size() == actions_before,
		"interpretation caused an action in the same year")
	assert(simulation.state.execution_archive.size() == executions_before,
		"interpretation caused an execution in the same year")
	assert(simulation.state.consequence_archive.size() == consequences_before,
		"interpretation caused a consequence in the same year")
	print("  NO RECURSION: no history, no action, no execution, no consequence.")
	completed += 1


func _test_interpretation_cannot_reach_this_years_intents() -> void:
	# The causal timing rule. A conclusion drawn this year changes what someone
	# wants NEXT year; it must never reach backwards into wants already formed.
	# The tick order is the only thing enforcing that, so the order is the test.
	var source := FileAccess.get_file_as_string("res://scripts/world_sim.gd")
	assert(not source.is_empty())
	var body_start := source.find("func advance_year")
	assert(body_start >= 0, "could not find the yearly tick to inspect")
	var body_end := source.find("\nfunc ", body_start + 1)
	var body := source.substr(body_start, body_end - body_start)
	var intents_at := body.find("tick_intents()")
	var perception_at := body.find("tick_perception()")
	var interpretation_at := body.find("tick_interpretations()")
	assert(intents_at >= 0 and perception_at >= 0 and interpretation_at >= 0,
		"the yearly tick no longer runs all three layers")
	assert(interpretation_at > intents_at,
		"interpretation runs BEFORE intents — a conclusion could change a want already formed")
	assert(interpretation_at > perception_at,
		"interpretation runs before perception — meaning without knowing")

	# And behaviourally: an interpretation that moved a relationship this year
	# left this year's already-recorded intents exactly as they were.
	var simulation := _sim()
	for year in range(20):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		var moved := false
		for record: Dictionary in simulation.state.last_interpretations:
			if not record["applied_effect"].is_empty():
				moved = true
		if not moved or simulation.state.last_intents.is_empty():
			continue
		for intent: Dictionary in simulation.state.last_intents:
			assert(int(intent["year"]) == simulation.state.year,
				"an intent from another year leaked into this one")
		completed += 1
		print("  TIMING: interpretation runs last; this year's wants were already settled.")
		return
	# Never reaching an effectful year is itself a failure: the assertion above
	# would silently never run.
	assert(false, "no year both formed an intent and moved a relationship")


func _test_interpretation_is_deterministic() -> void:
	# No dice anywhere. Two identical worlds reach identical conclusions, and
	# the rules name no randomness.
	var source := FileAccess.get_file_as_string("res://scripts/interpretation_rules.gd")
	for forbidden: String in ["randi", "randf", "rand_range", "RandomNumberGenerator"]:
		assert(not source.contains(forbidden),
			"interpretation rolled dice via '%s'" % forbidden)
	var first: Array = []
	var second: Array = []
	for run in range(2):
		var simulation := _sim()
		for year in range(12):
			simulation.resolve_action("do_nothing")
			simulation.advance_year()
		var signature: Array = []
		for record: Dictionary in simulation.state.interpretation_archive:
			signature.append("%s:%s:%s:%d" % [
				str(record["observer_id"]), str(record["source_knowledge_id"]),
				str(record["interpretation_type"]), int(record["score"])
			])
		if run == 0:
			first = signature
		else:
			second = signature
	assert(not first.is_empty(), "twelve years produced no interpretations to compare")
	assert(first == second, "two identical runs interpreted the world differently")
	print("  DETERMINISTIC: %d interpretations reproduced exactly." % first.size())
	completed += 1
