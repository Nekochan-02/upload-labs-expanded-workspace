extends "res://scripts/desktop.gd"

# Mod: Nekochan-ExpandedWorkspace  Phase 2A
#
# Overrides paste() to replace the Utils.MAX_WINDOW (500) global limit
# check with the modded limit (1000).
#
# DIFF NOTE: Only line 213 of the vanilla paste() is changed.
#   - VANILLA: if required > Utils.MAX_WINDOW - Globals.max_window_count:
#   + MODDED:  if required > MODDED_MAX_WINDOW - Globals.max_window_count:
#
# All other lines are verbatim copies of the vanilla script.

const MODDED_MAX_WINDOW: int = 1000


func paste(data: Dictionary) -> void:
	var seed: int = randi() / 10
	var new_windows: Array[Dictionary]
	var to_connect: Dictionary[String, Array]
	var required: int

	Data.update_schematic(data)

	var target_pos: Vector2 = Globals.camera_center - (data.rect.size / 2)
	var clamped_pos: Vector2 = target_pos.clamp(Vector2.ZERO, Vector2(Vector2(10000, 10000) - data.rect.size).max(Vector2.ZERO))

	for window: Dictionary in data.windows.duplicate(true):
		required += 1

		for resource: String in window.container_data:
			var new_name: String = Utils.generate_id_from_seed(window.container_data[resource].id.hash() + seed)
			window.container_data[resource].id = new_name
			window.container_data[resource].erase("count")
			to_connect[new_name] = []
			for output: String in window.container_data[resource].outputs_id:
				to_connect[new_name].append(Utils.generate_id_from_seed(output.hash() + seed))
			window.container_data[resource].outputs_id.clear()

		var new_name: String = find_window_name(window.name)
		window.position += clamped_pos - data.rect.position
		new_windows.append(window)

	# [MOD CHANGE] vanilla: Utils.MAX_WINDOW (500) -> modded: MODDED_MAX_WINDOW (1000)
	if required > MODDED_MAX_WINDOW - Globals.max_window_count:
		Signals.notify.emit("exclamation", "build_limit_reached")
		Sound.play("error")
		return

	data.windows = new_windows
	var windows_added: Array[WindowContainer] = paste_windows(data.windows)

	for i: String in data.connectors:
		var new_id: String = Utils.generate_id_from_seed(i.hash() + seed)
		if data.connectors[i].has("custom_points"):
			for point: int in data.connectors[i].custom_points.size():
				data.connectors[i].custom_points[point] += clamped_pos - data.rect.position
				data.connectors[i].custom_points[point] = data.connectors[i].custom_points[point].snappedf(25)
		connectors.connector_data[new_id] = data.connectors[i]

	for i: String in to_connect:
		var container: ResourceContainer = get_resource(i)
		if !container: continue
		for output: String in to_connect[i]:
			Signals.create_connection.emit(i, output)

	var connections: Array[Control]
	for i: String in to_connect:
		if connectors.connectors.has(i):
			connections.append_array(connectors.connectors[i].custom_points_rect)

	Globals.set_selection(windows_added, connections)
	connectors.connector_data.clear()
