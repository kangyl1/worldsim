extends SceneTree

# Smite v1 — a destructive divine force on the shared pipeline.
#
# Smite destroys. Take Life kills. A smite may one day end lives, but only as a
# consequence of destruction and never as its definition — and nothing in this
# world models a death, an injury or a ruined building, so v1 breaks only what
# the simulation can honestly describe.
#
# The temptation this suite guards against is spectacle. It would be easy, and
# entirely false, for a smite to report casualties, burn a palace, or record
# that a place was punished. Pressing Smite does not make the act a punishment:
# the world knows a destructive force struck somewhere, and what that MEANT is
# a mortal's to decide, with the same freedom they have about rain.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")
const ChronicleRulesScript = preload("res://scripts/chronicle_rules.gd")
const BeliefRulesScript = preload("res://scripts/belief_rules.gd")

const EXPECTED_TESTS := 22

var completed := 0


func _init() -> void:
	_test_it_changes_the_world()
	_test_intensity_is_monotonic()
	_test_cost_rises_with_force()
	_test_it_happens_once()
	_test_a_sustained_smite_is_refused()
	_test_a_refused_smite_costs_nothing()
	_test_an_unknown_target_is_refused_cleanly()
	_test_too_little_power_changes_nothing()
	_test_it_creates_an_objective_occurrence()
	_test_a_local_mortal_notices()
	_test_the_world_is_not_told()
	_test_what_they_learn_states_no_motive()
	_test_meaning_is_theirs()
	_test_belief_moves_only_through_interpretation()
	_test_history_records_the_act()
	_test_it_is_not_world_history()
	_test_it_is_divine_history()
	_test_the_damage_is_not_undone()
	_test_the_aftermath_can_outlive_the_act()
	_test_nothing_fabricates_casualties()
	_test_take_life_does_not_exist()
	_test_it_took_the_shared_road()

	if completed != EXPECTED_TESTS:
		push_error("SMITE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("SMITE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("SMITE TEST PASSED: the god destroyed something, and nobody was told why.")
	quit(0)


# --- force ------------------------------------------------------------------

func _test_it_changes_the_world() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	var before := _bands(state, "aster")
	var result: Dictionary = simulation.resolve_action(
		"smite", "aster", DivineActionRules.INTENSITY_GENTLE)
	assert(bool(result["ok"]), "the gentlest smite was refused: %s" % str(result["message"]))
	assert(_bands(state, "aster") != before,
		"a destructive act changed nothing about the world")
	print("  IT BREAKS THINGS: Aster %s -> %s." % [before, _bands(state, "aster")])
	completed += 1


func _test_intensity_is_monotonic() -> void:
	# From IDENTICAL starting state, with room to fall in every band.
	var totals: Dictionary = {}
	var per_band: Dictionary = {}
	for intensity: String in DivineActionRules.INTENSITIES:
		var simulation := _ready_world()
		var state = simulation.state
		var lost := 0
		var bands: Dictionary = {}
		for band: String in ["food", "stability", "prosperity"]:
			bands[band] = state.get_settlement_band("aster", band)
		simulation.resolve_action("smite", "aster", intensity)
		for band: String in bands:
			var fell: int = int(bands[band]) - state.get_settlement_band("aster", band)
			bands[band] = fell
			lost += fell
		totals[intensity] = lost
		per_band[intensity] = bands
	var ladder := DivineActionRules.INTENSITIES
	for index in range(ladder.size() - 1):
		var weaker: String = str(ladder[index])
		var stronger: String = str(ladder[index + 1])
		assert(int(totals[stronger]) > int(totals[weaker]),
			"%s destroyed no more than %s (%d vs %d)" % [
				stronger, weaker, int(totals[stronger]), int(totals[weaker])])
		# And no individual band recovers as force increases.
		for band: String in per_band[weaker]:
			assert(int(per_band[stronger][band]) >= int(per_band[weaker][band]),
				"%s damaged %s less than %s did" % [stronger, band, weaker])
	print("  MONOTONIC: bands lost %d / %d / %d / %d." % [
		int(totals[DivineActionRules.INTENSITY_GENTLE]),
		int(totals[DivineActionRules.INTENSITY_NORMAL]),
		int(totals[DivineActionRules.INTENSITY_STRONG]),
		int(totals[DivineActionRules.INTENSITY_OVERWHELMING])])
	completed += 1


func _test_cost_rises_with_force() -> void:
	var spent: Array[int] = []
	for intensity: String in DivineActionRules.INTENSITIES:
		var simulation := _ready_world()
		var state = simulation.state
		var before: int = state.divine_power
		simulation.resolve_action("smite", "aster", intensity)
		spent.append(before - int(state.divine_power))
	for index in range(spent.size() - 1):
		assert(spent[index + 1] > spent[index],
			"a stronger smite cost no more: %s" % str(spent))
	print("  PRICED: %d / %d / %d / %d divine power." % [
		spent[0], spent[1], spent[2], spent[3]])
	completed += 1


# --- one-shot ---------------------------------------------------------------

func _test_it_happens_once() -> void:
	var modes: Array = DivineActionRules.new().modes_for("smite")
	assert(modes.size() == 1 and str(modes[0]) == DivineActionRules.MODE_ONCE,
		"smite declares a duration it should not have: %s" % str(modes))
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_STRONG)
	assert(state.active_intervention_list().is_empty(),
		"a smite left a standing order behind")
	var after := _bands(state, "aster")
	for year in range(6):
		state.action_taken = true
		simulation.advance_year()
		assert(state.last_intervention_events.is_empty(),
			"a smite struck again in a later year")
	print("  ONCE: no standing order, no second strike in six years.")
	completed += 1


func _test_a_sustained_smite_is_refused() -> void:
	# Refused, NOT quietly performed once. Silently reshaping the order would
	# do something the player did not ask for and hide that it had.
	var simulation := _ready_world()
	var state = simulation.state
	for mode: String in [DivineActionRules.MODE_SUSTAINED, DivineActionRules.MODE_UNTIL_STOPPED]:
		var result: Dictionary = simulation.resolve_action(
			"smite", "aster", DivineActionRules.INTENSITY_NORMAL, mode, 3)
		assert(not bool(result["ok"]), "a %s smite was accepted" % mode)
		assert(str(result["message"]).contains("once"),
			"the refusal does not say why: %s" % str(result["message"]))
	print("  REFUSED: sustained and until-stopped smites are turned away.")
	completed += 1


func _test_a_refused_smite_costs_nothing() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	var power: int = state.divine_power
	var bands := _bands(state, "aster")
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING,
		DivineActionRules.MODE_UNTIL_STOPPED, 0)
	var acts: int = state.divine_action_archive.size()
	assert(state.divine_power == power, "a refused smite spent power")
	assert(_bands(state, "aster") == bands, "a refused smite still broke something")
	assert(not state.action_taken, "a refused smite consumed the year")
	# The settling years took real actions, so the archive is not empty; what
	# matters is that the refused one added nothing to it.
	assert(state.divine_action_archive.size() == acts, "a refused smite was recorded")
	print("  NO PARTIAL ACT: power, bands, turn and archive all untouched.")
	completed += 1


func _test_an_unknown_target_is_refused_cleanly() -> void:
	# An unknown location falls back to the year's event location rather than
	# failing, which is the existing targeting rule. What must not happen is a
	# silent strike on nowhere.
	var simulation := _ready_world()
	var state = simulation.state
	var result: Dictionary = simulation.resolve_action(
		"smite", "atlantis", DivineActionRules.INTENSITY_NORMAL)
	if bool(result["ok"]):
		assert(state.locations.has(str(state.last_divine_target_id)),
			"a smite landed on a place that does not exist")
		print("  NOWHERE IS NOT A TARGET: an unknown place fell back to %s."
			% str(state.last_divine_target_id))
	else:
		assert(not state.action_taken,
			"a refused smite still consumed the turn")
		print("  NOWHERE IS NOT A TARGET: refused outright.")
	completed += 1


func _test_too_little_power_changes_nothing() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	state.divine_power = 1
	var bands := _bands(state, "aster")
	var result: Dictionary = simulation.resolve_action(
		"smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING)
	assert(not bool(result["ok"]), "a smite was afforded with 1 power")
	assert(state.divine_power == 1, "a refused smite spent power anyway")
	assert(_bands(state, "aster") == bands, "a smite nobody could afford still landed")
	print("  UNAFFORDABLE: nothing spent, nothing broken.")
	completed += 1


# --- the causal road --------------------------------------------------------

func _test_it_creates_an_objective_occurrence() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_STRONG)
	var record: Dictionary = state.divine_action_archive[state.divine_action_archive.size() - 1]
	assert(str(record["action_type"]) == "smite", "no divine record was written")
	assert(not str(record["consequence_id"]).is_empty(), "the act produced no consequence")
	var consequence: Dictionary = state.get_consequence(str(record["consequence_id"]))
	assert(not consequence.is_empty(), "the consequence is not stored")
	assert(not (consequence["state_changes"] as Array).is_empty(),
		"a destructive act changed nothing measurable")
	print("  OCCURRENCE: %d objective state changes recorded." %
		(consequence["state_changes"] as Array).size())
	completed += 1


func _test_a_local_mortal_notices() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_STRONG)
	state.action_taken = true
	simulation.advance_year()
	var learned := false
	for knowledge_id: String in state.get_all_knowledge("aster_king"):
		if str(knowledge_id).contains("divine_destruction"):
			learned = true
	assert(learned, "the King lives in Aster and did not notice it being struck")
	print("  NOTICED: the resident of the struck settlement learned of it.")
	completed += 1


func _test_the_world_is_not_told() -> void:
	# Mara lives in Westfield. A force striking Aster is not something she
	# knows for free; it has to reach her the way anything else does.
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING)
	state.action_taken = true
	simulation.advance_year()
	for knowledge_id: String in state.get_all_knowledge("mara"):
		if not str(knowledge_id).contains("divine_destruction"):
			continue
		var record: Dictionary = state.get_knowledge("mara", str(knowledge_id))
		assert(str(record["source_type"]) != "direct",
			"a mortal in another settlement witnessed it directly")
	print("  NOT BROADCAST: the far settlement was not simply told.")
	completed += 1


func _test_what_they_learn_states_no_motive() -> void:
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_STRONG)
	state.action_taken = true
	simulation.advance_year()
	var claims := 0
	for entity_id: String in state.notable_entities.keys():
		for knowledge_id: String in state.get_all_knowledge(entity_id):
			if not str(knowledge_id).contains("divine_destruction"):
				continue
			claims += 1
			var claim := str(state.get_knowledge(entity_id, str(knowledge_id))["claim"]).to_lower()
			for word: String in _forbidden():
				assert(not claim.contains(word),
					"what a mortal learned states a motive: %s" % claim)
	assert(claims > 0, "nobody learned anything, so nothing is proven")
	print("  NO MOTIVE LEARNED: %d claims, none of them saying why." % claims)
	completed += 1


func _test_meaning_is_theirs() -> void:
	# The plain reading must be available and must win by default: a witness
	# sees ruin, not a verdict. Deciding nothing mortal did it is a separate
	# conclusion somebody has to reach.
	var InterpretationRulesScript = load("res://scripts/interpretation_rules.gd")
	var family: Dictionary = InterpretationRulesScript.WORLD_CANDIDATES["divine_destruction"]
	var witness: Array = family[InterpretationRulesScript.STANCE_WITNESS]
	var plain: Dictionary = {}
	var divine: Dictionary = {}
	for candidate: Dictionary in witness:
		if str(candidate["id"]) == "destruction_is_ruin":
			plain = candidate
		if str(candidate["id"]) == "destruction_was_not_mortal":
			divine = candidate
	assert(not plain.is_empty() and not divine.is_empty(), "the readings are missing")
	assert(int(plain["base_score"]) > int(divine["base_score"]),
		"the dramatic reading beats the plain one by default")
	for candidate: Dictionary in witness:
		assert((candidate["effect"] as Dictionary).is_empty(),
			"a world reading moves a relationship")
		for word: String in _forbidden():
			assert(not str(candidate["meaning"]).to_lower().contains(word),
				"a reading states a motive: %s" % str(candidate["meaning"]))
	print("  MEANING IS MORTAL: ruin %d beats 'not of this world' %d by default." % [
		int(plain["base_score"]), int(divine["base_score"])])
	completed += 1


func _test_belief_moves_only_through_interpretation() -> void:
	# The readings feed convictions that ALREADY existed. No smite-specific
	# proposition was invented, and nothing says the place deserved it.
	var supports: Dictionary = BeliefRulesScript.SUPPORTS
	assert(supports.has("destruction_is_ruin") and supports.has("destruction_was_not_mortal"),
		"the destructive readings feed no belief at all")
	for reading: String in ["destruction_is_ruin", "destruction_was_not_mortal"]:
		for entry: Dictionary in supports[reading]:
			assert(str(entry["proposition"]) in BeliefRulesScript.PROPOSITIONS,
				"a smite reading invented a proposition: %s" % str(entry["proposition"]))
	assert(BeliefRulesScript.PROPOSITIONS.size() == 7,
		"the proposition vocabulary grew for one power")
	print("  EXISTING CONVICTIONS: both readings feed propositions that already existed.")
	completed += 1


# --- history ----------------------------------------------------------------

func _test_history_records_the_act() -> void:
	var simulation := _smitten_world()
	var state = simulation.state
	var found := false
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) == ChronicleRulesScript.SOURCE_DIVINE \
			and str(record["location_id"]) == "aster":
			found = true
	assert(found, "an overwhelming smite reached no history at all")
	print("  RECORDED: the act is in the chronicle.")
	completed += 1


func _test_it_is_not_world_history() -> void:
	var simulation := _smitten_world()
	var state = simulation.state
	assert(simulation.chronicle_rules.world_history(state).is_empty(),
		"striking one settlement became world history")
	print("  LOCAL: breaking one place is not the world's history.")
	completed += 1


func _test_it_is_divine_history() -> void:
	var simulation := _smitten_world()
	var state = simulation.state
	var divine: Array = simulation.chronicle_rules.divine_history(state)
	assert(not divine.is_empty(), "the act is in no divine history")
	print("  DIVINE HISTORY: %d records." % divine.size())
	completed += 1


func _test_the_damage_is_not_undone() -> void:
	# A smite is not a debuff that wears off. Whatever the world does next, it
	# does through its own rules, and nothing restores a band because the act
	# has "expired".
	var code := _code_of("res://scripts/world_sim.gd")
	for forbidden: String in ["smite_recovery", "smite_wears_off", "undo_smite", "_restore_smite"]:
		assert(not code.contains(forbidden), "a smite expiry rule exists: %s" % forbidden)
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING)
	var immediately: int = state.get_settlement_band("aster", "stability")
	state.action_taken = true
	simulation.advance_year()
	assert(state.get_settlement_band("aster", "stability") <= immediately + 1,
		"the world handed the damage straight back")
	print("  KEPT: stability sat at %d after the strike, not restored." % immediately)
	completed += 1


func _test_the_aftermath_can_outlive_the_act() -> void:
	# The one-shot act ends in its own year. The history it created need not.
	var simulation := _smitten_world()
	var state = simulation.state
	var strike_year := 0
	for record: Dictionary in state.divine_action_archive:
		if str(record["action_type"]) == "smite":
			strike_year = int(record["year"])
	assert(strike_year > 0, "no smite happened")
	var later := 0
	for record: Dictionary in simulation.chronicle_rules.history_for_location(state, "aster"):
		if int(record["year"]) > strike_year:
			later += 1
	assert(later > 0,
		"nothing at all is recorded at Aster after the year it was struck")
	# And the EPISODE carries it. A one-shot act leaves no condition record of
	# its own damage, so an arc that tracked only recorded transitions would
	# end in the year of the strike and claim the story was over while the
	# settlement was still broken.
	var arcs: Array = simulation.episode_rules.divine_episodes(state)
	assert(not arcs.is_empty(), "the strike produced no divine episode at all")
	var arc: Dictionary = arcs[0]
	assert(int(arc["end_year"]) > strike_year,
		"the story of the strike ended in the same year it happened (y%d)" % strike_year)
	assert(str(arc["summary"]).contains("not recovered")
		or (arc["member_record_ids"] as Array).size() > 1,
		"a long arc says nothing about why it is still running: %s" % str(arc["summary"]))
	print("  AFTERMATH: %d records after y%d, and the story runs to y%d." % [
		later, strike_year, int(arc["end_year"])])
	completed += 1


# --- the boundary that matters ----------------------------------------------

func _test_nothing_fabricates_casualties() -> void:
	var invented := [
		"died", "dead", "death", "killed", "casualt", "corpse", "slain",
		"burned", "collapsed into", "rubble", "homes", "buildings", "palace",
		"wounded", "injur", "maimed", "bodies"
	]
	var simulation := _smitten_world()
	var state = simulation.state
	var checked := 0
	for record: Dictionary in state.chronicle:
		checked += 1
		for word: String in invented:
			assert(not str(record["summary"]).to_lower().contains(word),
				"history invented something the world does not model: %s" % str(record["summary"]))
	for record: Dictionary in state.divine_action_archive:
		for word: String in invented:
			assert(not str(record["result"]).to_lower().contains(word),
				"a smite reported something unmodelled: %s" % str(record["result"]))
	# And population really was left alone by the act itself.
	var fresh := _ready_world()
	var before: int = fresh.state.get_settlement_population("aster")
	fresh.resolve_action("smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING)
	assert(fresh.state.get_settlement_population("aster") == before,
		"a smite moved population; nothing here models a death")
	print("  NO SPECTACLE: %d records, no casualties, no buildings, population untouched." %
		checked)
	completed += 1


func _test_take_life_does_not_exist() -> void:
	var rules := DivineActionRules.new()
	for absent: String in ["take_life", "kill", "resurrect", "slay"]:
		assert(not rules.is_divine_action(absent),
			"%s was implemented alongside smite" % absent)
	var simulation := _ready_world()
	assert(not simulation.actions.has("take_life"), "Take Life appeared in the action table")
	print("  SEPARATE POWER: Take Life is still not built.")
	completed += 1


func _test_it_took_the_shared_road() -> void:
	var rules := DivineActionRules.new()
	assert(rules.is_shared_pipeline("smite"), "smite took the legacy road")
	var simulation := _ready_world()
	var result: Dictionary = simulation.resolve_action(
		"smite", "aster", DivineActionRules.INTENSITY_NORMAL)
	assert(str(result["interpretation"]).is_empty(), "the act decided its own meaning")
	assert(str(result["belief_tag"]).is_empty(), "the act pushed a belief directly")
	assert(str(result["reputation_hint"]).is_empty(), "the act set its own reputation")
	print("  SHARED ROAD: no interpretation, belief or reputation came from the act.")
	completed += 1


# --- helpers ----------------------------------------------------------------

func _forbidden() -> Array[String]:
	return [
		"punish", "wrath", "anger", "angry", "sins", "sinful", "guilt",
		"deserved", "judg", "vengeance", "curse", "mercy", "because"
	]


func _bands(state, location_id: String) -> String:
	return "%d/%d/%d" % [
		state.get_settlement_band(location_id, "food"),
		state.get_settlement_band(location_id, "stability"),
		state.get_settlement_band(location_id, "prosperity")
	]


func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A settled world with room to fall in every band and power to spend.
func _ready_world() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	for band: String in ["food", "stability", "prosperity"]:
		state.set_settlement_band("aster", band, 3)
	# Full reserves, not more: divine power is clamped to its maximum, so a
	# fixture that overfills it measures the clamp instead of the cost.
	state.divine_power = state.max_divine_power
	return simulation


func _smitten_world() -> Object:
	var simulation := _ready_world()
	var state = simulation.state
	simulation.resolve_action("smite", "aster", DivineActionRules.INTENSITY_OVERWHELMING)
	for year in range(18):
		state.action_taken = true
		simulation.advance_year()
	return simulation


func _code_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)
