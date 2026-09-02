extends Control

const ACTION_KEYS := ["send_rain", "bless_harvest", "speak_mortal", "do_nothing"]
# Events that read as an active crisis on the map.
const CRISIS_EVENTS := ["drought", "unrest"]

var simulation := WorldSimulation.new()
var action_buttons: Array[Button] = []
# Selection is interface state. It deliberately does not live in WorldState,
# so looking at a place can never change what is true about the world.
var selected_location_id: String = "aster"

@onready var year_value: Label = %YearValue
@onready var power_value: Label = %PowerValue
@onready var followers_value: Label = %FollowersValue
@onready var faith_value: Label = %FaithValue
@onready var reputation_value: Label = %ReputationValue
@onready var time_value: Label = %TimeValue
@onready var event_title: Label = %EventTitle
@onready var event_description: Label = %EventDescription
@onready var result_text: RichTextLabel = %ResultText
@onready var world_map: WorldMapView = %WorldMap
@onready var location_text: RichTextLabel = %LocationText
@onready var history_text: RichTextLabel = %HistoryText
@onready var beliefs_text: RichTextLabel = %BeliefsText
@onready var notable_text: RichTextLabel = %NotableText
@onready var advance_button: Button = %AdvanceButton


func _ready() -> void:
	action_buttons = [%Action1, %Action2, %Action3, %Action4]
	for index in action_buttons.size():
		action_buttons[index].pressed.connect(_on_action_pressed.bind(index))
	advance_button.pressed.connect(_on_advance_pressed)
	simulation.state_changed.connect(_render)
	var location_names := {}
	for location_id: String in simulation.state.get_location_ids():
		location_names[location_id] = str(simulation.state.get_location(location_id)["name"])
	world_map.set_locations(location_names)
	world_map.location_clicked.connect(_on_location_clicked)
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
	faith_value.text = "%d%%" % state.faith
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
			"[color=#9ca5a4]%s[/color]\n" % state.last_result
			+ "[color=#b38bc4]INTERPRETATION:[/color] [color=#d7c8dc]\"%s\"[/color]" % state.last_interpretation
		)

	_render_actions()
	_render_map()
	_render_location()
	_render_history()
	_render_beliefs()
	_render_notable_people()
	advance_button.disabled = not state.action_taken


func _render_actions() -> void:
	var state := simulation.state
	for index in ACTION_KEYS.size():
		var action_id: String = ACTION_KEYS[index]
		var action := simulation.get_action(action_id)
		var cost := int(action["cost"])
		action_buttons[index].text = "%d.  %s\n     Cost: %d Power  ·  %s" % [
			index + 1, action["title"], cost, action["hint"]
		]
		action_buttons[index].disabled = state.action_taken or state.divine_power < cost


func _on_location_clicked(location_id: String) -> void:
	if simulation.state.get_location(location_id).is_empty():
		return
	selected_location_id = location_id
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
		var entity := state.get_notable_entity(entity_id)
		lines.append("[color=#9ca5a4]  %s[/color]" % str(entity.get("name", entity_id)))
	return lines


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


# Debug inspection only: this panel reads simulation data and never changes it.
func _render_notable_people() -> void:
	var state := simulation.state
	var entity_ids := _sorted_entity_ids()
	if entity_ids.is_empty():
		notable_text.text = "[color=#68757c](No notable people.)[/color]"
		return
	var blocks: Array[String] = []
	for entity_id: String in entity_ids:
		blocks.append(_notable_entity_block(entity_id, entity_ids))
	notable_text.text = "\n\n".join(blocks)


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


func _notable_entity_block(entity_id: String, entity_ids: Array[String]) -> String:
	var state := simulation.state
	var entity := state.get_notable_entity(entity_id)
	var traits: Array = entity.get("traits", [])
	var traits_text := ", ".join(traits) if not traits.is_empty() else "(none)"
	var lines: Array[String] = [
		"[color=#e5e1d8]%s[/color]  [color=#68757c](%s)[/color]" % [
			str(entity.get("name", entity_id)).to_upper(), str(entity.get("kind", "unknown"))
		],
		"[color=#68757c]Traits:[/color]  [color=#9ca5a4]%s[/color]" % traits_text,
		"[color=#68757c]Relationships:[/color]"
	]
	lines.append_array(_relationship_lines(entity_id, entity_ids))
	lines.append("[color=#68757c]Knowledge:[/color]  [color=#9ca5a4]%d[/color]" % state.get_all_knowledge(entity_id).size())
	lines.append("[color=#68757c]Decision:[/color]  %s" % _latest_decision_text(entity_id))
	return "\n".join(lines)


func _relationship_lines(entity_id: String, entity_ids: Array[String]) -> Array[String]:
	# Directed: this entity's view of others only. King -> Mara is not Mara -> King.
	var lines: Array[String] = []
	for target_id: String in entity_ids:
		if target_id == entity_id:
			continue
		var record := simulation.state.get_relationship(entity_id, target_id)
		if record.is_empty():
			continue
		var target := simulation.state.get_notable_entity(target_id)
		lines.append("    [color=#9ca5a4]-> %s[/color]" % str(target.get("name", target_id)))
		lines.append(
			"       [color=#8d989d]Trust %d / Fear %d / Respect %d / Hostility %d[/color]" % [
				int(record["trust"]), int(record["fear"]), int(record["respect"]), int(record["hostility"])
			]
		)
	if lines.is_empty():
		lines.append("    [color=#68757c](none)[/color]")
	return lines


func _latest_decision_text(entity_id: String) -> String:
	var records: Array[Dictionary] = simulation.state.get_decisions_for(entity_id)
	if records.is_empty():
		return "[color=#68757c]-[/color]"
	# The archive appends chronologically, so the last record is the newest.
	var latest: Dictionary = records.back()
	var target_id := str(latest["target_id"])
	return "[color=#e8be63]%s[/color]  [color=#8d989d]· target %s · score %d · year %d[/color]" % [
		str(latest["decision_type"]),
		"none" if target_id.is_empty() else target_id,
		int(latest["score"]),
		int(latest["year"])
	]
