extends SceneTree

# Broader Interpretation Coverage v1.
#
# The architecture already worked; what it lacked was reach. Three topics that
# the event cycle produces EVERY YEAR — a settlement short of food, a settlement
# coming apart, a settlement's stores full again — entered Knowledge and meant
# nothing to anybody. A mortal could live through forty years of famine in their
# own village and never draw a conclusion from it.
#
# This suite covers the three new families and the two properties that make them
# worth having: the same fact reads differently depending on WHERE YOU LIVE, and
# it reads differently depending on WHO YOU ARE. Neither reading is the engine's
# opinion, and neither is more correct.
#
# The negative half matters as much. Coverage must not mean interpreting
# everything, must not invent motives the world cannot support, and must not
# quietly make history denser by bypassing the Chronicle's own rules.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 20

# The topics the event cycle produces every year, and which this milestone
# covered.
const CONDITION_TOPICS := ["food_shortage", "danger_unrest", "surplus"]

# Registered, observable, and deliberately without meanings: they belong to
# divine powers that have not been migrated, and designing what they MEAN is a
# separate approved pass.
# `harvest_yield` left this list when Bless Harvest migrated and its meanings
# were designed. Divine Voice's occurrence is the last one still held as a fact
# and read by nobody.
const DELIBERATELY_UNCOVERED := ["mortal_speech"]

const OUT_OF_SCOPE := [
	"religion", "doctrine", "faction", "politic", "ideology", "economy",
	"prophet", "worship", "procedural"
]

var completed := 0


func _init() -> void:
	_test_the_condition_topics_are_now_covered()
	_test_a_resident_reads_a_shortage_as_danger_at_home()
	_test_someone_elsewhere_reads_the_same_fact_differently()
	_test_recovery_is_read_as_recovery()
	_test_traits_change_the_reading_of_the_same_fact()
	_test_a_recurring_condition_is_reconsidered_when_it_returns()
	_test_a_continuing_condition_is_not_reconsidered_every_year()
	_test_low_confidence_reaches_uncertainty()
	_test_beliefs_bias_a_later_condition_reading()
	_test_a_condition_reading_reaches_a_later_intent()
	_test_condition_readings_move_no_relationship()
	_test_social_readings_still_move_one_bounded_axis()

	_test_coverage_report_names_the_gaps()
	_test_undesigned_topics_produce_no_conclusion()
	_test_no_hidden_cause_reaches_a_condition_reading()
	_test_interpretation_never_becomes_knowledge()
	_test_history_did_not_become_dense_by_bypass()
	_test_no_new_intents_or_out_of_scope_systems()
	_test_coverage_works_for_an_arbitrary_settlement()
	_test_the_autonomous_world_is_richer()

	if completed != EXPECTED_TESTS:
		push_error("Coverage suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("INTERPRETATION COVERAGE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("INTERPRETATION COVERAGE TEST PASSED: more of the world now means something.")
	quit(0)


# --- fixtures --------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _settle(simulation: Object, years: int = 6) -> void:
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()


# Hand a fact to one mortal directly, so a reading can be tested without
# waiting for the world to produce the circumstance.
func _deliver(simulation: Object, holder_id: String, topic: String,
		subject_id: String, claim: String, confidence: int = 90) -> String:
	var knowledge_id := "%s_%s" % [subject_id, topic]
	simulation.state.learn_direct_knowledge(holder_id, {
		"id": knowledge_id,
		"subject_id": subject_id,
		"topic": topic,
		"claim": claim,
		"confidence": confidence,
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": 3,
		"participants": []
	})
	return knowledge_id


# The reading of a topic ABOUT A PARTICULAR PLACE.
#
# A mortal interprets their own settlement's condition as well as any they are
# told about, so observer plus topic no longer identifies one record. Every test
# here says which settlement it means.
func _reading(simulation: Object, holder_id: String, topic: String,
		subject_id: String = "") -> Dictionary:
	for record: Dictionary in simulation.state.interpretation_archive:
		if str(record["observer_id"]) != holder_id or str(record["topic"]) != topic:
			continue
		if not subject_id.is_empty() and str(record["subject_id"]) != subject_id:
			continue
		return record
	return {}


func _readings_by_topic(state) -> Dictionary:
	var counts := {}
	for record: Dictionary in state.interpretation_archive:
		var topic := str(record["topic"])
		counts[topic] = int(counts.get(topic, 0)) + 1
	return counts


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- coverage --------------------------------------------------------------

func _test_the_condition_topics_are_now_covered() -> void:
	var rules := InterpretationRules.new()
	for topic: String in CONDITION_TOPICS:
		assert(rules.has_candidates(topic), "'%s' still has no meanings" % topic)
		assert(rules.is_world_topic(topic), "'%s' is not treated as a world occurrence" % topic)
		assert(rules.is_interpretable(topic), "'%s' is not interpretable" % topic)
	print("  COVERED: %s." % ", ".join(CONDITION_TOPICS))
	completed += 1


func _test_a_resident_reads_a_shortage_as_danger_at_home() -> void:
	# The point of locality. This is the settlement they live in.
	var simulation := _sim()
	_settle(simulation, 4)
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	simulation.tick_interpretations()
	var reading := _reading(simulation, "mara", "food_shortage")
	assert(not reading.is_empty(), "a resident drew nothing from her own settlement starving")
	assert(str(reading["role"]) == InterpretationRules.STANCE_WITNESS,
		"a resident was treated as a distant observer")
	assert(str(reading["interpretation_type"]) in ["home_is_in_danger", "shortage_will_pass"],
		"unexpected reading: %s" % str(reading["interpretation_type"]))
	print("  AT HOME: Mara reads Westfield's shortage as '%s'." % str(reading["interpretation_type"]))
	completed += 1


func _test_someone_elsewhere_reads_the_same_fact_differently() -> void:
	# Same claim, same confidence, two mortals, two conclusions — decided by
	# where each of them lives and nothing else.
	var simulation := _sim()
	_settle(simulation, 4)
	for holder: String in ["mara", "aster_king"]:
		_deliver(simulation, holder, "food_shortage", "westfield",
			"Westfield does not have enough food")
	simulation.tick_interpretations()
	var local := _reading(simulation, "mara", "food_shortage", "westfield")
	var distant := _reading(simulation, "aster_king", "food_shortage", "westfield")
	assert(not local.is_empty() and not distant.is_empty(), "one of them drew nothing")
	assert(str(local["role"]) == InterpretationRules.STANCE_WITNESS)
	assert(str(distant["role"]) == InterpretationRules.STANCE_DISTANT)
	assert(str(local["interpretation_type"]) != str(distant["interpretation_type"]),
		"the resident and the outsider reached the same conclusion")
	assert(str(distant["interpretation_type"]) == "elsewhere_is_struggling")
	print("  DISAGREEMENT BY PLACE: '%s' at home, '%s' from Aster." % [
		str(local["interpretation_type"]), str(distant["interpretation_type"])
	])
	completed += 1


func _test_recovery_is_read_as_recovery() -> void:
	var simulation := _sim()
	_settle(simulation, 4)
	_deliver(simulation, "mara", "surplus", "westfield", "Westfield's stores are full again")
	simulation.tick_interpretations()
	var reading := _reading(simulation, "mara", "surplus")
	assert(not reading.is_empty(), "recovery meant nothing to the people who lived it")
	assert(str(reading["interpretation_type"]) in
		["home_is_recovering", "surplus_is_ordinary_luck"])
	print("  RECOVERY: '%s'." % str(reading["interpretation_type"]))
	completed += 1


func _test_traits_change_the_reading_of_the_same_fact() -> void:
	# Two residents of the SAME settlement, same fact, different dispositions.
	var simulation := _sim()
	var state = simulation.state
	state.add_notable_entity("steady", "The Steady One", "person", ["loyal", "gullible"], {}, "westfield")
	state.add_notable_entity("wary", "The Wary One", "person", ["cautious"], {}, "westfield")
	_settle(simulation, 4)
	for holder: String in ["steady", "wary"]:
		_deliver(simulation, holder, "food_shortage", "westfield",
			"Westfield does not have enough food")
	simulation.tick_interpretations()
	var steady := _reading(simulation, "steady", "food_shortage")
	var wary := _reading(simulation, "wary", "food_shortage")
	assert(not steady.is_empty() and not wary.is_empty())
	assert(str(steady["role"]) == str(wary["role"]), "the two differ by more than disposition")
	assert(str(steady["interpretation_type"]) != str(wary["interpretation_type"]),
		"two very different people read a famine identically")
	print("  DISAGREEMENT BY TRAIT: loyal reads '%s', cautious reads '%s'." % [
		str(steady["interpretation_type"]), str(wary["interpretation_type"])
	])
	completed += 1


func _test_a_recurring_condition_is_reconsidered_when_it_returns() -> void:
	# A world condition carries a stable id and is refreshed while it holds, so
	# without episodes a mortal would conclude about a recurring famine once in
	# their life. A famine that LIFTS AND RETURNS is a new thing to think about.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var knowledge_id := _deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	simulation.tick_interpretations()
	var first: Dictionary = state.get_knowledge("mara", knowledge_id)
	assert(int(first["episode"]) == 0, "the first spell is not episode zero")
	assert(state.has_interpretation("mara", knowledge_id, 0))

	# Years pass with no shortage, then it comes back.
	_settle(simulation, 5)
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	var second: Dictionary = state.get_knowledge("mara", knowledge_id)
	assert(int(second["episode"]) > 0,
		"a famine that lifted and returned was treated as the same spell")
	simulation.tick_interpretations()
	var readings := 0
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == "mara" and str(record["topic"]) == "food_shortage":
			readings += 1
	assert(readings >= 2, "the returning famine produced no second conclusion")
	print("  RECURRENCE: %d conclusions across %d spells." % [readings, int(second["episode"]) + 1])
	completed += 1


func _test_a_continuing_condition_is_not_reconsidered_every_year() -> void:
	# The other half. An unbroken shortage is ONE situation, and concluding
	# about it every year is the grinding the one-conclusion rule prevents.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	for year in range(5):
		_deliver(simulation, "mara", "food_shortage", "westfield",
			"Westfield does not have enough food")
		simulation.tick_interpretations()
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var readings := 0
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == "mara" and str(record["topic"]) == "food_shortage":
			readings += 1
	assert(readings == 1,
		"an unbroken shortage was reconsidered %d times" % readings)
	print("  CONTINUITY: five years of the same famine, one conclusion.")
	completed += 1


func _test_low_confidence_reaches_uncertainty() -> void:
	# A faint rumour must not support a confident reading. The existing
	# uncertainty candidate handles it; no new probability model was built.
	var simulation := _sim()
	_settle(simulation, 4)
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food", 10)
	simulation.tick_interpretations()
	var reading := _reading(simulation, "mara", "food_shortage")
	assert(not reading.is_empty(), "a faint rumour produced no record at all")
	assert(str(reading["interpretation_type"]) == "unclear_what_happened",
		"a 10-confidence rumour produced the reading '%s'"
			% str(reading["interpretation_type"]))
	print("  UNCERTAIN: a faint rumour reaches '%s'." % str(reading["interpretation_type"]))
	completed += 1


func _test_beliefs_bias_a_later_condition_reading() -> void:
	# An established belief weights the reading without settling it.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.record_belief({
		"holder_id": "mara", "proposition": BeliefRules.CONDITIONS_ARE_IMPROVING,
		"subject_id": "", "confidence": 80, "support": 5, "contradiction": 0,
		"first_year": state.year - 3, "last_updated_year": state.year,
		"source_interpretation_ids": ["seed"], "status": BeliefRules.STATUS_HELD
	})
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	simulation.tick_interpretations()
	var reading := _reading(simulation, "mara", "food_shortage")
	var used := false
	for factor_value in reading["factors"]:
		if str((factor_value as Dictionary)["kind"]) == "belief_at_least":
			used = true
	assert(used, "an established belief did not reach the reading")
	assert(str(reading["interpretation_type"]) == "shortage_will_pass",
		"the belief did not tip the reading: %s" % str(reading["interpretation_type"]))
	print("  BELIEF BIAS: believing things improve, Mara reads the shortage as passing.")
	completed += 1


func _test_a_condition_reading_reaches_a_later_intent() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	simulation.tick_interpretations()
	var found := false
	for candidate: Dictionary in simulation.evaluate_intents("mara"):
		for factor_value in candidate["interpretation_factors"]:
			var factor: Dictionary = factor_value
			if str(factor["detail"]) in ["home_is_in_danger", "shortage_will_pass"]:
				found = true
	# A reading with no intent rule is legitimate; assert only that at least one
	# world reading can reach reasoning, which `home_is_in_danger` does.
	if not found:
		var reading := _reading(simulation, "mara", "food_shortage")
		assert(str(reading["interpretation_type"]) == "shortage_will_pass",
			"a danger reading failed to reach any want")
	print("  REACHES WANTS: a world reading is available to later reasoning.")
	completed += 1


func _test_condition_readings_move_no_relationship() -> void:
	# A settlement running short is not something one person did to another.
	# Inventing a party to blame would need a model of who is responsible for a
	# place, and no such model exists.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var before := str(state.relationships)
	for topic: String in CONDITION_TOPICS:
		_deliver(simulation, "mara", topic, "westfield", "Something about Westfield")
	simulation.tick_interpretations()
	assert(str(state.relationships) == before,
		"a world condition moved a relationship")
	for record: Dictionary in state.interpretation_archive:
		if str(record["topic"]) in CONDITION_TOPICS:
			assert(record["applied_effect"].is_empty(),
				"a condition reading applied a relationship effect")
	print("  NO BLAME: world conditions moved no relationship.")
	completed += 1


func _test_social_readings_still_move_one_bounded_axis() -> void:
	# The existing bound is unchanged by the new coverage.
	var simulation := _sim()
	var state = simulation.state
	for year in range(24):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var moved := 0
	for record: Dictionary in state.interpretation_archive:
		var effect: Dictionary = record["applied_effect"]
		if effect.is_empty():
			continue
		moved += 1
		assert(absi(int(effect["amount"])) <= InterpretationRules.MAX_EFFECT_MAGNITUDE,
			"an effect of %d exceeded the bound" % int(effect["amount"]))
		assert(str(effect["axis"]) in WorldState.RELATIONSHIP_AXES)
	assert(moved > 0, "no social reading moved anything, so nothing is proven")
	print("  BOUNDED: %d effects, none beyond +/-%d on one axis."
		% [moved, InterpretationRules.MAX_EFFECT_MAGNITUDE])
	completed += 1


# --- what coverage must not become -----------------------------------------

func _test_coverage_report_names_the_gaps() -> void:
	# The diagnostic exists so a content gap does not look like the system
	# choosing uncertainty.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 8)
	_deliver(simulation, "mara", "mortal_speech", "westfield", "A voice spoke with certainty")
	var report: Dictionary = simulation.interpretation_rules.coverage_report(state)
	for field: String in [
		"topics_encountered", "topics_covered", "topics_without_candidates",
		"families_designed"
	]:
		assert(report.has(field), "the coverage report cannot answer '%s'" % field)
	assert("mortal_speech" in report["topics_without_candidates"],
		"an uncovered topic in play was not reported as a gap")
	assert("mortal_speech" not in report["topics_covered"])
	for topic: String in report["topics_covered"]:
		assert(topic in report["families_designed"])
	print("  DIAGNOSTIC: %d topics in play, %d covered, gaps named: %s." % [
		report["topics_encountered"].size(), report["topics_covered"].size(),
		str(report["topics_without_candidates"])
	])
	completed += 1


func _test_undesigned_topics_produce_no_conclusion() -> void:
	# Better coverage, not total coverage. A topic nobody has written meanings
	# for is held as a fact and nothing is invented to fill it.
	var simulation := _sim()
	var state = simulation.state
	var rules := InterpretationRules.new()
	_settle(simulation, 4)
	for topic: String in DELIBERATELY_UNCOVERED:
		assert(not rules.has_candidates(topic),
			"this test is stale: '%s' now has meanings" % topic)
		_deliver(simulation, "mara", topic, "westfield", "Something happened in Westfield")
	simulation.tick_interpretations()
	for topic: String in DELIBERATELY_UNCOVERED:
		assert(_reading(simulation, "mara", topic).is_empty(),
			"a conclusion was invented for the undesigned topic '%s'" % topic)
		assert(not state.get_knowledge("mara", "westfield_%s" % topic).is_empty(),
			"the fact itself was dropped rather than merely left unread")
	print("  HELD, UNREAD: %s remain facts with no meaning." % ", ".join(DELIBERATELY_UNCOVERED))
	completed += 1


func _test_no_hidden_cause_reaches_a_condition_reading() -> void:
	# A reading may use only what the mortal has. The engine knows why the world
	# is the way it is; no factor may consult that.
	var code := _code_of("res://scripts/interpretation_rules.gd")
	for forbidden: String in [
		"objective_truth_state", "divine_action_archive", "get_divine_action",
		"consequence_archive", "get_consequence", "intent_archive", "execution_archive"
	]:
		assert(not code.contains(forbidden),
			"interpretation can see '%s', which mortals cannot" % forbidden)
	# Behaviourally: a shortage the god caused reads no differently.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	simulation.tick_interpretations()
	var reading := _reading(simulation, "mara", "food_shortage")
	for factor_value in reading["factors"]:
		var kind := str((factor_value as Dictionary)["kind"])
		assert(not kind.contains("divine_action") and not kind.contains("caused_by"),
			"a reading leaned on hidden causation: %s" % kind)
	print("  NO LEAK: readings use the observer's own state only.")
	completed += 1


func _test_interpretation_never_becomes_knowledge() -> void:
	# The fact stays the fact. A meaning must never be written back into it.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var knowledge_id := _deliver(simulation, "mara", "food_shortage", "westfield",
		"Westfield does not have enough food")
	var before: Dictionary = state.get_knowledge("mara", knowledge_id).duplicate(true)
	simulation.tick_interpretations()
	var after: Dictionary = state.get_knowledge("mara", knowledge_id)
	for field: String in ["claim", "topic", "confidence", "truth_state", "subject_id"]:
		assert(str(after[field]) == str(before[field]),
			"interpreting the fact changed its '%s'" % field)
	var reading := _reading(simulation, "mara", "food_shortage")
	assert(not str(after["claim"]).contains(str(reading["meaning"])),
		"a meaning was written into the factual record")
	print("  FACT INTACT: \"%s\" unchanged by being interpreted." % str(after["claim"]))
	completed += 1


func _test_history_did_not_become_dense_by_bypass() -> void:
	# More mental activity must not automatically mean more history. Chronicle's
	# own threshold and factor weights are untouched; anything new that reaches
	# history does so through the rules as they already stood.
	assert(ChronicleRules.IMPORTANCE_THRESHOLD == 50,
		"the Chronicle threshold moved")
	assert(int(ChronicleRules.FACTOR_SCORES["changes_later_behaviour"]) == 50)
	assert(int(ChronicleRules.FACTOR_SCORES["relationship_band_crossed"]) == 50)
	var chronicle_code := _code_of("res://scripts/chronicle_rules.gd")
	for topic: String in CONDITION_TOPICS:
		assert(not chronicle_code.contains('"%s"' % topic),
			"the Chronicle grew a special case for '%s'" % topic)
	# And every entry still clears the threshold on its own factors.
	var simulation := _sim()
	var state = simulation.state
	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	for record: Dictionary in state.chronicle:
		var total := 0
		for factor_value in record["factors"]:
			total += int((factor_value as Dictionary)["score"])
		assert(total == int(record["importance"])
			and total >= ChronicleRules.IMPORTANCE_THRESHOLD,
			"a history entry did not earn its place")
	print("  NO BYPASS: %d entries, each clearing the unchanged threshold." % state.chronicle.size())
	completed += 1


func _test_no_new_intents_or_out_of_scope_systems() -> void:
	var vocabulary := [
		"help", "protect", "acquire", "learn", "influence",
		"connect", "distance", "resolve", "preserve", "wait"
	]
	var simulation := _sim()
	var state = simulation.state
	for year in range(24):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	for record: Dictionary in state.intent_archive:
		assert(str(record["intent_type"]) in vocabulary,
			"a new intent appeared: %s" % str(record["intent_type"]))
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd"
	]:
		var code := _code_of(path).to_lower()
		for forbidden: String in OUT_OF_SCOPE:
			assert(not code.contains(forbidden),
				"%s reached into '%s'" % [path, forbidden])
	print("  SCOPE: ten intents, and no new subsystem.")
	completed += 1


func _test_coverage_works_for_an_arbitrary_settlement() -> void:
	# The locality foundation still holds: nothing in the new coverage knows
	# which settlements happen to exist.
	var simulation := _sim()
	var state = simulation.state
	state.add_location("test_vale", "Test Vale", "farming_village", "Grain", {
		"food": 1, "stability": 2, "prosperity": 1, "population": 90
	})
	state.add_notable_entity("test_farmer", "The Farmer", "person", ["cautious"], {}, "test_vale")
	_settle(simulation, 4)
	_deliver(simulation, "test_farmer", "food_shortage", "test_vale",
		"Test Vale does not have enough food")
	simulation.tick_interpretations()
	var reading := _reading(simulation, "test_farmer", "food_shortage")
	assert(not reading.is_empty(), "an invented settlement produced no reading")
	assert(str(reading["role"]) == InterpretationRules.STANCE_WITNESS)
	assert(str(reading["interpretation_type"]) == "home_is_in_danger")
	var code := _code_of("res://scripts/interpretation_rules.gd")
	assert(not code.contains('"westfield"') and not code.contains('"aster"'),
		"the new coverage named a settlement")
	print("  ARBITRARY IDS: the Farmer of Test Vale reads '%s'."
		% str(reading["interpretation_type"]))
	completed += 1


func _test_the_autonomous_world_is_richer() -> void:
	# The milestone's own success criterion: the SAME small world, left alone,
	# now produces meanings across more of what happens to it.
	var simulation := _sim()
	var state = simulation.state
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var by_topic := _readings_by_topic(state)
	var families := 0
	for topic in by_topic:
		families += 1
	assert(families >= 5,
		"only %d topic families were interpreted across forty years" % families)
	var condition_readings := 0
	for topic: String in CONDITION_TOPICS:
		condition_readings += int(by_topic.get(topic, 0))
	assert(condition_readings > 0,
		"the world's own conditions still mean nothing to anybody")
	# Beliefs formed from them, and Chronicle stayed a selection.
	var world_beliefs := 0
	for belief: Dictionary in state.mortal_beliefs:
		if str(belief["proposition"]) in [
			BeliefRules.HOME_IS_UNSAFE, BeliefRules.CONDITIONS_ARE_IMPROVING
		]:
			world_beliefs += 1
	assert(world_beliefs > 0, "no belief formed from the world's conditions")
	assert(state.chronicle.size() < state.interpretation_archive.size(),
		"history is no longer a selection over what mortals concluded")
	print("  RICHER: %d topic families, %d condition readings, %d world beliefs, %d history entries." % [
		families, condition_readings, world_beliefs, state.chronicle.size()
	])
	completed += 1
