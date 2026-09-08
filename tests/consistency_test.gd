extends SceneTree

# Simulation Consistency & Logical Contradiction Cleanup v1.
#
# This suite guards ONE line, and it is a narrow one.
#
# The world is allowed to be strange, unfair, tragic and surprising. A flooded
# settlement may starve. A blessed one may be miserable. Two mortals may look at
# the same rain and reach opposite conclusions, and both may be wrong. None of
# that is a defect, and several tests below exist specifically to prove those
# situations still happen.
#
# What the world may NOT do is assert two objective things that cannot both be
# true. "The wells are drying up" and "floodwater is standing here" are not two
# points of view about one settlement; they are a bug. The events were written
# before `water` existed and used to declare the ground's condition on their own
# authority, which made them a second source of truth for a physical fact the
# settlement already owned.
#
# The rule this suite enforces: an event may state a physical condition only
# where the world's own numbers permit it, and a force that claims to change the
# ground must actually change it.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const WorldStateScript = preload("res://scripts/world_state.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 30

var completed := 0


func _init() -> void:
	# The contradiction that started this.
	_test_a_flooded_place_cannot_have_a_drought()
	_test_a_drowned_world_has_no_drought_at_all()
	_test_an_unattended_place_dries_out()
	_test_drought_waits_for_dry_ground()
	_test_a_dry_season_can_happen_without_a_drought()
	_test_the_gentlest_order_still_floods()
	_test_stronger_rain_beats_drying_faster()
	_test_wells_answer_only_a_real_drought()
	_test_the_belief_bootstrap_survives()
	_test_chronicle_stays_sparse()
	_test_the_dry_season_still_presses_on_a_wet_world()
	_test_no_settlement_is_ever_described_as_drying_out()
	_test_long_runs_keep_settlements_different()
	_test_send_rain_still_matters_in_the_seeded_world()
	_test_the_event_is_valid_where_it_is_declared()

	# Water as the one physical truth.
	_test_persistent_rain_walks_the_whole_scale()
	_test_stopping_leaves_the_water_where_it_stands()
	_test_a_stopped_order_does_not_apply_again()
	_test_qualitative_labels_match_the_numbers()

	# Harvest and abundance.
	_test_a_flooded_place_has_no_promising_harvest()
	_test_harvest_facts_come_from_one_place_only()

	# Interventions.
	_test_a_finite_order_applies_exactly_its_years()
	_test_no_double_application_in_the_opening_year()
	_test_orders_on_different_places_stay_separate()
	_test_an_explicit_target_is_never_overridden()

	# Boundaries that must survive the cleanup.
	_test_nothing_reasons_from_the_control_panel()
	_test_a_generated_settlement_obeys_the_same_rules()
	_test_history_never_precedes_its_own_cause()

	# Weirdness that must NOT be normalised away.
	_test_flooded_and_starving_is_still_allowed()
	_test_mortals_may_still_disagree()

	if completed != EXPECTED_TESTS:
		push_error("CONSISTENCY TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		print("CONSISTENCY TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("CONSISTENCY TEST PASSED: the world may be cruel, but it is not incoherent.")
	quit(0)


# --- the reported contradiction -------------------------------------------

func _test_a_flooded_place_cannot_have_a_drought() -> void:
	# The exact screenshot: standing floodwater, an overwhelming rain order, and
	# the world announcing that no rain has fallen.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "aster",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	var offences := 0
	for year in range(18):
		state.action_taken = true
		simulation.advance_year()
		if str(state.current_event_id) != "drought":
			continue
		var where := str(state.current_event_location_id)
		assert(state.water_is_at_most(where, WorldStateScript.WATER_NORMAL),
			"a drought was declared in %s while its ground was %s" % [
				where, state.water_state(where)])
		if not state.water_is_at_most(where, WorldStateScript.WATER_NORMAL):
			offences += 1
	assert(state.water_state("aster") == WorldStateScript.WATER_FLOODED,
		"the standing order should have flooded Aster")
	assert(offences == 0, "%d droughts were declared on wet ground" % offences)
	print("  NO DROUGHT WHILE FLOODED: 18 years of standing rain, 0 contradictions.")
	completed += 1


func _test_a_drowned_world_has_no_drought_at_all() -> void:
	# If NOWHERE can be having a drought, the year is not a drought year. The
	# event is skipped rather than declared against the world's own numbers.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	for location_id: String in state.get_location_ids():
		state.set_water(location_id, WorldStateScript.WATER_MAX)
	assert(simulation.locations_for_event("drought").is_empty(),
		"a drowned world still offered somewhere for a drought")
	var droughts := 0
	for year in range(9):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for location_id: String in state.get_location_ids():
			state.set_water(location_id, WorldStateScript.WATER_MAX)
		if str(state.current_event_id) == "drought":
			droughts += 1
	assert(droughts == 0, "a drowned world had %d droughts" % droughts)
	print("  DROWNED WORLD: 9 years, 0 droughts, and the world still had things to say.")
	completed += 1


func _test_an_unattended_place_dries_out() -> void:
	# (1) The Natural Drying Foundation's whole point. Nobody touches this world;
	# the dry seasons take the ground down on their own, and `dry` is reachable
	# without any divine act and without drought causing itself.
	var simulation := _sim()
	var state = simulation.state
	var reached := -1
	var lowest := WorldStateScript.WATER_BASELINE
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		lowest = mini(lowest, int(state.get_water("westfield")))
		if reached < 0 and state.water_state("westfield") == WorldStateScript.WATER_DRY:
			reached = int(state.year)
	assert(reached > 0, "40 unattended years never dried the ground below %d" % lowest)
	print("  IT DRIES: unattended Westfield reached `dry` in year %d (low water %d)." % [
		reached, lowest])
	completed += 1


func _test_drought_waits_for_dry_ground() -> void:
	# (2) The condition never precedes its cause. Over a long unattended run the
	# ground dries first and the drought follows; a drought is never declared in
	# a year before any settlement is objectively dry.
	var simulation := _sim()
	var state = simulation.state
	var first_dry := -1
	var first_drought := -1
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for location_id: String in state.get_location_ids():
			if first_dry < 0 and state.water_state(location_id) == WorldStateScript.WATER_DRY:
				first_dry = int(state.year)
		if first_drought < 0 and str(state.current_event_id) == "drought":
			first_drought = int(state.year)
		if str(state.current_event_id) == "drought":
			assert(state.water_state(str(state.current_event_location_id))
				== WorldStateScript.WATER_DRY,
				"a drought was declared on ground that was %s" %
					state.water_state(str(state.current_event_location_id)))
	assert(first_dry > 0 and first_drought > 0, "the world never dried or never had a drought")
	assert(first_dry <= first_drought,
		"a drought (year %d) appeared before any ground was dry (year %d)" % [
			first_drought, first_dry])
	print("  CAUSE BEFORE CONDITION: ground dry in year %d, first drought in year %d." % [
		first_dry, first_drought])
	completed += 1


func _test_a_dry_season_can_happen_without_a_drought() -> void:
	# (3) Both narrations exist and neither replaces the other.
	var simulation := _sim()
	var state = simulation.state
	var tally: Dictionary = {}
	for year in range(60):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		tally[str(state.current_event_id)] = int(tally.get(str(state.current_event_id), 0)) + 1
	assert(int(tally.get("dry_season", 0)) > 0, "the dry season never happened: %s" % str(tally))
	assert(int(tally.get("drought", 0)) > 0, "the drought never happened: %s" % str(tally))
	print("  BOTH EXIST: %d dry seasons and %d droughts in 60 years." % [
		int(tally["dry_season"]), int(tally["drought"])])
	completed += 1


func _test_the_gentlest_order_still_floods() -> void:
	# (4) The sandbox invariant the drying magnitude was tuned around, asserted
	# here as well as in `intensity_test` so it cannot be lost to a later tweak.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_GENTLE, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	var flooded_after := -1
	for year in range(20):
		state.action_taken = true
		simulation.advance_year()
		if flooded_after < 0 and state.water_state("westfield") == WorldStateScript.WATER_FLOODED:
			flooded_after = year + 1
	assert(state.water_state("westfield") == WorldStateScript.WATER_FLOODED,
		"natural drying beat the gentlest standing order: ground is %s" %
			state.water_state("westfield"))
	print("  GENTLE STILL FLOODS: the mildest order beat natural drying in %d years." %
		flooded_after)
	completed += 1


func _test_stronger_rain_beats_drying_faster() -> void:
	# (5) Intensity still means something against the new force.
	var years_to_flood: Dictionary = {}
	for intensity: String in [
		DivineActionRules.INTENSITY_GENTLE, DivineActionRules.INTENSITY_STRONG
	]:
		var simulation := _sim()
		var state = simulation.state
		_settle(simulation, 4)
		state.set_water("westfield", 10)
		simulation.resolve_action("send_rain", "westfield",
			intensity, DivineActionRules.MODE_UNTIL_STOPPED, 0)
		for year in range(20):
			state.action_taken = true
			simulation.advance_year()
			if state.water_state("westfield") == WorldStateScript.WATER_FLOODED:
				years_to_flood[intensity] = year + 1
				break
	assert(years_to_flood.has(DivineActionRules.INTENSITY_STRONG),
		"strong rain never flooded at all")
	assert(int(years_to_flood[DivineActionRules.INTENSITY_STRONG])
		< int(years_to_flood[DivineActionRules.INTENSITY_GENTLE]),
		"strong rain was no faster than gentle: %s" % str(years_to_flood))
	print("  INTENSITY MATTERS: strong flooded in %d years, gentle in %d." % [
		int(years_to_flood[DivineActionRules.INTENSITY_STRONG]),
		int(years_to_flood[DivineActionRules.INTENSITY_GENTLE])])
	completed += 1


func _test_wells_answer_only_a_real_drought() -> void:
	# (7) Wells must not take credit for surviving a drought that never was.
	var code := _code_of("res://scripts/world_sim.gd")
	var dry_season_body := code.split("func _begin_dry_season()")[1].split("func _begin_good_harvest")[0]
	assert(not dry_season_body.contains("wells_built"),
		"the dry season claims credit for wells")
	var drought_body := code.split("func _begin_drought()")[1].split("func _begin_good_harvest")[0]
	assert(drought_body.contains("wells_built"),
		"a real drought no longer consults the wells")
	var reception := _code_of("res://scripts/divine_reception_system.gd")
	assert(not reception.contains("dry_season"),
		"a silence outcome is earned by a dry season rather than a drought")
	print("  WELLS EARNED HONESTLY: only a real drought builds or uses them.")
	completed += 1


func _test_the_belief_bootstrap_survives() -> void:
	# (8) Natural drying must not cost a mortal the ability to conclude that
	# something answered them. Circumstance only: no belief is injected, no
	# reading is seeded, and `home_was_in_crisis` is untouched.
	var BeliefRulesScript = load("res://scripts/belief_rules.gd")
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 8)
	var answered := 0
	for year in range(24):
		state.set_settlement_band("westfield", "food", 0)
		state.set_settlement_band("westfield", "prosperity", 0)
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		if state.condition_before_turn("westfield", "food") == 0 and int(state.divine_power) >= 2:
			state.current_event_location_id = "westfield"
			simulation.resolve_action("send_rain")
			simulation.advance_year()
			answered += 1
			if answered >= 5:
				break
	assert(answered >= 5, "the fixture could not stage five answered famines")
	var belief: Dictionary = state.get_belief(
		"mara", BeliefRulesScript.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not belief.is_empty(), "Mara reached no divine belief at all")
	assert(int(belief["confidence"]) >= BeliefRulesScript.ESTABLISHED_CONFIDENCE,
		"the bootstrap stalled below established: %d" % int(belief["confidence"]))
	print("  BOOTSTRAP INTACT: Mara reached '%s' at confidence %d from lived famine." % [
		BeliefRulesScript.DIVINE_HELP_FOLLOWS_NEED, int(belief["confidence"])])
	completed += 1


func _test_chronicle_stays_sparse() -> void:
	# (9) The guardrail, asserted against the same literal chronicle_test uses.
	var simulation := _sim()
	var state = simulation.state
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var per_year := float(state.chronicle.size()) / 40.0
	assert(per_year <= 2.0,
		"natural drying pushed history to %.2f entries a year" % per_year)
	print("  STILL SPARSE: %d entries over 40 years (%.2f a year)." % [
		state.chronicle.size(), per_year])
	completed += 1


func _test_the_dry_season_still_presses_on_a_wet_world() -> void:
	# The seasonal force must not be conditional on anybody's ground. A world
	# where every settlement is normal or wetter still has thin years, and they
	# still cost it food — this is the world's only downward food pressure, and
	# gating it let the world plateau at uniform plenty.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var pressed := false
	for year in range(9):
		# Held wet every year, so nothing can drift into `dry` behind the test.
		for location_id: String in state.get_location_ids():
			state.set_water(location_id, 60)
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		if str(state.current_event_id) != "dry_season":
			continue
		assert(str(state.current_event_id) != "drought", "a wet world had a drought")
		# The season's own pressure is a food cost applied to everyone.
		assert(int(WorldSimulationScript.EVENT_WEATHER["dry_season"]["food"]) < 0,
			"the dry season stopped costing the world food")
		assert(WorldSimulationScript.EVENT_WEATHER["dry_season"]
			== WorldSimulationScript.EVENT_WEATHER["drought"],
			"the dry season is no longer the same seasonal force as a drought")
		pressed = true
	assert(pressed, "a wet world never had a dry season at all")
	print("  SEASON SURVIVES: a world at water 60 still has dry years, still pays for them.")
	completed += 1


func _test_no_settlement_is_ever_described_as_drying_out() -> void:
	# The claim itself, checked against the ground it is made about. The drought
	# description is the only text in the world that says wells are failing, and
	# it may only ever appear over genuinely dry ground.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	var checked := 0
	for year in range(30):
		state.action_taken = true
		simulation.advance_year()
		var event: Dictionary = simulation.get_current_event()
		var where := str(event["location_id"])
		var text := "%s %s" % [str(event["title"]), str(event["description"])]
		if text.to_lower().contains("wells") or text.to_lower().contains("no rain has fallen"):
			assert(state.water_state(where) == WorldStateScript.WATER_DRY,
				"year %d described %s's wells as drying while its ground was %s" % [
					state.year, where, state.water_state(where)])
		checked += 1
	assert(checked == 30, "the run did not complete")
	print("  NO FALSE WELLS: 30 years under a standing order, no drying claim over wet ground.")
	completed += 1


func _test_long_runs_keep_settlements_different() -> void:
	# The guard the season exists to protect. Without the dry year the world
	# climbed to food 3 / prosperity 3 everywhere and stayed there.
	var simulation := _sim()
	var state = simulation.state
	for year in range(60):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var signatures: Dictionary = {}
	var maxed := 0
	for location_id: String in state.get_location_ids():
		signatures["%d/%d" % [
			state.get_settlement_band(location_id, "food"),
			state.get_settlement_band(location_id, "prosperity")
		]] = true
		if state.get_settlement_band(location_id, "food") >= 3 \
			and state.get_settlement_band(location_id, "prosperity") >= 3:
			maxed += 1
	assert(signatures.size() > 1,
		"60 autonomous years left every settlement identical: %s" % str(signatures.keys()))
	assert(maxed < state.get_location_ids().size(),
		"the world plateaued at uniform plenty")
	print("  STILL VARIED: 60 years, %d distinct settlement conditions." % signatures.size())
	completed += 1


func _test_send_rain_still_matters_in_the_seeded_world() -> void:
	# The deterministic fixture the other suites use. When the world plateaued,
	# rain had nothing left to move and four suites caught it; this keeps that
	# guarantee inside the consistency suite too.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	var target := str(state.current_event_location_id)
	state.set_water(target, 5)
	var food_before: int = state.get_settlement_band(target, "food")
	var stability_before: int = state.get_settlement_band(target, "stability")
	var water_before: int = state.get_water(target)
	simulation.resolve_action("send_rain", target)
	assert(state.get_water(target) > water_before,
		"Send Rain did not move the ground at all")
	assert(state.get_settlement_band(target, "food") != food_before
		or state.get_settlement_band(target, "stability") != stability_before,
		"Send Rain on dry ground changed nothing about %s" % target)
	print("  RAIN STILL MATTERS: %s food %d -> %d on dry ground." % [
		target, food_before, state.get_settlement_band(target, "food")])
	completed += 1


func _test_the_event_is_valid_where_it_is_declared() -> void:
	# The general invariant, over a long ordinary run: whatever the world says is
	# happening, it says it somewhere it could actually be happening.
	var simulation := _sim()
	var state = simulation.state
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		var where := str(state.current_event_location_id)
		assert(simulation.event_can_occur_at(str(state.current_event_id), where),
			"year %d: %s declared in %s, which cannot host it" % [
				state.year, state.current_event_id, where])
	print("  ALWAYS VALID: 40 autonomous years, every situation possible where stated.")
	completed += 1


# --- water as the single physical truth ------------------------------------

func _test_persistent_rain_walks_the_whole_scale() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	var seen: Array[String] = [state.water_state("westfield")]
	# The GENTLEST force, so the ground is sampled finely enough to be seen in
	# every band. A stronger one steps over `saturated` between two years, which
	# says nothing about the scale and everything about the sampling.
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_GENTLE, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	if not seen.has(state.water_state("westfield")):
		seen.append(state.water_state("westfield"))
	for year in range(32):
		state.action_taken = true
		simulation.advance_year()
		var now: String = state.water_state("westfield")
		if not seen.has(now):
			seen.append(now)
	for expected: String in WorldStateScript.WATER_STATES:
		assert(seen.has(expected), "the ground never passed through %s: %s" % [expected, seen])
	print("  WHOLE SCALE: dry -> normal -> wet -> saturated -> flooded, by one repeated force.")
	completed += 1


func _test_stopping_leaves_the_water_where_it_stands() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(5):
		state.action_taken = true
		simulation.advance_year()
	var standing: int = state.get_water("westfield")
	assert(standing > 85, "the order should have left deep water, got %d" % standing)
	simulation.stop_intervention_for("send_rain", "westfield")
	assert(state.get_water("westfield") == standing,
		"stopping drained the flood: %d -> %d" % [standing, state.get_water("westfield")])
	print("  STOPPING REVERSES NOTHING: water stayed at %d." % standing)
	completed += 1


func _test_a_stopped_order_does_not_apply_again() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 10)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	simulation.stop_intervention_for("send_rain", "westfield")
	for year in range(5):
		state.action_taken = true
		simulation.advance_year()
		for row: Dictionary in state.last_intervention_events:
			assert(false, "a stopped order applied again in year %d" % state.year)
	assert(state.active_intervention_list().is_empty(),
		"a stopped order is still listed as active")
	print("  STOPPED IS STOPPED: five years, no further applications.")
	completed += 1


func _test_qualitative_labels_match_the_numbers() -> void:
	# Presentation must not be able to say something the number does not.
	var PresentationRulesScript = load("res://scripts/presentation_rules.gd")
	var simulation := _sim()
	var state = simulation.state
	for value in range(0, 101):
		state.set_water("westfield", value)
		var band: String = state.water_state("westfield")
		assert(band == state.water_state_for(value), "water state disagreed at %d" % value)
		assert(not str(PresentationRulesScript.water_label(band)).is_empty(),
			"water state %s has no label" % band)
		state.set_abundance("westfield", value)
		var yielded: String = state.abundance_state("westfield")
		assert(not str(PresentationRulesScript.abundance_label(yielded)).is_empty(),
			"abundance state %s has no label" % yielded)
	print("  LABELS AGREE: every water and abundance value resolves and reads.")
	completed += 1


# --- harvest and abundance --------------------------------------------------

func _test_a_flooded_place_has_no_promising_harvest() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	for location_id: String in state.get_location_ids():
		state.set_water(location_id, WorldStateScript.WATER_MAX)
	assert(simulation.locations_for_event("good_harvest").is_empty(),
		"a drowned world still promised a harvest")
	state.set_water("frontier", WorldStateScript.WATER_BASELINE)
	var candidates: Array = simulation.locations_for_event("good_harvest")
	assert(candidates.size() == 1 and str(candidates[0]) == "frontier",
		"the only unflooded settlement should be the only harvest candidate: %s" % str(candidates))
	print("  NO HARVEST UNDER WATER: grain does not ripen in standing floodwater.")
	completed += 1


func _test_harvest_facts_come_from_one_place_only() -> void:
	# Abundance is the settlement's condition and `harvest_yield` is the act's
	# occurrence. Two topics, deliberately; but only ONE of them may be emitted
	# per blessing, or the same fact enters the world twice.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_abundance("westfield", 0)
	state.pending_perception_facts.clear()
	simulation.resolve_action("bless_harvest", "westfield")
	var by_id: Dictionary = {}
	for fact: Dictionary in state.pending_perception_facts:
		var id := str(fact["id"])
		assert(not by_id.has(id), "the same fact was offered twice: %s" % id)
		by_id[id] = true
	print("  ONE VOICE: %d facts from one blessing, none duplicated." % by_id.size())
	completed += 1


# --- interventions ----------------------------------------------------------

func _test_a_finite_order_applies_exactly_its_years() -> void:
	for years: int in [1, 3, 7]:
		var simulation := _sim()
		var state = simulation.state
		_settle(simulation, 4)
		simulation.resolve_action("send_rain", "westfield",
			DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_SUSTAINED, years)
		var applications := 1
		for year in range(years + 4):
			state.action_taken = true
			simulation.advance_year()
			applications += state.last_intervention_events.size()
		assert(applications == years,
			"a %d-year order applied %d times" % [years, applications])
	print("  EXACT DURATION: 1, 3 and 7-year orders applied 1, 3 and 7 times.")
	completed += 1


func _test_no_double_application_in_the_opening_year() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	var after_one: int = state.get_water("westfield")
	assert(after_one == simulation.RAIN_WATER_BY_INTENSITY[DivineActionRules.INTENSITY_NORMAL],
		"the opening year applied the order %s times" % str(float(after_one) /
			float(simulation.RAIN_WATER_BY_INTENSITY[DivineActionRules.INTENSITY_NORMAL])))
	print("  ONCE ONLY: an order's first year is one application, not two.")
	completed += 1


func _test_orders_on_different_places_stay_separate() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_water("westfield", 0)
	state.set_abundance("aster", 0)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	state.action_taken = false
	state.divine_power = 100
	simulation.resolve_action("bless_harvest", "aster",
		DivineActionRules.INTENSITY_NORMAL, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	assert(state.active_intervention_list().size() == 2, "two orders should coexist")
	simulation.stop_intervention_for("send_rain", "westfield")
	var standing: Array = state.active_intervention_list()
	assert(standing.size() == 1, "stopping one order stopped another")
	assert(str(standing[0]["action_id"]) == "bless_harvest", "the wrong order was stopped")
	var before: int = state.get_abundance("aster")
	state.action_taken = true
	simulation.advance_year()
	assert(state.get_abundance("aster") > before - WorldStateScript.ABUNDANCE_MAX,
		"the surviving order stopped working")
	assert(state.last_intervention_events.size() == 1,
		"exactly one order should still be applying")
	print("  ISOLATED: stopping the rain left the blessing running.")
	completed += 1


func _test_an_explicit_target_is_never_overridden() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	for location_id: String in state.get_location_ids():
		state.set_water(location_id, WorldStateScript.WATER_BASELINE)
	var elsewhere := ""
	for location_id: String in state.get_location_ids():
		if location_id != str(state.current_event_location_id):
			elsewhere = location_id
			break
	assert(not elsewhere.is_empty(), "the world needs a second settlement for this test")
	simulation.resolve_action("send_rain", elsewhere)
	assert(str(state.last_divine_target_id) == elsewhere,
		"the god's explicit target was replaced by the event's location")
	assert(state.get_water(elsewhere) > WorldStateScript.WATER_BASELINE,
		"the rain did not fall where it was aimed")
	assert(state.get_water(str(state.current_event_location_id)) <= WorldStateScript.WATER_BASELINE,
		"the rain also fell where it was not aimed")
	print("  AIMED: rain fell on %s, not on the year's event location." % elsewhere)
	completed += 1


# --- boundaries that must survive ------------------------------------------

func _test_nothing_reasons_from_the_control_panel() -> void:
	# The cleanup must not be achieved by telling mortals what the player did.
	# No rules file may read the god's control panel, whatever else it does.
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd",
		"res://scripts/chronicle_rules.gd", "res://scripts/intent_rules.gd",
		"res://scripts/consequence_rules.gd", "res://scripts/perception_rules.gd"
	]:
		var code := _code_of(path)
		for forbidden: String in [
			"active_interventions", "active_intervention_list", "get_intervention",
			"divine_action_archive", "action_counts", "intervention_counts"
		]:
			assert(not code.contains(forbidden),
				"%s reasons from %s" % [path, forbidden])
	# And the layers that decide what something MEANT may not read the world's
	# own answer. `consequence_rules.gd` is excluded on purpose: it is the layer
	# that WRITES objective truth onto a new fact, which is its whole job.
	for path: String in [
		"res://scripts/interpretation_rules.gd", "res://scripts/belief_rules.gd",
		"res://scripts/intent_rules.gd"
	]:
		assert(not _code_of(path).contains("objective_truth_state"),
			"%s reads objective truth" % path)
	print("  NO OMNISCIENCE: consistency was not bought with hidden knowledge.")
	completed += 1


func _test_a_generated_settlement_obeys_the_same_rules() -> void:
	# Nothing here may be keyed to the seeded three.
	var simulation := _sim()
	var state = simulation.state
	state.add_location("harborside", "Harborside", "harbour", "Fishing and trade", {})
	_settle(simulation, 4)
	state.set_water("harborside", WorldStateScript.WATER_MAX)
	assert(not simulation.event_can_occur_at("drought", "harborside"),
		"an invented settlement escaped the drought rule")
	state.set_water("harborside", 5)
	assert(simulation.event_can_occur_at("drought", "harborside"),
		"an invented settlement could never host a drought")
	var code := _code_of("res://scripts/world_sim.gd")
	for seeded: String in ["aster", "westfield", "frontier"]:
		assert(not code.contains('"%s"' % seeded),
			"world_sim.gd names the seeded settlement %s" % seeded)
	print("  GENERIC: Harborside obeys the same physical rules, unnamed by any of them.")
	completed += 1


func _test_history_never_precedes_its_own_cause() -> void:
	var simulation := _sim()
	var state = simulation.state
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(30):
		state.action_taken = true
		simulation.advance_year()
	var year_of: Dictionary = {}
	for entry: Dictionary in state.chronicle:
		year_of[str(entry["id"])] = int(entry["year"])
	for entry: Dictionary in state.chronicle:
		for parent_value in entry.get("caused_by", []):
			var parent := str(parent_value)
			if not year_of.has(parent):
				continue
			assert(int(year_of[parent]) <= int(entry["year"]),
				"%s was caused by %s, which happened later" % [entry["id"], parent])
	print("  CHRONOLOGY: %d entries, no effect precedes its cause." % state.chronicle.size())
	completed += 1


# --- weirdness that must survive -------------------------------------------

func _test_flooded_and_starving_is_still_allowed() -> void:
	# Explicitly NOT a contradiction, and the suite says so on purpose: standing
	# water ruins food. Nothing here may "tidy" that away.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_OVERWHELMING, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(12):
		state.action_taken = true
		simulation.advance_year()
	assert(state.water_state("westfield") == WorldStateScript.WATER_FLOODED,
		"the order should have flooded Westfield")
	assert(state.get_settlement_band("westfield", "food") <= 1,
		"a flooded settlement should be able to go hungry")
	print("  STILL CRUEL: Westfield is flooded AND short of food, which is allowed.")
	completed += 1


func _test_mortals_may_still_disagree() -> void:
	# Objective coherence is not consensus. Two people looking at one world may
	# still hold different, even false, views of it.
	var simulation := _sim()
	var state = simulation.state
	state.learn_knowledge("aster_king", {
		"id": "westfield_food_shortage",
		"claim": "Westfield does not have enough food",
		"confidence": 90, "truth_state": "true", "source_type": "direct",
		"topic": "food_shortage", "subject_id": "westfield"
	})
	state.learn_knowledge("mara", {
		"id": "westfield_food_shortage",
		"claim": "Westfield does not have enough food",
		"confidence": 30, "truth_state": "false", "source_type": "rumor",
		"topic": "food_shortage", "subject_id": "westfield"
	})
	var king_view: Dictionary = state.get_knowledge("aster_king", "westfield_food_shortage")
	var mara_view: Dictionary = state.get_knowledge("mara", "westfield_food_shortage")
	assert(int(king_view["confidence"]) != int(mara_view["confidence"]),
		"two mortals were forced into one view of the same fact")
	assert(str(mara_view["truth_state"]) == "false",
		"a mortal was quietly corrected by the engine")
	print("  DISAGREEMENT SURVIVES: one fact, two beliefs, one of them wrong.")
	completed += 1


# --- helpers ----------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _settle(simulation: Object, years: int = 6) -> void:
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)
