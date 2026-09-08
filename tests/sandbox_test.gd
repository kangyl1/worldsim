extends SceneTree

# Divine Sandbox & Cumulative Consequences Foundation v1.
#
# Send Rain used to ask whether a drought was running and hand out food
# accordingly. That made a divine power a CORRECT ANSWER to a situation, and the
# player a person picking the right response from a menu.
#
# Now it applies the same force every time — water into the ground — and what
# that force WAS depends entirely on what the ground was already holding. The
# god may water a parched field, a healthy one, or one already under water, and
# the world deals with the result. Nothing stops them.
#
# So this suite is in three parts. That the force accumulates and escalates from
# help to catastrophe; that nothing anywhere protects the player from doing it;
# and that the damage travels the ordinary causal road — perceived, known,
# interpreted, believed — rather than through any shortcut of its own.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 24

const FIXTURE_LOCATIONS = ["aster", "westfield", "frontier"]
const NEW_PLACE := "test_delta"

var completed := 0


func _init() -> void:
	_test_rain_can_target_any_settlement_explicitly()
	_test_the_target_is_not_replaced_by_the_event_location()
	_test_the_driest_settlement_is_not_chosen_for_the_player()
	_test_an_arbitrary_settlement_can_be_targeted()
	_test_no_rule_names_a_settlement()

	_test_one_rain_raises_the_water()
	_test_rain_on_dry_ground_helps()
	_test_rain_on_healthy_ground_does_little()
	_test_rain_accumulates()
	_test_water_drifts_back_on_its_own()
	_test_repeated_rain_outpaces_the_drift()
	_test_enough_rain_saturates_then_floods()
	_test_flooding_harms_the_settlement()
	_test_stopping_lets_the_ground_recover()

	_test_rain_is_never_disabled()
	_test_a_flooded_settlement_stays_targetable()
	_test_nothing_recommends_a_target()

	_test_the_flood_reaches_mortal_reasoning()
	_test_a_flood_can_contradict_a_divine_belief()
	_test_feedback_escalates_with_the_ground()

	_test_no_faith_or_legacy_path()
	_test_no_belief_or_relationship_is_written_directly()
	_test_flood_meaning_never_becomes_fact()
	_test_ordinary_rain_is_not_historic()

	if completed != EXPECTED_TESTS:
		push_error("Sandbox suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("SANDBOX TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("SANDBOX TEST PASSED: the god applies a force, and the world lives with it.")
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


# Rain on one place, year after year, whatever it needs.
func _rain_on(simulation: Object, location_id: String, times: int) -> int:
	var applied := 0
	for year in range(times):
		var result := simulation.resolve_action("send_rain", location_id) as Dictionary
		if bool(result["ok"]):
			applied += 1
		simulation.advance_year()
	return applied


func _knowledge_on(state, holder_id: String, topic: String) -> Dictionary:
	for record: Dictionary in state.get_all_knowledge(holder_id).values():
		if str(record.get("topic", "")) == topic:
			return record
	return {}


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- targeting -------------------------------------------------------------

func _test_rain_can_target_any_settlement_explicitly() -> void:
	for location_id: String in FIXTURE_LOCATIONS:
		var simulation := _sim()
		var state = simulation.state
		_settle(simulation, 4)
		var before: int = state.get_water(location_id)
		var result := simulation.resolve_action("send_rain", location_id) as Dictionary
		assert(bool(result["ok"]), "rain on %s was refused" % location_id)
		var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
		assert(str(record["target_id"]) == location_id,
			"the act landed on %s instead of %s" % [str(record["target_id"]), location_id])
		assert(state.get_water(location_id) > before,
			"the chosen settlement's ground did not change")
	print("  EXPLICIT TARGETS: every settlement can be rained on by name.")
	completed += 1


func _test_the_target_is_not_replaced_by_the_event_location() -> void:
	# The heart of the sandbox. The world decides where events happen; the god
	# decides where to act, and the two need not agree.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var elsewhere := ""
	for location_id: String in state.get_location_ids():
		if location_id != state.current_event_location_id:
			elsewhere = location_id
			break
	assert(not elsewhere.is_empty(), "the fixture needs a second settlement")
	var event_water: int = state.get_water(state.current_event_location_id)
	var result := simulation.resolve_action("send_rain", elsewhere) as Dictionary
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(str(record["target_id"]) == elsewhere,
		"the act was redirected to where the event was")
	assert(state.get_water(state.current_event_location_id) == event_water,
		"the event's settlement got the rain the player aimed elsewhere")
	print("  NOT REDIRECTED: event in %s, rain on %s." % [
		state.current_event_location_id, elsewhere
	])
	completed += 1


func _test_the_driest_settlement_is_not_chosen_for_the_player() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	# Make one settlement parched and rain somewhere else entirely.
	var parched := FIXTURE_LOCATIONS[0]
	var chosen := FIXTURE_LOCATIONS[1]
	state.set_water(parched, WorldState.WATER_MIN)
	state.set_water(chosen, WorldState.WATER_BASELINE)
	var parched_before: int = state.get_water(parched)
	simulation.resolve_action("send_rain", chosen)
	assert(state.get_water(parched) == parched_before,
		"the simulation watered the settlement that needed it most")
	assert(state.get_water(chosen) > WorldState.WATER_BASELINE)
	print("  NO AUTO-TARGET: the parched settlement stayed parched.")
	completed += 1


func _test_an_arbitrary_settlement_can_be_targeted() -> void:
	var simulation := _sim()
	var state = simulation.state
	state.add_location(NEW_PLACE, "Test Delta", "farming_village", "Fields", {
		"food": 1, "stability": 2, "prosperity": 1, "population": 80
	})
	state.add_notable_entity("test_ferryman", "The Ferryman", "person", ["cautious"], {}, NEW_PLACE)
	_settle(simulation, 4)
	assert(state.get_water(NEW_PLACE) == WorldState.WATER_BASELINE
		or state.get_water(NEW_PLACE) > 0, "a new settlement has no ground")
	var result := simulation.resolve_action("send_rain", NEW_PLACE) as Dictionary
	assert(bool(result["ok"]))
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(str(record["target_id"]) == NEW_PLACE)
	print("  ARBITRARY TARGET: Test Delta can be rained on like anywhere else.")
	completed += 1


func _test_no_rule_names_a_settlement() -> void:
	for path: String in [
		"res://scripts/world_sim.gd", "res://scripts/feedback_rules.gd",
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd",
		"res://scripts/consequence_rules.gd"
	]:
		var code := _code_of(path)
		for location_id: String in FIXTURE_LOCATIONS:
			assert(not code.contains('"%s"' % location_id),
				"%s names the settlement '%s'" % [path, location_id])
	print("  GENERIC: no rule names a settlement.")
	completed += 1


# --- cumulative pressure ---------------------------------------------------

func _test_one_rain_raises_the_water() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var before: int = state.get_water("westfield")
	simulation.resolve_action("send_rain", "westfield")
	assert(state.get_water("westfield") == before + WorldSimulation.RAIN_WATER_GAIN,
		"rain did not add the stated amount of water")
	print("  FORCE: one rain adds %d water." % WorldSimulation.RAIN_WATER_GAIN)
	completed += 1


func _test_rain_on_dry_ground_helps() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	state.set_settlement_band("westfield", "food", 0)
	assert(state.water_state("westfield") == WorldState.WATER_DRY)
	simulation.resolve_action("send_rain", "westfield")
	assert(state.get_settlement_band("westfield", "food") > 0,
		"rain on parched ground did not help the harvest")
	print("  HELPS: dry ground, food improves.")
	completed += 1


func _test_rain_on_healthy_ground_does_little() -> void:
	# The middle of the range: the same act, and almost nothing to show for it.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_BASELINE)
	state.set_settlement_band("westfield", "food", 2)
	assert(state.water_state("westfield") == WorldState.WATER_NORMAL)
	simulation.resolve_action("send_rain", "westfield")
	assert(state.get_settlement_band("westfield", "food") == 2,
		"rain on healthy ground changed the harvest")
	assert(state.get_water("westfield") > WorldState.WATER_BASELINE,
		"the water did not rise even though nothing else changed")
	print("  UNNECESSARY: healthy ground, no harvest change, water still rises.")
	completed += 1


func _test_rain_accumulates() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	var readings: Array[int] = []
	for repeat in range(3):
		simulation.resolve_action("send_rain", "westfield")
		readings.append(state.get_water("westfield"))
		simulation.advance_year()
	assert(readings[1] > readings[0] and readings[2] > readings[1],
		"repeated rain did not accumulate: %s" % str(readings))
	print("  ACCUMULATES: %s." % str(readings))
	completed += 1


func _test_water_drifts_back_on_its_own() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 2)
	state.set_water("westfield", WorldState.WATER_MAX)
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	assert(state.get_water("westfield") < WorldState.WATER_MAX,
		"the ground never drains")
	assert(state.get_water("westfield")
		== WorldState.WATER_MAX - WorldSimulation.WATER_DRIFT_PER_YEAR,
		"the drift is not the stated rate")
	print("  DRIFT: %d per year toward %d." % [
		WorldSimulation.WATER_DRIFT_PER_YEAR, WorldState.WATER_BASELINE
	])
	completed += 1


func _test_repeated_rain_outpaces_the_drift() -> void:
	# Without this the sandbox cannot escalate: a god who keeps intervening has
	# to be able to overpower what the world does on its own.
	assert(WorldSimulation.RAIN_WATER_GAIN > WorldSimulation.WATER_DRIFT_PER_YEAR,
		"one year of drift undoes one rain; nothing could ever accumulate")
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_BASELINE)
	var start: int = state.get_water("westfield")
	_rain_on(simulation, "westfield", 4)
	assert(state.get_water("westfield") > start,
		"four years of rain left the ground no wetter")
	print("  OUTPACES: rain %d vs drift %d." % [
		WorldSimulation.RAIN_WATER_GAIN, WorldSimulation.WATER_DRIFT_PER_YEAR
	])
	completed += 1


func _test_enough_rain_saturates_then_floods() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	var seen: Array[String] = []
	for repeat in range(8):
		simulation.resolve_action("send_rain", "westfield")
		var water_state: String = state.water_state("westfield")
		if water_state not in seen:
			seen.append(water_state)
		simulation.advance_year()
	for expected: String in [
		WorldState.WATER_NORMAL, WorldState.WATER_WET,
		WorldState.WATER_SATURATED, WorldState.WATER_FLOODED
	]:
		assert(expected in seen, "the ground never reached '%s': %s" % [expected, str(seen)])
	print("  ESCALATION: %s." % " -> ".join(seen))
	completed += 1


func _test_flooding_harms_the_settlement() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_MAX)
	state.set_settlement_band("westfield", "food", 3)
	state.set_settlement_band("westfield", "stability", 3)
	assert(state.water_state("westfield") == WorldState.WATER_FLOODED)
	simulation.resolve_action("send_rain", "westfield")
	assert(state.get_settlement_band("westfield", "food") < 3,
		"raining on a flood did not hurt the harvest")
	assert(state.get_settlement_band("westfield", "stability") < 3,
		"raining on a flood did not shake the settlement")
	print("  HARMS: rain on standing water ruins food and stability.")
	completed += 1


func _test_stopping_lets_the_ground_recover() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_MAX)
	for year in range(14):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	assert(state.water_state("westfield") == WorldState.WATER_NORMAL,
		"the ground did not recover in fourteen quiet years: %s"
			% state.water_state("westfield"))
	print("  RECOVERS: flooded ground returns to normal once the god stops.")
	completed += 1


# --- sandbox freedom -------------------------------------------------------

func _test_rain_is_never_disabled() -> void:
	# The power is a tool, not a response. Only the power cost may refuse it.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	for water in [0, 35, 70, 100]:
		state.set_water("westfield", water)
		state.action_taken = false
		state.divine_power = state.max_divine_power
		var result := simulation.resolve_action("send_rain", "westfield") as Dictionary
		assert(bool(result["ok"]),
			"Send Rain was refused at water %d: %s" % [water, str(result["message"])])
	# And nothing in the simulation reasons about whether rain is wanted.
	var code := _code_of("res://scripts/world_sim.gd")
	for forbidden: String in [
		"rain_not_needed", "already_used_here", "target_is_satisfied",
		"recommended_target", "best_target"
	]:
		assert(not code.contains(forbidden), "a gating rule exists: %s" % forbidden)
	print("  NEVER DISABLED: usable at every level of the ground.")
	completed += 1


func _test_a_flooded_settlement_stays_targetable() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_MAX)
	var applied := _rain_on(simulation, "westfield", 3)
	assert(applied == 3, "only %d of 3 rains on a flooded settlement were allowed" % applied)
	assert(state.water_state("westfield") == WorldState.WATER_FLOODED)
	print("  STILL TARGETABLE: three more rains onto standing water.")
	completed += 1


func _test_nothing_recommends_a_target() -> void:
	var code := _code_of("res://Main.gd")
	for forbidden: String in ["RECOMMENDED", "BEST TARGET", "NEEDS RAIN", "SUGGESTED"]:
		assert(not code.contains(forbidden), "the interface recommends a target: %s" % forbidden)
	# Every settlement is offered, whatever state it is in.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", WorldState.WATER_MAX)
	state.set_water("aster", WorldState.WATER_MIN)
	for location_id: String in state.get_location_ids():
		state.action_taken = false
		state.divine_power = state.max_divine_power
		assert(bool(simulation.resolve_action("send_rain", location_id)["ok"]),
			"%s could not be chosen" % location_id)
	print("  NO RECOMMENDATION: every target remains selectable.")
	completed += 1


# --- the causal road -------------------------------------------------------

func _test_the_flood_reaches_mortal_reasoning() -> void:
	# End to end, through the ordinary pipeline and no shortcut: repeated rain
	# floods a settlement, somebody who lives there notices, holds the fact, and
	# reaches a conclusion about it.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	state.set_water("westfield", 10)
	_rain_on(simulation, "westfield", 7)

	var fact := _knowledge_on(state, "mara", "flooding")
	assert(not fact.is_empty(), "the flood reached nobody who lived in it")
	assert(str(fact["claim"]).contains("Westfield"))
	# Objective: the claim says water is standing, never who sent it.
	assert(not str(fact["claim"]).to_lower().contains("god"),
		"the flood claim named a cause: %s" % str(fact["claim"]))
	var reading := {}
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == "mara" and str(record["topic"]) == "flooding":
			reading = record
	assert(not reading.is_empty(), "nobody made anything of the flood")
	print("  CHAIN: rain -> water -> flood -> \"%s\" -> %s." % [
		str(fact["claim"]), str(reading["interpretation_type"])
	])
	completed += 1


func _test_a_flood_can_contradict_a_divine_belief() -> void:
	# The revision this milestone exists to make possible. Somebody who came to
	# believe help arrives when the need is greatest, and then watched far more
	# arrive than anyone needed, is given a reason to doubt it — but only
	# through perceiving, knowing and INTERPRETING the flood.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	state.record_belief({
		"holder_id": "mara", "proposition": BeliefRules.DIVINE_INTERVENTION_EXISTS,
		"subject_id": "", "confidence": 80, "support": 5, "contradiction": 0,
		"first_year": state.year - 3, "last_updated_year": state.year,
		"source_interpretation_ids": ["seed"], "status": BeliefRules.STATUS_HELD
	})
	state.record_belief({
		"holder_id": "mara", "proposition": BeliefRules.DIVINE_HELP_FOLLOWS_NEED,
		"subject_id": "", "confidence": 70, "support": 5, "contradiction": 0,
		"first_year": state.year - 3, "last_updated_year": state.year,
		"source_interpretation_ids": ["seed"], "status": BeliefRules.STATUS_HELD
	})
	var before: int = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")["confidence"]

	state.set_water("westfield", 10)
	_rain_on(simulation, "westfield", 8)

	var excess := false
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == "mara" \
			and str(record["interpretation_type"]) == "flood_divine_excess":
			excess = true
	assert(excess, "a believer watching her home flood never read it as excess")
	var after: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(int(after["confidence"]) < before,
		"the flood did not weaken the belief (%d -> %d)" % [before, int(after["confidence"])])
	assert(int(after["contradiction"]) > 0, "no contradiction was recorded")
	print("  REVISION: divine_help_follows_need %d -> %d after the flood." % [
		before, int(after["confidence"])
	])
	completed += 1


func _test_feedback_escalates_with_the_ground() -> void:
	# The same power, three different scenes, decided by the ground.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	var headlines: Array[String] = []
	# Chosen so the rain LANDS in three different states: dry ground becomes
	# normal, wet becomes saturated, flooded stays flooded.
	for water in [10, 60, 100]:
		state.set_water("westfield", water)
		state.action_taken = false
		state.divine_power = state.max_divine_power
		var result := simulation.resolve_action("send_rain", "westfield") as Dictionary
		var feedback: Dictionary = simulation.feedback_rules.divine_feedback(state, result)
		headlines.append(str(feedback["headline"]))
	assert(headlines[0] != headlines[1] and headlines[1] != headlines[2],
		"the same power read identically on dry, soaked and flooded ground: %s"
			% str(headlines))
	assert(headlines[0] == "YOU SEND RAIN", "the plain case is not plain: %s" % headlines[0])
	print("  ESCALATING FEEDBACK: \"%s\" / \"%s\" / \"%s\"" % [
		headlines[0], headlines[1], headlines[2]
	])
	completed += 1


# --- boundaries ------------------------------------------------------------

func _test_no_faith_or_legacy_path() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	state.set_water("westfield", 10)
	# Measured across the ACT itself. Faith and followers drift for reasons of
	# their own across a year — population, the legacy powers — so comparing
	# over whole ticks would prove nothing about Send Rain.
	for repeat in range(6):
		var faith: int = state.faith
		var followers: int = state.followers
		var reputation: String = state.reputation
		var collective: int = state.interpretation_history.size()
		var result := simulation.resolve_action("send_rain", "westfield") as Dictionary
		assert(str(result["pipeline"]) == DivineActionRules.PIPELINE_SHARED,
			"a flood was routed through the legacy divine path")
		assert(str(result["interpretation"]).is_empty())
		assert(state.faith == faith, "the act moved realm faith")
		assert(state.followers == followers, "the act moved followers")
		assert(state.reputation == reputation, "the act renamed the god")
		assert(state.interpretation_history.size() == collective,
			"the legacy collective reader ran for a flood")
		simulation.advance_year()
	var faith_now: int = state.faith
	var followers_now: int = state.followers
	print("  BOUNDARY: six rains moved neither faith (%d) nor followers (%d)."
		% [faith_now, followers_now])
	completed += 1


func _test_no_belief_or_relationship_is_written_directly() -> void:
	# Send Rain's own effect may touch the WORLD. It may not touch a mind.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	var relationships := str(state.relationships)
	var beliefs := str(state.mortal_beliefs)
	state.set_water("westfield", WorldState.WATER_MAX)
	simulation.resolve_action("send_rain", "westfield")
	assert(str(state.relationships) == relationships,
		"a divine act moved a relationship directly")
	assert(str(state.mortal_beliefs) == beliefs, "a divine act wrote a belief directly")
	print("  NO SHORTCUT: the act changed the ground and nobody's mind.")
	completed += 1


func _test_flood_meaning_never_becomes_fact() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	state.set_water("westfield", 10)
	_rain_on(simulation, "westfield", 7)
	for entity: Dictionary in state.notable_entities.values():
		for record: Dictionary in state.get_all_knowledge(str(entity["id"])).values():
			var claim := str(record["claim"]).to_lower()
			for word: String in ["god", "punish", "anger", "blessed", "wrath", "deserved"]:
				assert(not claim.contains(word),
					"a meaning was written into a fact: %s" % str(record["claim"]))
	print("  OBJECTIVE: every flood fact states water, never a cause.")
	completed += 1


func _test_ordinary_rain_is_not_historic() -> void:
	# Chronicle keeps its own threshold. Routine rain on healthy ground must not
	# fill history, and nothing here lowered the bar.
	assert(ChronicleRules.IMPORTANCE_THRESHOLD == 50, "the Chronicle threshold moved")
	# Asserted about the ACTS themselves rather than about the size of history.
	# The world writes its own entries — crises elsewhere, conclusions reached —
	# so a raw count would mostly measure the world, not the rain. The claim
	# that matters is that a rain which changed nothing is not remembered.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	var harmless: Array[String] = []
	for repeat in range(6):
		state.set_water("westfield", WorldState.WATER_BASELINE)
		var food_before: int = state.get_settlement_band("westfield", "food")
		var result := simulation.resolve_action("send_rain", "westfield") as Dictionary
		# Harmless by construction: the ground was healthy, so nothing moved.
		if state.get_settlement_band("westfield", "food") == food_before:
			harmless.append(str(result["divine_action_id"]))
		simulation.advance_year()
	assert(harmless.size() >= 4, "the fixture produced only %d harmless rains" % harmless.size())
	for record: Dictionary in state.chronicle:
		assert(str(record["source_record_id"]) not in harmless,
			"a rain that changed nothing became history: %s" % str(record["summary"]))
	print("  NOT HISTORIC: %d rains that changed nothing, none remembered." % harmless.size())
	completed += 1
