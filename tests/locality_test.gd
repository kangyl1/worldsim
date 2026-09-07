extends SceneTree

# Population & Locality Coverage Foundation v1.
#
# Everything built so far was exercised against three hand-written settlements
# and two hand-written mortals. That is a fine laboratory and it stays. What it
# must not be is a hidden requirement — a world assembled by a generator later
# should participate in the simulation by EXISTING IN STATE, not by having its
# names added to a rules table somewhere.
#
# So the load-bearing test here creates a settlement and a mortal that no
# production file has ever heard of, and pushes them through the whole chain:
# condition, event, perception, knowledge, interpretation, belief, history,
# divine target. They work because they satisfy generic contracts.
#
# The second concern is the opposite case. A place with nobody in it is a
# legitimate world state, not a bug. An event there is real, is witnessed by
# nobody, teaches nobody anything, and is NOT quietly moved somewhere populated
# to manufacture a story. Several tests below exist to keep that honest.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 18

# Names invented here and nowhere else. If a production rule ever needs to know
# one of these, this milestone has failed.
const NEW_PLACE := "test_harbor"
const NEW_PLACE_NAME := "Test Harbor"
const NEW_RESIDENT := "test_resident"
const SECOND_RESIDENT := "test_neighbour"
const EMPTY_PLACE := "test_wastes"

# The seeded laboratory. Production rules must not branch on any of these.
const FIXTURE_LOCATIONS := ["aster", "westfield", "frontier"]
const FIXTURE_MORTALS := ["aster_king", "mara"]

# Files that decide what the simulation DOES. Seed data, presentation and the
# hand-drawn map are judged separately: see the coupling test.
const RULES_FILES := [
	"res://scripts/perception_rules.gd",
	"res://scripts/consequence_rules.gd",
	"res://scripts/interpretation_rules.gd",
	"res://scripts/intent_rules.gd",
	"res://scripts/action_rules.gd",
	"res://scripts/execution_rules.gd",
	"res://scripts/knowledge_rules.gd",
	"res://scripts/chronicle_rules.gd",
	"res://scripts/belief_rules.gd",
	"res://scripts/divine_action_rules.gd"
]

var completed := 0


func _init() -> void:
	_test_resident_queries_work_for_any_location()
	_test_a_location_can_hold_several_residents()
	_test_zero_residents_is_a_valid_answer()
	_test_a_new_settlement_holds_condition_generically()
	_test_a_local_event_reaches_every_eligible_resident()
	_test_a_local_event_reaches_nobody_elsewhere()
	_test_an_event_in_an_empty_place_leaks_nothing()
	_test_events_are_not_redirected_away_from_empty_places()
	_test_a_new_settlement_can_enter_crisis()
	_test_belief_locality_works_for_a_new_settlement()
	_test_the_chronicle_records_a_new_settlement()
	_test_a_divine_act_can_target_a_new_settlement()
	_test_coverage_is_inspectable()

	_test_no_rule_names_a_fixture_settlement()
	_test_no_rule_names_a_fixture_mortal()
	_test_nothing_creates_people()
	_test_no_movement_or_generation_was_added()
	_test_the_seeded_world_still_works()

	if completed != EXPECTED_TESTS:
		push_error("Locality suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("LOCALITY TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("LOCALITY TEST PASSED: places and people the code has never heard of take part.")
	quit(0)


# --- fixtures --------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A settlement and a mortal invented right here. Added through the same public
# calls a generator would use, and through no other door.
func _with_new_place(resident_traits: Array = ["compassionate"]) -> Object:
	var simulation := _sim()
	var state = simulation.state
	state.add_location(NEW_PLACE, NEW_PLACE_NAME, "harbour", "Fishing and trade", {
		"food": 2, "stability": 2, "prosperity": 1, "population": 120
	})
	state.add_notable_entity(
		NEW_RESIDENT, "The Harbourmaster", "person", resident_traits, {}, NEW_PLACE
	)
	return simulation


func _with_empty_place() -> Object:
	var simulation := _sim()
	simulation.state.add_location(EMPTY_PLACE, "The Wastes", "frontier_settlement", "Nothing", {
		"food": 1, "stability": 1, "prosperity": 0, "population": 40
	})
	return simulation


func _settle(simulation: Object, years: int = 6) -> void:
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()


func _knowledge_on(state, holder_id: String, topic: String) -> Dictionary:
	for record: Dictionary in state.get_all_knowledge(holder_id).values():
		if str(record.get("topic", "")) == topic:
			return record
	return {}


# Executable lines only, so a comment mentioning a settlement by name is not
# mistaken for a rule that depends on one.
func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- the locality contract -------------------------------------------------

func _test_resident_queries_work_for_any_location() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	assert(state.residents_of(NEW_PLACE) == [NEW_RESIDENT],
		"a new settlement could not answer who lives there")
	assert(state.resident_count(NEW_PLACE) == 1)
	assert(state.has_residents(NEW_PLACE))
	assert(state.has_local_perception_coverage(NEW_PLACE))
	assert(state.get_home_location(NEW_RESIDENT) == NEW_PLACE,
		"the new mortal is not associated with the new place")
	assert(NEW_PLACE in state.get_location_ids(), "the new place is not in the world")
	assert(NEW_PLACE in state.locations_with_residents())
	print("  QUERIES: an invented place answers every locality question.")
	completed += 1


func _test_a_location_can_hold_several_residents() -> void:
	# Nothing anywhere assumes one notable mortal per settlement.
	var simulation := _with_new_place()
	var state = simulation.state
	state.add_notable_entity(SECOND_RESIDENT, "The Netmender", "person", ["cautious"], {}, NEW_PLACE)
	assert(state.resident_count(NEW_PLACE) == 2, "a second resident was not accepted")
	assert(state.residents_of(NEW_PLACE) == [SECOND_RESIDENT, NEW_RESIDENT],
		"resident order is not deterministic: %s" % str(state.residents_of(NEW_PLACE)))
	print("  SEVERAL: two notable residents in one settlement, deterministically ordered.")
	completed += 1


func _test_zero_residents_is_a_valid_answer() -> void:
	# Not an error, not a gap, and nothing fills it.
	var simulation := _with_empty_place()
	var state = simulation.state
	assert(state.residents_of(EMPTY_PLACE).is_empty())
	assert(state.resident_count(EMPTY_PLACE) == 0)
	assert(not state.has_residents(EMPTY_PLACE))
	assert(not state.has_local_perception_coverage(EMPTY_PLACE))
	assert(EMPTY_PLACE in state.locations_without_residents())
	# It still has settlement state and still counts as a place.
	assert(state.get_settlement_band(EMPTY_PLACE, "food") == 1,
		"an unpeopled settlement lost its condition")
	assert(state.get_settlement_population(EMPTY_PLACE) > 0,
		"population and notable residents are different questions")
	print("  EMPTY IS VALID: a settlement with conditions, a population, and nobody of note.")
	completed += 1


func _test_a_new_settlement_holds_condition_generically() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	for band: String in WorldState.SETTLEMENT_BANDS:
		var before: int = state.get_settlement_band(NEW_PLACE, band)
		state.change_settlement_band(NEW_PLACE, band, -1)
		assert(state.get_settlement_band(NEW_PLACE, band) != before or before == 0,
			"band '%s' would not move for a new settlement" % band)
	_settle(simulation)
	assert(state.get_settlement_population(NEW_PLACE) > 0,
		"the new settlement stopped existing over six years")
	print("  CONDITIONS: food, stability and prosperity all move for an invented place.")
	completed += 1


func _test_a_local_event_reaches_every_eligible_resident() -> void:
	# Two residents, one local occurrence, both of them there.
	var simulation := _with_new_place()
	var state = simulation.state
	state.add_notable_entity(SECOND_RESIDENT, "The Netmender", "person", ["cautious"], {}, NEW_PLACE)
	_settle(simulation, 4)
	state.current_event_location_id = NEW_PLACE
	simulation.resolve_action("send_rain")
	simulation.advance_year()
	for resident: String in [NEW_RESIDENT, SECOND_RESIDENT]:
		assert(not _knowledge_on(state, resident, "weather_rain").is_empty(),
			"%s stood in the rain and did not notice" % resident)
	print("  LOCAL REACH: both residents of an invented settlement perceived it.")
	completed += 1


func _test_a_local_event_reaches_nobody_elsewhere() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	_settle(simulation, 4)
	state.current_event_location_id = NEW_PLACE
	simulation.resolve_action("send_rain")
	simulation.advance_year()
	for entity: Dictionary in state.notable_entities.values():
		var entity_id := str(entity["id"])
		if str(entity["home_location_id"]) == NEW_PLACE:
			continue
		assert(_knowledge_on(state, entity_id, "weather_rain").is_empty(),
			"%s learned about rain in a settlement they have no association with" % entity_id)
	print("  NO SPILL: the occurrence stopped at the people who were there.")
	completed += 1


func _test_an_event_in_an_empty_place_leaks_nothing() -> void:
	# The case this milestone exists to represent honestly.
	var simulation := _with_empty_place()
	var state = simulation.state
	_settle(simulation, 4)
	var knowledge_before := 0
	for entity: Dictionary in state.notable_entities.values():
		knowledge_before += state.get_all_knowledge(str(entity["id"])).size()
	var interpretations_before: int = state.interpretation_archive.size()

	state.current_event_location_id = EMPTY_PLACE
	var result := simulation.resolve_action("send_rain") as Dictionary
	simulation.advance_year()

	# The act happened and is on the record. It simply reached nobody.
	assert(bool(result["ok"]), "an act in an empty place was refused")
	assert(not state.divine_action_archive.is_empty(), "no divine record was written")
	var record: Dictionary = state.divine_action_archive.back()
	assert(str(record["target_id"]) == EMPTY_PLACE, "the act was moved elsewhere")
	assert(not str(record["consequence_id"]).is_empty(), "no consequence was produced")

	for entity: Dictionary in state.notable_entities.values():
		assert(_knowledge_on(state, str(entity["id"]), "weather_rain").is_empty(),
			"%s learned of rain in a place nobody lives" % str(entity["id"]))
	for index in range(interpretations_before, state.interpretation_archive.size()):
		assert(str(state.interpretation_archive[index]["topic"]) != "weather_rain",
			"somebody interpreted an occurrence they could not have perceived")
	print("  DEAD ZONE: the act is real, is recorded, and is known to nobody.")
	completed += 1


func _test_events_are_not_redirected_away_from_empty_places() -> void:
	# No thumb on the scale. The event selector places events by condition, and
	# must not prefer inhabited settlements to manufacture a story.
	var simulation := _with_empty_place()
	var state = simulation.state
	# Make the empty place the worst-off, which is what the selector looks for.
	state.set_settlement_band(EMPTY_PLACE, "food", 0)
	for location_id: String in state.get_location_ids():
		if location_id != EMPTY_PLACE:
			state.set_settlement_band(location_id, "food", 3)
	assert(simulation.event_location_for("drought") == EMPTY_PLACE,
		"the event selector steered away from a settlement with nobody in it")
	# And the selector is not written in terms of who lives where at all.
	var code := _code_of("res://scripts/world_sim.gd")
	var selector := code.substr(code.find("func event_location_for"), 400)
	for forbidden: String in ["residents", "has_residents", "notable_entities"]:
		assert(not selector.contains(forbidden),
			"event placement consults who lives where")
	print("  NO FORCING: the worst-off settlement is chosen even with nobody in it.")
	completed += 1


func _test_a_new_settlement_can_enter_crisis() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	_settle(simulation, 4)
	state.set_settlement_band(NEW_PLACE, "food", 0)
	assert(state.get_settlement_band(NEW_PLACE, "food") == ChronicleRules.CRISIS_BAND,
		"an invented settlement cannot reach the crisis floor")
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	assert(state.condition_before_turn(NEW_PLACE, "food") >= 0,
		"the invented settlement has no remembered condition")
	print("  CRISIS: an invented settlement reaches the crisis floor like any other.")
	completed += 1


func _test_belief_locality_works_for_a_new_settlement() -> void:
	# The divine bootstrap reads "was my own settlement in crisis" — it must
	# mean any settlement, not the one the fixture happens to use.
	var simulation := _with_new_place()
	var state = simulation.state
	_settle(simulation, 6)
	var answered := 0
	for year in range(20):
		state.set_settlement_band(NEW_PLACE, "food", 0)
		state.set_settlement_band(NEW_PLACE, "prosperity", 0)
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		if state.condition_before_turn(NEW_PLACE, "food") == 0 and int(state.divine_power) >= 2:
			state.current_event_location_id = NEW_PLACE
			simulation.resolve_action("send_rain")
			simulation.advance_year()
			answered += 1
			if answered >= 4:
				break
	assert(answered >= 3, "the fixture produced only %d answered famines" % answered)
	var divine := 0
	for record: Dictionary in state.interpretation_archive:
		if str(record["observer_id"]) == NEW_RESIDENT \
			and str(record["interpretation_type"]).begins_with("rain_divine"):
			divine += 1
	assert(divine > 0,
		"the bootstrap did not work for a settlement the rules have never heard of")
	var belief: Dictionary = state.get_belief(
		NEW_RESIDENT, BeliefRules.DIVINE_HELP_FOLLOWS_NEED, ""
	)
	assert(not belief.is_empty(), "no belief formed for the invented mortal")
	print("  BELIEF: the Harbourmaster reached a divine reading, %d times, belief at %d." % [
		divine, int(belief["confidence"])
	])
	completed += 1


func _test_the_chronicle_records_a_new_settlement() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	_settle(simulation, 4)
	# A crisis that lands and is then answered, in a settlement no rule knows.
	state.set_settlement_band(NEW_PLACE, "food", 0)
	state.set_settlement_band(NEW_PLACE, "prosperity", 0)
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	state.current_event_location_id = NEW_PLACE
	simulation.resolve_action("send_rain")
	simulation.advance_year()

	var here: Array = state.chronicle_for_location(NEW_PLACE)
	assert(not here.is_empty(), "nothing in an invented settlement was worth recording")
	var kinds: Array[String] = []
	var named_the_place := false
	for record: Dictionary in here:
		kinds.append(str(record["event_type"]))
		assert(str(record["location_id"]) == NEW_PLACE,
			"an entry was filed against the wrong place")
		# Entries about the SETTLEMENT name it; an entry about somebody's
		# reading is about the person, and naming the place in its summary
		# would be wrong rather than missing.
		if str(record["summary"]).contains(NEW_PLACE_NAME):
			named_the_place = true
	assert(named_the_place,
		"no entry named the invented settlement: %s" % str(kinds))
	print("  HISTORY: %d entries for an invented settlement (%s)." % [
		here.size(), ", ".join(kinds)
	])
	completed += 1


func _test_a_divine_act_can_target_a_new_settlement() -> void:
	# Record, consequence, observable fact, perception, knowledge — with the
	# target's name appearing in no rules table anywhere.
	var simulation := _with_new_place()
	var state = simulation.state
	_settle(simulation, 4)
	state.current_event_location_id = NEW_PLACE
	var result := simulation.resolve_action("send_rain") as Dictionary
	assert(bool(result["ok"]), "the pipeline refused an invented target")
	var record: Dictionary = state.get_divine_action(str(result["divine_action_id"]))
	assert(str(record["target_id"]) == NEW_PLACE)
	assert(str(record["pipeline"]) == DivineActionRules.PIPELINE_SHARED)
	assert(not str(record["consequence_id"]).is_empty())
	simulation.advance_year()
	var fact := _knowledge_on(state, NEW_RESIDENT, "weather_rain")
	assert(not fact.is_empty(), "the occurrence reached nobody in the target settlement")
	assert(str(fact["claim"]).contains(NEW_PLACE_NAME),
		"the claim does not name the settlement: %s" % str(fact["claim"]))
	print("  DIVINE TARGET: \"%s\"." % str(fact["claim"]))
	completed += 1


func _test_coverage_is_inspectable() -> void:
	var simulation := _with_new_place()
	var state = simulation.state
	state.add_location(EMPTY_PLACE, "The Wastes", "frontier_settlement", "Nothing", {
		"food": 1, "stability": 1, "prosperity": 0, "population": 40
	})
	var rows: Array = state.locality_coverage()
	assert(rows.size() == state.get_location_ids().size(),
		"coverage does not describe every location")
	var seen_covered := false
	var seen_dead := false
	for row: Dictionary in rows:
		for field: String in [
			"location_id", "name", "has_settlement_state", "population",
			"resident_count", "residents", "local_events_perceivable"
		]:
			assert(row.has(field), "coverage cannot report '%s'" % field)
		if bool(row["local_events_perceivable"]):
			seen_covered = true
			assert(int(row["resident_count"]) > 0)
		else:
			seen_dead = true
			assert(int(row["resident_count"]) == 0)
	assert(seen_covered and seen_dead,
		"coverage did not distinguish an inhabited place from an empty one")
	print("  COVERAGE: %d locations described, dead zones named." % rows.size())
	completed += 1


# --- what must not be true -------------------------------------------------

func _test_no_rule_names_a_fixture_settlement() -> void:
	# The point of the milestone. Nothing that decides what the simulation DOES
	# may branch on a settlement that happens to exist today.
	for path: String in RULES_FILES:
		var code := _code_of(path)
		for location_id: String in FIXTURE_LOCATIONS:
			assert(not code.contains('"%s"' % location_id),
				"%s depends on the settlement '%s'" % [path, location_id])
	# world_sim decides behaviour too. Its seed-facing text is another matter,
	# so this checks for id literals rather than display names.
	var sim_code := _code_of("res://scripts/world_sim.gd")
	for location_id: String in FIXTURE_LOCATIONS:
		assert(not sim_code.contains('"%s"' % location_id),
			"world_sim.gd depends on the settlement '%s'" % location_id)
	print("  NO PLACE NAMES: %d rules files, none naming a settlement." % RULES_FILES.size())
	completed += 1


func _test_no_rule_names_a_fixture_mortal() -> void:
	for path: String in RULES_FILES:
		var code := _code_of(path)
		for entity_id: String in FIXTURE_MORTALS:
			assert(not code.contains('"%s"' % entity_id),
				"%s depends on the mortal '%s'" % [path, entity_id])
	print("  NO PERSON NAMES: no rules file depends on a particular mortal.")
	completed += 1


func _test_nothing_creates_people() -> void:
	# Empty locations are not solved by inventing residents. Who exists is for
	# world generation to decide; the simulation consumes that state.
	var simulation := _with_empty_place()
	var state = simulation.state
	var before: int = state.notable_entities.size()
	_settle(simulation, 20)
	assert(state.notable_entities.size() == before,
		"the simulation created %d people on its own"
			% (state.notable_entities.size() - before))
	assert(not state.has_residents(EMPTY_PLACE),
		"somebody appeared in the empty settlement")
	for path: String in RULES_FILES + ["res://scripts/world_sim.gd"]:
		var code := _code_of(path)
		for forbidden: String in ["ensure_resident", "spawn_notable", "generate_person"]:
			assert(not code.contains(forbidden), "%s can conjure people" % path)
	print("  NO SPAWNING: twenty years, %d people throughout." % before)
	completed += 1


func _test_no_movement_or_generation_was_added() -> void:
	# home_location_id stays an association. No travel, no coordinates, no
	# current position, and no world generator.
	for path: String in RULES_FILES + [
		"res://scripts/world_sim.gd", "res://scripts/world_state.gd"
	]:
		var code := _code_of(path)
		for forbidden: String in [
			"current_location", "travel_to", "move_entity", "distance_between",
			"generate_settlement", "generate_world", "procedural"
		]:
			assert(not code.contains(forbidden),
				"%s grew '%s', which is later work" % [path, forbidden])
	var simulation := _with_new_place()
	var state = simulation.state
	var home: String = state.get_home_location(NEW_RESIDENT)
	_settle(simulation, 12)
	assert(state.get_home_location(NEW_RESIDENT) == home,
		"a mortal's association changed on its own; that is movement")
	print("  STILL ASSOCIATION: no travel, no position, no generator.")
	completed += 1


func _test_the_seeded_world_still_works() -> void:
	# The laboratory is preserved. Removing the hardcoded ordering constant must
	# not have changed where events land or how the seeded world behaves.
	var simulation := _sim()
	var state = simulation.state
	assert(state.get_location_ids() == FIXTURE_LOCATIONS,
		"the seeded world changed order: %s" % str(state.get_location_ids()))
	assert(not str(state.current_event_location_id).is_empty(),
		"the first event has nowhere to happen")
	assert(state.current_event_location_id in FIXTURE_LOCATIONS)
	assert(state.residents_of("aster") == ["aster_king"])
	assert(state.residents_of("westfield") == ["mara"])
	assert(state.residents_of("frontier").is_empty(),
		"the Frontier is the project's standing example of a place with nobody in it")
	_settle(simulation, 20)
	assert(not state.chronicle.is_empty(), "the seeded world stopped producing history")
	assert(not state.interpretation_archive.is_empty(),
		"the seeded world stopped producing conclusions")
	print("  LABORATORY INTACT: three settlements, two mortals, one of them empty.")
	completed += 1
