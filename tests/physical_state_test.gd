extends SceneTree

# Mortal Physical State v1 — life, injury and death.
#
# Injury is physical state. Death is life state. They are related and not
# identical, which is why they are two fields: a future Take Life must be able
# to end a life WITHOUT physical damage, and a model where death is merely
# "damage at maximum" could not express that.
#
# The rule this suite exists to hold is the one that is easy to get wrong in the
# opposite direction from usual. Death must END AGENCY and DELETE NOTHING. A
# tidy-minded cleanup that cleared a dead mortal's knowledge, relationships or
# beliefs would destroy the history God is meant to be able to inspect, and a
# forgotten loop that let a corpse keep forming intents would be worse.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const WorldStateScript = preload("res://scripts/world_state.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 24

var completed := 0


func _init() -> void:
	_test_a_new_mortal_is_alive_and_unhurt()
	_test_old_fixtures_default_safely()
	_test_damage_worsens_condition()
	_test_damage_accumulates()
	_test_more_damage_is_never_less_harm()
	_test_the_lethal_bound_kills()
	_test_death_records_when_and_why()
	_test_death_persists()
	_test_the_dead_form_no_intents()
	_test_the_dead_take_no_actions()
	_test_the_dead_perceive_nothing_new()
	_test_the_dead_are_neither_told_nor_tell()
	_test_knowledge_survives_death()
	_test_relationships_survive_death()
	_test_beliefs_survive_death()
	_test_the_personal_chronicle_survives_death()
	_test_death_appears_in_the_personal_chronicle()
	_test_small_damage_does_not_spam_a_life()
	_test_injury_is_not_world_history()
	_test_an_unknown_entity_is_untouched()
	_test_a_corpse_cannot_be_hurt_again()
	_test_labels_cover_every_condition()
	_test_no_recovery_was_invented()
	_test_take_life_and_person_smite_are_absent()

	if completed != EXPECTED_TESTS:
		push_error("PHYSICAL STATE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("PHYSICAL STATE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("PHYSICAL STATE TEST PASSED: death ended their agency and deleted none of them.")
	quit(0)


# --- defaults ---------------------------------------------------------------

func _test_a_new_mortal_is_alive_and_unhurt() -> void:
	var simulation := _sim()
	var state = simulation.state
	state.add_notable_entity("harbourmaster", "The Harbourmaster", "person", ["cautious"])
	assert(state.is_alive("harbourmaster"), "a new mortal was born dead")
	assert(state.get_physical_damage("harbourmaster") == WorldStateScript.PHYSICAL_MIN,
		"a new mortal was born hurt")
	assert(state.physical_condition("harbourmaster") == WorldStateScript.CONDITION_HEALTHY,
		"a new mortal is not healthy")
	assert(state.get_death("harbourmaster").is_empty(), "a living mortal has a death record")
	print("  BORN WELL: alive, undamaged, no death record.")
	completed += 1


func _test_old_fixtures_default_safely() -> void:
	# An entity built before these fields existed must read as a healthy living
	# person, not as a corpse with no record. Every accessor defaults.
	var simulation := _sim()
	var state = simulation.state
	var entity: Dictionary = state.notable_entities["aster_king"]
	entity.erase("is_alive")
	entity.erase("physical_damage")
	entity.erase("death")
	state.notable_entities["aster_king"] = entity
	assert(state.is_alive("aster_king"), "an entity with no field read as dead")
	assert(state.get_physical_damage("aster_king") == 0, "an entity with no field read as hurt")
	assert(state.physical_condition("aster_king") == WorldStateScript.CONDITION_HEALTHY,
		"an entity with no field read as injured")
	assert(state.living_entity_ids().has("aster_king"), "a defaulted entity lost its agency")
	print("  MIGRATION SAFE: a record missing all three fields reads as healthy and alive.")
	completed += 1


# --- damage -----------------------------------------------------------------

func _test_damage_worsens_condition() -> void:
	var state = _sim().state
	var ladder: Array[String] = []
	for amount: int in [25, 25, 25]:
		state.apply_physical_damage("mara", amount, {"source_type": "test"})
		ladder.append(state.physical_condition("mara"))
	assert(ladder[0] == WorldStateScript.CONDITION_HURT, "25 damage is not hurt: %s" % ladder[0])
	assert(ladder[1] == WorldStateScript.CONDITION_SERIOUS, "50 damage is not serious")
	assert(ladder[2] == WorldStateScript.CONDITION_CRITICAL, "75 damage is not critical")
	assert(state.is_alive("mara"), "75 damage killed her")
	print("  WORSENS: %s." % " -> ".join(ladder))
	completed += 1


func _test_damage_accumulates() -> void:
	var state = _sim().state
	for step in range(4):
		state.apply_physical_damage("mara", 10, {"source_type": "test"})
	assert(state.get_physical_damage("mara") == 40,
		"four blows of ten came to %d" % state.get_physical_damage("mara"))
	print("  ACCUMULATES: four blows of ten come to 40.")
	completed += 1


func _test_more_damage_is_never_less_harm() -> void:
	var results: Array[int] = []
	for amount: int in [10, 30, 60, 95]:
		var state = _sim().state
		state.apply_physical_damage("mara", amount, {"source_type": "test"})
		results.append(state.get_physical_damage("mara"))
	for index in range(results.size() - 1):
		assert(results[index + 1] > results[index],
			"a heavier blow did less: %s" % str(results))
	print("  MONOTONIC: %s." % str(results))
	completed += 1


func _test_the_lethal_bound_kills() -> void:
	var state = _sim().state
	state.apply_physical_damage("mara", WorldStateScript.LETHAL_DAMAGE - 1, {"source_type": "test"})
	assert(state.is_alive("mara"), "one short of the bound killed her")
	assert(state.physical_condition("mara") == WorldStateScript.CONDITION_CRITICAL,
		"one short of the bound is not critical")
	state.apply_physical_damage("mara", 1, {"source_type": "test"})
	assert(not state.is_alive("mara"), "reaching the bound did not kill her")
	assert(state.physical_condition("mara") == WorldStateScript.CONDITION_DEAD,
		"a dead mortal does not read as dead")
	# Damage stops at the bound: "how dead" is not a quantity.
	assert(state.get_physical_damage("mara") == WorldStateScript.LETHAL_DAMAGE,
		"damage ran past the lethal bound")
	print("  LETHAL: %d survives, %d does not." % [
		WorldStateScript.LETHAL_DAMAGE - 1, WorldStateScript.LETHAL_DAMAGE])
	completed += 1


func _test_death_records_when_and_why() -> void:
	var simulation := _sim()
	var state = simulation.state
	for year in range(3):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var when: int = state.year
	state.apply_physical_damage("mara", 100, {
		"source_type": "divine_action", "source_id": "divine_0016_smite_westfield_0",
		"location_id": "westfield"
	})
	var death: Dictionary = state.get_death("mara")
	assert(not death.is_empty(), "a death with no record")
	assert(int(death["year"]) == when, "the death year is wrong: %d" % int(death["year"]))
	assert(str(death["cause_type"]) == "physical_damage", "the cause is not physical damage")
	assert(str(death["source_type"]) == "divine_action", "the source kind was lost")
	assert(not str(death["source_id"]).is_empty(), "the source id was lost")
	assert(str(death["location_id"]) == "westfield", "where it happened was lost")
	print("  PROVENANCE: y%d, %s, from %s." % [
		int(death["year"]), str(death["cause_type"]), str(death["source_type"])])
	completed += 1


func _test_death_persists() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	for year in range(8):
		state.action_taken = true
		simulation.advance_year()
		assert(not state.is_alive("mara"), "she came back to life in year %d" % state.year)
		assert(state.get_physical_damage("mara") == WorldStateScript.LETHAL_DAMAGE,
			"a yearly tick healed a corpse")
	print("  STAYS DEAD: eight years of ticking, still dead.")
	completed += 1


# --- agency -----------------------------------------------------------------

func _test_the_dead_form_no_intents() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	var died: int = int(state.get_death("mara")["year"])
	for year in range(6):
		state.action_taken = true
		simulation.advance_year()
	for record: Dictionary in state.intent_archive:
		if str(record.get("actor_id", "")) != "mara":
			continue
		assert(int(record.get("year", 0)) <= died,
			"she wanted something in year %d, after dying in %d" % [
				int(record["year"]), died])
	assert(not state.living_entity_ids().has("mara"), "a corpse is listed among the living")
	print("  NO WANTS: nothing wanted after death.")
	completed += 1


func _test_the_dead_take_no_actions() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	var died: int = int(state.get_death("mara")["year"])
	for year in range(6):
		state.action_taken = true
		simulation.advance_year()
	for archive: Array in [state.action_archive, state.execution_archive]:
		for record: Dictionary in archive:
			if str(record.get("actor_id", "")) != "mara":
				continue
			assert(int(record.get("year", 0)) <= died,
				"she acted in year %d, after dying in %d" % [int(record["year"]), died])
	print("  NO ACTS: nothing attempted or executed after death.")
	completed += 1


func _test_the_dead_perceive_nothing_new() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	for year in range(6):
		state.action_taken = true
		simulation.advance_year()
		for opportunity: Dictionary in state.last_perceptions:
			assert(str(opportunity.get("observer_id", "")) != "mara",
				"a corpse was offered something to notice")
	print("  NO GHOST PERCEPTION: never offered a thing to see.")
	completed += 1


func _test_the_dead_are_neither_told_nor_tell() -> void:
	# The guard sits at the one funnel every route passes through. Gating only
	# the speakers left the dead still being told things for years.
	var simulation := _killed_world()
	var state = simulation.state
	var held: int = state.get_all_knowledge("mara").size()
	for year in range(8):
		state.action_taken = true
		simulation.advance_year()
	assert(state.get_all_knowledge("mara").size() == held,
		"a corpse learned %d new things" % (state.get_all_knowledge("mara").size() - held))
	# And directly, through the funnel itself.
	var refused: Dictionary = state.learn_knowledge("mara", {
		"id": "a_secret", "claim": "Something happened", "confidence": 90,
		"truth_state": "true", "source_type": "rumor", "topic": "surplus",
		"subject_id": "aster"
	})
	assert(refused.is_empty(), "a corpse was taught something directly")
	print("  SILENT: %d things known at death, %d eight years later." % [
		held, state.get_all_knowledge("mara").size()])
	completed += 1


# --- what survives ----------------------------------------------------------

func _test_knowledge_survives_death() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	assert(state.get_all_knowledge("mara").size() > 0,
		"death emptied her memory")
	print("  MEMORY KEPT: %d things she knew are still there." %
		state.get_all_knowledge("mara").size())
	completed += 1


func _test_relationships_survive_death() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	var edge: Dictionary = state.get_relationship("aster_king", "mara")
	assert(not edge.is_empty(), "how the King regarded her was deleted")
	var hers: Dictionary = state.get_relationship("mara", "aster_king")
	assert(not hers.is_empty(), "how she regarded the King was deleted")
	print("  TIES KEPT: both directed edges survive.")
	completed += 1


func _test_beliefs_survive_death() -> void:
	var simulation := _believer_killed()
	var state = simulation.state
	var kept := 0
	for belief: Dictionary in state.mortal_beliefs:
		if str(belief["holder_id"]) == "mara":
			kept += 1
	assert(kept > 0, "death erased what she had come to accept")
	print("  CONVICTIONS KEPT: %d beliefs still recorded." % kept)
	completed += 1


func _test_the_personal_chronicle_survives_death() -> void:
	var simulation := _killed_world()
	var life: Array = simulation.personal_chronicle("mara")
	assert(not life.is_empty(), "her life story was deleted when she died")
	print("  LIFE KEPT: %d entries still readable." % life.size())
	completed += 1


func _test_death_appears_in_the_personal_chronicle() -> void:
	var simulation := _killed_world()
	var found := false
	for entry: Dictionary in simulation.personal_chronicle("mara"):
		if str(entry.get("after_condition", "")) == WorldStateScript.CONDITION_DEAD:
			found = true
			assert(str(entry["summary"]).contains("died"),
				"her death reads as '%s'" % str(entry["summary"]))
	assert(found, "the largest event of her life is not in it")
	print("  DEATH RECORDED: it is in her chronicle, in words.")
	completed += 1


func _test_small_damage_does_not_spam_a_life() -> void:
	# Only a change of band is a moment. Accumulating damage inside one is not.
	var simulation := _sim()
	var state = simulation.state
	for step in range(10):
		state.apply_physical_damage("mara", 1, {"source_type": "test"})
	assert(state.physical_condition("mara") == WorldStateScript.CONDITION_HEALTHY,
		"ten points of damage left the healthy band")
	assert(state.physical_turning_points_for("mara").is_empty(),
		"%d turning points from damage that changed nothing" %
			state.physical_turning_points_for("mara").size())
	state.apply_physical_damage("mara", 15, {"source_type": "test"})
	assert(state.physical_turning_points_for("mara").size() == 1,
		"crossing a band did not produce exactly one moment")
	print("  NO SPAM: ten scratches record nothing; crossing a band records once.")
	completed += 1


func _test_injury_is_not_world_history() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	assert(simulation.chronicle_rules.world_history(state).is_empty(),
		"one mortal being hurt became world history")
	# And a physical turning point is not a chronicle record at all.
	for record: Dictionary in state.chronicle:
		assert(not record.has("after_condition"),
			"a physical state change was written into history")
	print("  PRIVATE: injury and death reached no world history.")
	completed += 1


# --- boundaries -------------------------------------------------------------

func _test_an_unknown_entity_is_untouched() -> void:
	var state = _sim().state
	var before: int = state.physical_turning_points.size()
	var result: Dictionary = state.apply_physical_damage("nobody", 50, {"source_type": "test"})
	assert(result.is_empty(), "damaging nobody reported something")
	assert(state.physical_turning_points.size() == before,
		"damaging nobody recorded a moment")
	assert(state.apply_physical_damage("mara", 0, {}).is_empty(),
		"zero damage reported a change")
	assert(state.apply_physical_damage("mara", -20, {}).is_empty(),
		"negative damage was accepted as healing")
	assert(state.get_physical_damage("mara") == 0, "negative damage moved the number")
	print("  REFUSED: unknown target, zero and negative damage all change nothing.")
	completed += 1


func _test_a_corpse_cannot_be_hurt_again() -> void:
	var simulation := _killed_world()
	var state = simulation.state
	var death: Dictionary = state.get_death("mara")
	var turns: int = state.physical_turning_points_for("mara").size()
	var result: Dictionary = state.apply_physical_damage("mara", 50, {
		"source_type": "second_blow", "source_id": "later"
	})
	assert(result.is_empty(), "a corpse reported being harmed")
	assert(state.get_death("mara") == death,
		"a later blow rewrote how and when she died")
	assert(state.physical_turning_points_for("mara").size() == turns,
		"harming a corpse recorded a moment")
	print("  NOT AGAIN: the dead cannot be harmed, and their death is not rewritten.")
	completed += 1


func _test_labels_cover_every_condition() -> void:
	for condition: String in WorldStateScript.PHYSICAL_CONDITIONS:
		var label := PresentationRulesScript.physical_label(condition)
		assert(not label.is_empty(), "%s has no label" % condition)
		assert(not label.contains("_"), "%s leaked an id: %s" % [condition, label])
	# And nothing describes an anatomy the model does not have.
	for condition: String in PresentationRulesScript.PHYSICAL_SENTENCES:
		var sentence := str(PresentationRulesScript.PHYSICAL_SENTENCES[condition]).to_lower()
		for word: String in ["blood", "bone", "limb", "arm", "leg", "skull", "shattered", "burn"]:
			assert(not sentence.contains(word),
				"a physical sentence invents anatomy: %s" % sentence)
	print("  LABELLED: %d conditions, no ids, no anatomy." %
		WorldStateScript.PHYSICAL_CONDITIONS.size())
	completed += 1


func _test_no_recovery_was_invented() -> void:
	# Nothing heals on its own. Adding regeneration because games usually have
	# it would be inventing a medical system nobody designed.
	var simulation := _sim()
	var state = simulation.state
	state.apply_physical_damage("mara", 55, {"source_type": "test"})
	var hurt: int = state.get_physical_damage("mara")
	for year in range(10):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	assert(state.get_physical_damage("mara") == hurt,
		"ten years healed her from %d to %d" % [hurt, state.get_physical_damage("mara")])
	var code := FileAccess.get_file_as_string("res://scripts/world_state.gd")
	for invented: String in ["heal(", "regenerate", "recover_physical", "physical_recovery"]:
		assert(not code.contains(invented), "a recovery mechanism exists: %s" % invented)
	print("  NO FAKE HEALING: 55 damage, ten years, still 55.")
	completed += 1


func _test_take_life_and_person_smite_are_absent() -> void:
	var rules := DivineActionRules.new()
	for absent: String in ["take_life", "heal", "resurrect", "kill"]:
		assert(not rules.is_divine_action(absent), "%s was implemented" % absent)
	# Smite still targets settlements only. A person id is not a location, and
	# nothing pretends otherwise.
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	state.divine_power = state.max_divine_power
	var before: int = state.get_physical_damage("mara")
	simulation.resolve_action("smite", "mara", DivineActionRules.INTENSITY_OVERWHELMING)
	assert(state.get_physical_damage("mara") == before,
		"smiting a person's id harmed them; person targeting is not built")
	assert(state.is_alive("mara"), "smiting a person's id killed them")
	print("  STILL ABSENT: no Take Life, no Heal, no person-target Smite.")
	completed += 1


# --- fixtures ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A settled world in which Mara has lived, known things and been killed.
func _killed_world() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(6):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	state.apply_physical_damage("mara", 30, {"source_type": "test"})
	state.apply_physical_damage("mara", 70, {
		"source_type": "divine_action", "source_id": "test_strike", "location_id": "westfield"
	})
	return simulation


# The same, but she reached a belief before dying.
func _believer_killed() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(8):
		state.set_settlement_band("westfield", "food", 0)
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		if state.condition_before_turn("westfield", "food") == 0 and int(state.divine_power) >= 2:
			state.current_event_location_id = "westfield"
			simulation.resolve_action("send_rain")
			simulation.advance_year()
	state.apply_physical_damage("mara", 100, {"source_type": "test"})
	return simulation
