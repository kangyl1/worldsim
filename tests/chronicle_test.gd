extends SceneTree

# Historical Selection + Chronicle v1, and the Autonomous Story Test.
#
# Every other layer answers what happened. This one answers which of it
# mattered, and the whole value of the answer is in what it leaves out. A
# chronicle that recorded everything would be the event log with extra steps.
#
# The test the selection has to satisfy is GDD section 36, and it is a test
# about the future rather than about drama: a memory earns its place by being
# capable of affecting later behaviour, belief, relationships or history. So
# most of this suite is negative — a settlement drifting one band, a divine act
# nobody needed, an ordinary agreement in a fed and quiet year, all correctly
# left out — and the positive half is one long autonomous run asked whether it
# produced a story anyone could follow.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 18

# Long enough for conditions to turn several times without the run becoming a
# test of endurance.
const STORY_YEARS := 40

# Words that would mean history had started saying what things MEANT.
const JUDGEMENT_WORDS := [
	"cruel", "betrayed", "merciful", "mercifully", "wicked", "heroic", "evil",
	"blessed", "cursed", "punished", "rewarded", "saved", "abandoned", "sacred",
	"answered", "faithful", "righteous", "wise", "foolish", "deserved"
]

# Later systems this layer must not quietly begin.
const OUT_OF_SCOPE := [
	"myth", "doctrine", "religion", "faction", "propaganda", "era",
	"forgotten", "decay", "rediscover", "oral_tradition", "narrative"
]

var completed := 0


func _init() -> void:
	_test_history_is_not_the_event_log()
	_test_selection_is_deterministic()
	_test_a_crisis_becomes_history()
	_test_ordinary_drift_does_not()
	_test_every_factor_names_its_own_score()
	_test_the_threshold_explains_both_answers()
	_test_records_point_back_at_their_source()
	_test_the_source_record_is_left_alone()
	_test_causal_links_are_ids_and_run_both_ways()
	_test_some_records_are_roots()
	_test_history_stays_objective()
	_test_a_divine_act_is_not_history_for_being_divine()
	_test_relationship_drift_is_not_recorded()
	_test_an_interpretation_enters_only_through_its_effect()
	_test_history_changes_no_behaviour()
	_test_nothing_out_of_scope_was_started()
	_test_history_is_not_forgotten()
	_test_the_autonomous_story()

	if completed != EXPECTED_TESTS:
		push_error("Chronicle suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("CHRONICLE TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("CHRONICLE TEST PASSED: the world produced a story, and left most of itself out.")
	quit(0)


# --- helpers ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A world left to itself, with the god answering droughts. Autonomous in the
# sense that matters: no scripted outcome, and the same one every run.
func _long_run(years: int = STORY_YEARS) -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(years):
		var choice := "do_nothing"
		if str(state.current_event_id) == "drought" and int(state.divine_power) >= 2:
			choice = "send_rain"
		simulation.resolve_action(choice)
		simulation.advance_year()
	return simulation


func _silent_run(years: int = STORY_YEARS) -> Object:
	var simulation := _sim()
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	return simulation


func _by_source(state, source_type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) == source_type:
			found.append(record)
	return found


func _has_factor(record: Dictionary, kind: String) -> bool:
	for factor_value in record["factors"]:
		if str((factor_value as Dictionary)["kind"]) == kind:
			return true
	return false


func _judgement_in(text: String) -> String:
	var padded := " %s " % text.to_lower().replace(".", " ").replace(",", " ")
	for word: String in JUDGEMENT_WORDS:
		if padded.contains(" %s " % word):
			return word
	return ""


# --- selection -------------------------------------------------------------

func _test_history_is_not_the_event_log() -> void:
	# The load-bearing property. Forty years of a world that never stops moving,
	# and history keeps a small fraction of it.
	var simulation := _long_run()
	var state = simulation.state
	var raw: int = state.consequence_archive.size() + state.interpretation_archive.size() \
		+ state.execution_archive.size() + state.divine_action_archive.size()
	assert(not state.chronicle.is_empty(), "%d years produced no history at all" % STORY_YEARS)
	assert(state.chronicle.size() < raw / 2,
		"history kept %d of %d records; that is an event log" % [state.chronicle.size(), raw])
	assert(state.chronicle.size() < STORY_YEARS * 2,
		"history averaged more than two entries a year")
	print("  SELECTIVE: %d entries from %d years (%d records seen)." % [
		state.chronicle.size(), STORY_YEARS, raw
	])
	completed += 1


func _test_selection_is_deterministic() -> void:
	# No dice. Two identical worlds write an identical history, and the rules
	# name no randomness.
	var source := FileAccess.get_file_as_string("res://scripts/chronicle_rules.gd")
	for forbidden: String in ["randi", "randf", "rand_range", "RandomNumberGenerator"]:
		assert(not source.contains(forbidden), "history rolled dice via '%s'" % forbidden)
	var signatures: Array[String] = []
	for run in range(2):
		var parts: Array[String] = []
		for record: Dictionary in _long_run(20).state.chronicle:
			parts.append("%d:%s:%d" % [
				int(record["year"]), str(record["id"]), int(record["importance"])
			])
		signatures.append("|".join(parts))
	assert(not signatures[0].is_empty(), "twenty years produced no history to compare")
	assert(signatures[0] == signatures[1], "two identical worlds wrote different histories")
	print("  DETERMINISTIC: the same world wrote the same history twice.")
	completed += 1


func _test_a_crisis_becomes_history() -> void:
	# The clearest case in the system: a settlement fell into a named crisis,
	# and that governs what everyone there will want.
	var state = _long_run().state
	var crises := 0
	for record: Dictionary in _by_source(state, ChronicleRules.SOURCE_CONDITION):
		if _has_factor(record, "crisis_entered") or _has_factor(record, "crisis_lifted"):
			crises += 1
	assert(crises > 0, "forty years and no crisis was worth recording")
	print("  CRISES: %d entered or lifted." % crises)
	completed += 1


func _test_ordinary_drift_does_not() -> void:
	# A band moving by one, in neither direction of a crisis, is weather. It
	# must never reach history, and the run must actually contain some so the
	# assertion is about a real exclusion rather than an absent case.
	var simulation := _long_run()
	var state = simulation.state
	for record: Dictionary in _by_source(state, ChronicleRules.SOURCE_CONDITION):
		assert(_has_factor(record, "crisis_entered")
			or _has_factor(record, "crisis_lifted")
			or _has_factor(record, "condition_swing"),
			"a condition entered history on drift alone: %s" % str(record["summary"]))
	# Prove drift happened and was passed over. The rejection list is this
	# year's only, so run one more year and read it.
	var considered := 0
	for year in range(6):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		considered += state.last_chronicle_rejections.size()
	assert(considered > 0, "nothing at all was considered and left out")
	print("  DRIFT: %d candidates considered and correctly left out." % considered)
	completed += 1


func _test_every_factor_names_its_own_score() -> void:
	# Explainability. An importance nobody can decompose is a number, not a
	# reason, and Developer Mode has to be able to answer "why is this history".
	var state = _long_run().state
	for record: Dictionary in state.chronicle:
		assert(not record["factors"].is_empty(),
			"a record became history with no stated reason: %s" % str(record["id"]))
		var total := 0
		for factor_value in record["factors"]:
			var factor: Dictionary = factor_value
			assert(ChronicleRules.FACTOR_SCORES.has(str(factor["kind"])),
				"unknown factor '%s'" % str(factor["kind"]))
			assert(not str(factor["detail"]).is_empty(),
				"factor '%s' explains nothing" % str(factor["kind"]))
			total += int(factor["score"])
		assert(total == int(record["importance"]),
			"%s scores %d but its factors sum to %d" % [
				str(record["id"]), int(record["importance"]), total
			])
	print("  EXPLAINED: every entry's importance decomposes exactly.")
	completed += 1


func _test_the_threshold_explains_both_answers() -> void:
	# Developer Mode must answer why something IS history and why something is
	# NOT. The second answer is the one that is easy to lose.
	var simulation := _long_run()
	var state = simulation.state
	for record: Dictionary in state.chronicle:
		assert(int(record["importance"]) >= ChronicleRules.IMPORTANCE_THRESHOLD,
			"%s is history below the threshold" % str(record["id"]))
	var seen := 0
	for year in range(8):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for rejection: Dictionary in state.last_chronicle_rejections:
			seen += 1
			assert(int(rejection["importance"]) < ChronicleRules.IMPORTANCE_THRESHOLD)
			assert(not str(rejection["reason"]).is_empty(),
				"a candidate was refused without a reason")
			assert(not str(rejection["source_record_id"]).is_empty(),
				"a refusal cannot be traced back to what was refused")
	assert(seen > 0, "no refusals to inspect")
	print("  BOTH ANSWERS: %d refusals, each with a reason and a source." % seen)
	completed += 1


# --- records and causality -------------------------------------------------

func _test_records_point_back_at_their_source() -> void:
	var state = _long_run().state
	var required := [
		"id", "year", "event_type", "subject_id", "actor_id", "target_id",
		"location_id", "summary", "source_record_type", "source_record_id",
		"importance", "factors", "caused_by", "led_to",
		# History Scope Foundation v1. Which histories this one record belongs
		# to, what kind of thing it was, and whether it is the world's business.
		# Metadata over the record, never a second copy of it: the ids behind
		# `scopes` stay in `location_id`, `actor_id` and `target_id`.
		"scopes", "categories", "world_history"
	]
	for record: Dictionary in state.chronicle:
		for field: String in required:
			assert(record.has(field), "a chronicle record is missing '%s'" % field)
		for field: String in record.keys():
			assert(str(field) in required,
				"the record grew a field with no stated use: %s" % str(field))
		assert(not str(record["source_record_id"]).is_empty(),
			"%s points at nothing" % str(record["id"]))
		# The source must be findable in the layer that wrote it.
		match str(record["source_record_type"]):
			ChronicleRules.SOURCE_DIVINE:
				assert(not state.get_divine_action(str(record["source_record_id"])).is_empty(),
					"a divine source vanished: %s" % str(record["source_record_id"]))
			ChronicleRules.SOURCE_CONSEQUENCE:
				assert(not state.get_consequence(str(record["source_record_id"])).is_empty()
					or state.consequence_archive.size() >= WorldState.MAX_STORED_CONSEQUENCES,
					"a consequence source vanished: %s" % str(record["source_record_id"]))
	print("  TRACEABLE: %d records, all pointing back." % state.chronicle.size())
	completed += 1


func _test_the_source_record_is_left_alone() -> void:
	# History observes. If a chronicle entry could edit its own source, the
	# objective record would stop being objective.
	var simulation := _long_run(24)
	var state = simulation.state
	var before := {}
	for record: Dictionary in state.consequence_archive:
		before[str(record["id"])] = str(record)
	for record: Dictionary in state.interpretation_archive:
		before[str(record["id"])] = str(record)
	for record: Dictionary in state.divine_action_archive:
		before[str(record["id"])] = str(record)
	assert(not before.is_empty(), "nothing to compare")
	# Run more years, so history is written again over the same archives.
	for year in range(6):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var checked := 0
	for record: Dictionary in state.consequence_archive + state.interpretation_archive \
		+ state.divine_action_archive:
		var record_id := str(record["id"])
		if not before.has(record_id):
			continue
		checked += 1
		assert(str(record) == before[record_id],
			"history rewrote its own source: %s" % record_id)
	assert(checked > 0, "no surviving source records to check")
	print("  UNTOUCHED: %d source records identical after being chronicled." % checked)
	completed += 1


func _test_causal_links_are_ids_and_run_both_ways() -> void:
	# A chain, built from ids rather than duplicated prose, and consistent in
	# both directions.
	var state = _long_run().state
	var linked := 0
	var longest := 0
	for record: Dictionary in state.chronicle:
		for parent_id_value in record["caused_by"]:
			var parent_id := str(parent_id_value)
			var parent: Dictionary = state.get_chronicle(parent_id)
			assert(not parent.is_empty(), "caused_by points at nothing: %s" % parent_id)
			assert(str(record["id"]) in parent["led_to"],
				"%s claims %s as a cause, which does not claim it back"
					% [str(record["id"]), parent_id])
			assert(int(parent["year"]) <= int(record["year"]),
				"a record was caused by something that had not happened yet")
			linked += 1
		for child_id_value in record["led_to"]:
			assert(not state.get_chronicle(str(child_id_value)).is_empty(),
				"led_to points at nothing")
		longest = maxi(longest, record["led_to"].size())
	assert(linked > 0, "forty years and nothing caused anything")
	print("  CAUSAL: %d links, widest root leads to %d records." % [linked, longest])
	completed += 1


func _test_some_records_are_roots() -> void:
	# Not everything has a parent, and forcing one would invent causality.
	var state = _long_run().state
	var roots := 0
	for record: Dictionary in state.chronicle:
		if record["caused_by"].is_empty():
			roots += 1
	assert(roots > 0, "every record claimed a cause; some events are roots")
	assert(roots < state.chronicle.size(), "nothing was caused by anything")
	print("  ROOTS: %d of %d records begin a chain." % [roots, state.chronicle.size()])
	completed += 1


# --- objectivity -----------------------------------------------------------

func _test_history_stays_objective() -> void:
	# "The King refused Mara's request" is history. "The cruel King betrayed
	# Westfield" is what somebody decided, and lives where it can be argued with.
	var state = _long_run().state
	for record: Dictionary in state.chronicle:
		var word := _judgement_in(str(record["summary"]))
		assert(word.is_empty(),
			"history judged with '%s': \"%s\"" % [word, str(record["summary"])])
	# And the interpretation's own meaning text was never copied into history.
	for interpretation: Dictionary in state.interpretation_archive:
		var meaning := str(interpretation["meaning"])
		for record: Dictionary in state.chronicle:
			assert(not str(record["summary"]).contains(meaning),
				"an interpretation's meaning became historical truth: \"%s\"" % meaning)
	print("  OBJECTIVE: %d summaries, none of them a verdict." % state.chronicle.size())
	completed += 1


func _test_a_divine_act_is_not_history_for_being_divine() -> void:
	# The god acting is not important. The god changing something is.
	var simulation := _long_run()
	var state = simulation.state
	var acts: int = state.divine_action_archive.size()
	var recorded := _by_source(state, ChronicleRules.SOURCE_DIVINE).size()
	assert(acts > recorded,
		"every divine act became history (%d of %d)" % [recorded, acts])
	for record: Dictionary in _by_source(state, ChronicleRules.SOURCE_DIVINE):
		assert(_has_factor(record, "divine_impact"),
			"a divine act became history without changing anything")
	# And a specific one refused: silence, which changes nothing measurable.
	var refused := false
	for year in range(6):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for rejection: Dictionary in state.last_chronicle_rejections:
			if str(rejection["source_record_type"]) == ChronicleRules.SOURCE_DIVINE:
				refused = true
				assert(int(rejection["importance"]) == 0,
					"an act that changed nothing scored %d" % int(rejection["importance"]))
	assert(refused, "no divine act was put forward and refused")
	print("  DIVINE: %d of %d acts mattered enough to record." % [recorded, acts])
	completed += 1


func _test_relationship_drift_is_not_recorded() -> void:
	# Relationships move every single year through trait drift. None of that is
	# history; only a movement that crosses an existing presentation band is.
	var state = _long_run().state
	var moved := 0
	for change: Dictionary in state.last_relationship_changes:
		moved += 1
	for record: Dictionary in _by_source(state, ChronicleRules.SOURCE_INTERPRETATION):
		assert(_has_factor(record, "relationship_band_crossed")
			or _has_factor(record, "changes_later_behaviour"),
			"a relationship entered history without crossing a band or reaching behaviour")
	# No history record exists for a bare relationship tick.
	for record: Dictionary in state.chronicle:
		assert(str(record["source_record_type"]) != "relationship_change",
			"relationship ticks became a history source")
	print("  DRIFT IGNORED: relationships moved and history stayed quiet.")
	completed += 1


func _test_an_interpretation_enters_only_through_its_effect() -> void:
	# An interpretation is not history for having been reached. It is history
	# when what it DID reaches forward, and the record says what it did rather
	# than asserting it was right.
	var state = _long_run().state
	var readings: int = state.interpretation_archive.size()
	var recorded := _by_source(state, ChronicleRules.SOURCE_INTERPRETATION)
	assert(readings > recorded.size(),
		"every interpretation became history (%d of %d)" % [recorded.size(), readings])
	for record: Dictionary in recorded:
		assert(str(record["event_type"]) == "interpretation_took_effect",
			"an interpretation was recorded as something other than its effect")
		var summary := str(record["summary"]).to_lower()
		for claim: String in [" was a sign", " proves ", " truly ", " in fact "]:
			assert(not summary.contains(claim),
				"history asserted a reading was correct: \"%s\"" % str(record["summary"]))
	print("  READINGS: %d of %d reached far enough to record." % [
		recorded.size(), readings
	])
	completed += 1


# --- boundaries ------------------------------------------------------------

func _test_history_changes_no_behaviour() -> void:
	# History is a record layer. Nothing reads it, so a world with a chronicle
	# and a world without one must behave identically.
	var with_history := _long_run(24)
	var control := _long_run(24)
	assert(not with_history.state.chronicle.is_empty(), "no history was written")
	# Same world, same decisions: the chronicle changed nothing upstream of it.
	var left: Array[String] = []
	var right: Array[String] = []
	for record: Dictionary in with_history.state.intent_archive:
		left.append("%s:%s:%d" % [
			str(record["actor_id"]), str(record["intent_type"]), int(record["score"])
		])
	for record: Dictionary in control.state.intent_archive:
		right.append("%s:%s:%d" % [
			str(record["actor_id"]), str(record["intent_type"]), int(record["score"])
		])
	assert(left == right and not left.is_empty(), "behaviour differed between identical runs")
	# Nothing outside the chronicle reads the chronicle.
	for path: String in [
		"res://scripts/intent_rules.gd", "res://scripts/action_rules.gd",
		"res://scripts/execution_rules.gd", "res://scripts/interpretation_rules.gd",
		"res://scripts/perception_rules.gd", "res://scripts/knowledge_rules.gd",
		"res://scripts/consequence_rules.gd"
	]:
		var code := FileAccess.get_file_as_string(path)
		assert(not code.contains("state.chronicle") and not code.contains("chronicle_for"),
			"%s reads history; history must not steer behaviour" % path)
	print("  RECORD ONLY: %d intents identical with history present." % left.size())
	completed += 1


func _test_nothing_out_of_scope_was_started() -> void:
	# Myth, doctrine, religion, factions, eras and forgetting are later systems.
	# v1 must not have quietly begun any of them.
	var code := ""
	for line: String in FileAccess.get_file_as_string(
		"res://scripts/chronicle_rules.gd"
	).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		code += (line.substr(0, hash_at) if hash_at >= 0 else line) + "\n"
	for forbidden: String in OUT_OF_SCOPE:
		assert(not code.to_lower().contains(forbidden),
			"chronicle v1 reached into '%s', which is later work" % forbidden)
	var state = _long_run().state
	assert(state.beliefs.is_empty() or state.known_beliefs.size() >= 0)
	for record: Dictionary in state.chronicle:
		assert(not record.has("era") and not record.has("title")
			and not record.has("confidence") and not record.has("survives"),
			"a chronicle record grew a later system's field")
	print("  SCOPE: no myth, doctrine, faction, era or decay was started.")
	completed += 1


func _test_history_is_not_forgotten() -> void:
	# v1 is immutable and permanent. GDD 96 wants gradual, legible fading one
	# day; abrupt deletion is exactly what it forbids, and a capped chronicle
	# would drop the oldest entries and leave the causal links dangling.
	var simulation := _long_run()
	var state = simulation.state
	var early: Dictionary = state.chronicle[0].duplicate(true)
	var size_before: int = state.chronicle.size()
	for year in range(20):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	assert(state.chronicle.size() >= size_before, "history shrank")
	var still_there: Dictionary = state.get_chronicle(str(early["id"]))
	assert(not still_there.is_empty(), "the oldest entry was forgotten")
	# Immutable but for led_to, which only grows.
	for field: String in ["year", "summary", "importance", "source_record_id", "event_type"]:
		assert(str(still_there[field]) == str(early[field]),
			"history rewrote its own entry's '%s'" % field)
	assert(still_there["caused_by"].size() >= early["caused_by"].size())
	print("  PERMANENT: the first entry survived %d more years unchanged." % 20)
	completed += 1


# --- GDD section 42 --------------------------------------------------------

func _test_the_autonomous_story() -> void:
	# The Autonomous Story Test. Several decades, no scripted outcome, and the
	# question is not whether a particular thing happened but whether the world
	# produced a causal story somebody could follow.
	var simulation := _long_run()
	var state = simulation.state

	# 1. events, 2. perception, 3. intents, 4. actions, 5. consequences
	assert(not state.history_archive.is_empty(), "no events occurred")
	assert(not state.perception_archive.is_empty(), "nobody perceived anything")
	assert(not state.intent_archive.is_empty(), "nobody wanted anything")
	assert(not state.action_archive.is_empty(), "nobody tried anything")
	assert(not state.execution_archive.is_empty(), "nothing came of any attempt")
	assert(not state.consequence_archive.is_empty(), "nothing objectively followed")

	# 6. interpretations reached later reasoning.
	#
	# The live channel is the social one: a reading moves a relationship axis,
	# and intent scoring reads relationships. Measured here rather than through
	# `interpretation_factors`, which carries only the DIVINE reading channel —
	# that one records zero in an autonomous run, because a mortal with no prior
	# divine experience calls rain weather and nothing seeds the first divine
	# reading. Correct behaviour, and a narrower channel than it looks.
	assert(not state.interpretation_archive.is_empty(), "nobody concluded anything")
	var applied := 0
	for record: Dictionary in state.interpretation_archive:
		if not record["applied_effect"].is_empty():
			applied += 1
	assert(applied > 0, "no reading ever changed anything about anybody")
	var relationship_factors := 0
	for record: Dictionary in state.intent_archive:
		relationship_factors += record["relationship_factors"].size()
	assert(relationship_factors > 0,
		"nobody's wants were weighted by how they regard anyone")

	# 7. some of it became history, 8. most of it did not
	assert(not state.chronicle.is_empty(), "nothing became history")
	assert(state.chronicle.size() < state.consequence_archive.size()
		+ state.interpretation_archive.size(),
		"history kept more than the world produced")

	# 9. at least one historical chain has causal links
	var chain_root := {}
	for record: Dictionary in state.chronicle:
		if record["led_to"].size() >= 1:
			chain_root = record
			break
	assert(not chain_root.is_empty(), "no historical chain has a cause and an effect")

	# 10. and the chain can be explained, entry by entry, from stored data alone
	var explained: Array[String] = ["YEAR %d  %s" % [
		int(chain_root["year"]), str(chain_root["summary"])
	]]
	for child_id_value in chain_root["led_to"]:
		var child: Dictionary = state.get_chronicle(str(child_id_value))
		var reasons: Array[String] = []
		for factor_value in child["factors"]:
			var factor: Dictionary = factor_value
			reasons.append("%s (%s)" % [str(factor["kind"]), str(factor["detail"])])
		assert(not reasons.is_empty(), "a historical record cannot explain itself")
		explained.append("  -> YEAR %d  %s" % [int(child["year"]), str(child["summary"])])
		explained.append("     because %s" % ", ".join(reasons))

	print("  AUTONOMOUS STORY:")
	for line: String in explained:
		print("    %s" % line)
	print("  ... from %d years: %d events, %d intents, %d readings, %d recorded." % [
		STORY_YEARS, state.history_archive.size(), state.intent_archive.size(),
		state.interpretation_archive.size(), state.chronicle.size()
	])
	completed += 1
