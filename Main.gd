extends Control

const ACTION_KEYS := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
# Events that read as an active crisis on the map.
const CRISIS_EVENTS := ["drought", "unrest"]
# Monospaced rows: name on the left, power cost right-aligned to this width.
const ACTION_ROW_WIDTH := 34
const PERSON_META_PREFIX := "person:"
const DEV_TAB_META := "dev_tab:"
const DEV_PERSON_META := "dev_person:"
const DEV_SECTIONS := ["world", "locations", "people", "perceptions", "knowledge", "intents", "actions", "executions", "belief", "history"]
const DEV_LIST_LIMIT := 24
const BACK_META := "back"
# Player-readable names for the broad intents the engine records. These name a
# direction a mortal wants to go, never an action they attempt: "Help" is what
# Mara wants, and how she would go about it is not decided yet.
const INTENT_LABELS := {
	"help": "Help",
	"protect": "Protect",
	"acquire": "Seek what is needed",
	"learn": "Understand",
	"influence": "Sway",
	"connect": "Grow closer",
	"distance": "Keep away",
	"resolve": "Settle a quarrel",
	"preserve": "Hold to what is",
	"wait": "Wait and watch"
}
# Player-readable names for the attempt a mortal is about to make. Nothing has
# happened yet: these describe what someone is going to try, not the outcome.
const ACTION_LABELS := {
	"give": "Give to %s",
	"ask": "Ask %s for help",
	"tell": "Bring word to %s",
	"support": "Stand with %s",
	"oppose": "Stand against %s",
	"observe": "Watch and learn",
	"wait": "Hold back for now."
}
const ACTION_ASK_FOR_RESOURCE := "Ask %s for food"
const ACTION_NO_VIABLE := "Unable to act right now."
# What came of the attempt, in a mortal's words. Keyed on result type, because
# the outcome word alone ("failure") tells a player nothing useful. "%s" is the
# person it was aimed at.
const RESULT_LABELS := {
	"request_accepted": "%s agreed to help.",
	"request_refused": "%s refused.",
	"no_standing_with_target": "%s had no reason to listen.",
	"claim_delivered": "The word reached %s.",
	"claim_not_believed": "%s did not believe it.",
	"target_already_knew": "%s already knew.",
	"too_unsure_to_speak": "The words would not come.",
	"missing_required_belief": "There was nothing left to say.",
	"support_expressed": "They stood with %s.",
	"opposition_expressed": "They stood against %s.",
	"observation_made": "They saw it for themselves.",
	"nothing_to_see": "There was nothing to see.",
	"deliberately_waited": "They held back.",
	"unable_to_act": "Nothing could be done.",
	"no_controlled_resource": "There was nothing to give.",
	"target_gone": "There was no one there.",
	"claim_not_delivered": "Nothing came of it.",
	"delivery_failed": "Nothing came of it.",
	"unknown_action": "Nothing came of it."
}

var simulation := WorldSimulation.new()
var action_buttons: Array[Button] = []
# Selection is interface state. It deliberately does not live in WorldState,
# so looking at a place can never change what is true about the world.
var selected_location_id: String = "aster"
var hovered_action_index: int = -1
var hovered_person_id: String = ""
var selected_person_id: String = ""
# Developer Mode is interface state only. The simulation never learns it exists.
var developer_mode_enabled: bool = false
var developer_section: String = "world"
var developer_person_id: String = ""

@onready var year_value: Label = %YearValue
@onready var power_value: Label = %PowerValue
@onready var followers_value: Label = %FollowersValue
@onready var faith_value: Label = %FaithValue
@onready var reputation_value: Label = %ReputationValue
@onready var time_value: Label = %TimeValue
@onready var event_title: Label = %EventTitle
@onready var event_description: Label = %EventDescription
@onready var result_text: RichTextLabel = %ResultText
@onready var action_hint: Label = %ActionHint
@onready var world_map: WorldMapView = %WorldMap
@onready var location_text: RichTextLabel = %LocationText
@onready var history_text: RichTextLabel = %HistoryText
@onready var beliefs_text: RichTextLabel = %BeliefsText
@onready var dev_button: Button = %DevButton
@onready var developer_overlay: PanelContainer = %DeveloperOverlay
@onready var developer_tabs: RichTextLabel = %DeveloperTabs
@onready var developer_text: RichTextLabel = %DeveloperText
@onready var advance_button: Button = %AdvanceButton


func _ready() -> void:
	action_buttons = [%Action1, %Action2, %Action3, %Action4]
	for index in action_buttons.size():
		action_buttons[index].pressed.connect(_on_action_pressed.bind(index))
		action_buttons[index].mouse_entered.connect(_on_action_hovered.bind(index))
		action_buttons[index].mouse_exited.connect(_on_action_unhovered.bind(index))
	advance_button.pressed.connect(_on_advance_pressed)
	dev_button.pressed.connect(toggle_developer_mode)
	developer_tabs.meta_clicked.connect(_on_developer_meta)
	developer_text.meta_clicked.connect(_on_developer_meta)
	simulation.state_changed.connect(_render)
	var map_locations := {}
	for location_id: String in simulation.state.get_location_ids():
		var location := simulation.state.get_location(location_id)
		map_locations[location_id] = {"name": str(location["name"]), "kind": str(location["kind"])}
	world_map.set_locations(map_locations)
	world_map.location_clicked.connect(_on_location_clicked)
	location_text.meta_clicked.connect(_on_person_clicked)
	location_text.meta_hover_started.connect(_on_person_hover_started)
	location_text.meta_hover_ended.connect(_on_person_hover_ended)
	_render()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode >= KEY_1 and event.keycode <= KEY_4:
		choose_action(int(event.keycode - KEY_1))
		get_viewport().set_input_as_handled()
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		advance_year()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F1:
		# Secondary route to the same state as the DEV button.
		toggle_developer_mode()
		get_viewport().set_input_as_handled()


func _on_action_pressed(index: int) -> void:
	choose_action(index)


func _on_advance_pressed() -> void:
	advance_year()


func choose_action(index: int) -> void:
	if index < 0 or index >= ACTION_KEYS.size():
		return
	var result := simulation.resolve_action(ACTION_KEYS[index])
	if not result["ok"]:
		result_text.text = str(result["message"])


func advance_year() -> void:
	var result := simulation.advance_year()
	if not result["ok"]:
		result_text.text = str(result["message"])


func _render() -> void:
	var state := simulation.state
	var event := simulation.get_current_event()
	year_value.text = str(state.year)
	power_value.text = "%d / %d" % [state.divine_power, state.max_divine_power]
	followers_value.text = str(state.followers)
	faith_value.text = PresentationRules.faith_label(state.faith).to_upper()
	reputation_value.text = state.reputation.to_upper()
	time_value.text = "READY TO ADVANCE" if state.action_taken else "AWAITING CHOICE"
	time_value.modulate = Color("e8be63") if state.action_taken else Color("76c8d5")

	event_title.text = str(event["title"])
	event_description.text = str(event["description"])
	if state.last_result.is_empty():
		result_text.text = "[color=#7f898b]Awaiting divine input.[/color]"
	elif state.last_interpretation.is_empty():
		result_text.text = "[color=#9ca5a4]%s[/color]" % state.last_result
	else:
		result_text.text = (
			"[color=#9ca5a4]%s[/color]\n\n" % state.last_result
			+ "[color=#b38bc4]INTERPRETATION[/color]\n"
			+ "[color=#d7c8dc]\"%s\"[/color]" % state.last_interpretation
		)

	_render_actions()
	_render_map()
	_render_location()
	_render_history()
	_render_beliefs()
	_render_developer()
	advance_button.disabled = not state.action_taken


func _render_actions() -> void:
	var state := simulation.state
	for index in ACTION_KEYS.size():
		var action_id: String = ACTION_KEYS[index]
		var action := simulation.get_action(action_id)
		var cost := int(action["cost"])
		var label := "%d.  %s" % [index + 1, action["title"]]
		var cost_label := "%d Power" % cost
		# The interface font is monospaced, so padding keeps the costs aligned.
		var padding := maxi(ACTION_ROW_WIDTH - label.length() - cost_label.length(), 1)
		action_buttons[index].text = label + " ".repeat(padding) + cost_label
		action_buttons[index].disabled = state.action_taken or state.divine_power < cost
	_render_action_hint()


func _render_action_hint() -> void:
	var state := simulation.state
	if hovered_action_index >= 0 and hovered_action_index < ACTION_KEYS.size():
		var action := simulation.get_action(ACTION_KEYS[hovered_action_index])
		var cost := int(action["cost"])
		if state.action_taken:
			action_hint.text = "%s  ·  already answered this year" % str(action["hint"])
		elif state.divine_power < cost:
			action_hint.text = "%s  ·  needs %d power, you hold %d" % [
				str(action["hint"]), cost, state.divine_power
			]
		else:
			action_hint.text = str(action["hint"])
		return
	action_hint.text = "The year awaits your answer." if not state.action_taken \
		else "Advance the year to see what the world makes of it."


func _on_action_hovered(index: int) -> void:
	hovered_action_index = index
	_render_action_hint()


func _on_action_unhovered(index: int) -> void:
	if hovered_action_index == index:
		hovered_action_index = -1
		_render_action_hint()


func _on_person_clicked(meta) -> void:
	# Inspection only: this never resolves an action or advances time.
	if str(meta) == BACK_META:
		selected_person_id = ""
		hovered_person_id = ""
		_render_location()
		return
	var entity_id := _person_id_from_meta(str(meta))
	if entity_id.is_empty() or simulation.state.get_notable_entity(entity_id).is_empty():
		return
	selected_person_id = entity_id
	_render_location()


func _on_person_hover_started(meta) -> void:
	hovered_person_id = _person_id_from_meta(str(meta))
	_render_location()


func _on_person_hover_ended(_meta) -> void:
	hovered_person_id = ""
	_render_location()


func _person_id_from_meta(meta: String) -> String:
	if not meta.begins_with(PERSON_META_PREFIX):
		return ""
	return meta.substr(PERSON_META_PREFIX.length())


func _on_location_clicked(location_id: String) -> void:
	if simulation.state.get_location(location_id).is_empty():
		return
	selected_location_id = location_id
	# Looking somewhere else closes whoever was open.
	selected_person_id = ""
	hovered_person_id = ""
	_render()


func _render_map() -> void:
	var state := simulation.state
	var markers := {}
	for location_id: String in state.get_location_ids():
		markers[location_id] = {
			"crisis": _location_in_crisis(location_id),
			"divine": _location_is_holy(location_id)
		}
	world_map.set_markers(markers)
	world_map.set_selected_location(selected_location_id)


func _location_in_crisis(location_id: String) -> bool:
	# Only the capital carries simulated conditions in this prototype.
	if not bool(simulation.state.get_location(location_id).get("simulated", false)):
		return false
	return simulation.state.current_event_id in CRISIS_EVENTS


func _location_is_holy(location_id: String) -> bool:
	if not bool(simulation.state.get_location(location_id).get("simulated", false)):
		return false
	return not simulation.state.beliefs.is_empty()


func _render_location() -> void:
	if not selected_person_id.is_empty():
		_render_person()
		return
	var state := simulation.state
	var location := state.get_location(selected_location_id)
	if location.is_empty():
		location_text.text = "[color=#68757c](No location selected.)[/color]"
		return
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]" % str(location["name"]).to_upper(),
		"[color=#68757c]%s[/color]\n" % _location_kind_label(str(location["kind"]))
	]
	if bool(location.get("simulated", false)):
		lines.append_array(_simulated_location_lines())
	else:
		lines.append_array(_placeholder_location_lines(location))
	location_text.text = "\n".join(lines)


func _location_kind_label(kind: String) -> String:
	match kind:
		"capital":
			return "Capital of the Kingdom"
		"farming_village":
			return "Farming village of the Kingdom"
		"frontier_settlement":
			return "Frontier settlement of the Kingdom"
	return "Settlement of the Kingdom"


func _simulated_location_lines() -> Array[String]:
	# Every value below is read from the simulation. Nothing is stored here.
	var state := simulation.state
	var lines: Array[String] = [
		"[color=#68757c]POPULATION[/color]   %d" % state.population,
		"[color=#68757c]FOOD[/color]         %s" % _status_colour(state.food_name(), state.food_level),
		"[color=#68757c]STABILITY[/color]    %s" % _status_colour(state.stability_name(), state.stability_level),
		"[color=#68757c]PROSPERITY[/color]   %s" % _status_colour(state.prosperity_name(), state.prosperity_level),
		"[color=#68757c]MILITARY[/color]     %s" % _status_colour(state.military_name(), state.military_level),
		""
	]
	if _location_in_crisis(selected_location_id):
		lines.append("[color=#d66a5e]! %s[/color]" % str(simulation.get_current_event()["title"]))
	else:
		lines.append("[color=#68757c]Current situation:[/color] [color=#9ca5a4]%s[/color]" % str(
			simulation.get_current_event()["title"]
		))
	lines.append("")
	lines.append("[color=#68757c]IMPORTANT PEOPLE[/color]")
	var entity_ids := _sorted_entity_ids()
	if entity_ids.is_empty():
		lines.append("[color=#68757c](none)[/color]")
	for entity_id: String in entity_ids:
		lines.append(_person_row(entity_id))
	return lines


# The person view shows what this mortal believes and intends. It deliberately
# never reads objective_truth_state, distortion, or transmission counts: the
# player is a god, but this panel is not the god's omniscient readout.
func _render_person() -> void:
	var state := simulation.state
	var entity := state.get_notable_entity(selected_person_id)
	if entity.is_empty():
		selected_person_id = ""
		_render_location()
		return
	var traits: Array = entity.get("traits", [])
	var trait_names: Array[String] = []
	for trait_value in traits:
		trait_names.append(str(trait_value).capitalize())
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]" % str(entity.get("name", selected_person_id)).to_upper(),
		"[color=#68757c]%s[/color]" % str(entity.get("kind", "person")).capitalize(),
		"[color=#9ca5a4]%s[/color]\n" % (
			" · ".join(trait_names) if not trait_names.is_empty() else "No recorded traits"
		)
	]
	lines.append_array(_person_intention_lines())
	lines.append("")
	lines.append_array(_person_relationship_lines())
	lines.append("")
	lines.append_array(_person_knowledge_lines())
	lines.append("")
	var location := state.get_location(selected_location_id)
	lines.append("[url=%s][color=#76c8d5]<-  BACK TO %s[/color][/url]" % [
		BACK_META, str(location.get("name", "the map")).to_upper()
	])
	location_text.text = "\n".join(lines)


func _person_intention_lines() -> Array[String]:
	var lines: Array[String] = ["[color=#68757c]CURRENT INTENTION[/color]"]
	var records: Array[Dictionary] = simulation.state.get_intents_for(selected_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]None recorded.[/color]")
		return lines
	# The archive appends chronologically, so the last record is the newest.
	var latest: Dictionary = records.back()
	var intent_type := str(latest["intent_type"])
	lines.append("[color=#e8be63]%s[/color]" % str(
		INTENT_LABELS.get(intent_type, intent_type.capitalize())
	))
	# A self-directed want has no "toward" to show: holding to your own position
	# is not aimed at anyone.
	var target_name := "" if str(latest["target_kind"]) in ["self", "none"] \
		else _display_name_for(str(latest["target_id"]))
	if not target_name.is_empty():
		lines.append("[color=#68757c]Toward:[/color] [color=#9ca5a4]%s[/color]" % target_name)
	lines.append("[color=#68757c]Formed in year %d.[/color]" % int(latest["year"]))
	lines.append_array(_person_action_lines(str(latest["id"])))
	return lines


func _person_action_lines(intent_id: String) -> Array[String]:
	# What they are about to try. Selection is not execution: nothing in the
	# world has moved because this line exists.
	var lines: Array[String] = ["", "[color=#68757c]PLANNED ACTION[/color]"]
	var record: Dictionary = simulation.state.get_action_for_intent(intent_id)
	if record.is_empty():
		lines.append("[color=#73627f]None yet.[/color]")
		return lines
	lines.append("[color=#e8be63]%s[/color]" % _action_phrase(record))
	lines.append_array(_person_result_lines(str(record["id"])))
	return lines


func _person_result_lines(action_id: String) -> Array[String]:
	# What came of it. Immediate result only: whatever it goes on to change in
	# the world has not been worked out yet.
	var record: Dictionary = simulation.state.get_execution_for_action(action_id)
	if record.is_empty():
		return []
	var lines: Array[String] = ["", "[color=#68757c]RESULT[/color]"]
	lines.append("[color=#9ca5a4]%s[/color]" % _result_phrase(record))
	return lines


func _result_phrase(record: Dictionary) -> String:
	var template := str(RESULT_LABELS.get(str(record["result_type"]), "Nothing came of it."))
	if not template.contains("%s"):
		return template
	var target_name := _display_name_for(str(record["target_id"]))
	return "Nothing came of it." if target_name.is_empty() else template % target_name


func _action_phrase(record: Dictionary) -> String:
	var action_type := str(record["action_type"])
	if action_type == "wait":
		return ACTION_NO_VIABLE if str(record["selection"]) == "fallback_no_viable_action" \
			else str(ACTION_LABELS["wait"])
	var target_name := _display_name_for(str(record["target_id"]))
	if target_name.is_empty():
		return str(ACTION_LABELS.get(action_type, action_type.capitalize()))
	var template := str(ACTION_LABELS.get(action_type, "%s"))
	if action_type == "ask" and not str(record["resource_type"]).is_empty():
		template = ACTION_ASK_FOR_RESOURCE
	if not template.contains("%s"):
		return template
	return template % target_name


func _person_relationship_lines() -> Array[String]:
	# Directed: this person's view of others. Mara -> the King is not the same
	# record as the King -> Mara, and the two are never merged here.
	var state := simulation.state
	var lines: Array[String] = ["[color=#68757c]RELATIONSHIPS[/color]"]
	var found := false
	for target_id: String in _sorted_entity_ids():
		if target_id == selected_person_id:
			continue
		var record := state.get_relationship(selected_person_id, target_id)
		if record.is_empty():
			continue
		found = true
		lines.append("[color=#9ca5a4]%s[/color]" % _display_name_for(target_id))
		for axis: String in WorldState.RELATIONSHIP_AXES:
			lines.append("[color=#68757c]   %s[/color] [color=#8d989d]%s[/color]" % [
				axis.capitalize().rpad(11),
				PresentationRules.relationship_label(axis, int(record[axis]))
			])
	if not found:
		lines.append("[color=#73627f]No notable relationships.[/color]")
	return lines


func _person_knowledge_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = ["[color=#68757c]KNOWN INFORMATION[/color]"]
	var stored := state.get_all_knowledge(selected_person_id)
	var knowledge_ids: Array = stored.keys()
	knowledge_ids.sort()
	var shown := 0
	for knowledge_id_value in knowledge_ids:
		var record: Dictionary = stored[str(knowledge_id_value)]
		if bool(record.get("invalidated", false)):
			continue
		var claim := str(record.get("claim", "")).strip_edges()
		if claim.is_empty():
			continue
		lines.append("[color=#9ca5a4]\"%s\"[/color]" % claim)
		lines.append("[color=#68757c]   %s[/color]" % PresentationRules.confidence_label(
			int(record["confidence"])
		))
		var source_id := str(record.get("source_id", ""))
		if source_id.is_empty() or source_id == selected_person_id:
			lines.append("[color=#68757c]   Witnessed it directly.[/color]")
		else:
			lines.append("[color=#68757c]   Heard from %s.[/color]" % _display_name_for(source_id))
		# Staleness from the mortal's side: when they last had word of it.
		var age := maxi(state.year - int(record.get("last_updated_year", state.year)), 0)
		if age == 0:
			lines.append("[color=#68757c]   Word of it came this year.[/color]")
		else:
			lines.append("[color=#68757c]   Last word of it %d year%s ago.[/color]" % [
				age, "" if age == 1 else "s"
			])
		shown += 1
	if shown == 0:
		lines.append("[color=#73627f]None recorded.[/color]")
	return lines


func _display_name_for(target_id: String) -> String:
	if target_id.is_empty():
		return ""
	var entity := simulation.state.get_notable_entity(target_id)
	if not entity.is_empty():
		return str(entity.get("name", target_id))
	var location := simulation.state.get_location(target_id)
	if not location.is_empty():
		return str(location.get("name", target_id))
	return target_id


func _person_row(entity_id: String) -> String:
	# Rows are already selectable so the next pass can open a person view.
	var entity := simulation.state.get_notable_entity(entity_id)
	var name_text := str(entity.get("name", entity_id))
	var colour := "#8d989d"
	var marker := " "
	if entity_id == selected_person_id:
		colour = "#e8be63"
		marker = ">"
	elif entity_id == hovered_person_id:
		colour = "#e5e1d8"
		marker = ">"
	var detail := ""
	if entity_id == selected_person_id:
		var traits: Array = entity.get("traits", [])
		detail = "\n     [color=#68757c]%s[/color]" % (
			", ".join(traits) if not traits.is_empty() else "no traits recorded"
		)
	return "[url=%s%s][color=%s]%s  %s[/color][/url]%s" % [
		PERSON_META_PREFIX, entity_id, colour, marker, name_text, detail
	]


func _placeholder_location_lines(location: Dictionary) -> Array[String]:
	return [
		"[color=#68757c]Primary role:[/color] [color=#9ca5a4]%s[/color]" % str(location.get("role", "Unknown")),
		"",
		"[color=#68757c]Detailed settlement simulation:[/color]",
		"[color=#73627f]Not yet implemented.[/color]",
		"",
		"[color=#68757c]Kingdom-wide conditions are shown under the capital.[/color]"
	]


func _status_colour(value: String, level: int) -> String:
	var colours := ["#d66a5e", "#d99a54", "#e8be63", "#71b892"]
	return "[color=%s]%s[/color]" % [colours[clampi(level, 0, 3)], value.to_upper()]


func _render_history() -> void:
	var lines: Array[String] = []
	for index in simulation.state.history.size():
		var colour := "#e5e1d8" if index == 0 else "#8d989d"
		lines.append("[color=%s]%s[/color]" % [colour, simulation.state.history[index]])
	history_text.text = "\n\n".join(lines)


func _render_beliefs() -> void:
	if simulation.state.beliefs.is_empty():
		beliefs_text.text = "[color=#73627f](None)[/color]\n\n[color=#68757c]Interpretations may become doctrine.[/color]"
		return
	var lines: Array[String] = []
	for belief in simulation.state.beliefs:
		lines.append("[color=#b38bc4]◆  %s[/color]" % belief)
	beliefs_text.text = "\n\n".join(lines)


func _sorted_entity_ids() -> Array[String]:
	# Sorted by display name, then id, so the panel never reorders itself.
	var entries: Array[Dictionary] = []
	for entity_id_value in simulation.state.notable_entities.keys():
		var entity_id := str(entity_id_value)
		var entity := simulation.state.get_notable_entity(entity_id)
		if entity.is_empty():
			continue
		entries.append({"id": entity_id, "name": str(entity.get("name", entity_id))})
	entries.sort_custom(func(a, b):
		if str(a["name"]) == str(b["name"]):
			return str(a["id"]) < str(b["id"])
		return str(a["name"]) < str(b["name"])
	)
	var sorted_ids: Array[String] = []
	for entry: Dictionary in entries:
		sorted_ids.append(str(entry["id"]))
	return sorted_ids


# ---------------------------------------------------------------------------
# Developer Mode: read-only inspection of exact simulation values. Nothing in
# this section writes to WorldState, and the panel is an overlay, so it costs
# no layout space while closed.
# ---------------------------------------------------------------------------

func toggle_developer_mode() -> void:
	developer_mode_enabled = not developer_mode_enabled
	if developer_mode_enabled and developer_person_id.is_empty():
		var entity_ids := _sorted_entity_ids()
		if not entity_ids.is_empty():
			developer_person_id = entity_ids[0]
	_render_developer()


func _on_developer_meta(meta) -> void:
	var value := str(meta)
	if value.begins_with(DEV_TAB_META):
		developer_section = value.substr(DEV_TAB_META.length())
		_render_developer()
	elif value.begins_with(DEV_PERSON_META):
		developer_person_id = value.substr(DEV_PERSON_META.length())
		_render_developer()


func _render_developer() -> void:
	# Only does work while open, and only when the state it reads has changed.
	dev_button.text = "DEV: ON" if developer_mode_enabled else "DEV"
	dev_button.modulate = Color("d66a5e") if developer_mode_enabled else Color(1, 1, 1)
	developer_overlay.visible = developer_mode_enabled
	if not developer_mode_enabled:
		return
	var tabs: Array[String] = []
	for section: String in DEV_SECTIONS:
		var is_active := section == developer_section
		tabs.append("[url=%s%s][color=%s]%s[/color][/url]" % [
			DEV_TAB_META, section, "#e8be63" if is_active else "#68757c", section.to_upper()
		])
	developer_tabs.text = "   ".join(tabs)
	match developer_section:
		"world":
			developer_text.text = "\n".join(_developer_world_lines())
		"locations":
			developer_text.text = "\n".join(_developer_location_lines())
		"people":
			developer_text.text = "\n".join(_developer_people_lines())
		"perceptions":
			developer_text.text = "\n".join(_developer_perception_lines())
		"knowledge":
			developer_text.text = "\n".join(_developer_knowledge_lines())
		"intents":
			developer_text.text = "\n".join(_developer_intent_lines())
		"actions":
			developer_text.text = "\n".join(_developer_action_lines())
		"executions":
			developer_text.text = "\n".join(_developer_execution_lines())
		"belief":
			developer_text.text = "\n".join(_developer_belief_lines())
		"history":
			developer_text.text = "\n".join(_developer_history_lines())
		_:
			developer_text.text = "[color=#68757c]Unknown section.[/color]"


func _dev_field(label: String, value) -> String:
	return "[color=#68757c]%s[/color]  [color=#9ca5a4]%s[/color]" % [label.rpad(24), str(value)]


func _dev_heading(text: String) -> String:
	return "[color=#e8be63]%s[/color]" % text


func _developer_world_lines() -> Array[String]:
	var state := simulation.state
	return [
		_dev_heading("WORLD STATE"),
		_dev_field("year", state.year),
		_dev_field("population", state.population),
		_dev_field("food_level", "%d  (%s)" % [state.food_level, state.food_name()]),
		_dev_field("stability_level", "%d  (%s)" % [state.stability_level, state.stability_name()]),
		_dev_field("prosperity_level", "%d  (%s)" % [state.prosperity_level, state.prosperity_name()]),
		_dev_field("military_level", "%d  (%s)" % [state.military_level, state.military_name()]),
		_dev_field("faith", state.faith),
		_dev_field("followers", state.followers),
		_dev_field("divine_power", "%d / %d" % [state.divine_power, state.max_divine_power]),
		_dev_field("reputation", state.reputation),
		"",
		_dev_heading("TURN STATE"),
		_dev_field("current_event_id", state.current_event_id),
		_dev_field("action_taken", state.action_taken),
		_dev_field("previous_action_id", _or_none(state.previous_action_id)),
		_dev_field("last_interpretation_id", _or_none(state.last_interpretation_id)),
		_dev_field("useful_silence_outcomes", state.useful_silence_outcomes),
		_dev_field("population_growth_bonus", state.population_growth_bonus)
	]


func _developer_location_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("LOCATIONS")]
	for location_id: String in state.get_location_ids():
		var location := state.get_location(location_id)
		lines.append("")
		lines.append("[color=#e5e1d8]%s[/color]" % location_id)
		for key: String in ["name", "kind", "role", "simulated"]:
			lines.append(_dev_field(key, location.get(key, "-")))
	lines.append("")
	lines.append("[color=#73627f]No per-location simulation values exist yet; conditions are kingdom-wide.[/color]")
	return lines


func _developer_people_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("NOTABLE ENTITIES")]
	for entity_id: String in _sorted_entity_ids():
		var entity := state.get_notable_entity(entity_id)
		var marker := ">" if entity_id == developer_person_id else " "
		lines.append("")
		lines.append("[url=%s%s][color=%s]%s %s[/color][/url]" % [
			DEV_PERSON_META, entity_id,
			"#e8be63" if entity_id == developer_person_id else "#9ca5a4",
			marker, entity_id
		])
		lines.append(_dev_field("name", entity.get("name", "-")))
		lines.append(_dev_field("kind", entity.get("kind", "-")))
		lines.append(_dev_field("traits", ", ".join(entity.get("traits", []))))
		lines.append(_dev_field("knowledge records", state.get_all_knowledge(entity_id).size()))
		for target_id: String in _sorted_entity_ids():
			if target_id == entity_id:
				continue
			var record := state.get_relationship(entity_id, target_id)
			if record.is_empty():
				continue
			lines.append("[color=#68757c]  %s -> %s[/color]  [color=#8d989d]trust %d  fear %d  respect %d  hostility %d[/color]" % [
				entity_id, target_id,
				int(record["trust"]), int(record["fear"]),
				int(record["respect"]), int(record["hostility"])
			])
	return lines


func _developer_perception_lines() -> Array[String]:
	# Who noticed, and who did not. Kept apart from KNOWLEDGE on purpose: what
	# happened, who had a chance to see it, and what they came to believe are
	# three questions, and the middle one is the new one.
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("PERCEPTIONS  ·  THIS YEAR")]
	var event: Dictionary = simulation.get_current_event()
	lines.append(_dev_field("current_event_id", state.current_event_id))
	lines.append(_dev_field("event_title", str(event.get("title", ""))))
	var fact: Dictionary = simulation.observable_fact()
	if fact.is_empty():
		lines.append(_dev_field("observable_fact", "(none — the world absorbed it)"))
	else:
		lines.append(_dev_field("observable_fact", fact["id"]))
		lines.append(_dev_field("observability", fact["observability"]))
		lines.append(_dev_field("subject_id", fact["subject_id"]))
		lines.append(_dev_field("template_confidence", fact["confidence"]))
	lines.append("")
	lines.append("[color=#76c8d5]who had a chance[/color]")
	if state.last_perceptions.is_empty():
		lines.append("[color=#73627f]  (nothing to notice this year)[/color]")
	for opportunity: Dictionary in state.last_perceptions:
		var mark := "SAW " if bool(opportunity["perceived"]) else "MISSED"
		var colour := "#8d989d" if bool(opportunity["perceived"]) else "#73627f"
		lines.append("[color=%s]  %-6s %-14s home %-11s conf %-4d %s[/color]" % [
			colour, mark, str(opportunity["observer_id"]),
			_or_none(state.get_home_location(str(opportunity["observer_id"]))),
			int(opportunity["confidence"]), str(opportunity["reason"])
		])
	lines.append("")
	lines.append("[color=#76c8d5]latest for %s[/color]" % _or_none(developer_person_id))
	if developer_person_id.is_empty():
		lines.append("[color=#73627f]  Select an entity in PEOPLE.[/color]")
		return lines
	var records: Array[Dictionary] = state.get_perceptions_for(developer_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]  Has never perceived anything.[/color]")
		return lines
	var latest: Dictionary = records.back()
	for field: String in ["event_id", "topic_id", "observability", "confidence", "knowledge_id"]:
		lines.append(_dev_field("  %s" % field, latest[field]))
	for factor: Dictionary in latest.get("factors", []):
		lines.append("[color=#8d989d]  %+d   %s[/color]" % [
			int(factor.get("delta", 0)), str(factor.get("detail", ""))
		])
	for reason in latest.get("reasons", []):
		lines.append("[color=#8d989d]  %s[/color]" % str(reason))
	lines.append(_dev_field("  perceptions recorded", records.size()))
	return lines


func _developer_knowledge_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("KNOWLEDGE  ·  %s" % _or_none(developer_person_id))]
	if developer_person_id.is_empty():
		lines.append("[color=#73627f]Select an entity in PEOPLE.[/color]")
		return lines
	var stored := state.get_all_knowledge(developer_person_id)
	var knowledge_ids: Array = stored.keys()
	knowledge_ids.sort()
	if knowledge_ids.is_empty():
		lines.append("[color=#73627f]No knowledge records.[/color]")
		return lines
	for knowledge_id_value in knowledge_ids:
		var record: Dictionary = stored[str(knowledge_id_value)]
		lines.append("")
		lines.append("[color=#e5e1d8]%s[/color]" % str(record["id"]))
		# Every stored field, including the truth the mortal cannot see.
		for key: String in [
			"claim", "topic", "subject_id", "confidence", "truth_state",
			"objective_truth_state", "source_id", "source_type", "origin_source_id",
			"transmission_count", "distorted", "invalidated", "freshness",
			"fresh_for_years", "year_learned", "last_updated_year", "is_outdated"
		]:
			if not record.has(key):
				continue
			var colour := "#9ca5a4"
			if key == "objective_truth_state" and str(record[key]) == "false":
				colour = "#d66a5e"
			if key == "distorted" and bool(record[key]):
				colour = "#d66a5e"
			lines.append("[color=#68757c]%s[/color]  [color=%s]%s[/color]" % [
				key.rpad(24), colour, str(record[key])
			])
	return lines


func _developer_intent_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("INTENTS  ·  %s" % _or_none(developer_person_id))]
	if developer_person_id.is_empty():
		lines.append("[color=#73627f]Select an entity in PEOPLE.[/color]")
		return lines
	var records: Array[Dictionary] = state.get_intents_for(developer_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]No intents recorded.[/color]")
		return lines
	var latest: Dictionary = records.back()
	lines.append(_dev_field("intent_id", latest["id"]))
	lines.append(_dev_field("intent_type", latest["intent_type"]))
	lines.append(_dev_field("target_id", _or_none(str(latest["target_id"]))))
	lines.append(_dev_field("target_kind", latest["target_kind"]))
	lines.append(_dev_field("selection", latest["selection"]))
	lines.append(_dev_field("base_priority", latest["base_priority"]))
	lines.append(_dev_field("score", latest["score"]))
	lines.append(_dev_field("priority", latest["priority"]))
	lines.append(_dev_field("year", latest["year"]))
	# The record already stores why it won. Render it; never recompute it.
	for section: String in ["trait_factors", "relationship_factors", "knowledge_used", "world_state_factors"]:
		lines.append("")
		lines.append("[color=#76c8d5]%s[/color]" % section)
		var factors: Array = latest.get(section, [])
		if factors.is_empty():
			lines.append("[color=#73627f]  (none)[/color]")
		for factor: Dictionary in factors:
			lines.append("[color=#8d989d]  %+d   %s[/color]" % [
				int(factor.get("delta", 0)),
				str(factor.get("detail", factor.get("knowledge_id", "")))
			])
	lines.append("")
	lines.append("[color=#76c8d5]reasons[/color]")
	for reason in latest.get("reasons", []):
		lines.append("[color=#8d989d]  %s[/color]" % str(reason))
	lines.append("")
	lines.append("[color=#76c8d5]considered[/color]")
	for candidate: Dictionary in latest.get("considered", []):
		lines.append("[color=#8d989d]  %-18s %-12s score %-5d %s[/color]" % [
			str(candidate["intent_type"]), _or_none(str(candidate["target_id"])),
			int(candidate["score"]), str(candidate["reason"])
		])
	lines.append("")
	lines.append(_dev_field("intents recorded", records.size()))
	return lines


func _developer_action_lines() -> Array[String]:
	# Kept apart from INTENTS on purpose. Why someone wanted something and why
	# they chose that way of pursuing it are two questions, and merging the
	# records would make neither answerable.
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("ACTIONS  ·  %s" % _or_none(developer_person_id))]
	if developer_person_id.is_empty():
		lines.append("[color=#73627f]Select an entity in PEOPLE.[/color]")
		return lines
	var records: Array[Dictionary] = state.get_actions_for(developer_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]No actions selected.[/color]")
		return lines
	var latest: Dictionary = records.back()
	lines.append(_dev_field("action_id", latest["id"]))
	lines.append(_dev_field("action_type", latest["action_type"]))
	lines.append(_dev_field("intent_id", _or_none(str(latest["intent_id"]))))
	lines.append(_dev_field("intent_type", latest["intent_type"]))
	lines.append(_dev_field("target_id", _or_none(str(latest["target_id"]))))
	lines.append(_dev_field("target_kind", latest["target_kind"]))
	lines.append(_dev_field("subject_id", _or_none(str(latest["subject_id"]))))
	lines.append(_dev_field("topic_id", _or_none(str(latest["topic_id"]))))
	lines.append(_dev_field("resource_type", _or_none(str(latest["resource_type"]))))
	lines.append(_dev_field("base_priority", latest["base_priority"]))
	lines.append(_dev_field("score", latest["score"]))
	lines.append(_dev_field("selection", latest["selection"]))
	lines.append(_dev_field("viable", latest["viable"]))
	lines.append(_dev_field("year", latest["year"]))
	# The record already stores why it won. Render it; never recompute it.
	for section: String in ["trait_factors", "relationship_factors", "knowledge_factors", "target_factors"]:
		lines.append("")
		lines.append("[color=#76c8d5]%s[/color]" % section)
		var factors: Array = latest.get(section, [])
		if factors.is_empty():
			lines.append("[color=#73627f]  (none)[/color]")
		for factor: Dictionary in factors:
			lines.append("[color=#8d989d]  %+d   %s[/color]" % [
				int(factor.get("delta", 0)), str(factor.get("detail", ""))
			])
	lines.append("")
	lines.append("[color=#76c8d5]reasons[/color]")
	for reason in latest.get("reasons", []):
		lines.append("[color=#8d989d]  %s[/color]" % str(reason))
	lines.append("")
	lines.append("[color=#76c8d5]considered  ·  capability checks[/color]")
	for candidate: Dictionary in latest.get("considered", []):
		lines.append("[color=#8d989d]  %-10s %-12s score %-5d %s[/color]" % [
			str(candidate["action_type"]), _or_none(str(candidate["target_id"])),
			int(candidate["score"]), str(candidate["reason"])
		])
	lines.append("")
	lines.append(_dev_field("actions selected", records.size()))
	return lines


func _developer_execution_lines() -> Array[String]:
	# The third of three questions, kept apart from the other two. Why she
	# wanted it, why she chose that way, and what came of it are separate
	# records, and merging any two would make neither answerable.
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("EXECUTIONS  ·  %s" % _or_none(developer_person_id))]
	if developer_person_id.is_empty():
		lines.append("[color=#73627f]Select an entity in PEOPLE.[/color]")
		return lines
	var records: Array[Dictionary] = state.get_executions_for(developer_person_id)
	if records.is_empty():
		lines.append("[color=#73627f]No executions recorded.[/color]")
		return lines
	var latest: Dictionary = records.back()
	lines.append(_dev_field("execution_id", latest["id"]))
	lines.append(_dev_field("action_id", _or_none(str(latest["action_id"]))))
	lines.append(_dev_field("intent_id", _or_none(str(latest["intent_id"]))))
	lines.append(_dev_field("action_type", latest["action_type"]))
	lines.append(_dev_field("outcome", latest["outcome"]))
	lines.append(_dev_field("result_type", latest["result_type"]))
	lines.append(_dev_field("target_id", _or_none(str(latest["target_id"]))))
	lines.append(_dev_field("subject_id", _or_none(str(latest["subject_id"]))))
	lines.append(_dev_field("topic_id", _or_none(str(latest["topic_id"]))))
	lines.append(_dev_field("score", latest["score"]))
	lines.append(_dev_field("year", latest["year"]))
	lines.append("")
	lines.append("[color=#76c8d5]factors[/color]")
	var factors: Array = latest.get("factors", [])
	if factors.is_empty():
		lines.append("[color=#73627f]  (none)[/color]")
	for factor: Dictionary in factors:
		lines.append("[color=#8d989d]  %+d   %s[/color]" % [
			int(factor.get("delta", 0)), str(factor.get("detail", ""))
		])
	lines.append("")
	lines.append("[color=#76c8d5]reasons[/color]")
	for reason in latest.get("reasons", []):
		lines.append("[color=#8d989d]  %s[/color]" % str(reason))
	lines.append("")
	# Anything not listed here did not happen. Consequences are a later system.
	lines.append("[color=#76c8d5]effects_applied[/color]")
	var effects: Array = latest.get("effects_applied", [])
	if effects.is_empty():
		lines.append("[color=#73627f]  (none — nothing in the world moved)[/color]")
	for effect: Dictionary in effects:
		lines.append("[color=#8d989d]  %-22s %s  confidence %d[/color]" % [
			str(effect.get("type", "")), str(effect.get("entity_id", "")),
			int(effect.get("confidence", 0))
		])
	lines.append("")
	lines.append(_dev_field("executions recorded", records.size()))
	return lines


func _developer_belief_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("ACTIVE BELIEFS")]
	lines.append(_dev_field("beliefs", ", ".join(state.beliefs) if not state.beliefs.is_empty() else "(none)"))
	lines.append(_dev_field("known_beliefs", state.known_beliefs.size()))
	lines.append("")
	lines.append(_dev_heading("BELIEF PRESSURE"))
	lines.append_array(_dev_dictionary(state.belief_pressure))
	lines.append("")
	lines.append(_dev_heading("REPUTATION"))
	lines.append(_dev_field("reputation", state.reputation))
	lines.append_array(_dev_dictionary(state.reputation_pressure))
	lines.append(_dev_field("reputation_changes", ", ".join(state.reputation_changes) if not state.reputation_changes.is_empty() else "(none)"))
	lines.append("")
	lines.append(_dev_heading("ACTION / INTERVENTION COUNTS"))
	lines.append_array(_dev_dictionary(state.action_counts))
	lines.append_array(_dev_dictionary(state.intervention_counts))
	lines.append("")
	lines.append(_dev_heading("WORLD FLAGS"))
	lines.append_array(_dev_dictionary(state.world_flags))
	lines.append_array(_dev_dictionary(state.world_flag_use_counts))
	lines.append("")
	lines.append(_dev_heading("INTERPRETATION HISTORY"))
	lines.append(_dev_field("count", state.interpretation_history.size()))
	lines.append("[color=#8d989d]%s[/color]" % ", ".join(_tail(state.interpretation_history, DEV_LIST_LIMIT)))
	return lines


func _developer_history_lines() -> Array[String]:
	var state := simulation.state
	var lines: Array[String] = [_dev_heading("HISTORY ARCHIVE  (%d entries, newest last)" % state.history_archive.size())]
	for entry in _tail(state.history_archive, DEV_LIST_LIMIT):
		lines.append("[color=#8d989d]%s[/color]" % str(entry))
	lines.append("")
	lines.append(_dev_heading("KNOWLEDGE EVENTS  (%d)" % state.knowledge_events.size()))
	for entry: Dictionary in _tail(state.knowledge_events, DEV_LIST_LIMIT):
		lines.append("[color=#8d989d]  y%-4d %-18s %-22s %s conf %s[/color]" % [
			int(entry.get("year", 0)), str(entry.get("type", "")),
			str(entry.get("knowledge_id", "")), str(entry.get("entity_id", "")),
			str(entry.get("confidence", ""))
		])
	lines.append("")
	lines.append(_dev_heading("LAST YEAR"))
	lines.append(_dev_field("last_perceptions", state.last_perceptions.size()))
	lines.append(_dev_field("last_knowledge_shares", state.last_knowledge_shares.size()))
	lines.append(_dev_field("last_relationship_changes", state.last_relationship_changes.size()))
	for change: Dictionary in state.last_relationship_changes:
		lines.append("[color=#8d989d]  %s -> %s  %s[/color]" % [
			str(change.get("source_id", "")), str(change.get("target_id", "")),
			str(change.get("changes", {}))
		])
	lines.append(_dev_field("last_intents", state.last_intents.size()))
	for intent: Dictionary in state.last_intents:
		lines.append("[color=#8d989d]  %s  %s -> %s  score %d[/color]" % [
			str(intent.get("actor_id", "")), str(intent.get("intent_type", "")),
			_or_none(str(intent.get("target_id", ""))), int(intent.get("score", 0))
		])
	lines.append(_dev_field("last_actions", state.last_actions.size()))
	for action: Dictionary in state.last_actions:
		lines.append("[color=#8d989d]  %s  %s -> %s  score %d  %s[/color]" % [
			str(action.get("actor_id", "")), str(action.get("action_type", "")),
			_or_none(str(action.get("target_id", ""))), int(action.get("score", 0)),
			str(action.get("selection", ""))
		])
	lines.append(_dev_field("last_executions", state.last_executions.size()))
	for execution: Dictionary in state.last_executions:
		lines.append("[color=#8d989d]  %s  %s  %s  %s  effects %d[/color]" % [
			str(execution.get("actor_id", "")), str(execution.get("action_type", "")),
			str(execution.get("outcome", "")), str(execution.get("result_type", "")),
			execution.get("effects_applied", []).size()
		])
	return lines


func _dev_dictionary(source: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var keys: Array = source.keys()
	keys.sort()
	for key_value in keys:
		lines.append(_dev_field(str(key_value), source[key_value]))
	return lines


func _tail(source: Array, limit: int) -> Array:
	if source.size() <= limit:
		return source.duplicate()
	return source.slice(source.size() - limit)


func _or_none(value: String) -> String:
	return "(none)" if value.strip_edges().is_empty() else value
