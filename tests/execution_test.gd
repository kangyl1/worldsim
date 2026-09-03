extends SceneTree

# Mortal Action Execution v1.
#
# Three questions, three records, and this suite exists to keep them apart:
# why she wanted it, why she chose that way, and what came of it. Execution
# answers only the third, and answering it must not quietly answer the fourth —
# what the result goes on to change is the Consequence Engine's job, and that
# engine does not exist.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 22

const SHORTAGE_FACT := {
	"id": "westfield_food_shortage",
	"subject_id": "westfield",
	"topic": "food_shortage",
	"claim": "Westfield does not have enough food",
	"confidence": 85,
	"truth_state": "true",
	"fresh_for_years": 3
}

const WOLVES_FACT := {
	"id": "wolves_near_aster",
	"subject_id": "aster",
	"topic": "danger_wolves",
	"claim": "Wolves are hunting near Aster",
	"confidence": 95,
	"truth_state": "true",
	"fresh_for_years": 3
}

const WARM_STANDING := {"trust": 80, "fear": 0, "respect": 60, "hostility": 0}
const HOSTILE_STANDING := {"trust": 5, "fear": 0, "respect": 5, "hostility": 70}

var completed := 0


func _init() -> void:
	_test_every_action_produces_one_result()
	_test_execution_links_back_to_the_chain()
	_test_outcomes_are_three_distinct_kinds()
	_test_give_is_blocked_not_failed()
	_test_blocked_give_leaves_the_intent_standing()
	_test_tell_uses_the_knowledge_system()
	_test_false_belief_travels()
	_test_objective_truth_cannot_reach_execution()
	_test_delivered_is_not_believed()
	_test_missing_belief_blocks_tell()
	_test_ask_reads_the_target_side_of_the_relationship()
	_test_ask_succeeds_where_standing_is_strong()
	_test_ask_fails_where_standing_is_hostile()
	_test_ask_fails_without_standing()
	_test_execution_never_edits_the_records_above_it()
	_test_two_kinds_of_waiting()
	_test_expression_changes_nothing()
	_test_observe_only_sees_what_the_world_shows()
	_test_no_consequences_escape_execution()
	_test_tick_order_gives_nobody_an_advantage()
	_test_determinism()
	_test_records_explain_themselves()

	if completed != EXPECTED_TESTS:
		push_error("Execution suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("EXECUTION TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("EXECUTION TEST PASSED: attempts have results, and results have no consequences yet.")
	quit(0)


func _test_every_action_produces_one_result() -> void:
	# Actors are scheduled on alternating years, so drive the real yearly
	# pipeline rather than assuming this year has anyone acting in it.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.learn_direct_knowledge("aster_king", WOLVES_FACT)

	var years_with_attempts := 0
	for turn in 6:
		assert(simulation.resolve_action("do_nothing")["ok"])
		assert(simulation.advance_year()["ok"])
		var actions: Array[Dictionary] = simulation.state.last_actions
		var results: Array[Dictionary] = simulation.state.last_executions
		assert(results.size() == actions.size(),
			"every selected attempt must produce exactly one result")
		var action_ids: Array[String] = []
		for record: Dictionary in results:
			var action_id := str(record["action_id"])
			assert(action_id not in action_ids, "an attempt must not be executed twice")
			action_ids.append(action_id)
		if not actions.is_empty():
			years_with_attempts += 1
	assert(years_with_attempts > 0, "the run must actually select and execute something")
	print("  ONE FOR ONE: attempts matched results across %d active years." % years_with_attempts)
	completed += 1


func _test_execution_links_back_to_the_chain() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	var intent: Dictionary = simulation.choose_intent("mara")
	var action: Dictionary = simulation.choose_mortal_action(intent)
	var execution: Dictionary = simulation.execute_mortal_action(action)

	assert(str(execution["action_id"]) == str(action["id"]))
	assert(str(execution["intent_id"]) == str(intent["id"]))
	assert(str(execution["action_type"]) == str(action["action_type"]))
	assert(str(execution["target_id"]) == str(action["target_id"]))
	assert(str(execution["subject_id"]) == str(action["subject_id"]))
	assert(not simulation.state.get_execution(str(execution["id"])).is_empty())
	assert(str(simulation.state.get_execution_for_action(str(action["id"]))["id"])
		== str(execution["id"]))
	print("  CHAIN: %s -> %s -> %s." % [
		str(intent["intent_type"]), str(action["action_type"]), str(execution["result_type"])
	])
	completed += 1


func _test_outcomes_are_three_distinct_kinds() -> void:
	# The required distinction: a give cannot even be attempted, a refused
	# request was attempted and fell short, a delivered claim landed.
	var blocked: Dictionary = _plan_give(_new_simulation())
	assert(str(blocked["outcome"]) == ExecutionRules.OUTCOME_BLOCKED)

	var refusing = _standing_simulation(HOSTILE_STANDING)
	var failed: Dictionary = _execute_for(refusing, "mara")
	assert(str(failed["action_type"]) == "ask")
	assert(str(failed["outcome"]) == ExecutionRules.OUTCOME_FAILURE)

	var told = _new_simulation()
	told.state.learn_direct_knowledge("mara", WOLVES_FACT)
	var succeeded: Dictionary = _execute_for(told, "mara")
	assert(str(succeeded["action_type"]) == "tell")
	assert(str(succeeded["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)

	assert(str(blocked["outcome"]) != str(failed["outcome"]))
	assert(str(failed["outcome"]) != str(succeeded["outcome"]))
	print("  THREE KINDS: give %s, ask %s, tell %s." % [
		str(blocked["outcome"]), str(failed["outcome"]), str(succeeded["outcome"])
	])
	completed += 1


func _test_give_is_blocked_not_failed() -> void:
	var record: Dictionary = _plan_give(_new_simulation())
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_BLOCKED)
	assert(str(record["result_type"]) == "no_controlled_resource")
	assert(record["effects_applied"].is_empty())
	# Blocked survives a world with full granaries: the realm's stores are not
	# anybody's to hand over.
	var rich = _new_simulation()
	rich.state.food_level = 3
	rich.state.prosperity_level = 3
	assert(str(_plan_give(rich)["result_type"]) == "no_controlled_resource")
	print("  GIVE: blocked, not failed — she had nothing to try with.")
	completed += 1


func _test_blocked_give_leaves_the_intent_standing() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	var intent: Dictionary = simulation.choose_intent("mara")
	var before := str(intent)
	var action := _give_action(simulation, intent)

	var record: Dictionary = simulation.execute_mortal_action(action)
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_BLOCKED)
	assert(str(intent) == before, "a blocked attempt must not edit the want")
	assert(str(simulation.choose_intent("mara")["intent_type"]) == "help",
		"she still wants to help")
	print("  BLOCKED INTENT: she still wants to help after the road closed.")
	completed += 1


func _test_tell_uses_the_knowledge_system() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	assert(not simulation.state.has_knowledge("aster_king", "wolves_near_aster"))

	var record: Dictionary = _execute_for(simulation, "mara")
	assert(str(record["action_type"]) == "tell")
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	assert(str(record["result_type"]) == "claim_delivered")

	var received: Dictionary = simulation.state.get_knowledge("aster_king", "wolves_near_aster")
	assert(not received.is_empty(), "the claim must arrive through the knowledge system")
	assert(str(received["source_id"]) == "mara", "the receiver must know where it came from")
	assert(str(received["source_type"]) == "rumor", "second-hand, as the knowledge system defines it")
	assert(int(received["transmission_count"]) == 1)
	assert(int(received["confidence"]) < int(
		simulation.state.get_knowledge("mara", "wolves_near_aster")["confidence"]
	), "the knowledge system's confidence loss must still apply")
	assert(record["effects_applied"].size() == 1)
	assert(str(record["effects_applied"][0]["type"]) == "knowledge_delivered")
	print("  TELL: delivered at %d, down from %d, marked as coming from Mara." % [
		int(received["confidence"]),
		int(simulation.state.get_knowledge("mara", "wolves_near_aster")["confidence"])
	])
	completed += 1


func _test_false_belief_travels() -> void:
	# GDD section 33: the engine must never quietly correct a character.
	var simulation = _false_belief_simulation("false")
	var record: Dictionary = _execute_for(simulation, "mara")
	assert(str(record["action_type"]) == "tell")
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)

	var received: Dictionary = simulation.state.get_knowledge("aster_king", "wolves_near_aster")
	assert(not received.is_empty(), "a false claim must travel exactly as a true one does")
	assert(str(received["objective_truth_state"]) == "false",
		"and it must stay false on arrival")
	print("  FALSEHOOD: a claim that is not true reached the King at confidence %d." % [
		int(received["confidence"])
	])
	completed += 1


func _test_objective_truth_cannot_reach_execution() -> void:
	var truthful = _false_belief_simulation("true")
	var false_world = _false_belief_simulation("false")
	var first: Dictionary = _execute_for(truthful, "mara")
	var second: Dictionary = _execute_for(false_world, "mara")

	assert(str(first["outcome"]) == str(second["outcome"]))
	assert(str(first["result_type"]) == str(second["result_type"]))
	assert(str(first["factors"]) == str(second["factors"]))
	assert(str(first["reasons"]) == str(second["reasons"]))
	assert(int(truthful.state.get_knowledge("aster_king", "wolves_near_aster")["confidence"])
		== int(false_world.state.get_knowledge("aster_king", "wolves_near_aster")["confidence"]),
		"what arrives must not depend on what is true")
	print("  BLINDNESS: truth flipped underneath, %s either way." % str(first["result_type"]))
	completed += 1


func _test_delivered_is_not_believed() -> void:
	# Execution and belief acceptance are separate. A claim can land weakly and
	# the telling still succeeded.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("doubter", "The Doubter", "person", ["cautious"]))
	assert(simulation.state.set_relationship("mara", "doubter", {
		"trust": 70, "fear": 0, "respect": 50, "hostility": 0
	}))
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)

	var action := _tell_action(simulation, "mara", "doubter", "wolves_near_aster")
	var record: Dictionary = simulation.execute_mortal_action(action)
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	var received: Dictionary = simulation.state.get_knowledge("doubter", "wolves_near_aster")
	assert(not received.is_empty())
	assert(int(received["confidence"]) < 95, "a cautious listener need not be convinced")
	print("  DELIVERED != BELIEVED: success at recipient confidence %d." % int(received["confidence"]))
	completed += 1


func _test_missing_belief_blocks_tell() -> void:
	# The world may move between choosing and doing.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	var intent: Dictionary = simulation.choose_intent("mara")
	var action: Dictionary = simulation.choose_mortal_action(intent)
	assert(str(action["action_type"]) == "tell")

	assert(simulation.state.invalidate_knowledge("mara", "wolves_near_aster"))
	var record: Dictionary = simulation.execute_mortal_action(action)
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_BLOCKED)
	assert(str(record["result_type"]) == "missing_required_belief")
	assert(not simulation.state.has_knowledge("aster_king", "wolves_near_aster"),
		"a blocked telling must deliver nothing")
	print("  STALE PLAN: the belief went, and the telling was blocked.")
	completed += 1


func _test_ask_reads_the_target_side_of_the_relationship() -> void:
	# Selection read Mara's view of the King. Execution must read the King's
	# view of Mara, because he is the one deciding.
	var simulation = _standing_simulation(WARM_STANDING)
	# Her view of him is poor; his view of her stays warm. The attempt is built
	# directly so that selection's own opinion of the edges cannot enter into
	# it: this test is only about which direction execution reads.
	assert(simulation.state.set_relationship("mara", "aster_king", {
		"trust": 40, "fear": 40, "respect": 10, "hostility": 30
	}))
	var record: Dictionary = simulation.execute_mortal_action(
		_ask_action(simulation, "mara", "aster_king")
	)
	assert(str(record["action_type"]) == "ask")
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS,
		"the target's regard decides, not the asker's")
	var cited := str(record["factors"])
	assert(cited.contains("from aster_king toward mara"),
		"the record must name which direction was read")
	assert(not cited.contains("from mara toward aster_king"))
	print("  DIRECTION: the King's regard for Mara decided it, not hers for him.")
	completed += 1


func _test_ask_succeeds_where_standing_is_strong() -> void:
	var record: Dictionary = _execute_for(_standing_simulation(WARM_STANDING), "mara")
	assert(str(record["action_type"]) == "ask")
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	assert(str(record["result_type"]) == "request_accepted")
	# Accepted, and nothing more. No grain moves because a King said yes.
	assert(record["effects_applied"].is_empty(),
		"an accepted request must not quietly do the thing that was asked")
	print("  ASK ACCEPTED: score %d, and nothing was granted yet." % int(record["score"]))
	completed += 1


func _test_ask_fails_where_standing_is_hostile() -> void:
	var record: Dictionary = _execute_for(_standing_simulation(HOSTILE_STANDING), "mara")
	assert(str(record["action_type"]) == "ask")
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_FAILURE)
	assert(str(record["result_type"]) == "request_refused")
	assert(record["effects_applied"].is_empty())
	# Refusal is not resentment. Nothing about the relationship changed.
	assert(int(record["score"]) < ExecutionRules.ASK_ACCEPTANCE_THRESHOLD)
	print("  ASK REFUSED: score %d against a threshold of %d." % [
		int(record["score"]), ExecutionRules.ASK_ACCEPTANCE_THRESHOLD
	])
	completed += 1


func _test_ask_fails_without_standing() -> void:
	# The actor knows of them; they have no recorded view in return. The request
	# arrives and finds no reason to be granted.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("stranger", "The Stranger", "person", []))
	assert(simulation.state.set_relationship("mara", "stranger", {
		"trust": 70, "fear": 0, "respect": 50, "hostility": 0
	}))
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)

	var action := _ask_action(simulation, "mara", "stranger")
	var record: Dictionary = simulation.execute_mortal_action(action)
	assert(str(record["outcome"]) == ExecutionRules.OUTCOME_FAILURE,
		"no standing is a refusal, not an impossibility")
	assert(str(record["result_type"]) == "no_standing_with_target")
	print("  NO STANDING: the request reached a stranger and found no reason.")
	completed += 1


func _test_execution_never_edits_the_records_above_it() -> void:
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.last_intents = simulation.tick_intents()
	simulation.state.last_actions = simulation.tick_action_selection()
	var intents_before := str(simulation.state.intent_archive)
	var actions_before := str(simulation.state.action_archive)

	simulation.tick_action_execution()

	assert(str(simulation.state.intent_archive) == intents_before,
		"execution must not edit the wants above it")
	assert(str(simulation.state.action_archive) == actions_before,
		"execution must not edit the attempts it carries out")
	print("  IMMUTABLE CHAIN: intents and actions untouched by what happened.")
	completed += 1


func _test_two_kinds_of_waiting() -> void:
	var settled = _new_simulation()
	settled.state.food_level = 2
	settled.state.stability_level = 2
	settled.state.prosperity_level = 2
	assert(settled.state.add_notable_entity("elder", "The Elder", "person", ["cautious"]))
	var deliberate: Dictionary = _execute_for(settled, "elder")
	assert(str(deliberate["action_type"]) == "wait")
	assert(str(deliberate["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	assert(str(deliberate["result_type"]) == "deliberately_waited")

	var stuck = _new_simulation()
	assert(stuck.state.add_notable_entity("hermit", "The Hermit", "person", ["compassionate"]))
	stuck.state.learn_direct_knowledge("hermit", SHORTAGE_FACT)
	var unable: Dictionary = _execute_for(stuck, "hermit")
	assert(str(unable["action_type"]) == "wait")
	assert(str(unable["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	assert(str(unable["result_type"]) == "unable_to_act")

	assert(str(deliberate["result_type"]) != str(unable["result_type"]))
	assert(deliberate["effects_applied"].is_empty() and unable["effects_applied"].is_empty())
	print("  TWO WAITS: %s vs %s." % [
		str(deliberate["result_type"]), str(unable["result_type"])
	])
	completed += 1


func _test_expression_changes_nothing() -> void:
	# Standing with someone, or against them, is the act itself. Nothing about
	# the world changes because it was said, and opposing is never violence.
	for pair: Array in [["support", "support_expressed"], ["oppose", "opposition_expressed"]]:
		var simulation = _new_simulation()
		var before := _world_snapshot(simulation)
		var relationships_before := str(simulation.state.relationships)
		var knowledge_before := str(simulation.state.notable_entities)

		var action := _expression_action(simulation, "mara", "aster_king", str(pair[0]))
		var record: Dictionary = simulation.execute_mortal_action(action)
		assert(str(record["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
		assert(str(record["result_type"]) == str(pair[1]))
		assert(record["effects_applied"].is_empty(), "%s must apply nothing" % str(pair[0]))
		assert(_world_snapshot(simulation) == before)
		assert(str(simulation.state.relationships) == relationships_before,
			"%s must not move a relationship" % str(pair[0]))
		assert(str(simulation.state.notable_entities) == knowledge_before)
		assert(simulation.state.population == before[1], "nobody may be harmed by opposing")
	print("  EXPRESSED: support and opposition said plainly, and nothing moved.")
	completed += 1


func _test_observe_only_sees_what_the_world_shows() -> void:
	# Looking harder is not a way of reading the world's mind. Observation uses
	# the same perception path the world already uses to make events public.
	var showing = _observer_simulation()
	assert(not showing.observable_fact().is_empty(), "the drought should be visible")
	var seen: Dictionary = _execute_for(showing, "merchant")
	assert(str(seen["action_type"]) == "observe")
	assert(str(seen["outcome"]) == ExecutionRules.OUTCOME_SUCCESS)
	assert(str(seen["result_type"]) == "observation_made")
	assert(seen["effects_applied"].size() == 1)
	var learned: Dictionary = showing.state.get_knowledge("merchant", "aster_food_shortage")
	assert(str(learned["source_type"]) == "direct", "they saw it themselves")

	# With the world showing nothing, watching yields nothing.
	var quiet = _observer_simulation()
	quiet.state.food_level = 3
	assert(quiet.observable_fact().is_empty(), "a world in good order shows no shortage")
	var unseen: Dictionary = quiet.execution_rules.plan(
		quiet.state, _observe_action(quiet, "merchant", "aster"), quiet.observable_fact()
	)
	assert(str(unseen["outcome"]) == ExecutionRules.OUTCOME_FAILURE)
	assert(str(unseen["result_type"]) == "nothing_to_see")
	print("  OBSERVE: sees only what the world is showing, and never the truth beneath it.")
	completed += 1


func _test_no_consequences_escape_execution() -> void:
	# The hard boundary. Across a long autonomous run, the only thing execution
	# may ever change is knowledge, and only through the knowledge system.
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	var allowed_effects := ["knowledge_delivered", "observation_recorded"]
	var applied := 0
	var executed := 0

	# Prove the guard below is not vacuous: drive one controlled attempt that
	# genuinely applies an effect, and check it is the only kind of thing that
	# moved. In the running world the ambient rumor pass usually carries a claim
	# before a deliberate telling gets the chance, so this cannot be left to
	# chance across the loop.
	var seeded_before := _world_snapshot(simulation)
	var seeded_relationships := str(simulation.state.relationships)
	var seeded: Dictionary = simulation.execute_mortal_action(
		_tell_action(simulation, "mara", "aster_king", "wolves_near_aster")
	)
	assert(seeded["effects_applied"].size() == 1, "the controlled telling must land")
	assert(str(seeded["effects_applied"][0]["type"]) == "knowledge_delivered")
	assert(_world_snapshot(simulation) == seeded_before,
		"delivering a claim must change no statistic")
	assert(str(simulation.state.relationships) == seeded_relationships,
		"delivering a claim must move no relationship")
	applied += 1
	for turn in 40:
		assert(simulation.resolve_action("do_nothing")["ok"])
		assert(simulation.advance_year()["ok"])
		# Snapshot after the year has fully settled, then run one more execution
		# pass over the same attempts. Anything execution touches on its own
		# will show up as a difference here.
		var relationships_before := str(simulation.state.relationships)
		var history_before: int = simulation.state.history.size()
		var flags_before := str(simulation.state.world_flags)
		var stats_before := _world_snapshot(simulation)
		for record: Dictionary in simulation.state.last_executions:
			executed += 1
			for effect: Dictionary in record["effects_applied"]:
				assert(str(effect["type"]) in allowed_effects,
					"execution applied %s, which belongs to the Consequence Engine" % str(effect["type"]))
				applied += 1
		simulation.tick_action_execution()
		assert(str(simulation.state.relationships) == relationships_before,
			"execution must never move a relationship")
		assert(simulation.state.history.size() == history_before,
			"execution must never write history")
		assert(str(simulation.state.world_flags) == flags_before,
			"execution must never set a world flag")
		assert(_world_snapshot(simulation) == stats_before,
			"execution must never change a world statistic")
	assert(simulation.state.execution_archive.size() > 0, "the run must actually execute things")
	assert(simulation.state.executions.size() <= WorldState.MAX_STORED_EXECUTIONS,
		"recent executions must stay capped")
	assert(executed > 0, "the run must actually execute attempts")
	assert(applied > 0, "the effect guard must have had something to check")
	print("  BOUNDARY: %d years, %d attempts, %d effects, and only knowledge ever moved." % [
		40, executed, applied
	])
	completed += 1


func _test_tick_order_gives_nobody_an_advantage() -> void:
	# Every attempt in a year is decided against the world as it stood when the
	# year's executions began, so sorting first buys nothing. If phase one
	# mutated, the second actor here would see the first one's delivery.
	var simulation = _new_simulation()
	assert(simulation.state.add_notable_entity("witness", "The Witness", "person", ["loyal"]))
	assert(simulation.state.set_relationship("witness", "aster_king", {
		"trust": 60, "fear": 0, "respect": 40, "hostility": 0
	}))
	simulation.state.learn_direct_knowledge("mara", WOLVES_FACT)
	simulation.state.learn_direct_knowledge("witness", WOLVES_FACT)

	var mara_action := _tell_action(simulation, "mara", "aster_king", "wolves_near_aster")
	var witness_action := _tell_action(simulation, "witness", "aster_king", "wolves_near_aster")
	var forward_actions: Array[Dictionary] = [mara_action, witness_action]
	simulation.state.last_actions = forward_actions
	var forward: Array[Dictionary] = simulation.tick_action_execution()

	var reversed_sim = _new_simulation()
	assert(reversed_sim.state.add_notable_entity("witness", "The Witness", "person", ["loyal"]))
	assert(reversed_sim.state.set_relationship("witness", "aster_king", {
		"trust": 60, "fear": 0, "respect": 40, "hostility": 0
	}))
	reversed_sim.state.learn_direct_knowledge("mara", WOLVES_FACT)
	reversed_sim.state.learn_direct_knowledge("witness", WOLVES_FACT)
	var backward_actions: Array[Dictionary] = [
		_tell_action(reversed_sim, "witness", "aster_king", "wolves_near_aster"),
		_tell_action(reversed_sim, "mara", "aster_king", "wolves_near_aster")
	]
	reversed_sim.state.last_actions = backward_actions
	var backward: Array[Dictionary] = reversed_sim.tick_action_execution()

	var forward_outcomes := _outcomes_by_actor(forward)
	var backward_outcomes := _outcomes_by_actor(backward)
	assert(forward_outcomes == backward_outcomes,
		"reversing the order must not change anyone's outcome: %s vs %s" % [
			str(forward_outcomes), str(backward_outcomes)
		])
	print("  FAIR ORDER: same outcomes either way round (%s)." % str(forward_outcomes))
	completed += 1


func _test_determinism() -> void:
	var first: Dictionary = _execute_for(_standing_simulation(WARM_STANDING), "mara")
	var second: Dictionary = _execute_for(_standing_simulation(WARM_STANDING), "mara")
	assert(str(first) == str(second), "identical context must reproduce exactly")

	# Planning twice on the same state must not drift either.
	var simulation = _standing_simulation(WARM_STANDING)
	var action: Dictionary = simulation.choose_mortal_action(simulation.choose_intent("mara"))
	assert(str(simulation.plan_mortal_action(action)) == str(simulation.plan_mortal_action(action)))
	print("  DETERMINISM: identical context reproduced %s." % str(first["result_type"]))
	completed += 1


func _test_records_explain_themselves() -> void:
	var record: Dictionary = _execute_for(_standing_simulation(WARM_STANDING), "mara")
	for field: String in [
		"id", "year", "actor_id", "intent_id", "action_id", "action_type",
		"target_id", "target_kind", "subject_id", "topic_id", "resource_type",
		"outcome", "result_type", "factors", "reasons", "effects_applied"
	]:
		assert(record.has(field), "the record is missing %s" % field)
	assert(not record.has("pending_effect"), "internal planning state must not be stored")
	assert(not record["reasons"].is_empty(), "a result must say why it came out that way")
	assert(not record["factors"].is_empty(), "an ask must show what the target weighed")
	var total := 0
	for factor: Dictionary in record["factors"]:
		total += int(factor.get("delta", 0))
	assert(total == int(record["score"]), "the score must equal what was recorded")
	print("  EXPLAINABILITY: %d factors summing to %d, %d reasons." % [
		record["factors"].size(), int(record["score"]), record["reasons"].size()
	])
	completed += 1


# --- fixtures ----------------------------------------------------------------


func _new_simulation():
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _standing_simulation(standing: Dictionary):
	var simulation = _new_simulation()
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	simulation.state.set_relationship("aster_king", "mara", standing)
	return simulation


func _false_belief_simulation(objective_truth: String):
	var simulation = _new_simulation()
	var belief := WOLVES_FACT.duplicate(true)
	belief["objective_truth_state"] = objective_truth
	simulation.state.learn_direct_knowledge("mara", belief)
	return simulation


func _observer_simulation():
	var simulation = _new_simulation()
	simulation.state.food_level = 0
	simulation.state.current_event_id = "drought"
	simulation.state.add_notable_entity("merchant", "The Merchant", "person", ["cautious"])
	simulation.state.set_relationship("merchant", "mara", {
		"trust": 40, "fear": 0, "respect": 20, "hostility": 0
	})
	simulation.state.learn_direct_knowledge("merchant", {
		"id": "aster_food_shortage",
		"subject_id": "aster",
		"topic": "food_shortage",
		"claim": "Aster does not have enough food",
		"confidence": 30,
		"truth_state": "unknown",
		"fresh_for_years": 1
	})
	simulation.state.year += 5
	simulation.state.age_knowledge()
	return simulation


func _execute_for(simulation, actor_id: String) -> Dictionary:
	var intent: Dictionary = simulation.choose_intent(actor_id)
	return simulation.execute_mortal_action(simulation.choose_mortal_action(intent))


func _plan_give(simulation) -> Dictionary:
	simulation.state.learn_direct_knowledge("mara", SHORTAGE_FACT)
	var intent: Dictionary = simulation.choose_intent("mara")
	return simulation.execute_mortal_action(_give_action(simulation, intent))


# Selection can never produce a GIVE while nobody owns anything, so these build
# the attempt directly to exercise the execution path behind it.
func _give_action(simulation, intent: Dictionary) -> Dictionary:
	var action: Dictionary = simulation.choose_mortal_action(intent)
	action["action_type"] = "give"
	action["resource_type"] = "food"
	action["id"] = "action_%04d_%s_give" % [simulation.state.year, str(intent["actor_id"])]
	return action


func _tell_action(simulation, actor_id: String, target_id: String, knowledge_id: String) -> Dictionary:
	return _synthetic_action(simulation, actor_id, target_id, "tell", knowledge_id)


func _ask_action(simulation, actor_id: String, target_id: String) -> Dictionary:
	return _synthetic_action(simulation, actor_id, target_id, "ask", "")


func _expression_action(simulation, actor_id: String, target_id: String, action_type: String) -> Dictionary:
	return _synthetic_action(simulation, actor_id, target_id, action_type, "")


func _observe_action(simulation, actor_id: String, subject_id: String) -> Dictionary:
	return _synthetic_action(simulation, actor_id, subject_id, "observe", "")


func _synthetic_action(
	simulation,
	actor_id: String,
	target_id: String,
	action_type: String,
	topic_id: String
) -> Dictionary:
	return {
		"id": "action_%04d_%s_%s" % [simulation.state.year, actor_id, action_type],
		"year": simulation.state.year,
		"actor_id": actor_id,
		"intent_id": "intent_%04d_%s_help" % [simulation.state.year, actor_id],
		"intent_type": "help",
		"action_type": action_type,
		"target_id": target_id,
		"target_kind": "person",
		"subject_id": "",
		"topic_id": topic_id,
		"resource_type": "",
		"selection": "argmax"
	}


func _outcomes_by_actor(records: Array) -> Dictionary:
	var outcomes := {}
	for record: Dictionary in records:
		outcomes[str(record["actor_id"])] = "%s:%s" % [
			str(record["outcome"]), str(record["result_type"])
		]
	return outcomes


func _world_snapshot(simulation) -> Array:
	return [
		simulation.state.year,
		simulation.state.population,
		simulation.state.food_level,
		simulation.state.stability_level,
		simulation.state.prosperity_level,
		simulation.state.military_level,
		simulation.state.faith,
		simulation.state.followers,
		simulation.state.divine_power,
		simulation.state.reputation
	]
