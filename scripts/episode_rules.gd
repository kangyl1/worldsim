class_name EpisodeRules
extends RefCounted

# Episode Compression v2 — historical episodes.
#
# Compression changes how history is READ, not what happened.
#
# The raw chronicle keeps every objective occurrence and is never touched by
# anything here. An episode is a VIEW: it names a span of years, points at the
# records inside it by id, and says which of them were the moments that
# mattered. It stores no record of its own, copies no summary, and is rebuilt
# from the chronicle every time it is asked for — so there is no second history
# to fall out of step with the first.
#
# Two families in v2, both grounded in records that already exist:
#
#   CONTINUING CONDITION — one settlement, one band, from the year it went
#   wrong to the year it came right. A genuine recovery CLOSES an episode, so
#   four separate famines stay four separate famines. The world's own state
#   transitions draw the boundaries; no fixed year-gap is invented.
#
#   DIVINE ARC — from the god's first act at a place until the world has
#   finished living with it. Deliberately NOT until the god stops: the action
#   may end long before the history it created ends, and an arc that closed
#   with the last raincloud would leave the flood it caused as orphan entries.
#
# What this layer may never do is manufacture truth. Every sentence it produces
# is assembled from what its members already say, and a test greps everything it
# can generate for punishment, mercy, wrath and the rest.

const TYPE_CONDITION := "continuing_condition"
const TYPE_DIVINE_ARC := "divine_arc"

const SOURCE_CONDITION := "settlement_condition"
const SOURCE_DIVINE := "divine_action"

# A lone closed record is an occurrence, not a story: it stays a standalone
# entry rather than being dressed up as an episode of one. A lone OPEN one is
# different — a settlement that has been destitute for thirty years without a
# single further record is exactly the kind of long hardship this layer exists
# to make legible.
const MIN_MEMBERS := 2
const MIN_OPEN_YEARS := 5

# A member severe enough to be a beat in its own right, rather than the middle
# of something. Deliberately well above the chronicle's own threshold of 50.
const TURNING_POINT_IMPORTANCE := 80

# Importance is the strongest thing that happened, nudged by how long it ran and
# how many real beats it had. NOT a sum: summing would make a long dull episode
# outrank a short catastrophic one purely by arithmetic.
const MAX_DURATION_BONUS := 10
const MAX_BEAT_BONUS := 10

# The band value a settlement is in crisis at, matching the chronicle's own.
const CRISIS_BAND := 0


# Whether the trouble is STILL trouble, asked of the world rather than of the
# records.
#
# This matters more than it looks. The chronicle deliberately suppresses a
# transition that repeats too soon, so some recoveries are never written down:
# Westfield's food entered crisis in year 35, quietly recovered, and no lift was
# recorded. Reasoning from records alone, an episode concluded the settlement
# was still starving years after it had stopped — a false sentence assembled
# entirely from true records. The settlement's own band is the authority on
# whether it is still in trouble.
func _still_in_crisis(state: WorldState, location_id: String, band: String) -> bool:
	return state.get_settlement_band(location_id, band) == CRISIS_BAND


# Every episode in the world, newest last. Rebuilt on demand.
func episodes(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var claimed: Dictionary = {}
	# Divine arcs first: where a god's act and a settlement's collapse describe
	# the same years, the arc is the story and the conditions are its beats.
	for episode: Dictionary in _divine_arcs(state, claimed):
		found.append(episode)
	for episode: Dictionary in _condition_episodes(state, claimed):
		found.append(episode)
	found.sort_custom(func(a, b): return int(a["start_year"]) < int(b["start_year"]))
	return found


func episodes_for_location(state: WorldState, location_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for episode: Dictionary in episodes(state):
		if str(episode["location_id"]) == location_id:
			found.append(episode)
	return found


func divine_episodes(state: WorldState) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for episode: Dictionary in episodes(state):
		if str(episode["episode_type"]) == TYPE_DIVINE_ARC:
			found.append(episode)
	return found


# The records at this location that no episode speaks for, and which a reader
# therefore still sees one at a time. Reported rather than hidden: a layer that
# claimed to cover everything would be over-compressing by definition.
func standalone_for_location(state: WorldState, location_id: String) -> Array[Dictionary]:
	var covered: Dictionary = {}
	for episode: Dictionary in episodes_for_location(state, location_id):
		for member_id in episode["member_record_ids"]:
			covered[str(member_id)] = true
	var found: Array[Dictionary] = []
	for record: Dictionary in _location_records(state, location_id):
		if not covered.has(str(record["id"])):
			found.append(record)
	return found


# --- continuing conditions --------------------------------------------------

func _condition_episodes(state: WorldState, claimed: Dictionary) -> Array[Dictionary]:
	var runs: Dictionary = {}
	var order: Array[String] = []
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) != SOURCE_CONDITION:
			continue
		if claimed.has(str(record["id"])):
			continue
		var key := "%s/%s" % [str(record["location_id"]), _band_of(record)]
		if not runs.has(key):
			runs[key] = [] as Array[Dictionary]
			order.append(key)
		(runs[key] as Array).append(record)

	var found: Array[Dictionary] = []
	for key: String in order:
		var members: Array[Dictionary] = []
		for record: Dictionary in runs[key]:
			members.append(record)
			# A GENUINE RECOVERY closes the story. Everything after it belongs
			# to whatever goes wrong next, which is why four famines separated
			# by four recoveries stay four famines.
			if str(record["event_type"]) != "crisis_lifted":
				continue
			var closed := _build_condition_episode(state, key, members, false)
			if not closed.is_empty():
				found.append(closed)
			members = []
		if not members.is_empty():
			var open_episode := _build_condition_episode(state, key, members, true)
			if not open_episode.is_empty():
				found.append(open_episode)
	return found


func _build_condition_episode(
	state: WorldState, key: String, members: Array[Dictionary], is_open: bool
) -> Dictionary:
	var parts := key.split("/")
	var location_id := str(parts[0])
	var band := str(parts[1])
	# A run with no recorded recovery is only still running if the settlement
	# is still in trouble. Otherwise it recovered without the chronicle saying
	# so, and the story ends at the last thing actually written down.
	var really_open := is_open and _still_in_crisis(state, location_id, band)
	is_open = really_open
	var end_year := int(state.year) if is_open else int(members[members.size() - 1]["year"])
	var duration := end_year - int(members[0]["year"])
	if members.size() < MIN_MEMBERS and not (is_open and duration >= MIN_OPEN_YEARS):
		return {}
	var episode := _base_episode(state, TYPE_CONDITION, location_id, members, is_open)
	episode["band"] = band
	episode["title"] = _condition_title(state, location_id, band, episode)
	episode["summary"] = _condition_summary(state, band, members, episode)
	return episode


# --- divine arcs ------------------------------------------------------------

func _divine_arcs(state: WorldState, claimed: Dictionary) -> Array[Dictionary]:
	var by_place: Dictionary = {}
	var order: Array[String] = []
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) != SOURCE_DIVINE:
			continue
		var location_id := str(record["location_id"])
		if location_id.is_empty():
			continue
		if not by_place.has(location_id):
			by_place[location_id] = [] as Array[Dictionary]
			order.append(location_id)
		(by_place[location_id] as Array).append(record)

	var found: Array[Dictionary] = []
	for location_id: String in order:
		var acts: Array = by_place[location_id]
		var start_year := int(acts[0]["year"])
		var members: Array[Dictionary] = []
		# Which crises this arc opened and has not yet seen closed. While any
		# remain, the world is still living with what the god did, and the
		# episode is still running even if the god stopped years ago.
		var unresolved: Dictionary = {}
		var damaged: Dictionary = {}
		# A ONE-SHOT act leaves no condition record of its own damage.
		#
		# The chronicle compares each year against the world as it stood at the
		# TOP of that year, which is after the player has already acted. A standing
		# order's damage therefore shows up as a transition and a single strike's
		# never does. The act still knows exactly what it moved, because its
		# consequence records every band it changed and what it changed it to, and
		# reading that is what lets an arc follow a one-shot act's aftermath at
		# all. Without it a smite is a one-year story about nothing.
		for act_value in acts:
			var act: Dictionary = act_value
			# chronicle record -> the divine act it points at -> that act's
			# consequence. The chronicle record's own source id is the ACT's, not
			# the consequence's, and following the wrong one silently finds nothing.
			var divine_record: Dictionary = state.get_divine_action(str(act["source_record_id"]))
			var caused: Dictionary = state.get_consequence(
				str(divine_record.get("consequence_id", "")))
			for change_value in caused.get("state_changes", []):
				var change: Dictionary = change_value
				if int(change.get("after", 1)) == CRISIS_BAND:
					unresolved[str(change["field"])] = true
					damaged[str(change["field"])] = true
		var end_year := start_year
		for record: Dictionary in _location_records(state, location_id):
			if int(record["year"]) < start_year:
				continue
			var source := str(record["source_record_type"])
			if source != SOURCE_DIVINE and source != SOURCE_CONDITION:
				# Social occurrences that merely happened here are their own
				# events and must not be swallowed by a flood's story.
				continue
			var still_running := not unresolved.is_empty()
			var is_act := source == SOURCE_DIVINE
			# Only the bands the god actually drove into crisis. A famine that
			# was already running when the strike landed is not the strike's
			# story, and sweeping every later trouble at the same place into
			# the arc would be over-compression wearing a god's name.
			if not is_act and not damaged.has(_band_of(record)):
				continue
			if not is_act and not still_running and int(record["year"]) > _last_year(acts):
				# The world has finished with it, and this is a new trouble.
				break
			members.append(record)
			end_year = int(record["year"])
			if source != SOURCE_CONDITION:
				continue
			var band := _band_of(record)
			if str(record["event_type"]) == "crisis_entered":
				unresolved[band] = true
			else:
				unresolved.erase(band)
		if members.is_empty():
			continue
		var still_open := false
		for band: String in unresolved:
			if _still_in_crisis(state, location_id, band):
				still_open = true
		var is_open := still_open
		var episode := _base_episode(state, TYPE_DIVINE_ARC, location_id, members, is_open)
		episode["end_year"] = int(state.year) if is_open else end_year
		episode["title"] = _divine_title(state, location_id, episode)
		episode["summary"] = _divine_summary(state, location_id, members, episode)
		for member: Dictionary in members:
			claimed[str(member["id"])] = true
		found.append(episode)
	return found


# --- shared -----------------------------------------------------------------

func _base_episode(
	state: WorldState, episode_type: String, location_id: String,
	members: Array[Dictionary], is_open: bool
) -> Dictionary:
	var member_ids: Array[String] = []
	var turning_points: Array[String] = []
	var strongest := 0
	var causes: Array[String] = []
	for index in range(members.size()):
		var record: Dictionary = members[index]
		member_ids.append(str(record["id"]))
		strongest = maxi(strongest, int(record["importance"]))
		if _is_turning_point(record, index, members):
			turning_points.append(str(record["id"]))
		# Provenance: a cause from OUTSIDE the episode is what the episode as a
		# whole came out of. One inside it is just its own shape.
		for parent_value in record["caused_by"]:
			var parent := str(parent_value)
			if not causes.has(parent):
				causes.append(parent)
	var kept_causes: Array[String] = []
	for cause: String in causes:
		if not member_ids.has(cause):
			kept_causes.append(cause)

	var start_year := int(members[0]["year"])
	var end_year := int(state.year) if is_open else int(members[members.size() - 1]["year"])
	var duration := maxi(end_year - start_year, 0)
	return {
		"id": "ep_%s_%s_%04d" % [episode_type.substr(0, 4), location_id, start_year],
		"episode_type": episode_type,
		"start_year": start_year,
		"end_year": end_year,
		"open": is_open,
		"location_id": location_id,
		"scope": "location",
		"member_record_ids": member_ids,
		"turning_point_ids": turning_points,
		"caused_by": kept_causes,
		"importance": strongest
			+ mini(duration / 2, MAX_DURATION_BONUS)
			+ mini(turning_points.size() * 2, MAX_BEAT_BONUS),
		"title": "",
		"summary": ""
	}


# A beat, rather than the middle of something.
#
# The first and last records anchor the story; a severe member is a beat on its
# own account; a divine act is a beat only where it BEGINS or ENDS the god's
# involvement, because the eleventh identical raincloud is the middle.
func _is_turning_point(record: Dictionary, index: int, members: Array[Dictionary]) -> bool:
	if index == 0 or index == members.size() - 1:
		return true
	if int(record["importance"]) >= TURNING_POINT_IMPORTANCE:
		return true
	if str(record["source_record_type"]) == SOURCE_DIVINE:
		var previous: Dictionary = members[index - 1]
		var following: Dictionary = members[index + 1]
		var opens := str(previous["source_record_type"]) != SOURCE_DIVINE
		var closes := str(following["source_record_type"]) != SOURCE_DIVINE
		return opens or closes
	return false


# The records that are this place's HISTORY, which is narrower than the records
# that merely name it.
#
# Interpretations are excluded for the same reason History Relevance excluded
# them: they are filed at the observer's home, and somebody forming an opinion
# in the capital is not something that happened to the capital. Counting them
# here made this layer disagree with `history_for_location()` — Aster reported
# thirty records of history and forty of them left over.
const SOURCE_INTERPRETATION := "interpretation"


func _location_records(state: WorldState, location_id: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for record: Dictionary in state.chronicle:
		if str(record["source_record_type"]) == SOURCE_INTERPRETATION:
			continue
		if str(record["location_id"]) == location_id:
			found.append(record)
	found.sort_custom(func(a, b): return int(a["year"]) < int(b["year"]))
	return found


func _band_of(record: Dictionary) -> String:
	var parts: PackedStringArray = str(record["source_record_id"]).split("_")
	return str(parts[parts.size() - 1])


func _last_year(records: Array) -> int:
	var latest := 0
	for record: Dictionary in records:
		latest = maxi(latest, int(record["year"]))
	return latest


# --- wording ----------------------------------------------------------------
#
# Assembled from the band, the place, the length and whether it ever ended.
# There is no table of dramatic phrases and no way for a motive to enter.

const BAND_NOUNS := {
	"food": "hunger",
	"stability": "unrest",
	"prosperity": "hardship"
}


func _band_noun(band: String) -> String:
	return str(BAND_NOUNS.get(band, band.replace("_", " ")))


func _condition_title(
	state: WorldState, location_id: String, band: String, episode: Dictionary
) -> String:
	var place := state.location_name(location_id).to_upper()
	var years := int(episode["end_year"]) - int(episode["start_year"])
	if bool(episode["open"]) and years >= MIN_OPEN_YEARS:
		return "THE LONG %s OF %s" % [_band_noun(band).to_upper(), place]
	if years >= MIN_OPEN_YEARS:
		return "THE %s YEARS IN %s" % [_band_noun(band).to_upper(), place]
	return "THE %s OF %s" % [_band_noun(band).to_upper(), place]


func _condition_summary(
	state: WorldState, band: String, members: Array[Dictionary], episode: Dictionary
) -> String:
	var years := int(episode["end_year"]) - int(episode["start_year"])
	var noun := _band_noun(band)
	var span := "for a single year" if years <= 1 else "for %d years" % years
	if bool(episode["open"]):
		return "%s has lived with %s %s, and it has not lifted." % [
			state.location_name(str(episode["location_id"])), noun, span
		]
	var relapses := 0
	for record: Dictionary in members:
		if str(record["event_type"]) == "crisis_entered":
			relapses += 1
	var middle := " It returned before it was over." if relapses > 1 else ""
	return "%s lived with %s %s before it lifted.%s" % [
		state.location_name(str(episode["location_id"])), noun, span, middle
	]


func _divine_title(state: WorldState, location_id: String, episode: Dictionary) -> String:
	var place := state.location_name(location_id).to_upper()
	var years := int(episode["end_year"]) - int(episode["start_year"])
	if years >= MIN_OPEN_YEARS:
		return "THE YEARS THE GOD ACTED ON %s" % place
	return "THE GOD'S HAND ON %s" % place


# States the act, the objective consequence, and how long the place carried it.
# It may say the god acted and that a settlement then suffered, because both are
# recorded. It may not say why, and there is nowhere here for why to come from.
func _divine_summary(
	state: WorldState, location_id: String, members: Array[Dictionary], episode: Dictionary
) -> String:
	var place := state.location_name(location_id)
	var acts := 0
	var last_act_year := 0
	var troubles := 0
	for record: Dictionary in members:
		if str(record["source_record_type"]) == SOURCE_DIVINE:
			acts += 1
			last_act_year = maxi(last_act_year, int(record["year"]))
		elif str(record["event_type"]) == "crisis_entered":
			troubles += 1
	var opening := "The god acted on %s %s." % [
		place, "once" if acts <= 1 else "%d times over %d years" % [
			acts, maxi(last_act_year - int(episode["start_year"]), 1)
		]
	]
	if troubles == 0:
		# A single strike leaves no condition record of its own damage, so an
		# arc can be long and have nothing but the act in it. Saying only that
		# the god acted would hide the reason the story is still running.
		if bool(episode["open"]):
			return "%s %s has not recovered in the %d years since." % [
				opening, place, maxi(int(episode["end_year"]) - int(episode["start_year"]), 1)
			]
		return opening
	var after := int(episode["end_year"]) - last_act_year
	if after <= 0:
		return "%s The settlement was in crisis %d times while it lasted." % [opening, troubles]
	return "%s The settlement was in crisis %d times, and was still recovering %d years after the god stopped." % [
		opening, troubles, after
	]
