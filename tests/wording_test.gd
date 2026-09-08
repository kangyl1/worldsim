extends SceneTree

# Social / Action Wording Cleanup v1.
#
# Fix the sentence, not the simulation.
#
# Every string here is derived from records the simulation already wrote, and
# this suite guards two things about that derivation. First, that it never
# leaks the vocabulary the code thinks in — "The King's reading of
# food_shortage" is an id in a sentence. Second, that improving a sentence
# never quietly improves the world: the actor, target and subject ids behind
# every claim are asserted unchanged, because the tempting way to tidy
# "concerning The King" is to stop recording the subject, and that would be
# deleting simulation truth to make the prose read better.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")
const ConsequenceRulesScript = preload("res://scripts/consequence_rules.gd")
const ActionRulesScript = preload("res://scripts/action_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 15

var completed := 0


func _init() -> void:
	_test_no_sentence_names_the_same_person_twice()
	_test_a_useful_subject_is_still_named()
	_test_no_topic_id_reaches_a_sentence()
	_test_an_unregistered_topic_still_loses_its_underscores()
	_test_the_sentences_are_grammatical()
	_test_the_records_behind_them_are_unchanged()
	_test_the_subject_is_still_recorded()
	_test_the_action_vocabulary_did_not_grow()
	_test_no_invented_motive_or_manner()
	_test_a_claim_states_no_detail_the_action_lacks()
	_test_no_malformed_name()
	_test_the_personal_chronicle_still_has_its_social_beats()
	_test_the_chronicle_is_the_same_size()
	_test_relationships_are_unchanged()
	_test_feedback_agrees_with_history()

	if completed != EXPECTED_TESTS:
		push_error("WORDING TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("WORDING TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("WORDING TEST PASSED: the sentences read, and the simulation is untouched.")
	quit(0)


# --- repetition -------------------------------------------------------------

func _test_no_sentence_names_the_same_person_twice() -> void:
	# "Mara stood with The King over The King" and "request concerning The King"
	# were the sentence collapsing, not the simulation.
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for record: Dictionary in state.chronicle:
			var summary := str(record["summary"])
			for entity_id: String in state.notable_entities.keys():
				var name := str(state.get_notable_entity(entity_id).get("name", ""))
				if name.is_empty():
					continue
				assert(summary.count(name) <= 1,
					"a sentence names %s more than once: %s" % [name, summary])
	print("  NO ONE NAMED TWICE: every social sentence names each person once.")
	completed += 1


func _test_a_useful_subject_is_still_named() -> void:
	# The clause was only dropped where it said nothing. Where the exchange was
	# genuinely about a third party or a place, it survives — otherwise this
	# would be tidying by deletion.
	var simulation := _flooded_world()
	var state = simulation.state
	var informative := 0
	for record: Dictionary in state.chronicle:
		var summary := str(record["summary"])
		if summary.contains("concerning") or summary.contains(" over "):
			informative += 1
			# Whatever it names must not be one of the two people in the sentence.
			var subject_id := str(record["subject_id"])
			assert(subject_id != str(record["actor_id"])
				and subject_id != str(record["target_id"]),
				"a redundant clause survived: %s" % summary)
	assert(informative > 0,
		"no informative subject clause survived, so the rule deletes rather than selects")
	print("  USEFUL CLAUSE KEPT: %d sentences still say what the exchange was about." %
		informative)
	completed += 1


# --- id leaks ---------------------------------------------------------------

func _test_no_topic_id_reaches_a_sentence() -> void:
	var leaks: Array[String] = []
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for record: Dictionary in state.chronicle:
			var summary := str(record["summary"])
			# Multi-word ids only: `food_shortage` in a sentence is unambiguously
			# an identifier, while "the surplus" containing the word "surplus"
			# is the phrase doing its job.
			for topic: String in PresentationRulesScript.TOPIC_PHRASES:
				if topic.contains("_") and summary.contains(topic):
					leaks.append("%s in '%s'" % [topic, summary])
			# And nothing that merely looks like an id.
			for word: String in summary.split(" "):
				assert(not word.contains("_"),
					"an identifier reached a sentence: '%s' in '%s'" % [word, summary])
	assert(leaks.is_empty(), "topic ids reached sentences: %s" % str(leaks))
	print("  NO IDS: no topic id or underscored token in any historical sentence.")
	completed += 1


func _test_an_unregistered_topic_still_loses_its_underscores() -> void:
	# The fallback carries the weight for every topic added later.
	var phrase := PresentationRulesScript.topic_phrase("some_future_condition")
	assert(not phrase.contains("_"), "an unregistered topic kept its underscores: %s" % phrase)
	assert(not phrase.is_empty(), "an unregistered topic reads as nothing")
	assert(not PresentationRulesScript.topic_phrase("").is_empty(),
		"a missing topic reads as nothing")
	# And every registered phrase is plain English.
	for topic: String in PresentationRulesScript.TOPIC_PHRASES:
		var registered := str(PresentationRulesScript.TOPIC_PHRASES[topic])
		assert(not registered.contains("_"), "a topic phrase contains an id: %s" % registered)
	print("  SAFE FALLBACK: '%s' rather than a raw id." % phrase)
	completed += 1


func _test_the_sentences_are_grammatical() -> void:
	# Narrow, mechanical checks: the specific breakages found, not a grammar model.
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for record: Dictionary in state.chronicle:
			var summary := str(record["summary"])
			assert(not summary.contains("  "), "a doubled space: %s" % summary)
			assert(not summary.contains(" the the "), "a doubled article: %s" % summary)
			assert(not summary.contains("The The"), "a doubled article: %s" % summary)
			if summary.contains("moved food") or summary.contains("moved stability") \
				or summary.contains("moved prosperity"):
				assert(summary.contains(" from "),
					"a band change with no 'from': %s" % summary)
	print("  GRAMMAR: no doubled articles, spaces, or bandless transitions.")
	completed += 1


# --- the simulation underneath ----------------------------------------------

func _test_the_records_behind_them_are_unchanged() -> void:
	# Two identical runs, one of which reads every sentence. The world must not
	# be able to tell the difference.
	var quiet := _lived_world()
	var read := _lived_world()
	for record: Dictionary in read.state.chronicle:
		var _unused := str(record["summary"])
	assert(quiet.state.chronicle.size() == read.state.chronicle.size(),
		"reading changed how much history exists")
	for index in range(quiet.state.chronicle.size()):
		var a: Dictionary = quiet.state.chronicle[index]
		var b: Dictionary = read.state.chronicle[index]
		for field: String in ["id", "actor_id", "target_id", "subject_id",
			"location_id", "importance", "source_record_id"]:
			assert(str(a[field]) == str(b[field]),
				"%s differs between two identical runs" % field)
	print("  DETERMINISTIC: %d records identical across two runs." %
		quiet.state.chronicle.size())
	completed += 1


func _test_the_subject_is_still_recorded() -> void:
	# THE trap of this milestone. The easy way to stop a sentence repeating a
	# name is to stop recording the subject; that would delete simulation truth
	# to improve prose.
	var simulation := _lived_world()
	var state = simulation.state
	var with_subject := 0
	for record: Dictionary in state.execution_archive:
		if not str(record.get("subject_id", "")).is_empty():
			with_subject += 1
	assert(with_subject > 0,
		"no execution carries a subject any more; the record was tidied away")
	# Including the redundant ones, which are still recorded and simply not
	# said. This is the whole point: the sentence stopped repeating the name,
	# the record did not stop knowing it.
	var redundant := 0
	for record: Dictionary in state.execution_archive:
		var subject_id := str(record.get("subject_id", ""))
		if subject_id.is_empty():
			continue
		if subject_id == str(record.get("target_id", "")) \
			or subject_id == str(record.get("actor_id", "")):
			redundant += 1
	assert(redundant > 0,
		"the redundant subject was removed from the record rather than from the sentence")
	print("  RECORD INTACT: %d executions carry a subject; %d of them redundant and still stored." % [
		with_subject, redundant])
	completed += 1


func _test_the_action_vocabulary_did_not_grow() -> void:
	# No new primitive was invented to make a sentence read better.
	assert(ActionRulesScript.ACTION_ORDER.size() == 7,
		"the action vocabulary changed size: %s" % str(ActionRulesScript.ACTION_ORDER))
	for invented: String in ["agree", "defend", "advocate", "plead", "endorse", "beg"]:
		assert(not ActionRulesScript.ACTION_ORDER.has(invented),
			"a presentation problem grew a new action: %s" % invented)
	print("  SEVEN VERBS: %s." % ", ".join(ActionRulesScript.ACTION_ORDER))
	completed += 1


func _test_no_invented_motive_or_manner() -> void:
	var forbidden := [
		"angrily", "coldly", "proudly", "bitterly", "cruel", "kind",
		"betray", "jealous", "loyal", "loving", "because", "deserved",
		"punish", "mercy", "wisely", "foolishly"
	]
	for simulation: Object in [_lived_world(), _flooded_world()]:
		for record: Dictionary in simulation.state.chronicle:
			var summary := str(record["summary"]).to_lower()
			for word: String in forbidden:
				assert(not summary.contains(word),
					"a sentence states a motive or manner: %s" % str(record["summary"]))
	for topic: String in PresentationRulesScript.TOPIC_PHRASES:
		var phrase := str(PresentationRulesScript.TOPIC_PHRASES[topic]).to_lower()
		for word: String in forbidden:
			assert(not phrase.contains(word), "a topic phrase judges: %s" % phrase)
	print("  NO MANNER: nothing says how or why anybody acted.")
	completed += 1


func _test_a_claim_states_no_detail_the_action_lacks() -> void:
	# Fabricated specificity is the subtle failure. "The King refused Mara's
	# request for aid" reads better than "refused Mara's request" and is a lie
	# whenever nothing in the action names aid — the execution carries an actor,
	# a target and a subject, and no purpose at all.
	#
	# So the claim vocabulary is a REGISTRY. Strip the placeholders and what
	# remains may only be words from this list; any other noun is detail the
	# record cannot support. Adding one deliberately means adding it here, which
	# is the point.
	var permitted := [
		"agreed", "to", "s", "request", "concerning",
		"refused", "stood", "with", "over", "against"
	]
	for key: String in ConsequenceRulesScript.EXECUTION_CONSEQUENCES:
		var template: Dictionary = ConsequenceRulesScript.EXECUTION_CONSEQUENCES[key]
		for field: String in ["claim", "subject_claim"]:
			if not template.has(field):
				continue
			var words := str(template[field]).replace("%s", " ").replace("'", " ")
			for word: String in words.split(" "):
				var cleaned := word.strip_edges().to_lower()
				if cleaned.is_empty():
					continue
				assert(permitted.has(cleaned),
					"a claim states detail the action does not carry: '%s' in \"%s\"" % [
						cleaned, str(template[field])])
	print("  NO FABRICATION: every claim word is one the record can support.")
	completed += 1


func _test_no_malformed_name() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	for record: Dictionary in state.chronicle:
		var summary := str(record["summary"])
		assert(not summary.contains("'s's"), "a doubled possessive: %s" % summary)
		assert(not summary.begins_with(" ") and not summary.ends_with(" "),
			"a sentence is padded with spaces: '%s'" % summary)
		assert(not summary.is_empty(), "an empty sentence was stored")
		for entity_id: String in state.notable_entities.keys():
			assert(not summary.contains(entity_id) or entity_id == str(
				state.get_notable_entity(entity_id).get("name", "")),
				"an entity id reached a sentence: %s" % summary)
	print("  NAMES: no id, doubled possessive or stray padding.")
	completed += 1


# --- everything that must still work ----------------------------------------

func _test_the_personal_chronicle_still_has_its_social_beats() -> void:
	var simulation := _lived_world()
	var social := 0
	for entry: Dictionary in simulation.personal_chronicle("aster_king"):
		if str(entry.get("source_record_type", "")) == "consequence":
			social += 1
			assert(not str(entry["summary"]).is_empty(), "a social beat reads as nothing")
	assert(social > 0, "the King's social beats vanished")
	print("  BEATS KEPT: %d social entries still in the King's life." % social)
	completed += 1


func _test_the_chronicle_is_the_same_size() -> void:
	var simulation := _lived_world()
	assert(simulation.state.chronicle.size() == 77,
		"history changed size during a wording cleanup: %d" % simulation.state.chronicle.size())
	print("  SAME HISTORY: 77 records, exactly as before the wording changed.")
	completed += 1


func _test_relationships_are_unchanged() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var edge: Dictionary = state.get_relationship("aster_king", "mara")
	assert(int(edge["trust"]) == 100 and int(edge["respect"]) == 100,
		"a wording change moved a relationship: %s" % str(edge))
	print("  RELATIONSHIPS: trust %d, respect %d — untouched." % [
		int(edge["trust"]), int(edge["respect"])])
	completed += 1


func _test_feedback_agrees_with_history() -> void:
	# The two layers need not use the same sentence, but they must not
	# contradict each other or leak ids where history no longer does.
	var simulation := _lived_world()
	var developments: Array = simulation.feedback_rules.developments(simulation.state)
	for item: Dictionary in developments:
		for field: String in ["headline", "body"]:
			var text := str(item.get(field, ""))
			for word: String in text.split(" "):
				assert(not word.contains("_"),
					"feedback leaked an identifier: '%s'" % text)
	print("  CONSISTENT: %d feedback lines, none leaking what history hides." %
		developments.size())
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
