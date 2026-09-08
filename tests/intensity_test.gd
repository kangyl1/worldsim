extends SceneTree

# Divine Intensity & Duration Foundation v1.
#
# The sandbox gains two more dials. WHAT and WHERE already existed; this adds
# HOW STRONGLY and HOW LONG, and the whole point is that they are INDEPENDENT.
# Gentle rain forever and overwhelming rain once are different orders with
# different histories, and neither is a way of expressing the other.
#
# The player still chooses only the input force. A standing order to rain
# overwhelmingly until revoked does not mean "cause a flood" — it means apply
# that force every year and let the world do what it does. The most important
# test here is that the gentlest possible order, left alone long enough, floods
# a settlement anyway: nothing decided that in advance.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 26

var completed := 0


func _init() -> void:
	_test_the_default_preserves_existing_behaviour()
	_test_rain_intensity_orders_correctly()
	_test_blessing_intensity_orders_correctly()
	_test_powers_convert_intensity_differently()
	_test_intensity_reaches_the_record_not_the_meaning()
	_test_an_unknown_intensity_falls_back()

	_test_once_applies_once()
	_test_a_standing_order_applies_once_in_its_first_year()
	_test_sustained_runs_for_exactly_its_duration()
	_test_until_stopped_outlives_any_finite_span()
	_test_each_application_reads_the_world_as_it_is()
	_test_duration_is_independent_of_intensity()
	_test_a_malformed_duration_cannot_be_created()

	_test_the_gentlest_order_can_still_flood()
	_test_overwhelming_once_does_not_persist()
	_test_overwhelming_blessing_forever_never_punishes()

	_test_stopping_prevents_future_applications()
	_test_stopping_does_not_undo_the_past()
	_test_stopping_one_order_leaves_the_others()
	_test_orders_coexist_across_powers_and_places()
	_test_reordering_the_same_power_replaces_rather_than_stacks()
	_test_one_shot_acts_still_stack()

	_test_standing_orders_cost_power_only_when_given()
	_test_a_standing_order_still_needs_the_player_to_advance()
	_test_applications_travel_the_shared_pipeline()
	_test_nothing_reads_the_control_panel()

	if completed != EXPECTED_TESTS:
		push_error("Intensity suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("INTENSITY TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("INTENSITY TEST PASSED: how hard and how long are two different questions.")
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


# Advance a year with the player doing nothing, which is what standing orders
# run underneath.
func _quiet_year(simulation: Object) -> int:
	simulation.advance_year()
	var applied: int = simulation.state.last_intervention_events.size()
	simulation.resolve_action("do_nothing")
	return applied


func _water_after_one_rain(intensity: String) -> int:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	simulation.resolve_action("send_rain", "westfield", intensity)
	return state.get_water("westfield")


func _abundance_after_one_blessing(intensity: String) -> int:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_abundance("westfield", 0)
	simulation.resolve_action("bless_harvest", "westfield", intensity)
	return state.get_abundance("westfield")


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- intensity -------------------------------------------------------------

func _test_the_default_preserves_existing_behaviour() -> void:
	# Every caller written before this milestone keeps its behaviour.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	simulation.resolve_action("send_rain", "westfield")
	assert(state.get_water("westfield") == WorldSimulation.RAIN_WATER_GAIN,
		"a bare call no longer applies the original rain force")
	assert(DivineActionRules.DEFAULT_INTENSITY == DivineActionRules.INTENSITY_NORMAL)
	assert(DivineActionRules.DEFAULT_MODE == DivineActionRules.MODE_ONCE)
	print("  DEFAULT: a bare call is still one normal rain.")
	completed += 1


func _test_rain_intensity_orders_correctly() -> void:
	var gentle := _water_after_one_rain(DivineActionRules.INTENSITY_GENTLE)
	var normal := _water_after_one_rain(DivineActionRules.INTENSITY_NORMAL)
	var strong := _water_after_one_rain(DivineActionRules.INTENSITY_STRONG)
	var overwhelming := _water_after_one_rain(DivineActionRules.INTENSITY_OVERWHELMING)
	assert(gentle < normal, "gentle rain is not gentler than normal")
	assert(normal < strong, "strong rain is not stronger than normal")
	assert(strong < overwhelming, "overwhelming rain is not the strongest")
	print("  RAIN FORCE: %d < %d < %d < %d." % [gentle, normal, strong, overwhelming])
	completed += 1


func _test_blessing_intensity_orders_correctly() -> void:
	var gentle := _abundance_after_one_blessing(DivineActionRules.INTENSITY_GENTLE)
	var normal := _abundance_after_one_blessing(DivineActionRules.INTENSITY_NORMAL)
	var overwhelming := _abundance_after_one_blessing(DivineActionRules.INTENSITY_OVERWHELMING)
	assert(gentle < normal and normal < overwhelming,
		"blessing intensity does not order: %d %d %d" % [gentle, normal, overwhelming])
	assert(normal == WorldSimulation.BLESSING_ABUNDANCE_GAIN,
		"normal is no longer the original blessing force")
	print("  BLESSING FORCE: %d < %d < %d." % [gentle, normal, overwhelming])
	completed += 1


func _test_powers_convert_intensity_differently() -> void:
	# A shared vocabulary, not a shared multiplier. Two powers reading the same
	# word the same way would make them the same force with two names.
	var rain := WorldSimulation.RAIN_WATER_BY_INTENSITY
	var blessing := WorldSimulation.BLESSING_ABUNDANCE_BY_INTENSITY
	var identical := true
	for level: String in DivineActionRules.INTENSITIES:
		assert(rain.has(level) and blessing.has(level),
			"a power does not answer for '%s'" % level)
		if int(rain[level]) != int(blessing[level]):
			identical = false
	assert(not identical, "both powers convert intensity identically")
	# And no shared multiplier exists to make them alike.
	var code := _code_of("res://scripts/world_sim.gd")
	assert(not code.contains("intensity_multiplier") and not code.contains("INTENSITY_SCALE"),
		"a universal intensity multiplier exists")
	print("  POWER-SPECIFIC: rain %s vs blessing %s." % [
		str(rain[DivineActionRules.INTENSITY_OVERWHELMING]),
		str(blessing[DivineActionRules.INTENSITY_OVERWHELMING])
	])
	completed += 1


func _test_intensity_reaches_the_record_not_the_meaning() -> void:
	# Recorded on the act, and unreadable by anything downstream — the same rule
	# the whole divine record already follows.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var result := simulation.resolve_action(
		"send_rain", "westfield", DivineActionRules.INTENSITY_OVERWHELMING
	) as Dictionary
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(str(record["parameters"]["intensity"]) == DivineActionRules.INTENSITY_OVERWHELMING)
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd"
	]:
		var code := _code_of(path)
		for forbidden: String in ["intensity", "overwhelming", "until_stopped"]:
			assert(not code.contains(forbidden),
				"%s can see how hard the god pushed" % path)
	print("  RECORDED, NOT READ: intensity is on the act and invisible downstream.")
	completed += 1


func _test_an_unknown_intensity_falls_back() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	simulation.resolve_action("send_rain", "westfield", "cataclysmic")
	assert(state.get_water("westfield") == WorldSimulation.RAIN_WATER_GAIN,
		"an unknown intensity did not fall back to normal")
	print("  FALLBACK: an unrecognised level is treated as normal.")
	completed += 1


# --- duration --------------------------------------------------------------

func _test_once_applies_once() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_ONCE)
	assert(state.active_intervention_list().is_empty(),
		"a one-shot act created a standing order")
	for year in range(4):
		assert(_quiet_year(simulation) == 0, "a one-shot act applied again later")
	print("  ONCE: no standing order, no later applications.")
	completed += 1


func _test_a_standing_order_applies_once_in_its_first_year() -> void:
	# The timing rule: giving the order applies it immediately, and the yearly
	# tick must not apply it a second time in that same year.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(state.get_water("westfield") == WorldSimulation.RAIN_WATER_GAIN,
		"the opening year applied the order %d times"
			% (state.get_water("westfield") / maxi(WorldSimulation.RAIN_WATER_GAIN, 1)))
	var applied := _quiet_year(simulation)
	assert(applied == 1, "the second year applied it %d times" % applied)
	print("  TIMING: applied once when given, once a year after.")
	completed += 1


func _test_sustained_runs_for_exactly_its_duration() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("bless_harvest", "westfield",
		DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_SUSTAINED, 3)
	# One application on the year it was given, then two more.
	var applications := 1
	for year in range(6):
		applications += _quiet_year(simulation)
	assert(applications == 3, "a three-year order applied %d times" % applications)
	assert(state.active_intervention_list().is_empty(),
		"the order stayed active past its duration")
	print("  SUSTAINED: three years ordered, three applications, then done.")
	completed += 1


func _test_until_stopped_outlives_any_finite_span() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_UNTIL_STOPPED)
	var applications := 1
	for year in range(15):
		applications += _quiet_year(simulation)
	assert(applications == 16, "an indefinite order applied only %d times" % applications)
	assert(not state.active_intervention_list().is_empty(), "it stopped on its own")
	print("  UNTIL STOPPED: %d applications and still running." % applications)
	completed += 1


func _test_each_application_reads_the_world_as_it_is() -> void:
	# Nothing is precomputed when the order is given. A settlement that changed
	# in between takes the same force differently.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	state.set_settlement_band("westfield", "food", 0)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	# Dry ground: the harvest recovers.
	assert(state.get_settlement_band("westfield", "food") > 0,
		"the first application ignored the dry ground")
	# Now drown it and let the order keep running into standing water.
	state.set_water("westfield", WorldState.WATER_MAX)
	state.set_settlement_band("westfield", "food", 3)
	_quiet_year(simulation)
	assert(state.get_settlement_band("westfield", "food") < 3,
		"a later application ignored the flooded ground it fell on")
	print("  LIVE STATE: the same order helped, then harmed, as the world changed.")
	completed += 1


func _test_duration_is_independent_of_intensity() -> void:
	# The dials must not secretly encode each other.
	var gentle_once := _sim()
	var gentle_forever := _sim()
	for simulation: Object in [gentle_once, gentle_forever]:
		_settle(simulation, 4)
		simulation.state.set_water("westfield", 0)
	gentle_once.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_ONCE)
	gentle_forever.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(gentle_once.state.get_water("westfield")
		== gentle_forever.state.get_water("westfield"),
		"duration changed the force of a single application")
	for year in range(8):
		_quiet_year(gentle_once)
		_quiet_year(gentle_forever)
	assert(gentle_forever.state.get_water("westfield")
		> gentle_once.state.get_water("westfield"),
		"the standing order did not outgrow the one-shot")
	print("  INDEPENDENT: same force, different histories (%d vs %d)." % [
		gentle_once.state.get_water("westfield"),
		gentle_forever.state.get_water("westfield")
	])
	completed += 1


func _test_a_malformed_duration_cannot_be_created() -> void:
	# REFUSED, not reshaped. Silently turning a 9999-year order into a ten-year
	# one would mean the player asked for one thing and the world did another.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var power_before: int = state.divine_power
	var water_before: int = state.get_water("westfield")
	for bad_duration: int in [0, -3, DivineActionRules.MAX_SUSTAINED_YEARS + 1, 9999]:
		var result := simulation.resolve_action(
			"send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
			DivineActionRules.MODE_SUSTAINED, bad_duration
		) as Dictionary
		assert(not bool(result["ok"]),
			"a %d-year order was accepted" % bad_duration)
		assert(str(result["message"]).contains("sustained"),
			"the refusal does not say what was wrong: %s" % str(result["message"]))
	# A refused order costs nothing and changes nothing.
	assert(state.divine_power == power_before, "a refused order spent divine power")
	assert(state.get_water("westfield") == water_before, "a refused order still rained")
	assert(state.active_intervention_list().is_empty(), "a refused order was recorded")
	assert(not state.action_taken, "a refused order consumed the year")
	# Every value in range is accepted and kept exactly as asked for.
	for good_duration: int in [
		DivineActionRules.MIN_SUSTAINED_YEARS, 5, DivineActionRules.MAX_SUSTAINED_YEARS
	]:
		var fresh := _sim()
		_settle(fresh, 4)
		assert(bool(fresh.resolve_action("bless_harvest", "westfield",
			DivineActionRules.INTENSITY_NORMAL,
			DivineActionRules.MODE_SUSTAINED, good_duration)["ok"]),
			"a valid %d-year order was refused" % good_duration)
		var record: Dictionary = fresh.state.active_intervention_list()[0]
		assert(int(record["remaining_years"]) == good_duration - 1,
			"a %d-year order was reshaped to %d" % [
				good_duration, int(record["remaining_years"]) + 1
			])
	print("  REFUSED: 0, -3, %d and 9999 rejected; 1..%d kept exactly." % [
		DivineActionRules.MAX_SUSTAINED_YEARS + 1, DivineActionRules.MAX_SUSTAINED_YEARS
	])
	completed += 1


# --- sandbox freedom -------------------------------------------------------

func _test_the_gentlest_order_can_still_flood() -> void:
	# The heart of it. Nothing decided this in advance: the mildest force the
	# player can choose, left running, outpaces the ground's recovery and drowns
	# the settlement anyway.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_UNTIL_STOPPED)
	for year in range(20):
		_quiet_year(simulation)
	assert(state.water_state("westfield") == WorldState.WATER_FLOODED,
		"twenty years of gentle rain left the ground at '%s'"
			% state.water_state("westfield"))
	print("  GENTLE FOREVER: twenty years of the mildest rain floods Westfield.")
	completed += 1


func _test_overwhelming_once_does_not_persist() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_ONCE)
	assert(state.active_intervention_list().is_empty(),
		"the strongest one-shot became a standing order")
	var water_after: int = state.get_water("westfield")
	for year in range(4):
		_quiet_year(simulation)
	assert(state.get_water("westfield") < water_after,
		"a one-shot kept adding water")
	print("  ONE-SHOT: overwhelming, once, and then only drift.")
	completed += 1


func _test_overwhelming_blessing_forever_never_punishes() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_settlement_band("westfield", "food", 2)
	state.set_settlement_band("westfield", "stability", 2)
	simulation.resolve_action("bless_harvest", "westfield",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED)
	for year in range(15):
		_quiet_year(simulation)
	assert(state.abundance_state("westfield") == WorldState.ABUNDANCE_SUSTAINED,
		"fifteen years of overwhelming blessing did not sustain abundance")
	assert(state.get_settlement_band("westfield", "food") >= 2,
		"sustained blessing starved the settlement")
	assert(state.get_settlement_band("westfield", "stability") >= 2,
		"sustained blessing destabilised the settlement")
	print("  NO PUNISHMENT: fifteen years of the strongest blessing, still fine.")
	completed += 1


# --- stopping and coexistence ----------------------------------------------

func _test_stopping_prevents_future_applications() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_STRONG,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(_quiet_year(simulation) == 1)
	assert(simulation.stop_intervention_for("send_rain", "westfield"))
	for year in range(4):
		assert(_quiet_year(simulation) == 0, "a revoked order applied again")
	assert(state.active_intervention_list().is_empty())
	print("  STOP: no application after revocation.")
	completed += 1


func _test_stopping_does_not_undo_the_past() -> void:
	# Stopping the rain does not drain a flood. The world recovers by its own
	# rules or not at all.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED)
	for year in range(4):
		_quiet_year(simulation)
	assert(state.water_state("westfield") == WorldState.WATER_FLOODED)
	var flooded_at: int = state.get_water("westfield")
	simulation.stop_intervention_for("send_rain", "westfield")
	assert(state.water_state("westfield") == WorldState.WATER_FLOODED,
		"revoking the order drained the flood instantly")
	_quiet_year(simulation)
	assert(state.get_water("westfield") < flooded_at,
		"the ground did not begin to recover on its own")
	assert(state.get_water("westfield")
		>= flooded_at - WorldSimulation.WATER_DRIFT_PER_YEAR,
		"the world lost more than its own drift")
	print("  HISTORY KEPT: the flood remains and drains at the world's pace.")
	completed += 1


func _test_stopping_one_order_leaves_the_others() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	simulation.advance_year()
	simulation.resolve_action("bless_harvest", "aster", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(state.active_intervention_list().size() == 2)
	simulation.stop_intervention_for("send_rain", "westfield")
	var remaining: Array[Dictionary] = state.active_intervention_list()
	assert(remaining.size() == 1, "revoking one order stopped %d" % (2 - remaining.size()))
	assert(str(remaining[0]["action_id"]) == "bless_harvest")
	var abundance_before: int = state.get_abundance("aster")
	_quiet_year(simulation)
	assert(state.get_abundance("aster") > abundance_before - 1,
		"the surviving order stopped applying")
	print("  ISOLATED: revoking the rain left the blessing running.")
	completed += 1


func _test_orders_coexist_across_powers_and_places() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_UNTIL_STOPPED)
	simulation.advance_year()
	simulation.resolve_action("send_rain", "aster", DivineActionRules.INTENSITY_STRONG,
		DivineActionRules.MODE_UNTIL_STOPPED)
	simulation.advance_year()
	simulation.resolve_action("bless_harvest", "frontier", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(state.active_intervention_list().size() == 3,
		"three orders did not coexist: %d" % state.active_intervention_list().size())
	var applied := _quiet_year(simulation)
	assert(applied == 3, "only %d of three orders applied" % applied)
	print("  COEXIST: the same power at two places, plus another power elsewhere.")
	completed += 1


func _test_reordering_the_same_power_replaces_rather_than_stacks() -> void:
	# Telling the rain to fall harder is a change of instruction, not a second
	# rain. Five identical schedules must never accumulate.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_GENTLE,
		DivineActionRules.MODE_UNTIL_STOPPED)
	for repeat in range(3):
		simulation.advance_year()
		simulation.resolve_action("send_rain", "westfield",
			DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED)
	assert(state.active_intervention_list().size() == 1,
		"reordering created %d schedules" % state.active_intervention_list().size())
	var record: Dictionary = state.active_intervention_list()[0]
	assert(str(record["intensity"]) == DivineActionRules.INTENSITY_OVERWHELMING,
		"the order did not take the new intensity")
	var applied := _quiet_year(simulation)
	assert(applied == 1, "%d applications from one standing order" % applied)
	print("  REPLACED: four orders, one schedule, now overwhelming.")
	completed += 1


func _test_one_shot_acts_still_stack() -> void:
	# The replace rule is about SCHEDULES. Repeating a one-shot is ordinary
	# sandbox play and must stay unrestricted.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	var applications := 0
	for repeat in range(4):
		if bool(simulation.resolve_action("send_rain", "westfield")["ok"]):
			applications += 1
		simulation.advance_year()
	assert(applications == 4, "only %d of four one-shot rains were allowed" % applications)
	assert(state.active_intervention_list().is_empty())
	print("  STACKABLE: four separate rains, no schedule.")
	completed += 1


# --- boundaries ------------------------------------------------------------

func _test_standing_orders_cost_power_only_when_given() -> void:
	# Settled with the user: charging per year would spend the whole of divine
	# income on one order and lock the player out of everything else.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.divine_power = state.max_divine_power
	var before: int = state.divine_power
	var cost := int(simulation.get_action("send_rain")["cost"])
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(state.divine_power == before - cost, "the order cost the wrong amount to give")
	for year in range(5):
		var power_before: int = state.divine_power
		simulation.advance_year()
		assert(state.divine_power >= power_before,
			"a standing order charged power for its yearly application")
		simulation.resolve_action("do_nothing")
	print("  UPKEEP: %d to give, nothing thereafter." % cost)
	completed += 1


func _test_a_standing_order_still_needs_the_player_to_advance() -> void:
	# Settled with the user: ongoing divine effects must not become invisible
	# background automation. The god still answers for each year.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_NORMAL,
		DivineActionRules.MODE_UNTIL_STOPPED)
	assert(bool(simulation.advance_year()["ok"]))
	assert(not state.action_taken, "the standing order answered for the player")
	assert(not bool(simulation.advance_year()["ok"]),
		"the year advanced with no choice made")
	print("  STILL ASKED: a standing order does not choose the player's year.")
	completed += 1


func _test_applications_travel_the_shared_pipeline() -> void:
	# A standing order is a reason the god acted, never a way of acting the
	# pipeline does not see.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	simulation.resolve_action("send_rain", "westfield", DivineActionRules.INTENSITY_STRONG,
		DivineActionRules.MODE_UNTIL_STOPPED)
	var records_before: int = state.divine_action_archive.size()
	var consequences_before: int = state.consequence_archive.size()
	simulation.advance_year()
	assert(state.divine_action_archive.size() > records_before,
		"a yearly application produced no divine record")
	assert(state.consequence_archive.size() > consequences_before,
		"a yearly application produced no consequence")
	var record: Dictionary = state.divine_action_archive.back()
	assert(str(record["pipeline"]) == DivineActionRules.PIPELINE_SHARED)
	assert(not str(record["consequence_id"]).is_empty())
	simulation.resolve_action("do_nothing")

	# Measured across the APPLICATION itself. Faith, followers, relationships
	# and beliefs all move for reasons of their own across a whole year —
	# population, the legacy powers, ordinary social life — so comparing over a
	# tick would prove nothing about what a standing order does.
	var faith: int = state.faith
	var followers: int = state.followers
	var reputation: String = state.reputation
	var relationships := str(state.relationships)
	var beliefs := str(state.mortal_beliefs)
	var collective: int = state.interpretation_history.size()
	simulation.apply_divine_effect("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG)
	assert(state.faith == faith, "an application moved faith")
	assert(state.followers == followers, "an application moved followers")
	assert(state.reputation == reputation, "an application renamed the god")
	assert(str(state.relationships) == relationships,
		"an application moved a relationship directly")
	assert(str(state.mortal_beliefs) == beliefs,
		"an application wrote a belief directly")
	assert(state.interpretation_history.size() == collective,
		"an application ran the legacy collective reader")
	# And it reaches mortals the ordinary way.
	for year in range(3):
		_quiet_year(simulation)
	var known := false
	for entity: Dictionary in state.notable_entities.values():
		for held: Dictionary in state.get_all_knowledge(str(entity["id"])).values():
			if str(held.get("topic", "")) == "weather_rain":
				known = true
	assert(known, "years of standing rain reached nobody")
	print("  PIPELINE: every application records, consequences and is perceived.")
	completed += 1


func _test_nothing_reads_the_control_panel() -> void:
	# Actors observe the world, not the player's standing orders.
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd",
		"res://scripts/chronicle_rules.gd", "res://scripts/intent_rules.gd",
		"res://scripts/consequence_rules.gd"
	]:
		var code := _code_of(path)
		for forbidden: String in [
			"active_interventions", "active_intervention_list", "get_intervention"
		]:
			assert(not code.contains(forbidden),
				"%s reads the god's control panel" % path)
	print("  UNSEEN: no rules file can read the standing orders.")
	completed += 1
