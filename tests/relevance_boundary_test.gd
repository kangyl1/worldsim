extends SceneTree

# History Relevance Boundary v1 + Personal Chronicle separation.
#
# History records what happened. A Personal Chronicle may also record what
# happened INSIDE someone.
#
# The distinction this suite guards: a thought can matter enormously to the
# person having it and not be the business of the place they were sitting in.
# Interpretation records used to be filed at the OBSERVER'S HOME, so a king
# forming opinions in the capital was writing the capital's history — 56 records
# for Aster against 3 for Westfield, most of the gap one man thinking.
#
# Nothing here deletes simulation truth. Every raw record still exists and is
# still reachable; what changed is which lens shows it.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const ChronicleRulesScript = preload("res://scripts/chronicle_rules.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 15

var completed := 0


func _init() -> void:
	_test_a_private_thought_is_not_the_place_it_was_had_in()
	_test_the_same_thought_is_still_that_persons_own()
	_test_an_internal_change_is_not_world_history()
	_test_a_consequential_act_is_history()
	_test_a_turning_point_can_be_personal_without_being_public()
	_test_repeated_reasoning_does_not_fill_a_life()
	_test_saturated_agreement_does_not_fill_a_life()
	_test_the_raw_record_is_still_there()
	_test_rumour_never_overwrites_the_record()
	_test_the_empty_frontier_gets_no_phantom_prosperity()
	_test_no_phantom_fall_reaches_history()
	_test_legitimate_local_silence_still_works()
	_test_causal_links_survive()
	_test_world_scope_rules_are_untouched()
	_test_personal_presentation_invents_nothing()

	if completed != EXPECTED_TESTS:
		push_error("RELEVANCE BOUNDARY TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("RELEVANCE BOUNDARY TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("RELEVANCE BOUNDARY TEST PASSED: a life and a place are different stories.")
	quit(0)


# --- location relevance -----------------------------------------------------

func _test_a_private_thought_is_not_the_place_it_was_had_in() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var thoughts := 0
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) != ChronicleRulesScript.SOURCE_INTERPRETATION:
			continue
		thoughts += 1
		# The record still truthfully says where the observer was...
		assert(not str(record["location_id"]).is_empty(),
			"the interpretation record lost where its observer was")
		# ...and that place's HISTORY does not contain it.
		assert(rules.location_history_ids(state, record).is_empty(),
			"a private conclusion became %s's history" % str(record["location_id"]))
		for location_id: String in state.get_location_ids():
			for other: Dictionary in rules.history_for_location(state, location_id):
				assert(str(other["id"]) != str(record["id"]),
					"a private conclusion reached %s's history" % location_id)
	assert(thoughts > 0, "the fixture produced no interpretations to test")
	print("  NOT THE PLACE'S BUSINESS: %d private conclusions, 0 in any location's history." %
		thoughts)
	completed += 1


func _test_the_same_thought_is_still_that_persons_own() -> void:
	# Excluded from the place, kept for the person. The record is not lost.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var personal: Array = rules.personal_chronicle_for(state, "aster_king")
	var thoughts := 0
	for record: Dictionary in personal:
		if str(record["source_record_type"]) == ChronicleRulesScript.SOURCE_INTERPRETATION:
			thoughts += 1
	assert(thoughts > 0, "the King's chronicle contains none of his own conclusions")
	print("  STILL HIS: %d of the King's %d life entries are his own conclusions." % [
		thoughts, personal.size()])
	completed += 1


func _test_an_internal_change_is_not_world_history() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	for record: Dictionary in rules.world_history(state):
		assert(str(record["source_record_type"]) != ChronicleRulesScript.SOURCE_INTERPRETATION,
			"somebody's private conclusion became world history")
	print("  NOT THE WORLD'S: no internal change reached world history.")
	completed += 1


func _test_a_consequential_act_is_history() -> void:
	# The other half of the rule. A thought is private; something DONE is not.
	# A refusal between two people is a consequence record, and it stays in the
	# history of the place it happened in.
	var simulation := _flooded_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var acts := 0
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) != ChronicleRulesScript.SOURCE_CONSEQUENCE:
			continue
		acts += 1
		assert(not rules.location_history_ids(state, record).is_empty(),
			"something that actually happened is nowhere's history: %s" % str(record["id"]))
	assert(acts > 0, "the fixture produced no social occurrences")
	print("  ACTS ARE HISTORY: %d occurrences, all kept in the place they happened." % acts)
	completed += 1


func _test_a_turning_point_can_be_personal_without_being_public() -> void:
	# The King's trust in Mara crossing into Strong is a real event in his life
	# and in nobody else's records.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var turning: Dictionary = {}
	for record: Dictionary in rules.personal_chronicle_for(state, "aster_king"):
		if str(record["summary"]).contains("trust toward"):
			turning = record
			break
	assert(not turning.is_empty(), "the King's life contains no relationship turning point")
	assert(rules.location_history_ids(state, turning).is_empty(),
		"a private turning point entered a location's history")
	assert(not bool(turning["world_history"]), "a private turning point became world history")
	print("  PERSONAL TURNING POINT: '%s' — his alone." %
		str(turning["summary"]).substr(0, 58))
	completed += 1


# --- personal chronicle is not a debug trace --------------------------------

func _test_repeated_reasoning_does_not_fill_a_life() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var raw: Array = rules.history_for_person(state, "aster_king")
	var personal: Array = rules.personal_chronicle_for(state, "aster_king")
	assert(personal.size() < raw.size(),
		"the curated life is no shorter than the raw trace")
	# No personal key may appear more than twice: a thread keeps where it began
	# and where it ended, never the identical middle.
	var counts: Dictionary = {}
	for record: Dictionary in personal:
		var key: String = rules.personal_key(record, "aster_king")
		counts[key] = int(counts.get(key, 0)) + 1
		assert(int(counts[key]) <= 2,
			"the same thread appears %d times in one life: %s" % [int(counts[key]), key])
	# And the fixture really did contain a long repetitive run.
	var raw_counts: Dictionary = {}
	var worst := 0
	for record: Dictionary in raw:
		var key: String = rules.personal_key(record, "aster_king")
		raw_counts[key] = int(raw_counts.get(key, 0)) + 1
		worst = maxi(worst, int(raw_counts[key]))
	assert(worst >= 5, "the fixture had no repetitive run to collapse (worst %d)" % worst)
	print("  A LIFE, NOT A TRACE: %d raw -> %d entries; longest repeated thread %d -> 2." % [
		raw.size(), personal.size(), worst])
	completed += 1


func _test_saturated_agreement_does_not_fill_a_life() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var agreements := 0
	for record: Dictionary in state.chronicle:
		if str(record["event_type"]) == "request_accepted":
			agreements += 1
	var in_life := 0
	for record: Dictionary in rules.personal_chronicle_for(state, "mara"):
		if str(record["event_type"]) == "request_accepted":
			in_life += 1
	assert(agreements >= 5, "the fixture produced no repeated agreements")
	assert(in_life <= 2, "%d identical agreements filled Mara's life" % in_life)
	# Trust really is saturated, which is why they stopped being news.
	var edge: Dictionary = state.get_relationship("aster_king", "mara")
	assert(int(edge["trust"]) >= 90, "the fixture's relationship never saturated")
	print("  SATURATION: %d identical agreements, %d in her life; trust sits at %d." % [
		agreements, in_life, int(edge["trust"])])
	completed += 1


func _test_the_raw_record_is_still_there() -> void:
	# Nothing was deleted to make a view cleaner.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var before: int = state.chronicle.size()
	for pass_number in range(3):
		for entity_id: String in state.notable_entities.keys():
			rules.personal_chronicle_for(state, entity_id)
			rules.history_for_person(state, entity_id)
		for location_id: String in state.get_location_ids():
			rules.history_for_location(state, location_id)
	assert(state.chronicle.size() == before,
		"reading the views changed the store: %d -> %d" % [before, state.chronicle.size()])
	# Every entry in the curated life is a real record from the store.
	for record: Dictionary in rules.personal_chronicle_for(state, "aster_king"):
		assert(state.has_chronicle(str(record["id"])),
			"a life entry is not a stored record")
	print("  NOTHING DELETED: %d records before and after every view." % before)
	completed += 1


func _test_rumour_never_overwrites_the_record() -> void:
	# Objective history and what people said about it are two layers. A
	# chronicle summary is drawn from occurrences, never from a mortal's belief,
	# and a test greps the rules for the knowledge store to prove it cannot be.
	var code := _code_of("res://scripts/chronicle_rules.gd")
	for forbidden: String in [
		"get_knowledge", "get_all_knowledge", "does_entity_believe",
		"knowledge_events", "truth_state", "\"rumor\""
	]:
		assert(not code.contains(forbidden),
			"chronicle_rules.gd can read what mortals merely believe: %s" % forbidden)
	# And an outright false belief changes no historical summary.
	var simulation := _lived_world()
	var state = simulation.state
	var before: Array[String] = []
	for record: Dictionary in state.chronicle:
		before.append(str(record["summary"]))
	state.learn_knowledge("mara", {
		"id": "aster_king_is_a_murderer",
		"claim": "The King murdered a man at the feast",
		"confidence": 95, "truth_state": "false", "source_type": "rumor",
		"topic": "danger_unrest", "subject_id": "aster_king"
	})
	var after: Array[String] = []
	for record: Dictionary in state.chronicle:
		after.append(str(record["summary"]))
	assert(before == after, "a rumour changed what history says happened")
	print("  TWO LAYERS: a confident falsehood rewrote no historical summary.")
	completed += 1


# --- the phantom prosperity bug ---------------------------------------------

func _test_the_empty_frontier_gets_no_phantom_prosperity() -> void:
	# The Frontier has no notable resident, so it has nobody to settle a crisis,
	# dig a well or organise anything. Silence outcomes that represent MORTAL
	# work may not be credited to it.
	var simulation := _sim()
	var state = simulation.state
	assert(not state.has_residents("frontier"), "the fixture's Frontier gained a resident")
	var bumps := 0
	for year in range(40):
		var before: int = state.get_settlement_band("frontier", "prosperity")
		simulation.resolve_action("do_nothing")
		if state.get_settlement_band("frontier", "prosperity") != before:
			bumps += 1
		simulation.advance_year()
	assert(bumps == 0,
		"an empty settlement received %d unearned prosperity movements" % bumps)
	print("  NOBODY THERE: 40 years, 0 unearned movements on an empty settlement.")
	completed += 1


func _test_no_phantom_fall_reaches_history() -> void:
	# The false record came from a false transition, so the transition is gone
	# and the record with it. It was not hidden or compressed away.
	var simulation := _lived_world()
	var state = simulation.state
	# The Frontier begins at Poor and falls to Destitute once, genuinely, in its
	# first years. What it must never do is fall from Poor AGAIN, having never
	# returned there — which it used to do four more times, once per silence
	# outcome that credited an empty settlement with its people's work.
	var falls: Array[int] = []
	for record: Dictionary in state.chronicle:
		if str(record["location_id"]) != "frontier":
			continue
		if not str(record["summary"]).contains("prosperity"):
			continue
		falls.append(int(record["year"]))
	assert(falls.size() <= 1,
		"the Frontier recorded %d prosperity transitions: years %s" % [falls.size(), str(falls)])
	assert(state.get_settlement_band("frontier", "prosperity") == 0,
		"the Frontier's prosperity left Destitute")
	print("  NO PHANTOM FALL: %d prosperity transition on the Frontier, down from 5." %
		falls.size())
	completed += 1


func _test_legitimate_local_silence_still_works() -> void:
	# The fix must not silence the legacy path everywhere. A settlement WITH
	# residents still receives what its people did.
	var simulation := _sim()
	var state = simulation.state
	var moved := 0
	for year in range(40):
		var before := {}
		for location_id: String in state.get_location_ids():
			before[location_id] = state.get_settlement_band(location_id, "prosperity") \
				+ state.get_settlement_band(location_id, "food") \
				+ state.get_settlement_band(location_id, "stability")
		simulation.resolve_action("do_nothing")
		for location_id: String in state.get_location_ids():
			if not state.has_residents(location_id):
				continue
			var now: int = state.get_settlement_band(location_id, "prosperity") \
				+ state.get_settlement_band(location_id, "food") \
				+ state.get_settlement_band(location_id, "stability")
			if now != int(before[location_id]):
				moved += 1
		simulation.advance_year()
	assert(moved > 0, "inhabited settlements stopped receiving silence consequences entirely")
	assert(state.useful_silence_outcomes > 0, "useful silence stopped happening")
	print("  STILL WORKS: %d silence consequences landed where people actually live." % moved)
	completed += 1


# --- untouched guarantees ---------------------------------------------------

func _test_causal_links_survive() -> void:
	var simulation := _flooded_world()
	var state = simulation.state
	var linked := 0
	for record: Dictionary in state.chronicle:
		for parent_value in record["caused_by"]:
			linked += 1
			assert(state.has_chronicle(str(parent_value)),
				"%s points at a missing parent" % str(record["id"]))
			var back: Array = state.get_chronicle(str(parent_value))["led_to"]
			assert(back.has(str(record["id"])), "a causal link is one-directional")
	assert(linked > 0, "no causal links to preserve")
	print("  CAUSALITY INTACT: %d links, all two-way." % linked)
	completed += 1


func _test_world_scope_rules_are_untouched() -> void:
	assert(ChronicleRulesScript.WORLD_HISTORY_THRESHOLD == 70, "the world bar moved")
	assert(ChronicleRulesScript.IMPORTANCE_THRESHOLD == 50, "the chronicle threshold moved")
	assert(ChronicleRulesScript.SCOPES.size() == 5, "the scope vocabulary changed")
	assert(ChronicleRulesScript.CATEGORIES.size() == 6, "the category vocabulary changed")
	print("  UNTOUCHED: thresholds and vocabularies exactly as they were.")
	completed += 1


func _test_personal_presentation_invents_nothing() -> void:
	for event_type: String in PresentationRulesScript.PERSONAL_TITLES:
		var template := str(PresentationRulesScript.PERSONAL_TITLES[event_type]).to_lower()
		for word: String in [
			"punish", "mercy", "sin", "guilt", "deserved", "betray", "adulter",
			"conspir", "wrath", "judg", "prophec", "because", "secret"
		]:
			assert(not template.contains(word),
				"a personal title claims motive or meaning: %s" % template)
	assert(PresentationRulesScript.personal_title("request_accepted", "Mara", 50).is_empty(),
		"a mundane life entry was given a headline")
	print("  NO INVENTED MOTIVE: every personal title states what happened and stops.")
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


func _flooded_world() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(26):
		state.action_taken = true
		simulation.advance_year()
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
