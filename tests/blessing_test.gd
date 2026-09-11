extends SceneTree

# Bless Harvest — Shared-Pipeline Sandbox v1.
#
# The second power to leave the legacy road, and the one that proves the sandbox
# architecture is not just "Send Rain with different words".
#
# Water has a top end that ruins a place, because too much water is a real
# problem. Grain does not. So this power accumulates the same way and escalates
# the same way, and its top state is simply a settlement that keeps producing —
# **no punishment is written into it**. If sustained abundance ever becomes
# dangerous, that will be ecology or politics or belief reacting to the
# condition, decided by systems that do not exist yet. A power that punished its
# own repetition would be pre-empting them.
#
# The other half is the migration: no faith, no followers, no reputation, no
# collective meaning. What a remarkable harvest MEANT is now something an
# observer works out, and one of them can spend forty years calling it a good
# season.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 24

const FIXTURE_LOCATIONS = ["aster", "westfield", "frontier"]
const NEW_PLACE := "test_terraces"

var completed := 0


func _init() -> void:
	_test_blessing_can_target_any_settlement()
	_test_the_target_is_not_the_event_location()
	_test_an_arbitrary_settlement_can_be_blessed()
	_test_available_whether_food_is_low_or_high()
	_test_repeatable_without_limit()

	_test_one_blessing_raises_abundance()
	_test_blessings_accumulate()
	_test_abundance_drifts_back()
	_test_blessings_outpace_the_drift()
	_test_abundance_crosses_its_states()
	_test_sustained_abundance_stays_beneficial()
	_test_stopping_returns_the_land_to_ordinary()

	_test_the_harvest_travels_the_shared_pipeline()
	_test_repetition_becomes_visible_evidence()
	_test_two_observers_disagree_about_the_same_harvest()
	_test_a_belief_can_form_about_a_place()
	_test_a_reading_can_reach_a_later_want()

	_test_no_legacy_reception_runs()
	_test_no_faith_followers_or_reputation()
	_test_no_artificial_drawback()
	_test_the_occurrence_names_no_cause()
	_test_rules_stay_actor_neutral()
	_test_other_powers_are_unchanged()
	_test_nothing_out_of_scope_was_added()

	if completed != EXPECTED_TESTS:
		push_error("Blessing suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("BLESSING TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("BLESSING TEST PASSED: the fields give, and nobody is punished for it.")
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


func _bless(simulation: Object, location_id: String, times: int) -> int:
	var applied := 0
	for year in range(times):
		if bool(simulation.resolve_action("bless_harvest", location_id)["ok"]):
			applied += 1
		simulation.advance_year()
	return applied


# Two observers of the same settlement with opposite dispositions, so a
# disagreement can be about temperament rather than about who they are.
func _with_observers(simulation: Object) -> void:
	var state = simulation.state
	state.add_notable_entity("test_hopeful", "The Hopeful One", "person", ["gullible"], {}, "westfield")
	state.add_notable_entity("test_dour", "The Dour One", "person", ["cautious"], {}, "westfield")


func _knowledge_on(state, holder_id: String, topic: String) -> Dictionary:
	for record: Dictionary in state.get_all_knowledge(holder_id).values():
		if str(record.get("topic", "")) == topic:
			return record
	return {}


func _readings(state, holder_id: String) -> Array[String]:
	var found: Array[String] = []
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == holder_id \
			and str(record["topic"]) in ["harvest_yield", "extraordinary_harvest"]:
			found.append(str(record["interpretation_type"]))
	return found


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- targeting and freedom -------------------------------------------------

func _test_blessing_can_target_any_settlement() -> void:
	for location_id: String in FIXTURE_LOCATIONS:
		var simulation := _sim()
		var state = simulation.state
		_settle(simulation, 4)
		var result := simulation.resolve_action("bless_harvest", location_id) as Dictionary
		assert(bool(result["ok"]), "blessing %s was refused" % location_id)
		var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
		assert(str(record["target_id"]) == location_id,
			"the blessing landed on %s" % str(record["target_id"]))
		assert(state.get_abundance(location_id) > 0, "%s gained no abundance" % location_id)
	print("  TARGETS: every settlement can be blessed by name.")
	completed += 1


func _test_the_target_is_not_the_event_location() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var elsewhere := ""
	for location_id: String in state.get_location_ids():
		if location_id != state.current_event_location_id:
			elsewhere = location_id
			break
	var event_abundance: int = state.get_abundance(state.current_event_location_id)
	simulation.resolve_action("bless_harvest", elsewhere)
	assert(state.get_abundance(elsewhere) > 0)
	assert(state.get_abundance(state.current_event_location_id) == event_abundance,
		"the blessing was redirected to where the event was")
	print("  NOT REDIRECTED: event in %s, blessing on %s." % [
		state.current_event_location_id, elsewhere
	])
	completed += 1


func _test_an_arbitrary_settlement_can_be_blessed() -> void:
	var simulation := _sim()
	var state = simulation.state
	state.add_location(NEW_PLACE, "Test Terraces", "farming_village", "Grain", {
		"food": 1, "stability": 2, "prosperity": 1, "population": 90
	})
	state.add_notable_entity("test_grower", "The Grower", "person", ["gullible"], {}, NEW_PLACE)
	_settle(simulation, 4)
	assert(bool(simulation.resolve_action("bless_harvest", NEW_PLACE)["ok"]))
	assert(state.get_abundance(NEW_PLACE) > 0)
	print("  ARBITRARY: Test Terraces blessed like anywhere else.")
	completed += 1


func _test_available_whether_food_is_low_or_high() -> void:
	# Not a remedy. It is offered when it is needed and when it is not.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	for food in [0, 3]:
		state.set_settlement_band("westfield", "food", food)
		state.action_taken = false
		state.divine_power = state.max_divine_power
		assert(bool(simulation.resolve_action("bless_harvest", "westfield")["ok"]),
			"blessing was refused at food %d" % food)
	var code := _code_of("res://scripts/world_sim.gd")
	for forbidden: String in [
		"harvest_not_needed", "already_blessed", "food_is_sufficient", "best_target"
	]:
		assert(not code.contains(forbidden), "a gating rule exists: %s" % forbidden)
	print("  NO GATING: usable at empty stores and full ones alike.")
	completed += 1


func _test_repeatable_without_limit() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var applied := _bless(simulation, "westfield", 8)
	assert(applied == 8, "only %d of 8 blessings were allowed" % applied)
	print("  REPEATABLE: eight consecutive blessings, none refused.")
	completed += 1


# --- persistent abundance --------------------------------------------------

func _test_one_blessing_raises_abundance() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var before: int = state.get_abundance("westfield")
	simulation.resolve_action("bless_harvest", "westfield")
	assert(state.get_abundance("westfield")
		== before + WorldSimulation.BLESSING_ABUNDANCE_GAIN,
		"the blessing did not add the stated abundance")
	print("  FORCE: one blessing adds %d abundance." % WorldSimulation.BLESSING_ABUNDANCE_GAIN)
	completed += 1


func _test_blessings_accumulate() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var readings: Array[int] = []
	for repeat in range(3):
		simulation.resolve_action("bless_harvest", "westfield")
		readings.append(state.get_abundance("westfield"))
		simulation.advance_year()
	assert(readings[1] > readings[0] and readings[2] > readings[1],
		"repeated blessings did not accumulate: %s" % str(readings))
	print("  ACCUMULATES: %s." % str(readings))
	completed += 1


func _test_abundance_drifts_back() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 2)
	state.set_abundance("westfield", WorldState.ABUNDANCE_MAX)
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	assert(state.get_abundance("westfield")
		== WorldState.ABUNDANCE_MAX - WorldSimulation.ABUNDANCE_DRIFT_PER_YEAR,
		"the drift is not the stated rate")
	print("  DRIFT: %d per year toward %d." % [
		WorldSimulation.ABUNDANCE_DRIFT_PER_YEAR, WorldState.ABUNDANCE_BASELINE
	])
	completed += 1


func _test_blessings_outpace_the_drift() -> void:
	assert(WorldSimulation.BLESSING_ABUNDANCE_GAIN
		> WorldSimulation.ABUNDANCE_DRIFT_PER_YEAR,
		"a year of drift undoes a blessing; abundance could never be sustained")
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_bless(simulation, "westfield", 4)
	assert(state.abundance_state("westfield") == WorldState.ABUNDANCE_SUSTAINED,
		"four blessings did not reach a sustained state: %s"
			% state.abundance_state("westfield"))
	print("  OUTPACES: blessing %d vs drift %d." % [
		WorldSimulation.BLESSING_ABUNDANCE_GAIN, WorldSimulation.ABUNDANCE_DRIFT_PER_YEAR
	])
	completed += 1


func _test_abundance_crosses_its_states() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var seen: Array[String] = []
	for repeat in range(5):
		simulation.resolve_action("bless_harvest", "westfield")
		var abundance_state: String = state.abundance_state("westfield")
		if abundance_state not in seen:
			seen.append(abundance_state)
		simulation.advance_year()
	for expected: String in [
		WorldState.ABUNDANCE_ABUNDANT, WorldState.ABUNDANCE_EXTRAORDINARY,
		WorldState.ABUNDANCE_SUSTAINED
	]:
		assert(expected in seen, "never reached '%s': %s" % [expected, str(seen)])
	print("  STATES: %s." % " -> ".join(seen))
	completed += 1


func _test_sustained_abundance_stays_beneficial() -> void:
	# The point of the whole power. Unlike water, the top of this scale is not
	# ruin: a settlement kept there keeps eating.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_settlement_band("westfield", "food", 1)
	state.set_settlement_band("westfield", "stability", 2)
	_bless(simulation, "westfield", 10)
	assert(state.abundance_state("westfield") == WorldState.ABUNDANCE_SUSTAINED)
	assert(state.get_settlement_band("westfield", "food") >= 2,
		"ten blessings left the settlement hungry")
	assert(state.get_settlement_band("westfield", "stability") >= 2,
		"sustained abundance shook the settlement")
	print("  NO PUNISHMENT: ten blessings, food %d and stability %d." % [
		state.get_settlement_band("westfield", "food"),
		state.get_settlement_band("westfield", "stability")
	])
	completed += 1


func _test_stopping_returns_the_land_to_ordinary() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_bless(simulation, "westfield", 4)
	for year in range(20):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	assert(state.abundance_state("westfield") == WorldState.ABUNDANCE_ORDINARY,
		"the land stayed extraordinary with nobody sustaining it: %s"
			% state.abundance_state("westfield"))
	print("  FADES: ordinary again once the blessings stop.")
	completed += 1


# --- the causal road -------------------------------------------------------

func _test_the_harvest_travels_the_shared_pipeline() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var result := simulation.resolve_action("bless_harvest", "westfield") as Dictionary
	assert(str(result["pipeline"]) == DivineActionRules.PIPELINE_SHARED,
		"Bless Harvest is still on the legacy road")
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(not str(record["consequence_id"]).is_empty(), "no consequence was produced")
	simulation.advance_year()
	var fact := _knowledge_on(state, "mara", "harvest_yield")
	assert(not fact.is_empty(), "the harvest reached nobody who lives there")
	assert(str(fact["claim"]).contains("Westfield"))
	var reading := _readings(state, "mara")
	assert(not reading.is_empty(), "nobody made anything of the harvest")
	print("  CHAIN: blessing -> \"%s\" -> %s." % [str(fact["claim"]), reading[0]])
	completed += 1


func _test_repetition_becomes_visible_evidence() -> void:
	# The evidence a mortal reasons from is the settlement's own condition,
	# which they can see — never the player's action history.
	var simulation := _sim()
	var state = simulation.state
	_with_observers(simulation)
	_settle(simulation, 4)
	_bless(simulation, "westfield", 6)
	var pattern := _knowledge_on(state, "test_hopeful", "extraordinary_harvest")
	assert(not pattern.is_empty(), "the pattern was never perceivable")
	assert(str(pattern["claim"]).contains("Westfield"))
	# And the rules cannot reach the player's record of what he did.
	var code := _code_of("res://scripts/interpretation_rules.gd")
	for forbidden: String in ["divine_action_archive", "action_counts", "intervention_counts"]:
		assert(not code.contains(forbidden),
			"interpretation can read the player's history: %s" % forbidden)
	print("  EVIDENCE: \"%s\"." % str(pattern["claim"]))
	completed += 1


func _test_two_observers_disagree_about_the_same_harvest() -> void:
	# Same settlement, same harvests, same years, opposite temperaments.
	var simulation := _sim()
	var state = simulation.state
	_with_observers(simulation)
	_settle(simulation, 4)
	_bless(simulation, "westfield", 8)
	var hopeful := _readings(state, "test_hopeful")
	var dour := _readings(state, "test_dour")
	assert(not hopeful.is_empty() and not dour.is_empty(), "one of them concluded nothing")
	var hopeful_divine := 0
	var dour_divine := 0
	for reading: String in hopeful:
		hopeful_divine += int(reading.contains("divine"))
	for reading: String in dour:
		dour_divine += int(reading.contains("divine"))
	assert(hopeful_divine > 0, "eight impossible harvests convinced nobody")
	assert(dour_divine == 0,
		"the cautious observer also concluded something was sent (%d times)" % dour_divine)
	print("  DISAGREEMENT: hopeful reached a divine reading %d times, dour %d." % [
		hopeful_divine, dour_divine
	])
	completed += 1


func _test_a_belief_can_form_about_a_place() -> void:
	var simulation := _sim()
	var state = simulation.state
	_with_observers(simulation)
	_settle(simulation, 4)
	_bless(simulation, "westfield", 6)
	var belief: Dictionary = state.get_belief(
		"test_hopeful", BeliefRules.DIVINE_INTERVENTION_EXISTS, ""
	)
	assert(not belief.is_empty(), "no belief formed from repeated impossible harvests")
	assert(int(belief["confidence"]) > 0)
	# The place-scoped one is about a SETTLEMENT, not a person or a people.
	for record: Dictionary in state.mortal_beliefs:
		if str(record["proposition"]) == BeliefRules.PLACE_IS_FAVOURED:
			assert(state.locations.has(str(record["subject_id"])),
				"a place-scoped belief is not about a place")
	print("  BELIEF: the Hopeful One holds divine_intervention_exists at %d."
		% int(belief["confidence"]))
	completed += 1


func _test_a_reading_can_reach_a_later_want() -> void:
	var simulation := _sim()
	var state = simulation.state
	_with_observers(simulation)
	_settle(simulation, 4)
	_bless(simulation, "westfield", 6)
	var reached := false
	for candidate: Dictionary in simulation.evaluate_intents("test_hopeful"):
		for factor_value in candidate["interpretation_factors"] + candidate["belief_factors"]:
			var detail := str((factor_value as Dictionary)["detail"])
			if detail.contains("harvest") or detail.contains("favoured") \
				or detail.contains("divine") or detail.contains("yield"):
				reached = true
	assert(reached, "nothing the observer concluded reached what they want")
	print("  FEEDBACK: a harvest conclusion reaches later reasoning.")
	completed += 1


# --- migration boundaries --------------------------------------------------

func _test_no_legacy_reception_runs() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var collective: int = state.interpretation_history.size()
	var result := simulation.resolve_action("bless_harvest", "westfield") as Dictionary
	assert(state.interpretation_history.size() == collective,
		"the legacy collective reader ran for a migrated power")
	for field: String in [
		"interpretation", "interpretation_id", "belief_tag", "belief_formed",
		"reputation_hint"
	]:
		assert(str(result[field]).is_empty(),
			"the act returned '%s': \"%s\"" % [field, str(result[field])])
	assert(not bool(result["reputation_changed"]))
	assert(state.last_interpretation.is_empty())
	print("  MIGRATED: no collective meaning, no legacy reception.")
	completed += 1


func _test_no_faith_followers_or_reputation() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	for repeat in range(6):
		var faith: int = state.faith
		var followers: int = state.followers
		var reputation: String = state.reputation
		var pressure := str(state.belief_pressure)
		var beliefs := str(state.beliefs)
		simulation.resolve_action("bless_harvest", "westfield")
		assert(state.faith == faith, "the blessing moved faith")
		assert(state.followers == followers, "the blessing moved followers")
		assert(state.reputation == reputation, "the blessing renamed the god")
		assert(str(state.belief_pressure) == pressure, "the blessing moved belief pressure")
		assert(str(state.beliefs) == beliefs, "the blessing wrote realm doctrine")
		simulation.advance_year()
	print("  BOUNDARY: six blessings moved no faith, follower or reputation.")
	completed += 1


func _test_no_artificial_drawback() -> void:
	# The design rule this power exists to demonstrate. Repetition must not
	# punish by arithmetic; a hazard has to come from a system reacting to the
	# condition, and none of those exist yet.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_settlement_band("westfield", "food", 3)
	state.set_settlement_band("westfield", "stability", 3)
	state.set_settlement_band("westfield", "prosperity", 2)
	var population_before: int = state.get_settlement_population("westfield")
	_bless(simulation, "westfield", 12)
	assert(state.get_settlement_band("westfield", "food") >= 2,
		"twelve blessings starved the settlement")
	assert(state.get_settlement_band("westfield", "stability") >= 2,
		"twelve blessings destabilised the settlement")
	assert(state.get_settlement_band("westfield", "prosperity") >= 2,
		"twelve blessings impoverished the settlement")
	assert(state.get_settlement_population("westfield") >= population_before / 2,
		"twelve blessings emptied the settlement")
	# And no hazard vocabulary exists anywhere in the power's own rules.
	var code := _code_of("res://scripts/world_sim.gd").to_lower()
	for forbidden: String in [
		"soil_exhaustion", "locust", "pest", "blight", "famine_from", "spoilage",
		"overproduction", "complacen"
	]:
		assert(not code.contains(forbidden), "a built-in punishment exists: %s" % forbidden)
	print("  NO DRAWBACK: twelve blessings, and the settlement is fine.")
	completed += 1


func _test_the_occurrence_names_no_cause() -> void:
	var simulation := _sim()
	var state = simulation.state
	_with_observers(simulation)
	_settle(simulation, 4)
	_bless(simulation, "westfield", 6)
	for entity: Dictionary in state.notable_entities.values():
		for record: Dictionary in state.get_all_knowledge(str(entity["id"])).values():
			if str(record["topic"]) not in ["harvest_yield", "extraordinary_harvest"]:
				continue
			var claim := str(record["claim"]).to_lower()
			for word: String in ["god", "blessed", "chosen", "faithful", "rewarded", "divine"]:
				assert(not claim.contains(word),
					"a harvest fact named a cause: %s" % str(record["claim"]))
	print("  OBJECTIVE: every harvest fact states yield, never a giver.")
	completed += 1


func _test_rules_stay_actor_neutral() -> void:
	# Humans are the prototype cast, not a requirement. No production rule may
	# depend on a particular actor, place, or on being human at all.
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd",
		"res://scripts/feedback_rules.gd", "res://scripts/chronicle_rules.gd",
		"res://scripts/consequence_rules.gd", "res://scripts/divine_action_rules.gd"
	]:
		var code := _code_of(path)
		# Quoted literals only. A bare substring search matches "aster" inside
		# "flood_is_disaster", which is the kind of false positive that makes a
		# structural test worse than none.
		for forbidden: String in FIXTURE_LOCATIONS + ["mara", "aster_king", "human"]:
			assert(not code.contains('"%s"' % forbidden),
				"%s depends on '%s'" % [path, forbidden])
	# And the whole chain works for an invented place and an invented actor.
	var simulation := _sim()
	var state = simulation.state
	state.add_location(NEW_PLACE, "Test Terraces", "farming_village", "Grain", {
		"food": 1, "stability": 2, "prosperity": 1, "population": 90
	})
	state.add_notable_entity("test_grower", "The Grower", "person", ["gullible"], {}, NEW_PLACE)
	_settle(simulation, 4)
	_bless(simulation, NEW_PLACE, 6)
	assert(not _readings(state, "test_grower").is_empty(),
		"an invented actor in an invented place concluded nothing")
	print("  ACTOR-NEUTRAL: the Grower of Test Terraces reasons like anyone else.")
	completed += 1


func _test_other_powers_are_unchanged() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var result := simulation.resolve_action("speak_mortal") as Dictionary
	if bool(result["ok"]):
		assert(str(result["pipeline"]) == DivineActionRules.PIPELINE_LEGACY,
			"an unmigrated power was quietly migrated")
		assert(not str(result["interpretation"]).is_empty(),
			"an unmigrated power lost its collective meaning")
	var rules := DivineActionRules.new()
	assert(rules.shared_pipeline_actions() == ["bless_harvest", "send_rain", "smite"],
		"the migrated set is not what CLAUDE.md records: %s"
			% str(rules.shared_pipeline_actions()))
	print("  LEGACY KEPT: %s still read collectively." % str(result["interpretation"]))
	completed += 1


func _test_nothing_out_of_scope_was_added() -> void:
	for path: String in [
		"res://scripts/world_sim.gd", "res://scripts/interpretation_rules.gd",
		"res://scripts/belief_rules.gd", "res://scripts/feedback_rules.gd"
	]:
		var code := _code_of(path).to_lower()
		for forbidden: String in [
			"religion", "doctrine", "faction", "politic", "ecology", "migration",
			"trade_route", "species", "kingdom_two", "second_god"
		]:
			assert(not code.contains(forbidden), "%s reached into '%s'" % [path, forbidden])
	print("  SCOPE: no religion, faction, ecology, species or second god.")
	completed += 1
