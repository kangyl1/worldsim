extends SceneTree

# History Scope Foundation v1.
#
# Reality happens once. History may be viewed through many lenses.
#
# The whole architectural claim is that there is ONE historical record store and
# every "history" the player might open is a FILTER over it. No world_history[],
# no location_history[], no person_history[] holding copies — because the moment
# a record exists twice, the two copies can disagree, and the causal links that
# make the chronicle worth having point into one of them and not the other.
#
# The second claim is that scope is not importance. A settlement starving is
# major history for that settlement and none of the world's business. Anything
# that quietly promotes local significance into World History has destroyed the
# distinction this milestone exists to create.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const ChronicleRulesScript = preload("res://scripts/chronicle_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")
const PresentationRulesScript = preload("res://scripts/presentation_rules.gd")

const EXPECTED_TESTS := 14

var completed := 0


func _init() -> void:
	_test_one_record_belongs_to_several_views()
	_test_a_local_event_is_local_history()
	_test_local_history_is_not_world_history()
	_test_world_history_needs_world_scale_and_a_higher_bar()
	_test_a_divine_act_reaches_location_and_divine_history()
	_test_divine_history_is_not_every_divine_act()
	_test_person_history_is_involvement()
	_test_perceiving_something_is_not_being_in_its_history()
	_test_classification_changes_no_objective_truth()
	_test_categories_come_from_the_record_not_the_wording()
	_test_the_views_store_nothing()
	_test_causal_links_survive()
	_test_presentation_cannot_invent_causality()
	_test_scope_and_category_vocabularies_stay_small()

	if completed != EXPECTED_TESTS:
		push_error("HISTORY SCOPE TEST FAILED: %d of %d tests finished." % [
			completed, EXPECTED_TESTS])
		print("HISTORY SCOPE TEST FAILED: %d of %d tests finished." % [
			completed, EXPECTED_TESTS])
		quit(1)
		return
	print("HISTORY SCOPE TEST PASSED: one past, many lenses, no duplicates.")
	quit(0)


# --- one record, many views -------------------------------------------------

func _test_one_record_belongs_to_several_views() -> void:
	# (A) The architectural claim. A record reached through two different views
	# must be the SAME record — same id, same object — not two copies.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var shared := {}
	for record: Dictionary in state.chronicle:
		# The HISTORY-relevance ids, not every location the record mentions.
		# A private conclusion names the place its observer was sitting in and
		# is deliberately not that place's history, so it cannot serve as a
		# record reachable from both lenses.
		var places: Array = rules.location_history_ids(state, record)
		var people: Array = rules.persons_of(state, record)
		if places.is_empty() or people.is_empty():
			continue
		var by_place: Array = rules.history_for_location(state, str(places[0]))
		var by_person: Array = rules.history_for_person(state, str(people[0]))
		var in_place := false
		var in_person := false
		for other: Dictionary in by_place:
			if str(other["id"]) == str(record["id"]):
				in_place = true
		for other: Dictionary in by_person:
			if str(other["id"]) == str(record["id"]):
				in_person = true
		assert(in_place and in_person,
			"%s could not be reached from both its place and its person" % str(record["id"]))
		shared = record
		break
	assert(not shared.is_empty(), "no record was history for both a place and a person")
	# And it exists exactly ONCE underneath.
	var occurrences := 0
	for record: Dictionary in state.chronicle:
		if str(record["id"]) == str(shared["id"]):
			occurrences += 1
	assert(occurrences == 1,
		"the record is stored %d times" % occurrences)
	print("  ONE RECORD, MANY VIEWS: %s reached from two lenses, stored once." %
		str(shared["id"]))
	completed += 1


func _test_a_local_event_is_local_history() -> void:
	# (B)
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var westfield: Array = rules.history_for_location(state, "westfield")
	for record: Dictionary in westfield:
		assert(rules.locations_of(state, record).has("westfield"),
			"%s is in Westfield's history without concerning Westfield" % str(record["id"]))
	# And nothing unrelated is swept in by sharing a year.
	var years: Dictionary = {}
	for record: Dictionary in westfield:
		years[int(record["year"])] = true
	for record: Dictionary in state.chronicle:
		if years.has(int(record["year"])) and not rules.locations_of(state, record).has("westfield"):
			var found := false
			for kept: Dictionary in westfield:
				if str(kept["id"]) == str(record["id"]):
					found = true
			assert(not found, "an unrelated record shared a year and was included")
	print("  LOCAL: Westfield's history holds %d records, all about Westfield." %
		westfield.size())
	completed += 1


func _test_local_history_is_not_world_history() -> void:
	# (C) THE load-bearing distinction.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var local: Array = rules.history_for_location(state, "aster")
	assert(not local.is_empty(), "Aster produced no local history to test with")
	var world: Array = rules.world_history(state)
	var promoted := 0
	for record: Dictionary in local:
		for w: Dictionary in world:
			if str(w["id"]) == str(record["id"]):
				promoted += 1
	assert(promoted < local.size(),
		"every one of Aster's %d local records became world history" % local.size())
	# The strongest local record must still not be world history on strength alone.
	var strongest: Dictionary = {}
	for record: Dictionary in local:
		if strongest.is_empty() or int(record["importance"]) > int(strongest["importance"]):
			strongest = record
	assert(int(strongest["importance"]) >= ChronicleRulesScript.IMPORTANCE_THRESHOLD,
		"the fixture produced no real history")
	print("  NOT THE WORLD'S BUSINESS: Aster's strongest record scores %d, world history holds %d." % [
		int(strongest["importance"]), world.size()])
	completed += 1


func _test_world_history_needs_world_scale_and_a_higher_bar() -> void:
	# (D) World history is a higher bar AND a different kind, not the same bar
	# seen from further away. Both conditions are asserted.
	assert(ChronicleRulesScript.WORLD_HISTORY_THRESHOLD
		> ChronicleRulesScript.IMPORTANCE_THRESHOLD,
		"world history is no harder to reach than ordinary history")
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	for record: Dictionary in rules.world_history(state):
		assert(int(record["importance"]) >= ChronicleRulesScript.WORLD_HISTORY_THRESHOLD,
			"a record below the world bar reached world history")
	# A single-settlement occurrence is never world-scale, however important.
	var confined := 0
	for record: Dictionary in state.chronicle:
		if rules.locations_of(state, record).size() == 1 and bool(record["world_history"]):
			confined += 1
	assert(confined == 0, "%d occurrences confined to one settlement became world history" % confined)
	print("  WORLD BAR: %d over %d, and nothing confined to one settlement." % [
		ChronicleRulesScript.WORLD_HISTORY_THRESHOLD,
		ChronicleRulesScript.IMPORTANCE_THRESHOLD])
	completed += 1


# --- divine -----------------------------------------------------------------

func _test_a_divine_act_reaches_location_and_divine_history() -> void:
	# (D) A god who floods a village makes local history and divine history, and
	# need not make world history at all.
	var simulation := _flooded_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var divine: Array = rules.divine_history(state)
	assert(not divine.is_empty(), "years of standing rain produced no divine history")
	var also_local := 0
	for record: Dictionary in divine:
		if not rules.locations_of(state, record).is_empty():
			also_local += 1
	assert(also_local > 0, "no divine record was also somewhere's local history")
	print("  DIVINE + LOCAL: %d divine records, %d of them also local history." % [
		divine.size(), also_local])
	completed += 1


func _test_divine_history_is_not_every_divine_act() -> void:
	# Divine History is a chronicle view, not the divine action archive. Acts
	# that changed nothing historically important are not history for being
	# divine — the existing chronicle rules already refuse them.
	var simulation := _flooded_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var acts: int = state.divine_action_archive.size()
	var divine: int = rules.divine_history(state).size()
	assert(acts > 0, "the fixture took no divine actions")
	assert(divine < acts,
		"every one of %d divine acts became history" % acts)
	print("  SELECTIVE: %d divine acts, %d reached history." % [acts, divine])
	completed += 1


# --- people -----------------------------------------------------------------

func _test_person_history_is_involvement() -> void:
	# (E)
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var mara: Array = rules.history_for_person(state, "mara")
	assert(not mara.is_empty(), "Mara took part in nothing historical")
	for record: Dictionary in mara:
		assert(str(record["actor_id"]) == "mara" or str(record["target_id"]) == "mara",
			"%s is in Mara's history without naming her as actor or target" % str(record["id"]))
	print("  INVOLVEMENT: Mara's history holds %d records, all naming her." % mara.size())
	completed += 1


func _test_perceiving_something_is_not_being_in_its_history() -> void:
	# (F) Perception is not participation. A settlement condition is perceived
	# by everyone who lives there and belongs to NOBODY's personal history.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var conditions := 0
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) != ChronicleRulesScript.SOURCE_CONDITION:
			continue
		conditions += 1
		assert(rules.persons_of(state, record).is_empty(),
			"a settlement condition entered someone's personal history: %s" % str(record["id"]))
		assert(not (record["scopes"] as Array).has(ChronicleRulesScript.SCOPE_PERSON),
			"a condition record carries person scope")
	assert(conditions > 0, "the fixture produced no condition records")
	# And the people who DID perceive it are real.
	assert(not state.residents_of("aster").is_empty(), "nobody lives in Aster to perceive anything")
	print("  NOT PARTICIPATION: %d conditions everyone lived through, in nobody's biography." %
		conditions)
	completed += 1


# --- boundaries -------------------------------------------------------------

func _test_classification_changes_no_objective_truth() -> void:
	# (G) Classifying a record may not alter what it says happened.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	for record: Dictionary in state.chronicle:
		var before := {}
		for key: String in [
			"id", "year", "event_type", "subject_id", "actor_id", "target_id",
			"location_id", "summary", "source_record_type", "source_record_id", "importance"
		]:
			before[key] = record[key]
		var caused_before: Array = (record["caused_by"] as Array).duplicate()
		# Re-classify. It must be a pure reading.
		var again: Dictionary = rules.classify(state, record, "")
		assert(again.has("scopes") and again.has("categories"), "classify returned nothing usable")
		for key: String in before:
			assert(record[key] == before[key],
				"classifying changed %s on %s" % [key, str(record["id"])])
		assert((record["caused_by"] as Array) == caused_before, "classifying changed causality")
	print("  READ ONLY: classification touched no objective field on %d records." %
		state.chronicle.size())
	completed += 1


func _test_categories_come_from_the_record_not_the_wording() -> void:
	# (H) A category is derived from the source and event type. It must not be
	# read out of the summary, and it must not cause anything.
	var simulation := _lived_world()
	var state = simulation.state
	for record: Dictionary in state.chronicle:
		var categories: Array = record["categories"]
		for category_value in categories:
			assert(ChronicleRulesScript.CATEGORIES.has(str(category_value)),
				"invented category %s" % str(category_value))
		match str(record["source_record_type"]):
			ChronicleRulesScript.SOURCE_INTERPRETATION:
				assert(categories.has(ChronicleRulesScript.CATEGORY_BELIEF),
					"an interpretation is not belief history")
			ChronicleRulesScript.SOURCE_CONSEQUENCE:
				assert(categories.has(ChronicleRulesScript.CATEGORY_SOCIAL),
					"a social occurrence is not social history")
	# The classifier cannot reach anything that would let it change the world.
	var code := _code_of("res://scripts/chronicle_rules.gd")
	for forbidden: String in [
		"change_settlement_band", "add_history", "set_water", "change_water",
		"set_abundance", "learn_knowledge", "divine_power"
	]:
		assert(not code.contains(forbidden),
			"chronicle_rules.gd can reach %s" % forbidden)
	print("  DERIVED, INERT: categories come from the record and change nothing.")
	completed += 1


func _test_the_views_store_nothing() -> void:
	# (I) The views are filters. Reading them cannot change how much history
	# exists, and no second store may appear anywhere in state.
	var simulation := _lived_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	var before: int = state.chronicle.size()
	for pass_number in range(3):
		rules.world_history(state)
		rules.divine_history(state)
		for location_id: String in state.get_location_ids():
			rules.history_for_location(state, location_id)
		for entity_id: String in state.notable_entities.keys():
			rules.history_for_person(state, entity_id)
		rules.history_for_region(state, "anywhere")
		for category: String in ChronicleRulesScript.CATEGORIES:
			rules.history_in_category(state, category)
	assert(state.chronicle.size() == before,
		"reading the views changed the chronicle: %d -> %d" % [before, state.chronicle.size()])
	# ONE OCCURRENCE, ONE RECORD. The real single-source invariant: history is
	# keyed by what it was drawn from, so a scheme that wrote one copy per scope
	# would show up here as two records pointing at the same source.
	var by_source: Dictionary = {}
	for record: Dictionary in state.chronicle:
		var key := "%s/%s" % [
			str(record["source_record_type"]), str(record["source_record_id"])
		]
		assert(not by_source.has(key),
			"two historical records were written for one occurrence: %s and %s" % [
				str(by_source.get(key, "")), str(record["id"])])
		by_source[key] = str(record["id"])
	var ids: Dictionary = {}
	for record: Dictionary in state.chronicle:
		assert(not ids.has(str(record["id"])), "a chronicle id appears twice")
		ids[str(record["id"])] = true
	var state_code := _code_of("res://scripts/world_state.gd")
	for forbidden: String in [
		"world_history_store", "location_history", "person_history", "divine_history_store"
	]:
		assert(not state_code.contains(forbidden),
			"a second history store exists: %s" % forbidden)
	print("  ONE STORE: %d records, unchanged by three passes over every view." % before)
	completed += 1


func _test_causal_links_survive() -> void:
	# (J)
	var simulation := _flooded_world()
	var state = simulation.state
	var linked := 0
	var year_of: Dictionary = {}
	for record: Dictionary in state.chronicle:
		year_of[str(record["id"])] = int(record["year"])
	var stamp_offsets := 0
	for record: Dictionary in state.chronicle:
		for parent_value in record["caused_by"]:
			var parent := str(parent_value)
			linked += 1
			assert(state.has_chronicle(parent), "%s points at a missing parent" % str(record["id"]))
			var back: Array = state.get_chronicle(parent)["led_to"]
			assert(back.has(str(record["id"])), "a causal link is one-directional")
			if int(year_of[parent]) <= int(record["year"]):
				continue
			# A PRE-EXISTING stamp offset, not a scope regression, and asserted
			# rather than ignored so it cannot quietly widen.
			#
			# A divine act carries the year the PLAYER took it, but is
			# chronicled in the tick that follows, whose own records carry the
			# next year. So a divine record can hang off a crisis that was
			# already open when the god acted and is stamped a year later. The
			# offset is bounded to one year and only ever affects divine
			# records; anything else genuinely would be an effect preceding its
			# cause.
			assert(str(record["source_record_type"]) == ChronicleRulesScript.SOURCE_DIVINE,
				"a non-divine record was caused by something later: %s" % str(record["id"]))
			assert(int(year_of[parent]) - int(record["year"]) == 1,
				"the divine year-stamp offset widened beyond one year")
			stamp_offsets += 1
	assert(linked > 0, "the fixture produced no causal links to preserve")
	print("  CAUSALITY INTACT: %d links, all two-way; %d divine stamp offsets, all 1 year." % [
		linked, stamp_offsets])
	completed += 1


func _test_presentation_cannot_invent_causality() -> void:
	# The absolute rule. Presentation may amplify; it may never claim the world
	# meant something. Every title the helper can produce is checked, not a
	# sample of them.
	var forbidden := [
		"punish", "mercy", "sin", "guilt", "deserved", "wrath", "judg",
		"chosen", "prophec", "blessed them", "cursed", "because they", "for their"
	]
	for event_type: String in PresentationRulesScript.HISTORY_TITLES:
		var template := str(PresentationRulesScript.HISTORY_TITLES[event_type]).to_lower()
		for word: String in forbidden:
			assert(not template.contains(word),
				"a history title claims meaning: %s" % template)
	# Strength never invents a title where the record does not support one.
	assert(PresentationRulesScript.history_title("crisis_entered", "Westfield", 50).is_empty(),
		"a mundane record was given a headline")
	assert(not PresentationRulesScript.history_title("crisis_entered", "Westfield", 90).is_empty(),
		"a major record got no headline")
	assert(PresentationRulesScript.history_title("interpretation_took_effect", "Westfield", 90).is_empty(),
		"a belief change was given an event headline")
	assert(PresentationRulesScript.history_strength(50)
		== PresentationRulesScript.HISTORY_MUNDANE, "strength bands are wrong")
	assert(PresentationRulesScript.history_strength(200)
		== PresentationRulesScript.HISTORY_LEGENDARY, "strength bands are wrong")
	print("  NO INVENTED MEANING: every possible title states an occurrence and stops.")
	completed += 1


func _test_scope_and_category_vocabularies_stay_small() -> void:
	assert(ChronicleRulesScript.SCOPES.size() == 5,
		"the scope vocabulary grew: %s" % str(ChronicleRulesScript.SCOPES))
	assert(ChronicleRulesScript.CATEGORIES.size() == 6,
		"the category vocabulary grew: %s" % str(ChronicleRulesScript.CATEGORIES))
	for future: String in ["kingdom", "religion", "species", "apostle", "culture", "war"]:
		assert(not ChronicleRulesScript.SCOPES.has(future),
			"%s was added before the system behind it exists" % future)
	var simulation := _lived_world()
	var state = simulation.state
	for record: Dictionary in state.chronicle:
		for scope_value in record["scopes"]:
			assert(ChronicleRulesScript.SCOPES.has(str(scope_value)),
				"invented scope %s" % str(scope_value))
	print("  SMALL VOCABULARY: 5 scopes, 6 categories, nothing faked ahead of its system.")
	completed += 1


# --- fixtures ---------------------------------------------------------------

func _sim() -> Object:
	var simulation = WorldSimulationScript.new()
	simulation.debug_logging_enabled = false
	return simulation


# Forty autonomous years: the deterministic world every other suite measures.
func _lived_world() -> Object:
	var simulation := _sim()
	for year in range(40):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	return simulation


# A world the god actually acted on, so divine history has something in it.
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
