extends SceneTree

# Episode Compression v2.
#
# Compression changes how history is READ, not what happened.
#
# The failure this suite exists to prevent is not a crash. It is a history that
# reads beautifully and is wrong — four separate famines told as one endless
# one, a flood whose story ends the year the god stopped, a summary that
# explains why. Every test here is aimed at a way of over-telling.
#
# The other half is preservation. An episode stores nothing: it points at
# records by id and is rebuilt whenever it is asked for, so the archive cannot
# drift out of step with the stories told over it. Building every episode in
# the world must leave the chronicle byte-identical.

const WorldSimulationScript = preload("res://scripts/world_sim.gd")
const EpisodeRulesScript = preload("res://scripts/episode_rules.gd")
const ChronicleRulesScript = preload("res://scripts/chronicle_rules.gd")
const DivineActionRules = preload("res://scripts/divine_action_rules.gd")

const EXPECTED_TESTS := 20

var completed := 0


func _init() -> void:
	_test_the_archive_is_untouched()
	_test_every_member_is_a_real_record()
	_test_no_record_belongs_to_two_episodes()
	_test_a_recovery_closes_an_episode()
	_test_separate_famines_stay_separate()
	_test_a_crisis_that_never_lifts_is_one_long_episode()
	_test_a_lone_closed_record_is_not_a_story()
	_test_the_divine_arc_is_one_story()
	_test_the_arc_outlives_the_intervention()
	_test_the_arc_closes_when_the_world_recovers()
	_test_social_events_are_not_swallowed()
	_test_turning_points_are_selective()
	_test_the_ends_are_always_beats()
	_test_importance_does_not_inflate()
	_test_an_episode_is_not_world_history()
	_test_private_thoughts_are_not_members()
	_test_personal_chronicle_is_untouched()
	_test_provenance_survives()
	_test_no_title_invents_a_reason()
	_test_no_summary_invents_a_reason()

	if completed != EXPECTED_TESTS:
		push_error("EPISODE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		print("EPISODE TEST FAILED: %d of %d." % [completed, EXPECTED_TESTS])
		quit(1)
		return
	print("EPISODE TEST PASSED: the stories read, and the archive is exactly as it was.")
	quit(0)


# --- preservation -----------------------------------------------------------

func _test_the_archive_is_untouched() -> void:
	var quiet := _lived_world()
	var read := _lived_world()
	var before: int = read.state.chronicle.size()
	for pass_number in range(3):
		read.episode_rules.episodes(read.state)
		for location_id: String in read.state.get_location_ids():
			read.episode_rules.episodes_for_location(read.state, location_id)
			read.episode_rules.standalone_for_location(read.state, location_id)
		read.episode_rules.divine_episodes(read.state)
	assert(read.state.chronicle.size() == before,
		"building episodes changed how much history exists: %d -> %d" % [
			before, read.state.chronicle.size()])
	# Field by field against a run that was never compressed.
	assert(quiet.state.chronicle.size() == read.state.chronicle.size(), "the runs diverged")
	for index in range(quiet.state.chronicle.size()):
		var a: Dictionary = quiet.state.chronicle[index]
		var b: Dictionary = read.state.chronicle[index]
		for field: String in ["id", "year", "event_type", "summary", "importance",
			"source_record_id", "source_record_type", "location_id"]:
			assert(str(a[field]) == str(b[field]),
				"%s was rewritten by compression" % field)
		assert((a["caused_by"] as Array) == (b["caused_by"] as Array),
			"causality was rewritten by compression")
	print("  ARCHIVE INTACT: %d records identical after building every episode." % before)
	completed += 1


func _test_every_member_is_a_real_record() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for episode: Dictionary in simulation.episode_rules.episodes(state):
			assert(not (episode["member_record_ids"] as Array).is_empty(),
				"an episode with no members")
			for member_id in episode["member_record_ids"]:
				assert(state.has_chronicle(str(member_id)),
					"an episode points at a record that does not exist: %s" % str(member_id))
			for turning_id in episode["turning_point_ids"]:
				assert((episode["member_record_ids"] as Array).has(str(turning_id)),
					"a turning point is not a member of its own episode")
	print("  REAL MEMBERS: every member id resolves, every beat is a member.")
	completed += 1


func _test_no_record_belongs_to_two_episodes() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var seen: Dictionary = {}
		for episode: Dictionary in simulation.episode_rules.episodes(simulation.state):
			for member_id in episode["member_record_ids"]:
				assert(not seen.has(str(member_id)),
					"%s is told in two stories at once" % str(member_id))
				seen[str(member_id)] = true
	print("  ONE STORY EACH: no record appears in two episodes.")
	completed += 1


# --- boundaries -------------------------------------------------------------

func _test_a_recovery_closes_an_episode() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var closed := 0
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		if str(episode["episode_type"]) != EpisodeRulesScript.TYPE_CONDITION:
			continue
		if bool(episode["open"]):
			continue
		closed += 1
		var members: Array = episode["member_record_ids"]
		var last: Dictionary = state.get_chronicle(str(members[members.size() - 1]))
		assert(str(last["event_type"]) == "crisis_lifted",
			"a closed episode does not end in a recovery: %s" % str(episode["title"]))
	assert(closed > 0, "no episode ever closed")
	print("  RECOVERY CLOSES: all %d closed episodes end on a recovery." % closed)
	completed += 1


func _test_separate_famines_stay_separate() -> void:
	# THE over-compression trap. Aster's food crosses in and out repeatedly
	# across forty years; those are separate famines with real recoveries
	# between them, and telling them as one endless hunger would be a lie.
	var simulation := _lived_world()
	var state = simulation.state
	var hunger: Array[Dictionary] = []
	for episode: Dictionary in simulation.episode_rules.episodes_for_location(state, "aster"):
		if str(episode.get("band", "")) == "food":
			hunger.append(episode)
	assert(hunger.size() >= 3,
		"Aster's separate famines were merged into %d episode(s)" % hunger.size())
	# And none of them swallows the whole run.
	for episode: Dictionary in hunger:
		var span := int(episode["end_year"]) - int(episode["start_year"])
		assert(span < 30, "one episode covers %d years of Aster's history" % span)
	# They really are separated by recoveries.
	for index in range(hunger.size() - 1):
		assert(int(hunger[index]["end_year"]) <= int(hunger[index + 1]["start_year"]),
			"two famine episodes overlap")
	print("  SEPARATE CRISES: Aster's hunger is %d distinct episodes, not one." % hunger.size())
	completed += 1


func _test_a_crisis_that_never_lifts_is_one_long_episode() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	var found: Dictionary = {}
	for episode: Dictionary in simulation.episode_rules.episodes_for_location(state, "frontier"):
		if bool(episode["open"]) and int(episode["end_year"]) - int(episode["start_year"]) > 20:
			found = episode
	assert(not found.is_empty(), "the Frontier's unending hardship is not a story")
	assert(str(found["summary"]).contains("not lifted"),
		"an open episode does not say it is still running")
	print("  LONG HARDSHIP: '%s', %d years and still open." % [
		str(found["title"]), int(found["end_year"]) - int(found["start_year"])])
	completed += 1


func _test_a_lone_closed_record_is_not_a_story() -> void:
	var simulation := _lived_world()
	var state = simulation.state
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		if bool(episode["open"]):
			continue
		assert((episode["member_record_ids"] as Array).size() >= EpisodeRulesScript.MIN_MEMBERS,
			"a single occurrence was dressed up as an episode: %s" % str(episode["title"]))
	# And such records really do exist, still shown one at a time.
	var standalone := 0
	for location_id: String in state.get_location_ids():
		var alone: Array = simulation.episode_rules.standalone_for_location(state, location_id)
		standalone += alone.size()
		# And what is left over agrees with the location-relevance boundary:
		# a private conclusion was never this place's history to begin with,
		# so it cannot be one of its leftovers either.
		var history: Array = simulation.chronicle_rules.history_for_location(state, location_id)
		for record: Dictionary in alone:
			assert(str(record["source_record_type"])
				!= ChronicleRulesScript.SOURCE_INTERPRETATION,
				"a private conclusion was counted as %s's leftover history" % location_id)
			var known := false
			for kept: Dictionary in history:
				if str(kept["id"]) == str(record["id"]):
					known = true
			assert(known, "a leftover is not part of %s's history at all" % location_id)
	assert(standalone > 0, "every record was absorbed; nothing is shown on its own any more")
	print("  NOT EVERYTHING IS A STORY: %d records still stand alone." % standalone)
	completed += 1


# --- the divine arc ---------------------------------------------------------

func _test_the_divine_arc_is_one_story() -> void:
	var simulation := _flooded_world()
	var state = simulation.state
	var arcs: Array = simulation.episode_rules.divine_episodes(state)
	assert(arcs.size() == 1, "years of sustained rain produced %d arcs" % arcs.size())
	var arc: Dictionary = arcs[0]
	assert(str(arc["location_id"]) == "westfield", "the arc is in the wrong place")
	assert((arc["member_record_ids"] as Array).size() >= 8,
		"the arc gathered only %d records" % (arc["member_record_ids"] as Array).size())
	print("  ONE STORY: '%s', %d records over years %d-%d." % [
		str(arc["title"]), (arc["member_record_ids"] as Array).size(),
		int(arc["start_year"]), int(arc["end_year"])])
	completed += 1


func _test_the_arc_outlives_the_intervention() -> void:
	# The action may end before the history it created ends. An arc that closed
	# with the last raincloud would leave the flood as orphan entries.
	var simulation := _flooded_world()
	var state = simulation.state
	var arc: Dictionary = simulation.episode_rules.divine_episodes(state)[0]
	var last_act := 0
	for member_id in arc["member_record_ids"]:
		var record: Dictionary = state.get_chronicle(str(member_id))
		if str(record["source_record_type"]) == ChronicleRulesScript.SOURCE_DIVINE:
			last_act = maxi(last_act, int(record["year"]))
	assert(last_act > 0, "the arc contains no divine act")
	assert(int(arc["end_year"]) > last_act,
		"the arc ended in year %d, the same year the god stopped" % int(arc["end_year"]))
	# And the aftermath is really inside it.
	var after := 0
	for member_id in arc["member_record_ids"]:
		if int(state.get_chronicle(str(member_id))["year"]) > last_act:
			after += 1
	assert(after > 0, "nothing that happened after the god stopped is in the story")
	print("  AFTERMATH KEPT: god stopped in y%d, story runs to y%d, %d records after." % [
		last_act, int(arc["end_year"]), after])
	completed += 1


func _test_the_arc_closes_when_the_world_recovers() -> void:
	var simulation := _flooded_world()
	var state = simulation.state
	var arc: Dictionary = simulation.episode_rules.divine_episodes(state)[0]
	if bool(arc["open"]):
		# Legitimate if Westfield is still in crisis; assert that it really is.
		var still_bad := false
		for band: String in ["food", "stability", "prosperity"]:
			if state.get_settlement_band("westfield", band) == 0:
				still_bad = true
		assert(still_bad, "the arc is open while Westfield is entirely recovered")
		print("  STILL RUNNING: Westfield has not finished recovering.")
		completed += 1
		return
	var members: Array = arc["member_record_ids"]
	var last: Dictionary = state.get_chronicle(str(members[members.size() - 1]))
	assert(str(last["event_type"]) == "crisis_lifted",
		"the arc closed on something other than a recovery: %s" % str(last["event_type"]))
	print("  CLOSED ON RECOVERY: the story ends when the last crisis lifts, y%d." %
		int(arc["end_year"]))
	completed += 1


func _test_social_events_are_not_swallowed() -> void:
	# A refusal between two people that happened during a flood is its own
	# event, not a beat in the flood's story.
	var simulation := _flooded_world()
	var state = simulation.state
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		for member_id in episode["member_record_ids"]:
			var record: Dictionary = state.get_chronicle(str(member_id))
			assert(str(record["source_record_type"]) != ChronicleRulesScript.SOURCE_CONSEQUENCE,
				"a social occurrence was absorbed into '%s'" % str(episode["title"]))
	print("  NOT SWALLOWED: no social occurrence hides inside an episode.")
	completed += 1


# --- turning points and importance ------------------------------------------

func _test_turning_points_are_selective() -> void:
	# On a long episode. A two-record episode is an opening and a recovery and
	# both of those genuinely are beats; the claim being tested is that a story
	# with a MIDDLE does not mark all of it.
	var simulation := _flooded_world()
	var state = simulation.state
	var longest: Dictionary = {}
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		if longest.is_empty() or (episode["member_record_ids"] as Array).size() \
			> (longest["member_record_ids"] as Array).size():
			longest = episode
	var members: int = (longest["member_record_ids"] as Array).size()
	var beats: int = (longest["turning_point_ids"] as Array).size()
	assert(members >= 8, "no episode is long enough to test selectivity")
	assert(beats < members,
		"every one of %d records is a turning point" % members)
	print("  SELECTIVE: the longest story marks %d of %d records as beats." % [beats, members])
	completed += 1


func _test_the_ends_are_always_beats() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for episode: Dictionary in simulation.episode_rules.episodes(state):
			var members: Array = episode["member_record_ids"]
			var beats: Array = episode["turning_point_ids"]
			assert(beats.has(str(members[0])), "an episode does not mark its own beginning")
			assert(beats.has(str(members[members.size() - 1])),
				"an episode does not mark its own end")
	print("  ANCHORED: every episode marks where it began and where it ended.")
	completed += 1


func _test_importance_does_not_inflate() -> void:
	# Summing members would make a long dull episode outrank a short
	# catastrophic one by arithmetic. Importance stays anchored to the
	# strongest thing that actually happened.
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for episode: Dictionary in simulation.episode_rules.episodes(state):
			var strongest := 0
			var total := 0
			for member_id in episode["member_record_ids"]:
				var value := int(state.get_chronicle(str(member_id))["importance"])
				strongest = maxi(strongest, value)
				total += value
			var ceiling: int = strongest + EpisodeRulesScript.MAX_DURATION_BONUS \
				+ EpisodeRulesScript.MAX_BEAT_BONUS
			assert(int(episode["importance"]) <= ceiling,
				"'%s' scored %d, above its own ceiling of %d" % [
					str(episode["title"]), int(episode["importance"]), ceiling])
			assert(int(episode["importance"]) >= strongest,
				"an episode scored below its strongest member")
			if (episode["member_record_ids"] as Array).size() > 3:
				assert(int(episode["importance"]) < total,
					"a long episode's importance is the sum of its parts")
	print("  NO INFLATION: every episode sits between its strongest member and +20.")
	completed += 1


# --- boundaries with other layers -------------------------------------------

func _test_an_episode_is_not_world_history() -> void:
	var simulation := _flooded_world()
	var state = simulation.state
	var rules = simulation.chronicle_rules
	assert(not simulation.episode_rules.episodes(state).is_empty(), "no episodes to test")
	assert(rules.world_history(state).is_empty(),
		"an episode promoted local history to world history")
	print("  NOT PROMOTED: %d episodes, world history still empty." %
		simulation.episode_rules.episodes(state).size())
	completed += 1


func _test_private_thoughts_are_not_members() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		var state = simulation.state
		for episode: Dictionary in simulation.episode_rules.episodes(state):
			for member_id in episode["member_record_ids"]:
				var record: Dictionary = state.get_chronicle(str(member_id))
				assert(str(record["source_record_type"])
					!= ChronicleRulesScript.SOURCE_INTERPRETATION,
					"a private conclusion became part of a place's story")
	print("  STILL PRIVATE: no interpretation is a member of any episode.")
	completed += 1


func _test_personal_chronicle_is_untouched() -> void:
	var simulation := _lived_world()
	var before: int = simulation.personal_chronicle("aster_king").size()
	simulation.episode_rules.episodes(simulation.state)
	var after: int = simulation.personal_chronicle("aster_king").size()
	assert(before == after, "compression changed a life: %d -> %d" % [before, after])
	assert(before > 0, "the King has no life to protect")
	var turns: int = simulation.state.belief_turning_points.size()
	assert(turns > 0, "no belief turning points to protect")
	print("  LIVES UNTOUCHED: %d life entries and %d turning points, unchanged." % [
		before, turns])
	completed += 1


func _test_provenance_survives() -> void:
	var simulation := _flooded_world()
	var state = simulation.state
	for episode: Dictionary in simulation.episode_rules.episodes(state):
		# A cause named by an episode must be a real record OUTSIDE it: a cause
		# from inside is just the episode's own shape.
		for cause in episode["caused_by"]:
			assert(state.has_chronicle(str(cause)), "an episode cites a missing cause")
			assert(not (episode["member_record_ids"] as Array).has(str(cause)),
				"an episode claims to be caused by one of its own members")
	# And the underlying links are all still there.
	var links := 0
	for record: Dictionary in state.chronicle:
		links += (record["caused_by"] as Array).size()
	assert(links > 0, "causality vanished")
	print("  PROVENANCE: %d causal links intact beneath the episodes." % links)
	completed += 1


# --- the sentences ----------------------------------------------------------

func _test_no_title_invents_a_reason() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		for episode: Dictionary in simulation.episode_rules.episodes(simulation.state):
			var title := str(episode["title"]).to_lower()
			for word: String in _forbidden():
				assert(not title.contains(word),
					"a title claims a reason: %s" % str(episode["title"]))
			assert(not title.contains("_"), "a title leaked an id: %s" % title)
	print("  TITLES: name a condition and a place, and stop.")
	completed += 1


func _test_no_summary_invents_a_reason() -> void:
	for simulation: Object in [_lived_world(), _flooded_world()]:
		for episode: Dictionary in simulation.episode_rules.episodes(simulation.state):
			var summary := str(episode["summary"]).to_lower()
			assert(not summary.is_empty(), "an episode reads as nothing")
			for word: String in _forbidden():
				assert(not summary.contains(word),
					"a summary claims a reason: %s" % str(episode["summary"]))
			for word: String in summary.split(" "):
				assert(not word.contains("_"), "a summary leaked an id: %s" % summary)
	print("  SUMMARIES: state what happened and for how long.")
	completed += 1


func _forbidden() -> Array[String]:
	return [
		"punish", "mercy", "wrath", "sins", "sinful", "guilt", "deserved", "judg",
		"betray", "prophec", "curse", "blessed", "approv", "angry",
		"cruel", "because", "revenge", "chosen"
	]


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


# Sustained rain, then stopped, then long enough for the ground to drain.
func _flooded_world() -> Object:
	var simulation := _sim()
	var state = simulation.state
	for year in range(4):
		simulation.resolve_action("do_nothing")
		simulation.advance_year()
	simulation.resolve_action("send_rain", "westfield",
		DivineActionRules.INTENSITY_STRONG, DivineActionRules.MODE_UNTIL_STOPPED, 0)
	for year in range(12):
		state.action_taken = true
		simulation.advance_year()
	simulation.stop_intervention_for("send_rain", "westfield")
	for year in range(14):
		state.action_taken = true
		simulation.advance_year()
	return simulation
