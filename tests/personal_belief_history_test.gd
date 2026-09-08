extends SceneTree

# Personal Chronicle Belief Turning Points v1.
#
# A belief can be important to a life without being important to the world.
#
# The King spending thirteen years slowly becoming convinced that conditions
# were improving is the largest thing that happens to him in the seeded run, and
# until now it appeared nowhere: his chronicle held the INPUTS to his reasoning
# and never the moment they amounted to something.
#
# What this suite guards is the boundary that makes that safe. A private
# conviction changing is not something that happened in the world, so it reaches
# exactly one lens — the holder's own. History keeps its four sources, the
# chronicle store is untouched, and the moment a belief becomes public or causes
# an action, that action is an occurrence judged by the ordinary rules.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const ChronicleRulesScript = preload("res://scripts/chronicle_rules.gd")
const BeliefRulesScript = preload("res://scripts/belief_rules.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")

const EXPECTED_TESTS := 16

var completed := 0


func _init() -> void:
	_test_becoming_convinced_is_recorded_once()
	_test_more_of_the_same_evidence_records_nothing()
	_test_a_conviction_giving_way_is_its_own_moment()
	_test_confidence_moving_inside_a_status_records_nothing()
	_test_the_turning_point_reaches_the_persons_life()
	_test_a_wavering_conviction_is_one_thread()
	_test_it_is_not_the_history_of_where_they_live()
	_test_it_is_not_world_history()
	_test_a_divine_belief_is_not_divine_history()
	_test_history_keeps_its_four_sources()
	_test_the_chronicle_store_is_untouched()
	_test_repeated_reasoning_stays_curated()
	_test_relationship_turning_points_survive()
	_test_actions_survive()
	_test_the_sentence_cannot_invent_a_reason()
	_test_raw_and_curated_stay_separate()

	if completed != EXPECTED_TESTS:
		push_error("PERSONAL BELIEF TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("PERSONAL BELIEF TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("PERSONAL BELIEF TEST PASSED: a conviction changed, and the world stayed out of it.")
	quit(0)


# --- the transitions --------------------------------------------------------

func _test_becoming_convinced_is_recorded_once() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var established: Array[Dictionary] = []
	for turn: Dictionary in state.belief_turning_points:
		if str(turn["transition"]) == "established":
			established.append(turn)
	assert(not established.is_empty(), "no belief ever became a conviction")
	# Each is a genuine crossing of the established line, in that direction.
	for turn: Dictionary in established:
		assert(int(turn["new_confidence"]) >= BeliefRulesScript.ESTABLISHED_CONFIDENCE,
			"a belief was 'established' below the line: %d" % int(turn["new_confidence"]))
		assert(str(turn["old_status"]) != str(turn["new_status"]),
			"a turning point was recorded without a change of state")
	# One entry per belief per transition per year, never two.
	var seen: Dictionary = {}
	for turn: Dictionary in state.belief_turning_points:
		var key := "%s/%s/%d" % [str(turn["belief_id"]), str(turn["transition"]), int(turn["year"])]
		assert(not seen.has(key), "the same turning point was recorded twice: %s" % key)
		seen[key] = true
	print("  A CONVICTION ARRIVES: %d established, each one a real crossing." % established.size())
	completed += 1


func _test_more_of_the_same_evidence_records_nothing() -> void:
	# The load-bearing anti-spam property. A believer goes on reading the same
	# thing for years; the belief keeps gaining support and stays established,
	# and none of that is a further moment in their life.
	var simulation := _lived_world()
	var state = simulation.state
	var per_belief: Dictionary = {}
	for turn: Dictionary in state.belief_turning_points:
		var key := str(turn["belief_id"])
		per_belief[key] = int(per_belief.get(key, 0)) + 1
	# Beliefs carry far more evidence than they do turning points.
	var most_evidence := 0
	for belief: Dictionary in state.mortal_beliefs:
		most_evidence = maxi(most_evidence,
			int(belief["support"]) + int(belief["contradiction"]))
	assert(most_evidence >= 10, "no belief accumulated enough evidence to test with")
	for key: String in per_belief:
		assert(int(per_belief[key]) < most_evidence,
			"a belief produced a turning point for nearly every piece of evidence")
	print("  NOT EVERY TICK: strongest belief carries %d pieces of evidence, %d turning points." % [
		most_evidence, int(per_belief.values().max())])
	completed += 1


func _test_a_conviction_giving_way_is_its_own_moment() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var kinds: Dictionary = {}
	for turn: Dictionary in state.belief_turning_points:
		kinds[str(turn["transition"])] = true
	assert(kinds.has("established"), "nothing ever became a conviction")
	assert(kinds.has("lapsed") or kinds.has("weakening"),
		"no conviction ever gave way, so the falling half is unproven")
	for turn: Dictionary in state.belief_turning_points:
		if str(turn["transition"]) != "lapsed":
			continue
		assert(int(turn["new_confidence"]) < BeliefRulesScript.ESTABLISHED_CONFIDENCE,
			"a belief 'lapsed' while still above the established line")
	print("  AND GIVES WAY: transitions seen — %s." % ", ".join(kinds.keys()))
	completed += 1


func _test_confidence_moving_inside_a_status_records_nothing() -> void:
	# Every stored turning point must name two DIFFERENT statuses. Drift inside
	# one status is not a moment, however far the number moves.
	var simulation := _lived_world()
	var state = simulation.state
	for turn: Dictionary in state.belief_turning_points:
		assert(str(turn["old_status"]) != str(turn["new_status"]),
			"a turning point records no change of state: %s" % str(turn["proposition"]))
	# And beliefs really did drift without crossing.
	var drifting := 0
	for belief: Dictionary in state.mortal_beliefs:
		var turns := 0
		for turn: Dictionary in state.belief_turning_points:
			if str(turn["belief_id"]) == str(belief["id"]):
				turns += 1
		if int(belief["support"]) + int(belief["contradiction"]) > turns:
			drifting += 1
	assert(drifting > 0, "no belief moved without a turning point, so nothing is proven")
	print("  DRIFT IS NOT A MOMENT: %d beliefs moved more often than they turned." % drifting)
	completed += 1


# --- the personal lens ------------------------------------------------------

func _test_the_turning_point_reaches_the_persons_life() -> void:
	var simulation := _lived_world()
	var life: Array = simulation.personal_chronicle("aster_king")
	var beliefs := 0
	for entry: Dictionary in life:
		if str(entry.get("entry_kind", "")) == "belief_turning_point":
			beliefs += 1
			assert(not str(entry["summary"]).is_empty(), "a turning point reads as nothing")
	assert(beliefs > 0, "the King's life contains none of his convictions")
	print("  IN HIS LIFE: %d of the King's %d life entries are convictions changing." % [
		beliefs, life.size()])
	completed += 1


func _test_a_wavering_conviction_is_one_thread() -> void:
	# `home_is_unsafe` crosses the line repeatedly in the seeded run. All the
	# crossings are stored; the LIFE keeps where it arrived and where it rested.
	var simulation := _lived_world()
	var state = simulation.state
	var stored: Dictionary = {}
	for turn: Dictionary in state.belief_turning_points_for("aster_king"):
		stored[str(turn["belief_id"])] = int(stored.get(str(turn["belief_id"]), 0)) + 1
	var wavering := ""
	for key: String in stored:
		if int(stored[key]) >= 4:
			wavering = key
	assert(not wavering.is_empty(), "no conviction wavered enough to test the rule")
	var in_life := 0
	for entry: Dictionary in simulation.personal_chronicle("aster_king"):
		if str(entry.get("belief_id", "")) == wavering:
			in_life += 1
	assert(in_life <= 2,
		"a wavering conviction filled %d entries of one life" % in_life)
	print("  ONE THREAD: a conviction that turned %d times occupies %d entries of his life." % [
		int(stored[wavering]), in_life])
	completed += 1


# --- the boundaries ---------------------------------------------------------

func _test_it_is_not_the_history_of_where_they_live() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	assert(not state.belief_turning_points.is_empty(), "nothing to test with")
	for location_id: String in state.get_location_ids():
		for record: Dictionary in rules.history_for_location(state, location_id):
			assert(not record.has("transition"),
				"a private conviction entered %s's history" % location_id)
			for turn: Dictionary in state.belief_turning_points:
				assert(str(record["id"]) != str(turn["id"]),
					"a turning point reached a location's history")
	print("  NOT THE PLACE'S: no conviction reached any settlement's history.")
	completed += 1


func _test_it_is_not_world_history() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	for record: Dictionary in rules.world_history(state):
		assert(not record.has("transition"), "a private conviction became world history")
	print("  NOT THE WORLD'S: world history holds no convictions.")
	completed += 1


func _test_a_divine_belief_is_not_divine_history() -> void:
	# A belief ABOUT the god is still a private belief. Divine History is what
	# the god DID, not what somebody decided about him.
	var simulation := _believer()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var divine_beliefs := 0
	for turn: Dictionary in state.belief_turning_points:
		if str(turn["proposition"]).begins_with("divine"):
			divine_beliefs += 1
	assert(divine_beliefs > 0, "the fixture produced no divine belief to test with")
	for record: Dictionary in rules.divine_history(state):
		assert(not record.has("transition"),
			"a belief about the god became divine history")
		for turn: Dictionary in state.belief_turning_points:
			assert(str(record["id"]) != str(turn["id"]),
				"a turning point reached divine history")
	print("  NOT DIVINE HISTORY: %d divine convictions, none of them an act of God." %
		divine_beliefs)
	completed += 1


func _test_history_keeps_its_four_sources() -> void:
	# The documented guarantee, re-asserted here because this milestone is the
	# obvious moment to break it.
	var simulation := _lived_world()
	var state = simulation.state
	for record: Dictionary in state.chronicle:
		assert(str(record["source_record_type"]) in [
			ChronicleRulesScript.SOURCE_CONDITION, ChronicleRulesScript.SOURCE_DIVINE,
			ChronicleRulesScript.SOURCE_CONSEQUENCE, ChronicleRulesScript.SOURCE_INTERPRETATION
		], "history grew a new source: %s" % str(record["source_record_type"]))
		for turn: Dictionary in state.belief_turning_points:
			assert(str(record["source_record_id"]) != str(turn["belief_id"]),
				"a belief was written into history")
	var code := _code_of("res://scripts/chronicle_rules.gd")
	assert(not code.contains("mortal_beliefs") and not code.contains("get_belief")
		and not code.contains("belief_turning_points"),
		"the chronicle rules learned that beliefs exist")
	print("  FOUR SOURCES: history still knows nothing about belief.")
	completed += 1


func _test_the_chronicle_store_is_untouched() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var before: int = state.chronicle.size()
	var turns_before: int = state.belief_turning_points.size()
	for pass_number in range(3):
		for entity_id: String in state.notable_entities.keys():
			simulation.personal_chronicle(entity_id)
	assert(state.chronicle.size() == before, "reading a life changed the chronicle")
	assert(state.belief_turning_points.size() == turns_before,
		"reading a life changed the turning points")
	print("  READ ONLY: %d records and %d turning points, unchanged by three passes." % [
		before, turns_before])
	completed += 1


# --- what must still work ---------------------------------------------------

func _test_repeated_reasoning_stays_curated() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var counts: Dictionary = {}
	for entry: Dictionary in simulation.personal_chronicle("aster_king"):
		if str(entry.get("entry_kind", "")) == "belief_turning_point":
			continue
		var key: String = rules.personal_key(entry, "aster_king")
		counts[key] = int(counts.get(key, 0)) + 1
		assert(int(counts[key]) <= 2, "repeated reasoning came back: %s" % key)
	print("  STILL CURATED: no repeated thread exceeds two entries.")
	completed += 1


func _test_relationship_turning_points_survive() -> void:
	var simulation := _lived_world()
	var found := false
	for entry: Dictionary in simulation.personal_chronicle("aster_king"):
		if str(entry["summary"]).contains("trust toward"):
			found = true
	assert(found, "the King's relationship turning points were lost")
	print("  RELATIONSHIPS KEPT: his trust in Mara still appears.")
	completed += 1


func _test_actions_survive() -> void:
	var simulation := _lived_world()
	var actions := 0
	for entry: Dictionary in simulation.personal_chronicle("aster_king"):
		if str(entry.get("source_record_type", "")) == ChronicleRulesScript.SOURCE_CONSEQUENCE:
			actions += 1
	assert(actions > 0, "the King's actions were lost from his life")
	print("  ACTIONS KEPT: %d social occurrences still in his life." % actions)
	completed += 1


func _test_the_sentence_cannot_invent_a_reason() -> void:
	# Every sentence the helper can produce, not a sample. There is nowhere for
	# a motive to enter: the tables hold a proposition and a transition, and no
	# cause at all.
	var forbidden := [
		"because", "punish", "mercy", "reward", "sin", "guilt", "deserved",
		"god's", "wrath", "judg", "prophec", "betray", "secret", "fault"
	]
	for proposition: String in PresentationRulesScript.BELIEF_PHRASES:
		for transition: String in PresentationRulesScript.BELIEF_TRANSITIONS:
			var sentence := PresentationRulesScript.belief_sentence(
				proposition, transition, "The King", "Mara"
			).to_lower()
			assert(not sentence.is_empty(), "a real transition reads as nothing")
			for word: String in forbidden:
				assert(not sentence.contains(word),
					"a belief sentence claims a reason: %s" % sentence)
	# An unknown proposition or transition invents nothing at all.
	assert(PresentationRulesScript.belief_sentence("something_new", "established", "X", "").is_empty(),
		"an unknown proposition produced a sentence anyway")
	assert(PresentationRulesScript.belief_sentence(
		"conditions_are_improving", "exploded", "X", "").is_empty(),
		"an unknown transition produced a sentence anyway")
	print("  NO INVENTED REASON: every possible sentence states the change and stops.")
	completed += 1


func _test_raw_and_curated_stay_separate() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var raw: Array = rules.history_for_person(state, "aster_king")
	var life: Array = simulation.personal_chronicle("aster_king")
	assert(raw.size() > life.size(), "the raw trace is no longer larger than the life")
	for record: Dictionary in raw:
		assert(not record.has("transition"), "a belief leaked into the raw record view")
	print("  TWO VIEWS: %d raw records, %d life entries." % [raw.size(), life.size()])
	completed += 1


# --- fixtures ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _lived_world() -> Object:
	var simulation := _sim()
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	return simulation


# Somebody who reaches a belief about the god, through lived circumstance only.
func _believer() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(8):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
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
	return simulation


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)
