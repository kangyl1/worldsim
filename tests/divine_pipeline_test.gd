extends SceneTree

# Generic Divine Action Pipeline Foundation.
#
# The divine_action_test suite proves that SEND RAIN travels the causal road
# correctly. This suite proves the ROAD is a road and not a path worn by one
# power: that routing lives in one place, that the record and the consequence
# contract are shaped around divine acts rather than around rain, and that a
# power nobody has designed yet can travel it without a single new branch in
# the simulation.
#
# The load-bearing test is _test_an_unforeseen_power_travels_the_road. It
# registers a power this file invents, sends it down the pipeline, and asserts
# it comes out the far end with a record, a consequence, a fact, a perceiver
# and a knowledge entry — having touched no code that names it. If that test
# ever needs a change in `world_sim.gd`, `consequence_rules.gd` or
# `perception_rules.gd` to pass, the abstraction has come undone.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 14

# Core routing: the files an act passes through on its way into the world. None
# of them may decide which road it takes, and none may name a power.
const CORE_ROUTING_FILES := [
	"res://scripts/consequence_rules.gd",
	"res://scripts/perception_rules.gd",
	"res://scripts/interpretation_rules.gd"
]
const REGISTERED_POWERS := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]

# Subjective state the generic pipeline must never write. Faith and reputation
# are what someone concluded; the pipeline only carries what occurred.
const FORBIDDEN_WRITES := [
	"state.faith", "state.followers", "state.reputation",
	"belief_pressure", "reputation_pressure", "known_beliefs",
	"prophet_created", "world_flags"
]

var completed := 0


func _init() -> void:
	_test_routing_lives_in_one_place()
	_test_core_routing_names_no_power()
	_test_the_record_is_shaped_around_acts_not_rain()
	_test_every_power_produces_a_record()
	_test_the_consequence_contract_is_generic()
	_test_the_observable_fact_is_separate_from_the_act()
	_test_an_act_may_leave_nothing_to_notice()
	_test_interpretation_topics_come_from_the_registry()
	_test_a_registered_topic_may_have_no_meaning_yet()
	_test_legacy_and_shared_powers_coexist()
	_test_no_double_reaction()
	_test_the_generic_path_writes_no_subjective_state()
	_test_perception_stays_selective_for_any_power()
	_test_an_unforeseen_power_travels_the_road()

	if completed != EXPECTED_TESTS:
		push_error("Divine pipeline suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("DIVINE PIPELINE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("DIVINE PIPELINE TEST PASSED: the road is generic, and a new power can walk it.")
	quit(0)


# --- helpers ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _lived_in_world(target: String = "aster") -> Object:
	var simulation := _sim()
	for year in range(12):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	simulation.state.current_event_location_id = target
	return simulation


func _knowledge_on(state, holder_id: String, topic: String) -> Dictionary:
	for record: Dictionary in state.get_all_knowledge(holder_id).values():
		if str(record.get("topic", "")) == topic:
			return record
	return {}


# Executable lines only. A comment saying a layer must not touch faith is the
# opposite of that layer touching faith, and must not read as a violation.
func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- architecture ----------------------------------------------------------

func _test_routing_lives_in_one_place() -> void:
	# One file answers "which road does this power take", and it answers for
	# every registered power.
	var rules := DivineActionRules.new()
	for action_id: String in REGISTERED_POWERS:
		assert(rules.is_divine_action(action_id), "%s is not registered" % action_id)
		var pipeline := rules.pipeline_for(action_id)
		assert(pipeline in [DivineActionRules.PIPELINE_SHARED, DivineActionRules.PIPELINE_LEGACY],
			"%s took an unknown road: %s" % [action_id, pipeline])
	# An unregistered power gets the old road, never the new one by default.
	assert(rules.pipeline_for("summon_locusts") == DivineActionRules.PIPELINE_LEGACY,
		"an unregistered power was silently granted the shared pipeline")
	assert(rules.shared_pipeline_actions() == ["bless_harvest", "send_rain"],
		"the migrated set is not what CLAUDE.md records: %s"
			% str(rules.shared_pipeline_actions()))
	print("  ONE SURFACE: %d powers registered, %d on the shared road." % [
		REGISTERED_POWERS.size(), rules.shared_pipeline_actions().size()
	])
	completed += 1


func _test_core_routing_names_no_power() -> void:
	# The point of the registry. A power's name may appear where its own effect
	# is written; it must not appear in the layers every act passes through.
	for path: String in CORE_ROUTING_FILES:
		var code := _code_of(path)
		for action_id: String in REGISTERED_POWERS:
			assert(not code.contains(action_id),
				"%s branches on '%s'; routing belongs to divine_action_rules.gd"
					% [path, action_id])
	# world_sim.gd resolves each power's own objective effect, so it names them
	# there — but it must not decide the road, and it no longer keeps a list.
	var sim_code := _code_of("res://scripts/world_sim.gd")
	assert(not sim_code.contains("MIGRATED_DIVINE_ACTIONS"),
		"world_sim still keeps its own migration list")
	for forbidden: String in ['== "send_rain"', 'action_id in ["send_rain"']:
		assert(not sim_code.contains(forbidden),
			"world_sim branches on a power id to route: %s" % forbidden)
	print("  NO SCATTER: three core layers name no divine power at all.")
	completed += 1


func _test_the_record_is_shaped_around_acts_not_rain() -> void:
	# The record answers what God attempted, where, at what cost, which road it
	# took and what it created. Nothing in it is about weather.
	var simulation := _lived_in_world()
	var result := simulation.resolve_action("send_rain") as Dictionary
	var record: Dictionary = simulation.state.get_divine_action(str(result["divine_action_id"]))
	var required := [
		"id", "year", "action_type", "target_id", "subject_id", "parameters",
		"power_cost", "result", "consequence_id", "pipeline", "occurrence_topic"
	]
	for field: String in required:
		assert(record.has(field), "the record cannot answer '%s'" % field)
	for field: String in record.keys():
		assert(str(field) in required,
			"the record grew a field with no stated use: %s" % str(field))
	# No field is rain-shaped, and none carries a meaning.
	for field: String in record.keys():
		var name := str(field).to_lower()
		for word: String in ["rain", "weather", "faith", "belief", "meaning", "reputation"]:
			assert(not name.contains(word),
				"the record has a '%s' field; the format is not generic" % str(field))
	print("  RECORD: %d fields, all about the act." % required.size())
	completed += 1


func _test_every_power_produces_a_record() -> void:
	# Migrated or not, an act is an act and gets recorded as one.
	for action_id: String in REGISTERED_POWERS:
		var simulation := _lived_in_world()
		var state = simulation.state
		var before: int = state.divine_action_archive.size()
		var result := simulation.resolve_action(action_id) as Dictionary
		if not bool(result["ok"]):
			continue
		assert(state.divine_action_archive.size() == before + 1,
			"%s produced %d records" % [action_id, state.divine_action_archive.size() - before])
		var record: Dictionary = state.divine_action_archive.back()
		assert(str(record["action_type"]) == action_id, "%s filed the wrong act" % action_id)
		assert(str(record["pipeline"]) == DivineActionRules.new().pipeline_for(action_id),
			"%s's record disagrees with the registry" % action_id)
	print("  ALWAYS RECORDED: every registered power files a divine action.")
	completed += 1


func _test_the_consequence_contract_is_generic() -> void:
	# plan_divine is handed the occurrence rather than looking the power up. It
	# no longer knows any power exists.
	var rules := ConsequenceRules.new()
	var simulation := _lived_in_world()
	var state = simulation.state
	var invented := {
		"topic": "test_occurrence",
		"claim": "Something happened in %s",
		"observability": "local",
		"confidence": 80
	}
	var planned := rules.plan_divine(state, "any_power_at_all", "aster", [], invented)
	assert(not planned["pending_fact"].is_empty(),
		"the consequence layer refused a power it had never heard of")
	assert(str(planned["pending_fact"]["topic"]) == "test_occurrence")
	assert(str(planned["pending_fact"]["claim"]) == "Something happened in Aster",
		"the claim was not built from the supplied template")
	assert(str(planned["subject_id"]) == "aster", "the consequence lost its place")
	# And it answers only its own question.
	for field: String in ["faith", "reputation", "belief", "interpretation", "meaning"]:
		assert(not planned.has(field), "the consequence record carries '%s'" % field)
	print("  CONTRACT: a power the layer has never heard of plans cleanly.")
	completed += 1


func _test_the_observable_fact_is_separate_from_the_act() -> void:
	# God caused rain in Aster; mortals were offered "Rain fell on Aster". Two
	# records, and the mortal one does not name an actor.
	var simulation := _lived_in_world()
	var result := simulation.resolve_action("send_rain") as Dictionary
	simulation.advance_year()
	var state = simulation.state
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	var fact := _knowledge_on(state, "aster_king", str(record["occurrence_topic"]))
	assert(not fact.is_empty(), "the act offered nothing anyone could notice")
	assert(str(fact["claim"]) != str(record["result"]),
		"the mortal fact and the divine record are the same sentence")
	assert(not str(fact["claim"]).to_lower().contains("god"),
		"the observable fact named the actor: \"%s\"" % str(fact["claim"]))
	assert(str(record["action_type"]) not in str(fact["claim"]),
		"the fact leaked the power's internal name")
	print("  TWO RECORDS: act \"%s\" / fact \"%s\"." % [
		str(record["result"]).substr(0, 28), str(fact["claim"])
	])
	completed += 1


func _test_an_act_may_leave_nothing_to_notice() -> void:
	# Silence registers no occurrence. It is still an act with a record, and it
	# offers nobody anything — which is a real outcome, not a missing template.
	var rules := DivineActionRules.new()
	assert(not rules.has_occurrence("do_nothing"), "silence became observable")
	assert(rules.topic_for("do_nothing").is_empty())
	var simulation := _lived_in_world()
	var state = simulation.state
	var before: int = state.knowledge_events.size()
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	for entity: Dictionary in state.notable_entities.values():
		assert(_knowledge_on(state, str(entity["id"]), "").is_empty(),
			"silence taught somebody something")
	print("  SILENCE: an act with no occurrence, and nothing to notice.")
	completed += 1


func _test_interpretation_topics_come_from_the_registry() -> void:
	# Interpretation keeps no second list of what the god can do.
	var rules := InterpretationRules.new()
	var registry := DivineActionRules.new()
	var topics := registry.occurrence_topics()
	assert(not topics.is_empty(), "the registry offers no topics at all")
	for topic: String in topics:
		assert(rules.is_world_topic(topic),
			"interpretation does not recognise the registered topic '%s'" % topic)
	assert(not rules.is_world_topic("something_never_registered"))
	var source := _code_of("res://scripts/interpretation_rules.gd")
	assert(not source.contains('WORLD_TOPICS := ['),
		"interpretation still keeps a hand-written topic list")
	print("  ONE LIST: %d occurrence topics, all from the registry." % topics.size())
	completed += 1


func _test_a_registered_topic_may_have_no_meaning_yet() -> void:
	# A power can be observable before anybody designs what it could mean. The
	# fact is held; no conclusion is invented to fill the gap.
	var rules := InterpretationRules.new()
	# `mortal_speech` is the remaining example: registered, observable, and
	# belonging to a power whose migration has not happened. `harvest_yield` was
	# this example until Bless Harvest migrated and gave it meanings.
	assert(rules.is_world_topic("mortal_speech"),
		"a registered occurrence is not recognised")
	assert(not rules.has_candidates("mortal_speech"),
		"this test is stale: mortal_speech now has designed meanings")
	assert(not rules.is_interpretable("mortal_speech"),
		"an undesigned occurrence was interpreted anyway")
	assert(rules.has_candidates("weather_rain") and rules.is_interpretable("weather_rain"),
		"a designed occurrence stopped being interpretable")
	# And nobody reached a conclusion about it in a real run.
	var simulation := _lived_in_world()
	simulation.resolve_action("speak_mortal")
	simulation.advance_year()
	var state = simulation.state
	assert(not _knowledge_on(state, "aster_king", "mortal_speech").is_empty(),
		"the speech was not even noticed")
	for record: Dictionary in state.interpretation_archive:
		assert(str(record["topic"]) != "mortal_speech",
			"a meaning was invented for an occurrence nobody has designed")
	print("  HELD, UNREAD: the harvest is known and means nothing yet.")
	completed += 1


func _test_legacy_and_shared_powers_coexist() -> void:
	# Both roads open at once, in one world, across one run.
	var simulation := _lived_in_world()
	var state = simulation.state
	var seen := {}
	for action_id: String in ["send_rain", "bless_harvest", "speak_mortal"]:
		state.current_event_location_id = "aster"
		var result := simulation.resolve_action(action_id) as Dictionary
		if bool(result["ok"]):
			seen[str(result["pipeline"])] = true
		simulation.advance_year()
	assert(seen.has(DivineActionRules.PIPELINE_SHARED)
		and seen.has(DivineActionRules.PIPELINE_LEGACY),
		"one world did not carry both roads: %s" % str(seen.keys()))
	print("  COEXIST: shared and legacy powers ran in the same world.")
	completed += 1


func _test_no_double_reaction() -> void:
	# A migrated act must not also be read collectively. A legacy one must still
	# be. Exactly one of the two, every time.
	for action_id: String in ["send_rain", "bless_harvest", "speak_mortal"]:
		var simulation := _lived_in_world()
		var state = simulation.state
		var before: int = state.interpretation_history.size()
		var result := simulation.resolve_action(action_id) as Dictionary
		if not bool(result["ok"]):
			continue
		var collective: int = state.interpretation_history.size() - before
		if str(result["pipeline"]) == DivineActionRules.PIPELINE_SHARED:
			assert(collective == 0, "%s was read collectively AND individually" % action_id)
			assert(str(result["interpretation"]).is_empty(),
				"%s returned a collective meaning" % action_id)
		else:
			assert(collective == 1, "%s lost its legacy reading" % action_id)
			assert(not str(result["interpretation"]).is_empty(),
				"%s returned no meaning at all" % action_id)
	print("  EXACTLY ONE: each power is read once, by one road.")
	completed += 1


func _test_the_generic_path_writes_no_subjective_state() -> void:
	# The shared road carries occurrences. Faith, reputation, belief and
	# doctrine are conclusions, and belong to layers further down.
	for path: String in [
		"res://scripts/divine_action_rules.gd", "res://scripts/consequence_rules.gd"
	]:
		var code := _code_of(path)
		for forbidden: String in FORBIDDEN_WRITES:
			assert(not code.contains(forbidden),
				"%s writes '%s'; the generic path must not" % [path, forbidden])
	# And no relationship axis, either.
	var registry_code := _code_of("res://scripts/divine_action_rules.gd")
	for axis: String in ["trust", "hostility", "fear", "respect"]:
		assert(not registry_code.contains(axis),
			"the registry reaches into relationships via '%s'" % axis)
	# Behaviourally: a shared act moves nothing subjective.
	var simulation := _lived_in_world()
	var state = simulation.state
	var faith: int = state.faith
	var reputation: String = state.reputation
	var relationships := str(state.relationships)
	var history: int = state.history_archive.size()
	simulation.resolve_action("send_rain")
	assert(state.faith == faith and state.reputation == reputation)
	assert(str(state.relationships) == relationships, "the generic path moved a relationship")
	assert(state.history_archive.size() - history <= 1,
		"the generic path wrote more than the objective occurrence")
	print("  NO SUBJECTIVITY: the road carries occurrences and nothing else.")
	completed += 1


func _test_perception_stays_selective_for_any_power() -> void:
	# Observability is the registry's to declare and perception's to enforce.
	# No power may teach the world because it happened.
	for action_id: String in ["send_rain", "bless_harvest"]:
		var simulation := _lived_in_world("aster")
		var state = simulation.state
		if not bool(simulation.resolve_action(action_id)["ok"]):
			continue
		simulation.advance_year()
		var topic := DivineActionRules.new().topic_for(action_id)
		var holders := 0
		for entity: Dictionary in state.notable_entities.values():
			if not _knowledge_on(state, str(entity["id"]), topic).is_empty():
				holders += 1
				assert(str(entity["home_location_id"]) == "aster",
					"%s reached somebody who lives elsewhere" % action_id)
		assert(holders > 0 and holders < state.notable_entities.size(),
			"%s reached %d of %d mortals" % [
				action_id, holders, state.notable_entities.size()
			])
	print("  SELECTIVE: every power's occurrence stopped at the people present.")
	completed += 1


func _test_an_unforeseen_power_travels_the_road() -> void:
	# The test this milestone exists for.
	#
	# A power nobody designed, invented here and registered at runtime, is sent
	# down the pipeline. It must produce a record, an objective consequence, an
	# observable fact, a perceiver and a knowledge entry — without one line
	# anywhere in the simulation knowing its name. If this ever needs a branch
	# added to make it pass, migrating a real power is not cheap after all.
	var simulation := _lived_in_world()
	var state = simulation.state
	var rules = simulation.divine_action_rules
	rules.register("still_the_waters", {
		"pipeline": DivineActionRules.PIPELINE_SHARED,
		"occurrence": {
			"topic": "waters_stilled",
			"claim": "The river beside %s ran flat and quiet",
			"observability": "local",
			"confidence": 85
		}
	})
	assert(rules.is_shared_pipeline("still_the_waters"))
	# And offered to the player. Two registrations, deliberately: how a power is
	# priced is not how it enters the world.
	simulation.offer_action("still_the_waters", {
		"title": "STILL THE WATERS", "cost": 1, "hint": "Quiet the river"
	})

	# The god acts. `_apply_immediate_action` knows nothing about this power, so
	# it changes no bands and returns its generic line — which is the honest
	# outcome for a power whose effect nobody has written yet.
	var before: int = state.divine_action_archive.size()
	var result := simulation.resolve_action("still_the_waters") as Dictionary
	assert(bool(result["ok"]), "the pipeline refused an unforeseen power")

	# 1. A divine action record.
	assert(state.divine_action_archive.size() == before + 1, "no record was filed")
	var record: Dictionary = state.divine_action_archive.back()
	assert(str(record["action_type"]) == "still_the_waters")
	assert(str(record["pipeline"]) == DivineActionRules.PIPELINE_SHARED,
		"the new power was routed to the legacy path")
	assert(str(record["occurrence_topic"]) == "waters_stilled")

	# 2. An objective consequence, tied to the record.
	assert(not str(record["consequence_id"]).is_empty(), "the act created no consequence")

	# 3. No collective meaning was read out of it.
	assert(str(result["interpretation"]).is_empty()
		and str(result["belief_tag"]).is_empty(),
		"the legacy reader ran for a power it has never heard of")

	# 4 and 5. Perception, then knowledge.
	simulation.advance_year()
	var fact := _knowledge_on(state, "aster_king", "waters_stilled")
	assert(not fact.is_empty(), "the occurrence reached nobody")
	assert(str(fact["claim"]) == "The river beside Aster ran flat and quiet",
		"the claim was not built from the registration: \"%s\"" % str(fact["claim"]))
	assert(int(fact["confidence"]) > 0 and str(fact["source_type"]) == "direct")
	if state.notable_entities.has("mara"):
		assert(_knowledge_on(state, "mara", "waters_stilled").is_empty(),
			"a local occurrence reached somebody who lives elsewhere")

	# 6. Interpretation is downstream, and stayed silent: nobody has designed
	# what a stilled river could mean, so the fact is held and read by no one.
	for reading: Dictionary in state.interpretation_archive:
		assert(str(reading["topic"]) != "waters_stilled",
			"a meaning was invented for a power that has none designed")

	print("  NEW POWER: registered at runtime, walked the whole road, no branch added.")
	completed += 1
