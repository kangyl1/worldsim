extends SceneTree

# Person-Subject Perception v1.
#
# The subject is what an occurrence is ABOUT. The location is WHERE it
# happened. For years those were the same thing — a drought in Aster is about
# Aster — so perception decided who saw something local by comparing an
# observer's home against the occurrence's SUBJECT.
#
# That holds until an occurrence is about a person. A force striking Mara in
# Westfield has subject `mara`; no observer's home is ever `mara`; the event
# would have been perceived by nobody at all. Everything below exists to keep
# those two facts apart all the way from the occurrence into knowledge and
# history, and to make sure the old location events did not change at all.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const WorldStateScript = preload("res://scripts/world_state.gd")
const PerceptionRulesScript = preload("res://scripts/perception_rules.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 22

var completed := 0


func _init() -> void:
	_test_a_place_subject_is_unchanged()
	_test_a_person_subject_keeps_its_type()
	_test_a_person_subject_keeps_its_location()
	_test_an_unknown_subject_is_not_guessed()
	_test_locality_reads_the_location()
	_test_a_neighbour_perceives_it()
	_test_somebody_elsewhere_does_not()
	_test_public_stays_public()
	_test_hidden_stays_hidden()
	_test_a_participant_still_sees_it()
	_test_being_the_subject_does_not_wake_the_dead()
	_test_a_dead_observer_perceives_nothing()
	_test_knowledge_keeps_the_person()
	_test_knowledge_keeps_the_place()
	_test_presentation_leaks_no_ids()
	_test_a_person_event_is_not_a_settlement_event()
	_test_it_is_not_world_history()
	_test_episodes_group_by_location()
	_test_the_old_local_events_still_work()
	_test_location_smite_is_unchanged()
	_test_smiting_a_person_is_refused()
	_test_an_unknown_target_still_falls_back()

	if completed != EXPECTED_TESTS:
		push_error("PERSON SUBJECT TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("PERSON SUBJECT TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("PERSON SUBJECT TEST PASSED: it happened to somebody, and somewhere, and those are two facts.")
	quit(0)


# --- the schema -------------------------------------------------------------

func _test_a_place_subject_is_unchanged() -> void:
	var state = _sim().state
	var occurrence: Dictionary = state.normalise_occurrence({
		"id": "aster_food_shortage", "subject_id": "aster", "observability": "local"
	})
	assert(str(occurrence["subject_type"]) == WorldStateScript.SUBJECT_LOCATION,
		"a settlement subject was not typed as a place")
	assert(str(occurrence["location_id"]) == "aster",
		"a settlement occurrence lost its own location")
	print("  PLACE UNCHANGED: aster -> subject location, at aster.")
	completed += 1


func _test_a_person_subject_keeps_its_type() -> void:
	var state = _sim().state
	var occurrence: Dictionary = state.normalise_occurrence({
		"id": "mara_struck", "subject_id": "mara", "observability": "local"
	})
	assert(str(occurrence["subject_type"]) == WorldStateScript.SUBJECT_PERSON,
		"a person subject was not typed as a person")
	assert(str(occurrence["subject_id"]) == "mara", "the person was lost from the subject")
	print("  PERSON TYPED: mara -> subject person.")
	completed += 1


func _test_a_person_subject_keeps_its_location() -> void:
	var state = _sim().state
	var occurrence: Dictionary = state.normalise_occurrence({
		"id": "mara_struck", "subject_id": "mara", "observability": "local"
	})
	assert(str(occurrence["location_id"]) == "westfield",
		"an occurrence about Mara happened at '%s'" % str(occurrence["location_id"]))
	assert(state.location_of_person("mara") == "westfield", "her location resolves wrongly")
	# And an explicit location is never overwritten.
	var stated: Dictionary = state.normalise_occurrence({
		"id": "x", "subject_id": "mara", "location_id": "aster"
	})
	assert(str(stated["location_id"]) == "aster",
		"a stated location was overwritten by the subject's home")
	print("  PERSON PLACED: an occurrence about Mara happened in Westfield.")
	completed += 1


func _test_an_unknown_subject_is_not_guessed() -> void:
	# Resolution, not guesswork. A subject that is neither a place nor a person
	# keeps an empty type rather than being assigned one.
	var state = _sim().state
	var occurrence: Dictionary = state.normalise_occurrence({
		"id": "x", "subject_id": "the_sea"
	})
	assert(str(occurrence["subject_type"]).is_empty(),
		"an unknown subject was guessed as %s" % str(occurrence["subject_type"]))
	assert(str(occurrence["location_id"]).is_empty(),
		"an unknown subject was given a location")
	print("  NOT GUESSED: an unknown subject stays untyped and unplaced.")
	completed += 1


# --- locality ---------------------------------------------------------------

func _test_locality_reads_the_location() -> void:
	# The load-bearing change. Under the old rule this event was invisible to
	# everyone, because no observer's home is ever a person.
	var simulation := _sim()
	var state = simulation.state
	var chance: Dictionary = simulation.perception_rules.evaluate(
		state, _strike_on_mara(), "mara")
	assert(bool(chance["eligible"]),
		"the person it happened to could not perceive it: %s" % str(chance["reason"]))
	assert(str(chance["location_id"]) == "westfield", "the chance lost where it happened")
	assert(str(chance["subject_id"]) == "mara", "the chance lost who it was about")
	print("  LOCALITY BY PLACE: Mara perceives a strike on Mara, in Westfield.")
	completed += 1


func _test_a_neighbour_perceives_it() -> void:
	# Somebody else living in Westfield sees it too: locality is about the
	# place, not about being the subject.
	var simulation := _sim()
	var state = simulation.state
	state.add_notable_entity("neighbour", "The Neighbour", "person", [], {}, "westfield")
	var chance: Dictionary = simulation.perception_rules.evaluate(
		state, _strike_on_mara(), "neighbour")
	assert(bool(chance["eligible"]),
		"a Westfield local missed something that happened in Westfield: %s" % str(chance["reason"]))
	print("  NEIGHBOURS SEE IT: a Westfield local perceives it without being its subject.")
	completed += 1


func _test_somebody_elsewhere_does_not() -> void:
	var simulation := _sim()
	var state = simulation.state
	var chance: Dictionary = simulation.perception_rules.evaluate(
		state, _strike_on_mara(), "aster_king")
	assert(not bool(chance["eligible"]),
		"the King in Aster saw something that happened in Westfield")
	assert(str(chance["reason"]) == "elsewhere",
		"he missed it for the wrong reason: %s" % str(chance["reason"]))
	print("  ELSEWHERE: the King in Aster misses it.")
	completed += 1


func _test_public_stays_public() -> void:
	var simulation := _sim()
	var state = simulation.state
	var fact := _strike_on_mara()
	fact["observability"] = "public"
	var chance: Dictionary = simulation.perception_rules.evaluate(state, fact, "aster_king")
	assert(bool(chance["eligible"]), "a public occurrence did not reach a distant observer")
	print("  PUBLIC UNCHANGED: a public person event still reaches everyone.")
	completed += 1


func _test_hidden_stays_hidden() -> void:
	var simulation := _sim()
	var state = simulation.state
	var fact := _strike_on_mara()
	fact["observability"] = "hidden"
	for observer: String in ["mara", "aster_king"]:
		var chance: Dictionary = simulation.perception_rules.evaluate(state, fact, observer)
		assert(not bool(chance["eligible"]),
			"%s perceived a hidden occurrence" % observer)
	print("  HIDDEN UNCHANGED: nobody perceives it, subject included.")
	completed += 1


func _test_a_participant_still_sees_it() -> void:
	var simulation := _sim()
	var state = simulation.state
	var fact := _strike_on_mara()
	fact["observability"] = "direct"
	fact["participants"] = ["aster_king"]
	var chance: Dictionary = simulation.perception_rules.evaluate(state, fact, "aster_king")
	assert(bool(chance["eligible"]),
		"taking part no longer beats being near: %s" % str(chance["reason"]))
	print("  DIRECT UNCHANGED: a participant perceives it wherever they live.")
	completed += 1


# --- the dead ---------------------------------------------------------------

func _test_being_the_subject_does_not_wake_the_dead() -> void:
	# Subject typing must not hand agency back. Being what an occurrence is
	# about is not the same as being able to notice it.
	var simulation := _sim()
	var state = simulation.state
	state.apply_physical_damage("mara", 100, {"source_type": "test"})
	assert(not state.is_alive("mara"), "the fixture failed to kill her")
	state.offer_perceivable_fact(_strike_on_mara())
	var reached: Array = simulation.tick_perception()
	for chance: Dictionary in reached:
		assert(str(chance["observer_id"]) != "mara",
			"a corpse was offered a chance to notice an event about itself")
	assert(state.get_all_knowledge("mara").is_empty()
		or not state.get_all_knowledge("mara").has("mara_struck"),
		"a corpse learned about the thing that happened to it")
	print("  STILL DEAD: being the subject grants no perception.")
	completed += 1


func _test_a_dead_observer_perceives_nothing() -> void:
	var simulation := _sim()
	var state = simulation.state
	state.apply_physical_damage("aster_king", 100, {"source_type": "test"})
	var fact := _strike_on_mara()
	fact["observability"] = "public"
	state.offer_perceivable_fact(fact)
	for chance: Dictionary in simulation.tick_perception():
		assert(str(chance["observer_id"]) != "aster_king",
			"a corpse was offered a public event")
	print("  NO GHOSTS: a dead observer is offered nothing, even in public.")
	completed += 1


# --- knowledge and history --------------------------------------------------

func _test_knowledge_keeps_the_person() -> void:
	var simulation := _learned_world()
	var state = simulation.state
	var record: Dictionary = state.get_knowledge("mara", "mara_struck")
	assert(not record.is_empty(), "nothing was learned to inspect")
	assert(str(record["subject_id"]) == "mara",
		"knowledge collapsed the subject to '%s'" % str(record["subject_id"]))
	print("  SUBJECT KEPT: what she knows is about Mara, not about Westfield.")
	completed += 1


func _test_knowledge_keeps_the_place() -> void:
	var simulation := _learned_world()
	var state = simulation.state
	var record: Dictionary = state.get_knowledge("mara", "mara_struck")
	assert(str(record.get("location_id", "")) == "westfield"
		or str(record["claim"]).contains("Westfield"),
		"knowledge lost where it happened: %s" % str(record))
	print("  PLACE KEPT: and it happened in Westfield.")
	completed += 1


func _test_presentation_leaks_no_ids() -> void:
	var phrase := PresentationRulesScript.occurrence_subject_phrase(
		WorldStateScript.SUBJECT_PERSON, "Mara", "Westfield")
	assert(phrase == "Mara in Westfield", "a person phrase reads '%s'" % phrase)
	var place := PresentationRulesScript.occurrence_subject_phrase(
		WorldStateScript.SUBJECT_LOCATION, "Aster", "Aster")
	assert(place == "Aster", "a place phrase repeats itself: '%s'" % place)
	for phrase_value: String in [phrase, place]:
		assert(not phrase_value.contains("_"), "a phrase leaked an id: %s" % phrase_value)
	assert(PresentationRulesScript.occurrence_subject_phrase(
		WorldStateScript.SUBJECT_PERSON, "", "Westfield").is_empty(),
		"a nameless subject produced a phrase anyway")
	print("  WORDS NOT IDS: '%s' and '%s'." % [phrase, place])
	completed += 1


func _test_a_person_event_is_not_a_settlement_event() -> void:
	# The confusion this milestone exists to prevent: Mara is not a place, and
	# nothing may treat her id as one.
	var state = _sim().state
	assert(not state.locations.has("mara"), "Mara is registered as a settlement")
	assert(state.subject_type_of("mara") == WorldStateScript.SUBJECT_PERSON,
		"Mara types as something other than a person")
	assert(state.subject_type_of("westfield") == WorldStateScript.SUBJECT_LOCATION,
		"Westfield types as something other than a place")
	assert(state.location_of_subject(WorldStateScript.SUBJECT_LOCATION, "mara").is_empty(),
		"Mara resolved as a location when asked for one")
	print("  NOT INTERCHANGEABLE: a person never resolves as a place.")
	completed += 1


func _test_it_is_not_world_history() -> void:
	var simulation := _learned_world()
	var state = simulation.state
	assert(simulation.chronicle_rules.world_history(state).is_empty(),
		"an event about one person became world history")
	print("  LOCAL: a person-subject event reached no world history.")
	completed += 1


func _test_episodes_group_by_location() -> void:
	# Episode grouping must read the location field, never infer a place from
	# whatever the subject happens to be.
	var simulation := _flooded_world()
	var state = simulation.state
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		var place := str(episode["location_id"])
		assert(state.locations.has(place),
			"an episode is filed under '%s', which is not a settlement" % place)
		for member_id in episode["member_record_ids"]:
			var record: Dictionary = state.get_chronicle(str(member_id))
			assert(str(record["location_id"]) == place,
				"a member of %s's episode happened somewhere else" % place)
	# And nothing filed at Aster was LOST. This is where grouping by subject
	# shows up: a social occurrence's subject is the person it was about, not
	# the settlement it happened in, so a layer matching subjects silently
	# drops every such record out of that settlement's history.
	var expected: Array[String] = []
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) == "interpretation":
			continue
		if str(record["location_id"]) == "aster":
			expected.append(str(record["id"]))
	var accounted: Dictionary = {}
	for episode: Dictionary in simulation.episode_rules.episodes_for_location(state, "aster"):
		for member_id in episode["member_record_ids"]:
			accounted[str(member_id)] = true
	for record: Dictionary in simulation.episode_rules.standalone_for_location(state, "aster"):
		accounted[str(record["id"])] = true
	assert(not expected.is_empty(), "the fixture put nothing at Aster")
	for record_id: String in expected:
		assert(accounted.has(record_id),
			"%s happened in Aster and appears in neither its episodes nor its leftovers" % record_id)
	print("  EPISODES BY PLACE: all %d records that happened in Aster are accounted for there." %
		expected.size())
	completed += 1


# --- nothing old changed ----------------------------------------------------

func _test_the_old_local_events_still_work() -> void:
	# The whole point of resolving rather than demanding: an occurrence written
	# before any of this existed behaves exactly as it did.
	var simulation := _sim()
	var state = simulation.state
	var legacy := {
		"id": "aster_food_shortage", "event_id": "drought", "subject_id": "aster",
		"topic": "food_shortage", "claim": "Aster does not have enough food",
		"confidence": 90, "truth_state": "true", "objective_truth_state": "true",
		"fresh_for_years": 3, "observability": "local", "participants": []
	}
	var king: Dictionary = simulation.perception_rules.evaluate(state, legacy, "aster_king")
	var mara: Dictionary = simulation.perception_rules.evaluate(state, legacy, "mara")
	assert(bool(king["eligible"]), "the King stopped seeing a shortage at home")
	assert(not bool(mara["eligible"]), "Mara started seeing Aster's shortage from Westfield")
	print("  LEGACY INTACT: a fact with no subject_type or location behaves as before.")
	completed += 1


func _test_location_smite_is_unchanged() -> void:
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	state.divine_power = state.max_divine_power
	# Room to fall: a settlement already at the floor cannot be broken further,
	# which would prove nothing either way.
	state.set_settlement_band("aster", "stability", 3)
	var before: int = state.get_settlement_band("aster", "stability")
	var result: Dictionary = simulation.resolve_action(
		"smite", "aster", DivineActionRules.INTENSITY_STRONG)
	assert(bool(result["ok"]), "smiting a settlement was refused: %s" % str(result["message"]))
	assert(state.get_settlement_band("aster", "stability") < before,
		"smiting a settlement stopped working")
	print("  LOCATION SMITE INTACT: Aster's stability %d -> %d." % [
		before, state.get_settlement_band("aster", "stability")])
	completed += 1


func _test_smiting_a_person_is_refused() -> void:
	# It used to land on whatever settlement the year's event was in. The god
	# struck a village believing they had struck somebody.
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	state.divine_power = state.max_divine_power
	var power: int = state.divine_power
	var bands: Array[int] = []
	for location_id: String in state.get_location_ids():
		bands.append(state.get_settlement_band(location_id, "stability"))
	var acts: int = state.divine_action_archive.size()
	var result: Dictionary = simulation.resolve_action(
		"smite", "mara", DivineActionRules.INTENSITY_OVERWHELMING)
	assert(not bool(result["ok"]), "a power was aimed at a person and accepted")
	assert(str(result["message"]).to_lower().contains("person"),
		"the refusal does not say why: %s" % str(result["message"]))
	assert(state.divine_power == power, "a refused aim spent power")
	assert(not state.action_taken, "a refused aim consumed the year")
	assert(state.divine_action_archive.size() == acts, "a refused aim was recorded")
	var index := 0
	for location_id: String in state.get_location_ids():
		assert(state.get_settlement_band(location_id, "stability") == bands[index],
			"a settlement was struck instead of the person")
		index += 1
	assert(state.is_alive("mara") and state.get_physical_damage("mara") == 0,
		"the person was harmed by a power that cannot reach them")
	print("  NO SILENT REDIRECT: '%s'" % str(result["message"]))
	completed += 1


func _test_an_unknown_target_still_falls_back() -> void:
	# The documented guard against a stale selection stranding the player is
	# untouched: an UNKNOWN id still falls back. Only a known person is refused.
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	state.divine_power = state.max_divine_power
	var result: Dictionary = simulation.resolve_action(
		"smite", "atlantis", DivineActionRules.INTENSITY_GENTLE)
	assert(bool(result["ok"]), "an unknown target stopped falling back")
	assert(state.locations.has(str(state.last_divine_target_id)),
		"the fallback landed somewhere that is not a settlement")
	print("  FALLBACK KEPT: an unknown id still lands on %s." % str(state.last_divine_target_id))
	completed += 1


# --- fixtures ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# A destructive occurrence ABOUT Mara, happening IN Westfield. Built by hand
# rather than by a power, because person-target Smite is deliberately not built.
func _strike_on_mara() -> Dictionary:
	return {
		"id": "mara_struck",
		"event_id": "test_divine_strike",
		"subject_id": "mara",
		"subject_type": WorldStateScript.SUBJECT_PERSON,
		"location_id": "westfield",
		"topic": "divine_destruction",
		"claim": "A destructive force struck Mara in Westfield",
		"confidence": 95,
		"truth_state": "true",
		"objective_truth_state": "true",
		"fresh_for_years": 3,
		"observability": "local",
		"participants": []
	}


func _learned_world() -> Object:
	var simulation := _sim()
	simulation.state.offer_perceivable_fact(_strike_on_mara())
	simulation.tick_perception()
	return simulation


func _flooded_world() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(20):
		state.action_taken = true
		simulation.advance_year()
	return simulation
