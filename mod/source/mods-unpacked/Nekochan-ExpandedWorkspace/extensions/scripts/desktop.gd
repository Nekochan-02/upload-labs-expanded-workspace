extends "res://scripts/desktop.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const VANILLA_WORKSPACE_SIZE: float = 10000.0
const MOD_LOG_NAME: String = "Nekochan-ExpandedWorkspace"

var _expanded_workspace_drag_start_positions: Dictionary = {}
var _saved_restore_positions: Dictionary = {}
var _restoration_correlation_blocked: bool
var _template_correction_skip_reported: bool
var _input_blocker_coverage_applied: bool


func _enter_tree() -> void:
	_capture_restoration_snapshots()
	super._enter_tree()
	if not _restoration_correlation_blocked and not _saved_restore_positions.is_empty():
		call_deferred("_apply_restoration_corrections")


func _ready() -> void:
	super._ready()
	if not Signals.begin_drag.is_connected(_on_expanded_workspace_begin_drag):
		Signals.begin_drag.connect(_on_expanded_workspace_begin_drag)
	if not Signals.drag_selection.is_connected(_on_expanded_workspace_drag_selection):
		Signals.drag_selection.connect(_on_expanded_workspace_drag_selection)
	call_deferred("_apply_input_blocker_coverage")


func paste(data: Dictionary) -> void:
	var correction_context: Dictionary = _begin_template_correction(data)
	_paste_with_expanded_node_limit(data)
	if not correction_context.is_empty():
		_apply_template_correction(correction_context)


func _paste_with_expanded_node_limit(data: Dictionary) -> void:
	var required: int = _count_required_windows(data)
	if required <= 0 or Globals.max_window_count + required <= Utils.MAX_WINDOW:
		super.paste(data)
		return
	if Globals.max_window_count + required > MODDED_MAX_WINDOW:
		Signals.notify.emit("exclamation", "build_limit_reached")
		Sound.play("error")
		return

	var before: int = Globals.max_window_count
	var temporary_count: int = Utils.MAX_WINDOW - required
	Globals.max_window_count = temporary_count
	super.paste(data)
	var added: int = max(0, Globals.max_window_count - temporary_count)
	Globals.max_window_count = before + added


func _begin_template_correction(data: Dictionary) -> Dictionary:
	var rect_value = data.get("rect", Rect2())
	if not (rect_value is Rect2):
		return {}

	var template_rect: Rect2 = rect_value
	var raw_target: Vector2 = Globals.camera_center - (template_rect.size / 2.0)
	var old_max: Vector2 = (
		Vector2(VANILLA_WORKSPACE_SIZE, VANILLA_WORKSPACE_SIZE) - template_rect.size
	).max(Vector2.ZERO)
	var old_candidate: Vector2 = raw_target.clamp(Vector2.ZERO, old_max)
	var expanded_candidate: Vector2 = raw_target.clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(template_rect.size)
	)
	var correction_delta: Vector2 = expanded_candidate - old_candidate
	if raw_target.is_equal_approx(old_candidate) or correction_delta.is_zero_approx():
		return {}

	return {
		"before_window_ids": _capture_window_ids(),
		"before_connector_ids": _capture_connector_ids(),
		"expected_window_count": _expected_window_count(data),
		"correction_delta": correction_delta,
	}


func _apply_template_correction(context: Dictionary) -> void:
	var new_windows: Array[WindowContainer] = _collect_new_windows(
		context["before_window_ids"]
	)
	var new_connectors: Array[Connector] = _collect_new_connectors(
		context["before_connector_ids"]
	)
	var resource_owners: Dictionary = _collect_pasted_resource_owners(new_windows)
	if not _template_correction_is_safe(
		context,
		new_windows,
		new_connectors,
		resource_owners
	):
		_warn_template_correction_skipped()
		return

	var correction_delta: Vector2 = context["correction_delta"]
	for window: WindowContainer in new_windows:
		window.position += correction_delta
		window.moved.emit()
	for connector: Connector in new_connectors:
		for point_index: int in connector.custom_points.size():
			connector.custom_points[point_index] = (
				connector.custom_points[point_index] + correction_delta
			)
		connector.update_points()


func _template_correction_is_safe(
	context: Dictionary,
	new_windows: Array[WindowContainer],
	new_connectors: Array[Connector],
	resource_owners: Dictionary
) -> bool:
	if new_windows.size() != context["expected_window_count"]:
		return false
	if not _windows_are_valid(new_windows) or not _connectors_are_valid(new_connectors):
		return false
	if not _selection_matches(new_windows):
		return false
	if not resource_owners.get("valid", false):
		return false
	return _connectors_are_internal_to_pasted_set(
		new_connectors,
		resource_owners.get("owners", {})
	)


func _warn_template_correction_skipped() -> void:
	if _template_correction_skip_reported:
		return
	_template_correction_skip_reported = true
	ModLoaderLog.warning(
		"Template placement correction skipped because its ownership guard did not pass.",
		MOD_LOG_NAME
	)


func _expected_window_count(data: Dictionary) -> int:
	var window_data = data.get("windows", [])
	if not (window_data is Array):
		return 0
	var count: int = 0
	for window_entry in window_data:
		if not (window_entry is Dictionary):
			continue
		var filename: String = str(window_entry.get("filename", ""))
		if not filename.is_empty() and ResourceLoader.exists("res://scenes/windows/" + filename):
			count += 1
	return count


func _capture_window_ids() -> Dictionary:
	var ids: Dictionary = {}
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return ids
	for child in windows_node.get_children():
		if child is WindowContainer:
			ids[child.get_instance_id()] = true
	return ids


func _capture_connector_ids() -> Dictionary:
	var ids: Dictionary = {}
	var connectors_node: Node = get_node_or_null("Connectors")
	if not connectors_node:
		return ids
	for child in connectors_node.get_children():
		if child is Connector:
			ids[child.get_instance_id()] = true
	return ids


func _collect_new_windows(before_ids: Dictionary) -> Array[WindowContainer]:
	var new_windows: Array[WindowContainer] = []
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return new_windows
	for child in windows_node.get_children():
		if child is WindowContainer and not before_ids.has(child.get_instance_id()):
			new_windows.append(child)
	return new_windows


func _collect_new_connectors(before_ids: Dictionary) -> Array[Connector]:
	var new_connectors: Array[Connector] = []
	var connectors_node: Node = get_node_or_null("Connectors")
	if not connectors_node:
		return new_connectors
	for child in connectors_node.get_children():
		if child is Connector and not before_ids.has(child.get_instance_id()):
			new_connectors.append(child)
	return new_connectors


func _windows_are_valid(windows_to_check: Array[WindowContainer]) -> bool:
	var windows_node: Node = get_node_or_null("Windows")
	for window: WindowContainer in windows_to_check:
		if not is_instance_valid(window) or window.get_parent() != windows_node:
			return false
	return true


func _connectors_are_valid(connectors_to_check: Array[Connector]) -> bool:
	var connectors_node: Node = get_node_or_null("Connectors")
	for connector: Connector in connectors_to_check:
		if not is_instance_valid(connector) or connector.get_parent() != connectors_node:
			return false
	return true


func _selection_matches(new_windows: Array[WindowContainer]) -> bool:
	if Globals.selections.size() != new_windows.size():
		return false
	for selected: WindowContainer in Globals.selections:
		if not new_windows.has(selected):
			return false
	return true


func _collect_pasted_resource_owners(windows_to_check: Array[WindowContainer]) -> Dictionary:
	var owners: Dictionary = {}
	for window: WindowContainer in windows_to_check:
		if not is_instance_valid(window):
			return {"valid": false, "owners": owners}
		for resource: ResourceContainer in window.containers:
			if not is_instance_valid(resource) or not window.is_ancestor_of(resource):
				return {"valid": false, "owners": owners}
			var resource_id: String = str(resource.id)
			if resource_id.is_empty() or owners.has(resource_id):
				return {"valid": false, "owners": owners}
			owners[resource_id] = true
	return {"valid": true, "owners": owners}


func _connectors_are_internal_to_pasted_set(
	connectors_to_check: Array[Connector],
	resource_owners: Dictionary
) -> bool:
	for connector: Connector in connectors_to_check:
		if not is_instance_valid(connector):
			return false
		var output_id: String = connector.output_id
		var input_id: String = connector.input_id
		if output_id.is_empty() or input_id.is_empty():
			return false
		if not is_instance_valid(connector.output) or not is_instance_valid(connector.input):
			return false
		if str(connector.output.id) != output_id or str(connector.input.id) != input_id:
			return false
		if not resource_owners.has(output_id) or not resource_owners.has(input_id):
			return false
	return true


func _count_required_windows(data: Dictionary) -> int:
	if not data.has("windows") or not (data["windows"] is Array):
		return 0
	return data.windows.size()


func _on_expanded_workspace_begin_drag() -> void:
	_expanded_workspace_drag_start_positions.clear()
	for window: WindowContainer in Globals.selections:
		if is_instance_valid(window):
			_expanded_workspace_drag_start_positions[window] = window.global_position


func _on_expanded_workspace_drag_selection(from: Vector2, to: Vector2) -> void:
	if not _expanded_workspace_drag_start_positions.is_empty():
		call_deferred("_apply_expanded_workspace_drag_selection", to - from)


func _apply_expanded_workspace_drag_selection(delta: Vector2) -> void:
	for window: WindowContainer in _expanded_workspace_drag_start_positions:
		if not is_instance_valid(window):
			continue
		var start_position: Vector2 = _expanded_workspace_drag_start_positions[window]
		var target_position: Vector2 = (start_position + delta).clamp(
			Vector2.ZERO,
			WorkspaceAreaConfig.get_max_position(window.size)
		).snappedf(50)
		window.move(target_position)


func _capture_restoration_snapshots() -> void:
	_saved_restore_positions.clear()
	_restoration_correlation_blocked = false
	if not Globals.tutorial_done or Data.loading.is_empty() or not Data.loading.has("desktop_data"):
		return
	var desktop_data = Data.loading.desktop_data
	if not (desktop_data is Dictionary) or not desktop_data.has("windows"):
		return
	if not (desktop_data.windows is Array):
		return

	var seen_names: Dictionary = {}
	for window_data in desktop_data.windows:
		if not (window_data is Dictionary):
			continue
		var window_name: String = str(window_data.get("name", ""))
		if window_name.is_empty() or seen_names.has(window_name):
			_restoration_correlation_blocked = true
			_saved_restore_positions.clear()
			return
		seen_names[window_name] = true
		var saved_position = window_data.get("position")
		if saved_position is Vector2:
			_saved_restore_positions[window_name] = saved_position


func _apply_restoration_corrections() -> void:
	for window_name: String in _saved_restore_positions:
		var window: WindowContainer = get_node_or_null("Windows/" + window_name) as WindowContainer
		if not is_instance_valid(window):
			continue
		var saved_position: Vector2 = _saved_restore_positions[window_name]
		if saved_position.x < 0.0 or saved_position.y < 0.0:
			continue
		var vanilla_max_position: Vector2 = Vector2.ONE * VANILLA_WORKSPACE_SIZE - window.size
		if not _is_beyond_vanilla_bounds(saved_position, vanilla_max_position):
			continue
		var desired_position: Vector2 = saved_position.clamp(
			Vector2.ZERO,
			WorkspaceAreaConfig.get_max_position(window.size)
		)
		window.position = desired_position
		window.moved.emit()
	_saved_restore_positions.clear()


func _is_beyond_vanilla_bounds(saved_position: Vector2, vanilla_max_position: Vector2) -> bool:
	return saved_position.x > vanilla_max_position.x or saved_position.y > vanilla_max_position.y


func _apply_input_blocker_coverage() -> void:
	if _input_blocker_coverage_applied:
		return

	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var workspace_size: Vector2 = WorkspaceAreaConfig.get_workspace_size()
	var expected_workspace_size: Vector2 = Vector2(
		WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE,
		WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE
	)
	var target_rect: Rect2 = Rect2(Vector2.ZERO, workspace_size)
	var parent_is_desktop: bool = is_instance_valid(input_blocker) and input_blocker.get_parent() == self
	var workspace_matches_config: bool = workspace_size.is_equal_approx(expected_workspace_size)

	if not is_instance_valid(input_blocker) or not parent_is_desktop or not workspace_matches_config:
		ModLoaderLog.warning(
			"InputBlocker coverage correction skipped: invalid Desktop-local workspace rect.",
			MOD_LOG_NAME
		)
		return

	var before_position: Vector2 = input_blocker.position
	var before_size: Vector2 = input_blocker.size
	input_blocker.position = Vector2.ZERO
	input_blocker.size = workspace_size

	var actual_rect: Rect2 = input_blocker.get_global_rect()
	if not _rect_matches(actual_rect, target_rect):
		input_blocker.position = before_position
		input_blocker.size = before_size
		ModLoaderLog.warning(
			"InputBlocker coverage correction skipped: resulting rect did not match workspace.",
			MOD_LOG_NAME
		)
		return

	_input_blocker_coverage_applied = true


func _rect_matches(left: Rect2, right: Rect2) -> bool:
	return left.position.is_equal_approx(right.position) and left.size.is_equal_approx(right.size)
