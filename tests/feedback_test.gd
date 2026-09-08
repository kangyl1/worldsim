extends SceneTree

# Situational Choices & Theatrical Feedback v1.
#
# The simulation had grown deeper than the game could show. This layer decides
# what the player is told and how it is worded — and its whole risk is that a
# presentation layer is the easiest place in a project to start lying. A
# headline saying a bond has broken is worth nothing if the trust behind it
# moved by one point inside the same band.
#
# So most of this suite is about grounding. Presentation may amplify what is
# true; it may never assert what is not, invent a motive, or change anything. A
# line with no state behind it must simply not appear.
#
# The other half is variety that is real rather than cosmetic: the same
# execution result should read differently when the history behind it differs,
# and two mortals who concluded different things should say different things.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 22

const ACTION_VOCABULARY := ["give", "ask", "tell", "support", "oppose", "observe", "wait"]
const INTENT_VOCABULARY := [
	"help", "protect", "acquire", "learn", "influence",
	"connect", "distance", "resolve", "preserve", "wait"
]
const OUT_OF_SCOPE := [
	"religion", "doctrine", "faction", "politic", "procedural", "economy"
]

var completed := 0


func _init() -> void:
	_test_a_primitive_gets_a_contextual_label()
	_test_the_same_primitive_reads_differently_with_context()
	_test_identical_parameters_give_identical_labels()
	_test_a_repeated_attempt_is_worded_as_repeated()
	_test_a_first_refusal_and_a_repeated_one_differ()
	_test_a_stronger_line_needs_the_belief_behind_it()
	_test_an_important_reading_becomes_character_voice()
	_test_two_mortals_who_disagree_say_different_things()
	_test_a_belief_taking_hold_is_surfaced()
	_test_a_belief_breaking_is_surfaced()
	_test_a_band_crossing_is_surfaced()
	_test_a_small_relationship_movement_is_not()
	_test_a_crisis_is_surfaced()
	_test_an_ordinary_year_is_not()
	_test_a_divine_act_reports_itself_clearly()
	_test_the_feed_is_bounded()
	_test_every_item_names_the_record_it_came_from()

	_test_feedback_changes_no_state()
	_test_feedback_invents_no_vocabulary()
	_test_no_hidden_cause_or_raw_score_leaks()
	_test_no_line_exists_without_state_behind_it()
	_test_the_simulation_still_runs_the_same()

	if completed != EXPECTED_TESTS:
		push_error("Feedback suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("FEEDBACK TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("FEEDBACK TEST PASSED: the world is visible, and still telling the truth.")
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


func _action(actor_id: String, target_id: String, action_type: String,
		topic_id: String = "", subject_id: String = "") -> Dictionary:
	return {
		"action_type": action_type, "actor_id": actor_id, "target_id": target_id,
		"topic_id": topic_id, "subject_id": subject_id
	}


# Record an execution directly, so a history of repeated attempts exists
# without waiting for the world to produce one.
func _log_attempt(simulation: Object, actor_id: String, target_id: String,
		action_type: String, result_type: String) -> Dictionary:
	var state = simulation.state
	var record := {
		"id": "execution_%d_%s_%s_%d" % [
			state.year, actor_id, target_id, state.execution_archive.size()
		],
		"year": state.year, "actor_id": actor_id, "actor_name": actor_id,
		"target_id": target_id, "target_kind": "person", "action_type": action_type,
		"action_id": "", "intent_id": "", "subject_id": target_id, "topic_id": "",
		"resource_type": "", "outcome": "failure" if result_type == "request_refused" else "success",
		"result_type": result_type, "effects_applied": [], "factors": [],
		"reasons": [], "score": 0
	}
	state.execution_archive.append(record)
	return record


func _hold_belief(simulation: Object, holder_id: String, proposition: String,
		subject_id: String, confidence: int) -> void:
	var state = simulation.state
	state.record_belief({
		"holder_id": holder_id, "proposition": proposition, "subject_id": subject_id,
		"confidence": confidence, "support": 4, "contradiction": 0,
		"first_year": state.year - 2, "last_updated_year": state.year,
		"source_interpretation_ids": ["seed"],
		"status": BeliefRules.STATUS_HELD if confidence >= BeliefRules.ESTABLISHED_CONFIDENCE
			else BeliefRules.STATUS_FORMING
	})


# The `last_*` stores are typed Array[Dictionary], so a batch has to be typed
# before it can be assigned.
func _batch(record: Dictionary) -> Array[Dictionary]:
	var typed: Array[Dictionary] = [record]
	return typed


# Clear the year's other channels, so a test asserting one kind of development
# is not crowded out of the three-item feed by whatever the settling years
# happened to produce. The cap is real and is asserted on its own elsewhere.
func _isolate(simulation: Object) -> void:
	var state = simulation.state
	var empty: Array[Dictionary] = []
	state.last_chronicle_entries = empty.duplicate()
	state.last_belief_updates = empty.duplicate()
	state.last_relationship_changes = empty.duplicate()
	state.last_interpretations = empty.duplicate()
	state.last_executions = empty.duplicate()


func _by_category(items: Array, category: String) -> Dictionary:
	for item: Dictionary in items:
		if str(item["category"]) == category:
			return item
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


# --- situational labels ----------------------------------------------------

func _test_a_primitive_gets_a_contextual_label() -> void:
	var simulation := _sim()
	var state = simulation.state
	var label: String = simulation.feedback_rules.label_for_action(
		state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	)
	assert(label.contains("The King"), "the label does not name who is being asked")
	assert(label.contains("Westfield"), "the label does not name what it is about")
	assert(not label.contains("ask"), "the raw verb leaked into the label: %s" % label)
	assert(label.length() < 90, "the label is not short: %s" % label)
	print("  LABEL: \"%s\"" % label)
	completed += 1


func _test_the_same_primitive_reads_differently_with_context() -> void:
	# One verb, three situations, three sentences — and no new verb anywhere.
	var simulation := _sim()
	var state = simulation.state
	var rules = simulation.feedback_rules
	var labels: Array[String] = [
		rules.label_for_action(state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")),
		rules.label_for_action(state, _action("mara", "aster_king", "ask", "danger_unrest", "aster")),
		rules.label_for_action(state, _action("mara", "aster_king", "observe", "danger_unrest", "aster"))
	]
	for index in range(labels.size()):
		for other in range(index + 1, labels.size()):
			assert(labels[index] != labels[other],
				"two different situations produced the same label: %s" % labels[index])
	print("  CONTEXTUAL: %s / %s" % [labels[0], labels[1]])
	completed += 1


func _test_identical_parameters_give_identical_labels() -> void:
	# No fake variety. Two actions differing in nothing must read the same,
	# because a difference in wording must mean a difference in the world.
	var simulation := _sim()
	var state = simulation.state
	var rules = simulation.feedback_rules
	var one := _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	var two := _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	assert(rules.label_for_action(state, one) == rules.label_for_action(state, two),
		"identical parameters produced different wording")
	print("  NO FAKE VARIETY: identical parameters, identical wording.")
	completed += 1


func _test_a_repeated_attempt_is_worded_as_repeated() -> void:
	var simulation := _sim()
	var state = simulation.state
	var rules = simulation.feedback_rules
	var plain: String = rules.label_for_action(
		state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	)
	_log_attempt(simulation, "mara", "aster_king", "ask", "request_refused")
	var second: String = rules.label_for_action(
		state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	)
	assert(second != plain, "a repeated attempt read exactly like the first")
	assert(second.contains("again"), "the repetition is not expressed: %s" % second)
	for extra in range(3):
		_log_attempt(simulation, "mara", "aster_king", "ask", "request_refused")
	var many: String = rules.label_for_action(
		state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")
	)
	assert(many != second, "a long history read like a single repetition")
	print("  HISTORY IN WORDING: \"%s\" -> \"%s\" -> \"%s\"" % [plain, second, many])
	completed += 1


# --- outcome presentation --------------------------------------------------

func _test_a_first_refusal_and_a_repeated_one_differ() -> void:
	# The same execution RESULT, two different scenes, decided by the archive.
	var first := _sim()
	_settle(first, 4)
	_isolate(first)
	# Genuinely the first: the settling years may already have produced an ask
	# between these two, and "first refusal" has to mean what it says.
	var no_history: Array[Dictionary] = []
	first.state.execution_archive = no_history
	first.state.last_executions = _batch(
		_log_attempt(first, "mara", "aster_king", "ask", "request_refused")
	)
	var first_item := _by_category(first.feedback_rules.developments(first.state), "request_refused")
	assert(not first_item.is_empty(), "a refusal produced no development at all")

	var later := _sim()
	_settle(later, 4)
	_isolate(later)
	for prior in range(3):
		_log_attempt(later, "mara", "aster_king", "ask", "request_refused")
	later.state.last_executions = _batch(
		_log_attempt(later, "mara", "aster_king", "ask", "request_refused")
	)
	var later_item := _by_category(later.feedback_rules.developments(later.state), "request_refused")
	assert(not later_item.is_empty(), "a repeated refusal produced no development")

	assert(str(first_item["headline"]) != str(later_item["headline"]),
		"the fourth refusal reads exactly like the first")
	assert(str(later_item["headline"]).contains("AGAIN"))
	assert(bool(later_item["context"]["repeated_occurrence"]))
	assert(not bool(first_item["context"]["repeated_occurrence"]))
	print("  SAME RESULT, TWO SCENES: \"%s\" / \"%s\"" % [
		str(first_item["headline"]), str(later_item["headline"])
	])
	completed += 1


func _test_a_stronger_line_needs_the_belief_behind_it() -> void:
	# The load-bearing grounding test. "No longer expects his help" is a claim
	# about a conviction, and may appear only when the conviction is held.
	var without := _sim()
	_settle(without, 4)
	_isolate(without)
	for prior in range(3):
		_log_attempt(without, "mara", "aster_king", "ask", "request_refused")
	without.state.last_executions = _batch(
		_log_attempt(without, "mara", "aster_king", "ask", "request_refused")
	)
	var bare := _by_category(without.feedback_rules.developments(without.state), "request_refused")
	assert(not bare.is_empty(), "the control refusal produced no development")
	assert(not str(bare["body"]).contains("no longer expects"),
		"presentation claimed a conviction the mortal does not hold")

	var with_belief := _sim()
	_settle(with_belief, 4)
	_isolate(with_belief)
	_hold_belief(with_belief, "mara", BeliefRules.IS_UNRELIABLE, "aster_king", 70)
	for prior in range(3):
		_log_attempt(with_belief, "mara", "aster_king", "ask", "request_refused")
	with_belief.state.last_executions = _batch(
		_log_attempt(with_belief, "mara", "aster_king", "ask", "request_refused")
	)
	var grounded := _by_category(
		with_belief.feedback_rules.developments(with_belief.state), "request_refused"
	)
	assert(not grounded.is_empty(), "the repeated refusal produced no development")
	assert(str(grounded["body"]).contains("no longer expects"),
		"a held belief was not reflected in the scene")
	print("  GROUNDED: the stronger line appears only with the belief behind it.")
	completed += 1


# --- voices ----------------------------------------------------------------

func _test_an_important_reading_becomes_character_voice() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	state.last_interpretations = _batch({
		"id": "interpretation_test", "year": state.year, "observer_id": "mara",
		"source_knowledge_id": "k", "topic": "weather_rain", "subject_id": "westfield",
		"actor_id": "", "target_id": "", "role": "witness",
		"interpretation_type": "rain_divine_help", "meaning": "m", "confidence": 80,
		"score": 0, "factors": [], "considered": [], "planned_effect": {},
		"applied_effect": {}, "effect_reason": ""
	})
	var item := _by_category(simulation.feedback_rules.developments(state), "interpretation")
	assert(not item.is_empty(), "an important reading produced no reaction")
	assert(str(item["voice"]) == FeedbackRules.VOICE_CHARACTER)
	assert(str(item["headline"]) == "MARA")
	assert(str(item["body"]).begins_with("\""), "character voice is not speech: %s" % str(item["body"]))
	assert(str(item["body"]).length() < 70, "the line is a monologue")
	print("  CHARACTER VOICE: %s %s" % [str(item["headline"]), str(item["body"])])
	completed += 1


func _test_two_mortals_who_disagree_say_different_things() -> void:
	# Same fact, two conclusions, two lines — and neither mortal is hardcoded as
	# the believer. The mapping is from interpretation type to line, so swapping
	# who concluded what swaps who says what.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	var readings: Array[Dictionary] = []
	for pair: Array in [["mara", "rain_divine_help"], ["aster_king", "rain_natural_weather"]]:
		readings.append({
			"id": "interpretation_%s" % str(pair[0]), "year": state.year,
			"observer_id": str(pair[0]), "source_knowledge_id": "k",
			"topic": "weather_rain", "subject_id": "westfield", "actor_id": "",
			"target_id": "", "role": "witness", "interpretation_type": str(pair[1]),
			"meaning": "m", "confidence": 80, "score": 0, "factors": [],
			"considered": [], "planned_effect": {}, "applied_effect": {}, "effect_reason": ""
		})
	state.last_interpretations = readings
	# `rain_natural_weather` is deliberately not "news", so compare the lines
	# the voice table would give each of them.
	var rules = simulation.feedback_rules
	var believer := str(FeedbackRules.CHARACTER_LINES["rain_divine_help"])
	var sceptic := str(FeedbackRules.CHARACTER_LINES["rain_natural_weather"])
	assert(believer != sceptic, "two different conclusions share one line")
	var surfaced := _by_category(rules.developments(state), "interpretation")
	assert(not surfaced.is_empty(), "neither reading was surfaced")
	assert(str(surfaced["actor_id"]) == "mara",
		"the wrong mortal was surfaced for the divine reading")
	assert(str(surfaced["body"]).contains(believer))
	print("  DISAGREEMENT: \"%s\" / \"%s\"" % [believer, sceptic])
	completed += 1


# --- belief, relationship and world feedback -------------------------------

func _test_a_belief_taking_hold_is_surfaced() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	state.last_belief_updates = _batch({
		"year": state.year, "belief_id": "b", "holder_id": "mara",
		"proposition": BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "subject_id": "",
		"change": "reinforced", "before": BeliefRules.ESTABLISHED_CONFIDENCE - 5,
		"after": BeliefRules.ESTABLISHED_CONFIDENCE + 2, "delta": 7, "factors": []
	})
	var item := _by_category(simulation.feedback_rules.developments(state), "belief_formed")
	assert(not item.is_empty(), "a belief taking hold was not surfaced")
	assert(str(item["headline"]) == "A BELIEF TAKES ROOT")
	assert(str(item["body"]).contains("Mara"))
	assert(int(item["priority"]) == FeedbackRules.PRIORITY_HIGH)
	print("  BELIEF: %s — %s" % [str(item["headline"]), str(item["body"])])
	completed += 1


func _test_a_belief_breaking_is_surfaced() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	state.last_belief_updates = _batch({
		"year": state.year, "belief_id": "b", "holder_id": "mara",
		"proposition": BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "subject_id": "",
		"change": "weakened", "before": BeliefRules.ESTABLISHED_CONFIDENCE + 3,
		"after": BeliefRules.ESTABLISHED_CONFIDENCE - 4, "delta": -7, "factors": []
	})
	var item := _by_category(simulation.feedback_rules.developments(state), "belief_broken")
	assert(not item.is_empty(), "a belief coming apart was not surfaced")
	assert(str(item["headline"]) == "DOUBT RETURNS")
	print("  DOUBT: %s" % str(item["body"]))
	completed += 1


func _test_a_band_crossing_is_surfaced() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	# Trust falling across a presentation band boundary.
	var low := 10
	var high := 60
	assert(PresentationRules.relationship_label("trust", low)
		!= PresentationRules.relationship_label("trust", high),
		"this test needs two values in different bands")
	state.last_relationship_changes = _batch({
		"relationship_id": "mara::aster_king", "source_id": "mara", "target_id": "aster_king",
		"source_traits": [], "target_traits": [],
		"before": {"trust": high, "fear": 0, "respect": 30, "hostility": 5},
		"after": {"trust": low, "fear": 0, "respect": 30, "hostility": 5},
		"changes": {"trust": low - high}
	})
	var item := _by_category(
		simulation.feedback_rules.developments(state), "relationship_band_crossed"
	)
	assert(not item.is_empty(), "a band crossing was not surfaced")
	assert(str(item["body"]).contains("weakening"), "the direction is wrong: %s" % str(item["body"]))
	assert(bool(item["context"]["relationship_band_crossed"]))
	print("  RELATIONSHIP: %s — %s" % [str(item["headline"]), str(item["body"])])
	completed += 1


func _test_a_small_relationship_movement_is_not() -> void:
	# The noise filter. Trust moving inside its own band is not news, and
	# announcing it would make every year look like a crisis.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 4)
	_isolate(simulation)
	var before := 50
	var after := 52
	assert(PresentationRules.relationship_label("trust", before)
		== PresentationRules.relationship_label("trust", after),
		"this test needs two values in the SAME band")
	state.last_relationship_changes = _batch({
		"relationship_id": "mara::aster_king", "source_id": "mara", "target_id": "aster_king",
		"source_traits": [], "target_traits": [],
		"before": {"trust": before, "fear": 0, "respect": 30, "hostility": 5},
		"after": {"trust": after, "fear": 0, "respect": 30, "hostility": 5},
		"changes": {"trust": after - before}
	})
	var item := _by_category(
		simulation.feedback_rules.developments(state), "relationship_band_crossed"
	)
	assert(item.is_empty(), "a two-point movement inside one band was announced")
	print("  NOISE FILTER: %d -> %d stayed quiet." % [before, after])
	completed += 1


func _test_a_crisis_is_surfaced() -> void:
	var simulation := _sim()
	var state = simulation.state
	var seen := false
	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for item: Dictionary in simulation.feedback_rules.developments(state):
			if str(item["category"]) in ["crisis_entered", "crisis_lifted"]:
				seen = true
				assert(int(item["priority"]) == FeedbackRules.PRIORITY_HIGH)
				assert(str(item["source_record_type"]) == "chronicle")
	assert(seen, "thirty years of crises produced no crisis feedback")
	print("  CRISIS: settlement crises reach the player.")
	completed += 1


func _test_an_ordinary_year_is_not() -> void:
	# A quiet year must be allowed to stay quiet; the contrast is the point.
	var simulation := _sim()
	var state = simulation.state
	var quiet := 0
	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		if simulation.feedback_rules.developments(state).is_empty():
			quiet += 1
	assert(quiet > 0, "every single year produced a development; nothing is quiet")
	print("  QUIET YEARS: %d of 30 had nothing worth reporting." % quiet)
	completed += 1


func _test_a_divine_act_reports_itself_clearly() -> void:
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 6)
	state.current_event_location_id = "aster"
	# Parched, so there is a world change to report. Rain on healthy ground
	# legitimately reports none.
	state.set_water("aster", WorldState.WATER_MIN)
	var result := simulation.resolve_action("send_rain", "aster") as Dictionary
	var feedback: Dictionary = simulation.feedback_rules.divine_feedback(state, result)
	assert(not feedback.is_empty(), "the god acted and the player was told nothing")
	assert(str(feedback["headline"]).begins_with("YOU "))
	assert(str(feedback["pipeline"]) == DivineActionRules.PIPELINE_SHARED,
		"divine feedback was read from the legacy path")
	assert(not feedback["changes"].is_empty(), "no world change was reported")
	for line: String in feedback["changes"]:
		# Qualitative, matching the rest of the player interface.
		for digit: String in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
			assert(not line.contains(digit), "a raw band number reached the player: %s" % line)
	print("  DIVINE: %s / %s" % [str(feedback["headline"]), str(feedback["changes"][0])])
	completed += 1


func _test_the_feed_is_bounded() -> void:
	# Asserted against a LITERAL as well as the constant. Checking only
	# `<= MAX_DEVELOPMENTS` is self-referential: raising the constant would move
	# the goalpost with it, and a mutation test proved exactly that.
	assert(FeedbackRules.MAX_DEVELOPMENTS <= 3,
		"the feed cap grew to %d; a year's news should stay a handful"
			% FeedbackRules.MAX_DEVELOPMENTS)
	var simulation := _sim()
	var state = simulation.state
	var worst := 0
	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		var items: Array = simulation.feedback_rules.developments(state)
		worst = maxi(worst, items.size())
		assert(items.size() <= FeedbackRules.MAX_DEVELOPMENTS,
			"%d developments in one year" % items.size())
	assert(worst <= 3, "a year surfaced %d developments; that is a wall of text" % worst)
	print("  BOUNDED: busiest year surfaced %d, cap %d." % [
		worst, FeedbackRules.MAX_DEVELOPMENTS
	])
	completed += 1


func _test_every_item_names_the_record_it_came_from() -> void:
	var simulation := _sim()
	var state = simulation.state
	var required := [
		"year", "priority", "category", "voice", "headline", "body",
		"source_record_type", "source_record_id", "actor_id", "target_id", "context"
	]
	var checked := 0
	for year in range(24):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for item: Dictionary in simulation.feedback_rules.developments(state):
			checked += 1
			for field: String in required:
				assert(item.has(field), "a feedback item is missing '%s'" % field)
			for field: String in item.keys():
				assert(str(field) in required,
					"the record grew a field with no stated use: %s" % str(field))
			assert(not str(item["source_record_id"]).is_empty(),
				"an item points at no record")
			assert(not str(item["headline"]).is_empty() and not str(item["body"]).is_empty())
			assert(int(item["priority"]) in [
				FeedbackRules.PRIORITY_HIGH, FeedbackRules.PRIORITY_MEDIUM,
				FeedbackRules.PRIORITY_LOW
			])
			assert(str(item["voice"]) in [
				FeedbackRules.VOICE_CHARACTER, FeedbackRules.VOICE_CHRONICLER,
				FeedbackRules.VOICE_WORLD
			])
	assert(checked > 0, "nothing was surfaced, so nothing is proven")
	print("  TRACEABLE: %d items, each pointing back at a record." % checked)
	completed += 1


# --- what presentation must never do ---------------------------------------

func _test_feedback_changes_no_state() -> void:
	# The purity guarantee. Asking what to show must not change the world.
	var simulation := _sim()
	var state = simulation.state
	_settle(simulation, 12)
	var before := {
		"relationships": str(state.relationships),
		"beliefs": str(state.mortal_beliefs),
		"chronicle": state.chronicle.size(),
		"interpretations": state.interpretation_archive.size(),
		"executions": state.execution_archive.size(),
		"knowledge": str(state.get_all_knowledge("mara")),
		"history": state.history_archive.size(),
		"year": state.year
	}
	for repeat in range(5):
		simulation.feedback_rules.developments(state)
		simulation.feedback_rules.label_for_action(
			state, _action("mara", "aster_king", "ask", "food_shortage", "westfield")
		)
	assert(str(state.relationships) == before["relationships"], "feedback moved a relationship")
	assert(str(state.mortal_beliefs) == before["beliefs"], "feedback changed a belief")
	assert(state.chronicle.size() == before["chronicle"], "feedback wrote history")
	assert(state.interpretation_archive.size() == before["interpretations"])
	assert(state.execution_archive.size() == before["executions"])
	assert(str(state.get_all_knowledge("mara")) == before["knowledge"], "feedback taught somebody")
	assert(state.history_archive.size() == before["history"])
	assert(state.year == before["year"], "feedback advanced time")
	print("  PURE: five full passes changed nothing at all.")
	completed += 1


func _test_feedback_invents_no_vocabulary() -> void:
	var simulation := _sim()
	var state = simulation.state
	for year in range(24):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	for record: Dictionary in state.action_archive:
		assert(str(record["action_type"]) in ACTION_VOCABULARY,
			"a new action verb appeared: %s" % str(record["action_type"]))
	for record: Dictionary in state.intent_archive:
		assert(str(record["intent_type"]) in INTENT_VOCABULARY,
			"a new intent appeared: %s" % str(record["intent_type"]))
	# And the presentation layer knows only the seven verbs.
	for verb in FeedbackRules.ACTION_PHRASES.keys():
		assert(str(verb) in ACTION_VOCABULARY,
			"presentation names a verb the simulation does not have: %s" % str(verb))
	var code := _code_of("res://scripts/feedback_rules.gd").to_lower()
	for forbidden: String in OUT_OF_SCOPE:
		assert(not code.contains(forbidden), "feedback reached into '%s'" % forbidden)
	print("  NO NEW VOCABULARY: seven verbs, ten intents, no new systems.")
	completed += 1


func _test_no_hidden_cause_or_raw_score_leaks() -> void:
	# Presentation may read the simulation, but must not hand the player the
	# machinery: no scores, no truth metadata, no divine causation.
	var code := _code_of("res://scripts/feedback_rules.gd")
	for forbidden: String in [
		"objective_truth_state", "truth_state", "divine_action_archive",
		"intent_archive", '"score"', "base_score", "importance_threshold"
	]:
		assert(not code.contains(forbidden),
			"feedback can reach '%s'" % forbidden)
	var simulation := _sim()
	var state = simulation.state
	for year in range(24):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for item: Dictionary in simulation.feedback_rules.developments(state):
			var text := "%s %s" % [str(item["headline"]), str(item["body"])]
			for leak: String in ["score", "confidence ", "trust:", "+1", "-1", "delta"]:
				assert(not text.to_lower().contains(leak),
					"raw machinery reached the player: %s" % text)
	print("  NO LEAK: no score, delta or truth flag reaches the player.")
	completed += 1


func _test_no_line_exists_without_state_behind_it() -> void:
	# Every character line must correspond to a real interpretation type, and
	# every belief sentence to a real proposition. A template with nothing
	# behind it is a line waiting to be said about nothing.
	var rules := InterpretationRules.new()
	for reading_value in FeedbackRules.CHARACTER_LINES.keys():
		var reading := str(reading_value)
		var known := false
		for topic: String in rules.covered_topics():
			for role_value in (rules.CANDIDATES.get(topic, rules.WORLD_CANDIDATES.get(topic, {}))).values():
				for candidate_value in role_value:
					if str((candidate_value as Dictionary)["id"]) == reading:
						known = true
		if reading == "unclear_what_happened":
			known = true
		assert(known, "a character line exists for a reading nothing produces: %s" % reading)
	for proposition_value in FeedbackRules.BELIEF_SENTENCES.keys():
		assert(str(proposition_value) in BeliefRules.PROPOSITIONS,
			"a belief sentence exists for no proposition: %s" % str(proposition_value))
	for proposition_value in FeedbackRules.BELIEF_LOST_SENTENCES.keys():
		assert(str(proposition_value) in BeliefRules.PROPOSITIONS)
	for reading: String in FeedbackRules.NOTABLE_INTERPRETATIONS:
		assert(FeedbackRules.CHARACTER_LINES.has(reading),
			"a reading is marked notable with no line to say: %s" % reading)
	print("  GROUNDED TEMPLATES: %d lines, all for readings the world produces."
		% FeedbackRules.CHARACTER_LINES.size())
	completed += 1


func _test_the_simulation_still_runs_the_same() -> void:
	# Presentation is not a second decision engine. Two identical worlds behave
	# identically whether or not anybody asks what to show.
	var watched := _sim()
	var control := _sim()
	for year in range(20):
		watched.resolve_action("do_nothing")
		watched.advance_year()
		watched.feedback_rules.developments(watched.state)
		control.resolve_action("do_nothing")
		control.advance_year()
	var left: Array[String] = []
	var right: Array[String] = []
	for record: Dictionary in watched.state.intent_archive:
		left.append("%s:%s:%d" % [
			str(record["actor_id"]), str(record["intent_type"]), int(record["score"])
		])
	for record: Dictionary in control.state.intent_archive:
		right.append("%s:%s:%d" % [
			str(record["actor_id"]), str(record["intent_type"]), int(record["score"])
		])
	assert(left == right and not left.is_empty(),
		"asking what to show changed what the world did")
	assert(watched.state.chronicle.size() == control.state.chronicle.size())
	assert(str(watched.state.mortal_beliefs) == str(control.state.mortal_beliefs))
	print("  NOT A DECISION ENGINE: %d intents identical with feedback running." % left.size())
	completed += 1
