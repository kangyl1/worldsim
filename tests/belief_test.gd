extends SceneTree

# Belief Formation v1.
#
# The layer that turns repeated conclusions into something durable. Knowledge is
# what a mortal thinks happened, an interpretation is what they made of one
# occurrence, and a belief is what they have come to accept about the world —
# the first thing here that outlives the event that started it.
#
# The milestone exists to close a dead loop. A divine reading needed a prior
# divine reading, so the first one could never happen and no mortal could ever
# come to believe anything about the god. The bootstrap test below is the point
# of the whole suite: a mortal reaching a divine conclusion from evidence they
# could actually see, with nothing seeded.
#
# Most of the rest is negative, because the dangerous failure here is not a
# belief that fails to form. It is a belief that forms too easily, from evidence
# the mortal never had — the engine knows the player sent the rain, and that
# fact must never reach anybody's convictions.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")

const EXPECTED_TESTS := 20

# Later systems this layer must not begin.
const OUT_OF_SCOPE := [
	"religion", "doctrine", "prophet", "worship", "ritual", "temple", "church",
	"cult", "schism", "convert", "preach", "denomination", "holy"
]

# Realm-level values this layer must never touch.
const FORBIDDEN_REALM := [
	"state.faith", "state.followers", "state.reputation",
	"state.beliefs", "state.known_beliefs", "belief_pressure"
]

var completed := 0


func _init() -> void:
	_test_the_first_divine_belief_bootstraps()
	_test_formation_is_gradual()
	_test_two_mortals_disagree()
	_test_a_belief_can_be_contradicted()
	_test_belief_biases_a_later_interpretation()
	_test_belief_does_not_lock_in_theology()
	_test_belief_reaches_later_intent_scoring()
	_test_evidence_is_not_counted_twice()
	_test_a_belief_outlives_its_evidence()
	_test_beliefs_are_stored_once_per_proposition()
	_test_the_record_explains_itself()
	_test_confidence_stays_bounded()

	_test_knowledge_does_not_become_belief()
	_test_hidden_divine_metadata_cannot_reach_belief()
	_test_the_realm_faith_is_neither_read_nor_written()
	_test_belief_changes_nothing_directly()
	_test_beliefs_do_not_spread()
	_test_no_religion_was_started()
	_test_no_same_year_recursion()
	_test_the_chronicle_is_not_flooded()

	if completed != EXPECTED_TESTS:
		push_error("Belief suite incomplete: %d of %d." % [completed, EXPECTED_TESTS])
		print("BELIEF TEST FAILED: %d of %d tests finished." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("BELIEF TEST PASSED: a mortal came to believe something, and could stop.")
	quit(0)


# --- fixtures --------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


func _settled(simulation: Object, years: int = 8) -> void:
	for year in range(years):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()


# Put Westfield through a shortage its people actually live through, and end the
# year still in it. Nothing here touches belief, interpretation or the divine
# record: it makes the WORLD hard, which is all a fixture is allowed to do.
func _hungry_year(simulation: Object) -> bool:
	var state = simulation.state
	state.set_settlement_band("westfield", "food", 0)
	state.set_settlement_band("westfield", "prosperity", 0)
	simulation.resolve_action("do_nothing")
	simulation.advance_year()
	return state.condition_before_turn("westfield", "food") == 0


# The god answers a famine Westfield has been living through. This is the whole
# fixture: circumstance, not instruction. No belief is injected, no
# interpretation is seeded, and nothing tells Mara a god was involved.
func _answered_famines(simulation: Object, times: int, limit: int = 24) -> int:
	var state = simulation.state
	var answered := 0
	for year in range(limit):
		if _hungry_year(simulation) and int(state.divine_power) >= 2:
			state.current_event_location_id = "westfield"
			simulation.resolve_action("send_rain")
			simulation.advance_year()
			answered += 1
			if answered >= times:
				break
	return answered


func _believer(times: int = 4) -> Object:
	var simulation := _sim()
	_settled(simulation)
	_answered_famines(simulation, times)
	return simulation


func _rain_readings(state, observer_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in state.interpretation_archive:
		if str(record["topic"]) == "weather_rain" \
			and str(record["observer_id"]) == observer_id:
			found.append(record)
	return found


func _code_of(path: String) -> String:
	var kept: Array[String] = []
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var trimmed := line.strip_edges()
		if trimmed.begins_with("#") or trimmed.is_empty():
			continue
		var hash_at := line.find("#")
		kept.append(line.substr(0, hash_at) if hash_at >= 0 else line)
	return "\n".join(kept)


# --- the bootstrap ---------------------------------------------------------

func _test_the_first_divine_belief_bootstraps() -> void:
	# THE test. Nobody starts with a divine belief and nobody is given one. Rain
	# arrives while Westfield's wells are dry, Mara lived through the shortage,
	# and she draws her own conclusion from what she could see.
	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	# Social beliefs may already have formed from ordinary life, and should
	# have. What must not exist is any belief about the divine, and any prior
	# divine reading for one to have grown from.
	for belief: Dictionary in state.mortal_beliefs:
		assert(not str(belief["proposition"]).begins_with("divine"),
			"a divine belief existed before the god had been noticed at all")
	assert(_rain_readings(state, "mara").is_empty(), "Mara had already read a rain")

	var answered := _answered_famines(simulation, 4)
	assert(answered >= 3, "the fixture only produced %d answered famines" % answered)

	var divine_readings := 0
	var first_year := -1
	for record: Dictionary in _rain_readings(state, "mara"):
		if str(record["interpretation_type"]).begins_with("rain_divine"):
			divine_readings += 1
			if first_year < 0:
				first_year = int(record["year"])
	assert(divine_readings > 0, "no divine reading ever arose from mortal-visible evidence")

	# The FIRST one had no prior divine reading and no belief behind it: it came
	# from the circumstance alone.
	var first: Dictionary = {}
	for record: Dictionary in _rain_readings(state, "mara"):
		if int(record["year"]) == first_year:
			first = record
			break
	for factor_value in first["factors"]:
		var factor: Dictionary = factor_value
		assert(str(factor["kind"]) != "prior_divine_reading",
			"the first divine reading leaned on a prior one, which is the dead loop")
		assert(str(factor["kind"]) != "belief_at_least",
			"the first divine reading leaned on a belief it had not formed yet")

	var belief: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not belief.is_empty(), "the readings never became a belief")
	assert(int(belief["confidence"]) >= BeliefRules.ESTABLISHED_CONFIDENCE,
		"the belief formed but never became established (%d)" % int(belief["confidence"]))
	print("  BOOTSTRAP: Mara's first divine reading in year %d, belief at %d by year %d." % [
		first_year, int(belief["confidence"]), int(belief["last_updated_year"])
	])
	completed += 1


func _test_formation_is_gradual() -> void:
	# One reading must not make a conviction. The belief exists after the first
	# supporting interpretation and is nowhere near firm.
	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	_answered_famines(simulation, 1)
	var belief: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not belief.is_empty(), "one reading produced no belief at all")
	assert(int(belief["confidence"]) < BeliefRules.ESTABLISHED_CONFIDENCE,
		"one interpretation created an established belief (%d)" % int(belief["confidence"]))
	assert(str(belief["status"]) == BeliefRules.STATUS_FORMING)
	assert(int(belief["support"]) == 1)
	var after_one := int(belief["confidence"])

	_answered_famines(simulation, 3)
	var later: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(int(later["confidence"]) > after_one, "repetition did not strengthen it")
	assert(int(later["support"]) > 1, "the support count did not grow")
	print("  GRADUAL: %d after one reading, %d after %d." % [
		after_one, int(later["confidence"]), int(later["support"])
	])
	completed += 1


func _test_two_mortals_disagree() -> void:
	# Same world, same kind of evidence, different people. The King is ambitious
	# and unmoved; Mara is compassionate and concludes something happened.
	var simulation := _believer()
	var state = simulation.state
	var mara_divine: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	var king_divine: Dictionary = state.get_belief("aster_king", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not mara_divine.is_empty(), "Mara concluded nothing")
	assert(king_divine.is_empty()
		or int(king_divine["confidence"]) < int(mara_divine["confidence"]),
		"both mortals reached the same conviction")
	# And it shows in their readings, not only in the store.
	var king_divine_readings := 0
	for record: Dictionary in _rain_readings(state, "aster_king"):
		if str(record["interpretation_type"]).begins_with("rain_divine"):
			king_divine_readings += 1
	assert(king_divine_readings == 0 or state.get_belief(
		"aster_king", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, ""
	).is_empty() == false, "inconsistent king state")
	print("  DISAGREEMENT: Mara at %d, the King at %d." % [
		int(mara_divine["confidence"]),
		int(king_divine.get("confidence", 0)) if not king_divine.is_empty() else 0
	])
	completed += 1


func _test_a_belief_can_be_contradicted() -> void:
	# Beliefs are revisable. Rain that arrives when nothing is wrong reads as
	# ordinary weather, and ordinary weather is evidence AGAINST the idea that
	# something answers need.
	var simulation := _believer()
	var state = simulation.state
	var before := int(state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")["confidence"])
	assert(before >= BeliefRules.ESTABLISHED_CONFIDENCE, "nothing established to contradict")

	for year in range(6):
		state.set_settlement_band("westfield", "food", 2)
		state.set_settlement_band("westfield", "prosperity", 2)
		# Healthy ground each year, so this is ORDINARY rain on a settlement
		# that is fine — which is what should read as weather and contradict the
		# belief. Left to accumulate it would flood the place instead, and a
		# flood is a different argument (see `sandbox_test.gd`).
		state.set_water("westfield", WorldState.WATER_BASELINE)
		state.current_event_location_id = "westfield"
		simulation.resolve_action("send_rain", "westfield")
		simulation.advance_year()

	var after: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(int(after["confidence"]) < before,
		"contradicting readings did not weaken the belief (%d -> %d)"
			% [before, int(after["confidence"])])
	assert(int(after["contradiction"]) > 0, "no contradiction was recorded")
	assert(not after.is_empty(), "the belief was deleted rather than weakened")
	print("  REVISABLE: %d -> %d after %d contradictions, status %s." % [
		before, int(after["confidence"]), int(after["contradiction"]), str(after["status"])
	])
	completed += 1


# --- what beliefs do -------------------------------------------------------

func _test_belief_biases_a_later_interpretation() -> void:
	# An established belief is a factor in later readings, and it names itself.
	var simulation := _believer(5)
	var state = simulation.state
	var used := false
	for record: Dictionary in _rain_readings(state, "mara"):
		for factor_value in record["factors"]:
			if str((factor_value as Dictionary)["kind"]) == "belief_at_least":
				used = true
	assert(used, "no reading was ever weighted by what Mara had come to believe")
	print("  BIASES READING: an established belief appears as an interpretation factor.")
	completed += 1


func _test_belief_does_not_lock_in_theology() -> void:
	# The important limit. A believer must still be able to look at ordinary
	# rain and call it ordinary, or belief has stopped being belief.
	var simulation := _believer()
	var state = simulation.state
	var before := _rain_readings(state, "mara").size()
	for year in range(4):
		state.set_settlement_band("westfield", "food", 2)
		state.set_settlement_band("westfield", "prosperity", 2)
		state.current_event_location_id = "westfield"
		simulation.resolve_action("send_rain")
		simulation.advance_year()
	var natural := 0
	var readings := _rain_readings(state, "mara")
	for index in range(before, readings.size()):
		if str(readings[index]["interpretation_type"]) == "rain_natural_weather":
			natural += 1
	assert(natural > 0,
		"a believer read every later rain as divine; that is theology lock-in")
	print("  NO LOCK-IN: a believer called %d later rains ordinary." % natural)
	completed += 1


func _test_belief_reaches_later_intent_scoring() -> void:
	# The loop closes. An established belief weights what its holder wants, and
	# says so in an explainable factor.
	var simulation := _believer(5)
	var found: Dictionary = {}
	for candidate: Dictionary in simulation.evaluate_intents("mara"):
		if not bool(candidate["eligible"]):
			continue
		if not candidate["belief_factors"].is_empty():
			found = candidate
			break
	assert(not found.is_empty(), "no want was weighted by anything Mara believes")
	var factor: Dictionary = found["belief_factors"][0]
	assert(int(factor["delta"]) != 0, "a belief factor that changes nothing")
	assert(not str(factor["belief_id"]).is_empty(), "the factor cannot be traced to a belief")
	assert(int(factor["confidence"]) >= BeliefRules.ESTABLISHED_CONFIDENCE,
		"an unestablished belief reached intent scoring")
	print("  REACHES INTENT: '%s' weights %s by %+d." % [
		str(factor["detail"]), str(found["intent_type"]), int(factor["delta"])
	])
	completed += 1


func _test_evidence_is_not_counted_twice() -> void:
	# A reading and the belief it fed are the same evidence in two forms. Once
	# the belief is established it speaks, and the reading stays quiet.
	var simulation := _believer(5)
	var state = simulation.state
	var belief_logic := BeliefRules.new()
	var settled: Array[String] = []
	for belief: Dictionary in state.get_beliefs_for("mara"):
		if belief_logic.is_established(belief):
			settled.append(str(belief["proposition"]))
	assert(not settled.is_empty(), "nothing settled, so nothing to double count")

	for candidate: Dictionary in simulation.evaluate_intents("mara"):
		for factor_value in candidate["interpretation_factors"]:
			var factor: Dictionary = factor_value
			for proposition: String in belief_logic.propositions_supported_by(
				str(factor["detail"])
			):
				assert(proposition not in settled,
					"'%s' was counted as a reading AND as the belief it built"
						% str(factor["detail"]))
	print("  NO DOUBLE COUNT: %d settled propositions, none also counted as readings."
		% settled.size())
	completed += 1


func _test_a_belief_outlives_its_evidence() -> void:
	# The reason belief is stored apart from knowledge. Knowledge is capped and
	# pruned; what somebody came to accept must not vanish with the fact.
	var simulation := _believer()
	var state = simulation.state
	var belief: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "").duplicate(true)
	assert(not belief.is_empty(), "nothing to outlive anything")
	# Wipe every fact she holds. The belief is not a cache of them.
	# `get_all_knowledge` hands back a copy, so the live store is emptied here.
	state.notable_entities["mara"]["knowledge"] = {}
	assert(state.get_all_knowledge("mara").is_empty(), "the fixture failed to forget")
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var still: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not still.is_empty(), "the belief died with the facts behind it")
	assert(int(still["confidence"]) == int(belief["confidence"]),
		"the belief drifted although nothing contradicted it")
	print("  DURABLE: belief held at %d after every underlying fact was forgotten."
		% int(still["confidence"]))
	completed += 1


func _test_beliefs_are_stored_once_per_proposition() -> void:
	var state = _believer(5).state
	var seen: Array[String] = []
	for belief: Dictionary in state.mortal_beliefs:
		var key := "%s|%s|%s" % [
			str(belief["holder_id"]), str(belief["proposition"]), str(belief["subject_id"])
		]
		assert(key not in seen, "the same conviction is stored twice: %s" % key)
		seen.append(key)
		assert(str(belief["holder_id"]) != str(belief["subject_id"]),
			"a mortal formed a belief about themselves")
	print("  ONE EACH: %d beliefs, no duplicates." % seen.size())
	completed += 1


func _test_the_record_explains_itself() -> void:
	var simulation := _believer()
	var state = simulation.state
	var required := [
		"id", "holder_id", "proposition", "subject_id", "confidence", "support",
		"contradiction", "first_year", "last_updated_year",
		"source_interpretation_ids", "status"
	]
	for belief: Dictionary in state.mortal_beliefs:
		for field: String in required:
			assert(belief.has(field), "a belief record is missing '%s'" % field)
		for field: String in belief.keys():
			assert(str(field) in required,
				"the record grew a field with no stated use: %s" % str(field))
		assert(str(belief["proposition"]) in BeliefRules.PROPOSITIONS,
			"a proposition outside the vocabulary: %s" % str(belief["proposition"]))
		assert(not belief["source_interpretation_ids"].is_empty(),
			"a belief with no evidence behind it")
		assert(int(belief["first_year"]) <= int(belief["last_updated_year"]))
	# And this year's updates name what moved them.
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
		for update: Dictionary in state.last_belief_updates:
			assert(not update["factors"].is_empty(), "a belief moved for no stated reason")
			assert(str(update["change"]) in ["formed", "reinforced", "weakened"])
	print("  EXPLAINED: every belief names its evidence and every update its cause.")
	completed += 1


func _test_confidence_stays_bounded() -> void:
	var simulation := _believer()
	var state = simulation.state
	# Hammer it with supporting evidence and it must not exceed the ceiling.
	_answered_famines(simulation, 12, 40)
	for belief: Dictionary in state.mortal_beliefs:
		assert(int(belief["confidence"]) >= BeliefRules.CONFIDENCE_MIN
			and int(belief["confidence"]) <= BeliefRules.CONFIDENCE_MAX,
			"confidence escaped its bounds: %d" % int(belief["confidence"]))
	var top: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(int(top["confidence"]) <= BeliefRules.CONFIDENCE_MAX)
	print("  BOUNDED: strongest belief at %d after %d supports." % [
		int(top["confidence"]), int(top["support"])
	])
	completed += 1


# --- what beliefs must not do ----------------------------------------------

func _test_knowledge_does_not_become_belief() -> void:
	# Holding a fact is not accepting a proposition. A long ordinary run
	# produces plenty of knowledge and no divine conviction.
	var simulation := _sim()
	var state = simulation.state
	for year in range(30):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var facts := 0
	for entity: Dictionary in state.notable_entities.values():
		facts += state.get_all_knowledge(str(entity["id"])).size()
	assert(facts > 0, "thirty years produced no knowledge")
	for belief: Dictionary in state.mortal_beliefs:
		assert(not str(belief["proposition"]).begins_with("divine"),
			"a divine belief appeared with no divine reading behind it")
	print("  NOT AUTOMATIC: %d facts held, no divine belief formed." % facts)
	completed += 1


func _test_hidden_divine_metadata_cannot_reach_belief() -> void:
	# The engine knows the player caused the rain. No belief may be founded on
	# that. The layer must not be able to NAME the places that knowledge lives.
	var code := _code_of("res://scripts/belief_rules.gd")
	for forbidden: String in [
		"divine_action", "divine_action_archive", "get_divine_action",
		"objective_truth_state", "consequence_archive", "pipeline", "action_type"
	]:
		assert(not code.contains(forbidden),
			"belief formation can see '%s', which mortals cannot" % forbidden)
	# Behaviourally: rain that nobody interpreted forms no belief.
	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	# Aim it at the Frontier, where nobody lives. The act happens; nobody sees.
	for year in range(6):
		state.current_event_location_id = "frontier"
		simulation.resolve_action("send_rain")
		simulation.advance_year()
	assert(not state.divine_action_archive.is_empty(), "the god never acted")
	for belief: Dictionary in state.mortal_beliefs:
		assert(not str(belief["proposition"]).begins_with("divine"),
			"a divine belief formed from an act nobody perceived")
	print("  NO PEEKING: six unseen interventions produced no belief.")
	completed += 1


func _test_the_realm_faith_is_neither_read_nor_written() -> void:
	var code := _code_of("res://scripts/belief_rules.gd")
	for forbidden: String in FORBIDDEN_REALM:
		assert(not code.contains(forbidden),
			"belief formation touches '%s'" % forbidden)
	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	_answered_famines(simulation, 4)
	assert(not state.mortal_beliefs.is_empty(), "nothing formed, so nothing is proven")
	# Measured across belief formation ALONE. Realm faith does move elsewhere in
	# the year — the unmigrated divine powers still write it — so comparing
	# across a whole tick would prove nothing about this layer.
	var faith: int = state.faith
	var followers: int = state.followers
	var legacy := str(state.beliefs)
	var updates: Array = simulation.tick_beliefs()
	assert(state.faith == faith, "belief formation moved realm faith")
	assert(state.followers == followers, "belief formation moved followers")
	assert(str(state.beliefs) == legacy, "belief formation wrote the legacy doctrine list")
	print("  SEPARATE: %d belief updates, realm faith %d and followers %d untouched."
		% [updates.size(), faith, followers])
	completed += 1


func _test_belief_changes_nothing_directly() -> void:
	# Belief is a record layer. It moves no relationship, changes no world state,
	# and executes nothing.
	var code := _code_of("res://scripts/belief_rules.gd")
	for forbidden: String in [
		"set_relationship", "change_settlement_band", "add_history",
		"record_chronicle", "learn_knowledge", "trust", "hostility"
	]:
		assert(not code.contains(forbidden),
			"belief formation reaches into '%s'" % forbidden)
	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	var before_relationships := str(state.relationships)
	var before_actions: int = state.action_archive.size()
	simulation.tick_beliefs()
	assert(str(state.relationships) == before_relationships,
		"a belief update moved a relationship")
	assert(state.action_archive.size() == before_actions, "a belief update acted")
	print("  INERT: belief formation moved no relationship and took no action.")
	completed += 1


func _test_beliefs_do_not_spread() -> void:
	# Facts travel. Convictions do not. Mara believing something must never
	# place that belief in anybody else.
	var simulation := _believer(5)
	var state = simulation.state
	var mara: Dictionary = state.get_belief("mara", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(not mara.is_empty(), "nothing to fail to spread")
	for year in range(10):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	var king: Dictionary = state.get_belief("aster_king", BeliefRules.DIVINE_HELP_FOLLOWS_NEED, "")
	assert(king.is_empty(), "a belief spread to somebody who never saw the evidence")
	var code := _code_of("res://scripts/belief_rules.gd")
	for forbidden: String in ["share", "spread", "transmit", "convert", "teach"]:
		assert(not code.contains(forbidden), "belief formation can '%s'" % forbidden)
	print("  PRIVATE: ten more years and the King still believes nothing of the kind.")
	completed += 1


func _test_no_religion_was_started() -> void:
	var code := _code_of("res://scripts/belief_rules.gd").to_lower()
	for forbidden: String in OUT_OF_SCOPE:
		assert(not code.contains(forbidden),
			"belief v1 reached into '%s', which is later work" % forbidden)
	var simulation := _believer(5)
	var state = simulation.state
	assert(not state.prophet_created, "a prophet appeared")
	for belief: Dictionary in state.mortal_beliefs:
		assert(not belief.has("religion") and not belief.has("doctrine")
			and not belief.has("members"),
			"a belief record grew a religion's field")
	print("  NOT A RELIGION: a conviction held by one person, and nothing else.")
	completed += 1


func _test_no_same_year_recursion() -> void:
	# A belief formed this year must not reach a want already chosen this year.
	# Structural: belief formation runs after intents, and behaviourally the
	# archive for this year is already written when it runs.
	var source := FileAccess.get_file_as_string("res://scripts/world_sim.gd")
	var intents_at := source.find("state.last_intents = tick_intents()")
	var beliefs_at := source.find("state.last_belief_updates = tick_beliefs()")
	var chronicle_at := source.find("state.last_chronicle_entries = tick_chronicle(")
	assert(intents_at > 0 and beliefs_at > 0 and chronicle_at > 0, "the tick changed shape")
	assert(beliefs_at > intents_at, "belief formation runs before intents are chosen")
	assert(beliefs_at < chronicle_at, "belief formation runs after the chronicle")

	var simulation := _sim()
	var state = simulation.state
	_settled(simulation)
	var intents_before: int = state.intent_archive.size()
	var actions_before: int = state.action_archive.size()
	simulation.tick_beliefs()
	assert(state.intent_archive.size() == intents_before, "a belief update formed an intent")
	assert(state.action_archive.size() == actions_before, "a belief update caused an action")
	print("  ORDER: intents, then interpretation, then belief, then history.")
	completed += 1


func _test_the_chronicle_is_not_flooded() -> void:
	# Belief updates are frequent; history is not. The chronicle must not have
	# grown a per-belief entry.
	var simulation := _believer(6)
	var state = simulation.state
	# A stretch that actually moves beliefs, so the comparison means something.
	# Quiet years move nothing, and would prove only that nothing happened.
	var updates := 0
	var chronicle_before: int = state.chronicle.size()
	for year in range(10):
		if _hungry_year(simulation) and int(state.divine_power) >= 2:
			state.current_event_location_id = "westfield"
			simulation.resolve_action("send_rain")
			simulation.advance_year()
		updates += state.last_belief_updates.size()
	for record: Dictionary in state.chronicle:
		assert(str(record["source_record_type"]) != "belief",
			"belief updates became a chronicle source")
	assert(updates > 0, "no beliefs moved, so nothing is proven")
	var chronicle_growth: int = state.chronicle.size() - chronicle_before
	# Deliberately NOT a ratio. This fixture drives Westfield into famine every
	# year, so it manufactures history by itself and any count comparison would
	# be measuring the fixture. The property that matters is categorical: a
	# belief is not a thing history is written from. Every entry in the
	# chronicle traces to one of the four sources it already had, and none of
	# them is a belief.
	for record: Dictionary in state.chronicle:
		assert(str(record["source_record_type"]) in [
			ChronicleRules.SOURCE_CONDITION, ChronicleRules.SOURCE_DIVINE,
			ChronicleRules.SOURCE_CONSEQUENCE, ChronicleRules.SOURCE_INTERPRETATION
		], "history grew a new source: %s" % str(record["source_record_type"]))
		for belief: Dictionary in state.mortal_beliefs:
			assert(str(record["source_record_id"]) != str(belief["id"]),
				"a belief was written into history directly")
	# And the chronicle rules cannot even name the belief store.
	var chronicle_code := _code_of("res://scripts/chronicle_rules.gd")
	assert(not chronicle_code.contains("mortal_beliefs")
		and not chronicle_code.contains("get_belief"),
		"the chronicle reads beliefs; belief is not a historical source in v1")
	print("  NOT A SOURCE: %d belief updates, and none of the %d new history entries came from one."
		% [updates, chronicle_growth])
	completed += 1
