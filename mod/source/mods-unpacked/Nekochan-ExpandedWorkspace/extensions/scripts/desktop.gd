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
var _f29_selection_attempt_started: bool
var _f29_selection_attempt_completed: bool
var _f29_selection_start_screen: Vector2
var _f29_selection_start_world: Vector2
var _f29_selection_start_panel_world: Vector2
var _f51_active_attempt: Dictionary = {}
var _f51_old_guard_snapshot: Dictionary = {}
var _f51_expected_area: String = "old_guard"
var _f51_attempt_id: int
var _f51_guard_failed: bool
var _f53_coverage_applied: bool
var _f53_coverage_blocked: bool


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
	_f29_log_armed_geometry()
	_f51_connect_input_blocker_observer()
	_f51_log("B0_DIAGNOSTIC_ARMED", "passive=true base=0.2.29 expected_attempt_order=old_guard_then_expanded selection_panel_override=false")
	call_deferred("_f53_apply_input_blocker_coverage")


func _input(event: InputEvent) -> void:
	_f51_record_desktop_input(event)
	if _f29_selection_attempt_completed or not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.is_pressed():
		if _f29_is_selection_attempt_candidate(event):
			_f29_capture_selection_start(event)
	elif _f29_selection_attempt_started:
		_f29_capture_selection_release(event)


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


func _f29_is_selection_attempt_candidate(event: InputEventMouseButton) -> bool:
	if Globals.cur_screen != 0:
		return false
	return (
		Globals.tool == Utils.tools.SELECT
		or event.shift_pressed
		or Input.is_action_pressed("multi_select")
	)


func _f29_capture_selection_start(event: InputEventMouseButton) -> void:
	_f29_selection_attempt_started = true
	_f29_selection_start_screen = event.position
	_f29_selection_start_world = Utils.screen_to_world_pos(event.position)
	_f29_selection_start_panel_world = _f29_panel_mouse_world()

	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	ModLoaderLog.info(
		"[F29][R1_SELECTION_INPUT_START] tool=%s input_blocker_visible=%s input_blocker_global_position=%s input_blocker_size=%s selection_panel_visible=%s selection_panel_global_position=%s selection_panel_size=%s" % [
			str(Globals.tool),
			str(is_instance_valid(input_blocker) and input_blocker.visible),
			_f29_control_global_position(input_blocker),
			_f29_control_size(input_blocker),
			str(is_instance_valid(selection_panel) and selection_panel.visible),
			_f29_control_global_position(selection_panel),
			_f29_control_size(selection_panel),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R2_SHIFT_STATE] event_shift_pressed=%s multi_select_pressed=%s" % [
			str(event.shift_pressed),
			str(Input.is_action_pressed("multi_select")),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R3_DRAG_START_SCREEN_WORLD] screen=%s utils_world=%s panel_world=%s camera_center=%s" % [
			str(_f29_selection_start_screen),
			str(_f29_selection_start_world),
			str(_f29_selection_start_panel_world),
			str(Globals.camera_center),
		],
		MOD_LOG_NAME
	)


func _f29_capture_selection_release(event: InputEventMouseButton) -> void:
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var end_screen: Vector2 = event.position
	var end_world: Vector2 = Utils.screen_to_world_pos(end_screen)
	var end_panel_world: Vector2 = _f29_panel_mouse_world()
	var raw_rect: Rect2 = Rect2(
		_f29_selection_start_panel_world,
		end_panel_world - _f29_selection_start_panel_world
	)
	var normalized_raw_rect: Rect2 = raw_rect.abs()
	var actual_rect: Rect2 = _f29_control_rect(selection_panel)
	var old_bounds: Rect2 = Rect2(
		Vector2.ZERO,
		Vector2(VANILLA_WORKSPACE_SIZE, VANILLA_WORKSPACE_SIZE)
	)
	var expanded_bounds: Rect2 = Rect2(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_workspace_size()
	)
	var old_candidate: Rect2 = normalized_raw_rect.intersection(old_bounds)
	var expanded_candidate: Rect2 = normalized_raw_rect.intersection(expanded_bounds)
	var raw_exceeds_old_bounds: bool = not old_bounds.encloses(normalized_raw_rect)
	var actual_matches_old_candidate: bool = _f29_rect_equals(actual_rect, old_candidate)
	var input_blocker_contains_end: bool = (
		is_instance_valid(input_blocker)
		and input_blocker.get_global_rect().has_point(end_panel_world)
	)
	var old_bound_limit_detected: bool = (
		raw_exceeds_old_bounds and actual_matches_old_candidate
	)
	var selection_rect_drawn: bool = (
		is_instance_valid(selection_panel)
		and selection_panel.visible
		and actual_rect.has_area()
	)
	var hit_test: Dictionary = _f29_collect_hit_test_candidates(actual_rect)

	ModLoaderLog.info(
		"[F29][R4_DRAG_CURRENT_SCREEN_WORLD] screen=%s utils_world=%s panel_world=%s camera_center=%s" % [
			str(end_screen),
			str(end_world),
			str(end_panel_world),
			str(Globals.camera_center),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R5_SELECTION_RECT_RAW] raw=%s normalized_raw=%s" % [
			str(raw_rect),
			str(normalized_raw_rect),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R6_SELECTION_RECT_AFTER_CLAMP] actual_used=%s old_bound_candidate=%s expanded_bound_candidate=%s raw_exceeds_old_bounds=%s input_blocker_contains_end=%s old_bound_limit_detected=%s" % [
			str(actual_rect),
			str(old_candidate),
			str(expanded_candidate),
			str(raw_exceeds_old_bounds),
			str(input_blocker_contains_end),
			str(old_bound_limit_detected),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R7_SELECTION_RECT_DRAWN] visible=%s has_area=%s drawn=%s actual_used=%s" % [
			str(is_instance_valid(selection_panel) and selection_panel.visible),
			str(actual_rect.has_area()),
			str(selection_rect_drawn),
			str(actual_rect),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R8_WINDOW_HIT_TEST_CANDIDATES] selectable_count=%d expanded_area_window_count=%d old_area_window_count=%d window_hit_ids=%s window_hit_count=%d connector_hit_ids=%s connector_hit_count=%d" % [
			int(hit_test["selectable_count"]),
			int(hit_test["expanded_area_window_count"]),
			int(hit_test["old_area_window_count"]),
			str(hit_test["window_hit_ids"]),
			int(hit_test["window_hit_count"]),
			str(hit_test["connector_hit_ids"]),
			int(hit_test["connector_hit_count"]),
		],
		MOD_LOG_NAME
	)
	ModLoaderLog.info(
		"[F29][R9_SELECTION_RESULT] computed_window_ids=%s computed_window_count=%d computed_connector_ids=%s computed_connector_count=%d" % [
			str(hit_test["window_hit_ids"]),
			int(hit_test["window_hit_count"]),
			str(hit_test["connector_hit_ids"]),
			int(hit_test["connector_hit_count"]),
		],
		MOD_LOG_NAME
	)
	call_deferred("_f29_capture_final_state", hit_test)


func _f29_capture_final_state(hit_test: Dictionary) -> void:
	if _f29_selection_attempt_completed:
		return
	_f29_selection_attempt_completed = true
	var final_window_ids: Array[String] = _f29_node_ids(Globals.selections)
	var final_connector_ids: Array[String] = _f29_node_ids(Globals.connector_selection)
	var selection_applied: bool = _f29_expected_selection_present(
		hit_test["window_hit_ids"],
		hit_test["connector_hit_ids"],
		final_window_ids,
		final_connector_ids
	)
	ModLoaderLog.info(
		"[F29][R10_SELECTION_FINAL_STATE] final_window_ids=%s final_window_count=%d final_connector_ids=%s final_connector_count=%d selection_applied=%s" % [
			str(final_window_ids),
			final_window_ids.size(),
			str(final_connector_ids),
			final_connector_ids.size(),
			str(selection_applied),
		],
		MOD_LOG_NAME
	)


func _f29_log_armed_geometry() -> void:
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	ModLoaderLog.info(
		"[F29][RANGE_SELECTION] armed_for_one_attempt input_blocker_global_position=%s input_blocker_size=%s selection_panel_global_position=%s selection_panel_size=%s" % [
			_f29_control_global_position(input_blocker),
			_f29_control_size(input_blocker),
			_f29_control_global_position(selection_panel),
			_f29_control_size(selection_panel),
		],
		MOD_LOG_NAME
	)


func _f29_panel_mouse_world() -> Vector2:
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	if is_instance_valid(selection_panel):
		return selection_panel.get_global_mouse_position()
	return Utils.screen_to_world_pos(get_viewport().get_mouse_position())


func _f29_control_rect(control: Control) -> Rect2:
	if is_instance_valid(control):
		return control.get_rect()
	return Rect2()


func _f29_control_global_position(control: Control) -> String:
	if is_instance_valid(control):
		return str(control.global_position)
	return "MISSING"


func _f29_control_size(control: Control) -> String:
	if is_instance_valid(control):
		return str(control.size)
	return "MISSING"


func _f29_collect_hit_test_candidates(selection_rect: Rect2) -> Dictionary:
	var selectable_count: int
	var expanded_area_window_count: int
	var old_area_window_count: int
	var window_hit_ids: Array[String] = []
	var connector_hit_ids: Array[String] = []

	for node: Node in get_tree().get_nodes_in_group("selectable"):
		if not (node is WindowContainer):
			continue
		var window: WindowContainer = node
		if not window.can_multi_select:
			continue
		selectable_count += 1
		if _f29_window_is_in_expanded_area(window):
			expanded_area_window_count += 1
		else:
			old_area_window_count += 1
		if selection_rect.intersects(window.get_rect()):
			window_hit_ids.append(_f29_node_id(window))

	for node: Node in get_tree().get_nodes_in_group("connector_point"):
		if node is Control and selection_rect.intersects(node.get_rect()):
			connector_hit_ids.append(_f29_node_id(node))

	return {
		"selectable_count": selectable_count,
		"expanded_area_window_count": expanded_area_window_count,
		"old_area_window_count": old_area_window_count,
		"window_hit_ids": window_hit_ids,
		"window_hit_count": window_hit_ids.size(),
		"connector_hit_ids": connector_hit_ids,
		"connector_hit_count": connector_hit_ids.size(),
	}


func _f29_window_is_in_expanded_area(window: WindowContainer) -> bool:
	return (
		window.global_position.x + window.size.x > VANILLA_WORKSPACE_SIZE
		or window.global_position.y + window.size.y > VANILLA_WORKSPACE_SIZE
	)


func _f29_node_ids(nodes: Array) -> Array[String]:
	var ids: Array[String] = []
	for node: Node in nodes:
		if is_instance_valid(node):
			ids.append(_f29_node_id(node))
	return ids


func _f29_node_id(node: Node) -> String:
	return "%s#%d" % [node.name, node.get_instance_id()]


func _f29_expected_selection_present(
	expected_window_ids: Array,
	expected_connector_ids: Array,
	final_window_ids: Array[String],
	final_connector_ids: Array[String]
) -> bool:
	for expected_id: String in expected_window_ids:
		if not final_window_ids.has(expected_id):
			return false
	for expected_id: String in expected_connector_ids:
		if not final_connector_ids.has(expected_id):
			return false
	return true


func _f29_rect_equals(left: Rect2, right: Rect2) -> bool:
	return (
		left.position.is_equal_approx(right.position)
		and left.size.is_equal_approx(right.size)
	)


func _f51_connect_input_blocker_observer() -> void:
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	if is_instance_valid(input_blocker) and not input_blocker.gui_input.is_connected(_f51_record_input_blocker_gui):
		input_blocker.gui_input.connect(_f51_record_input_blocker_gui)


func _f53_apply_input_blocker_coverage() -> void:
	if _f53_coverage_applied or _f53_coverage_blocked:
		return

	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var workspace_size: Vector2 = WorkspaceAreaConfig.get_workspace_size()
	var expected_workspace_size: Vector2 = Vector2(
		WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE,
		WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE
	)
	var target_rect: Rect2 = Rect2(Vector2.ZERO, workspace_size)
	var before_rect: Rect2 = input_blocker.get_global_rect() if is_instance_valid(input_blocker) else Rect2()
	var parent_is_desktop: bool = is_instance_valid(input_blocker) and input_blocker.get_parent() == self
	var workspace_matches_config: bool = workspace_size.is_equal_approx(expected_workspace_size)

	if not is_instance_valid(input_blocker) or not parent_is_desktop or not workspace_matches_config:
		_f53_coverage_blocked = true
		_f53_log(
			"C0_COVERAGE_APPLY",
			"status=BLOCKED input_blocker_valid=%s parent_is_desktop=%s workspace_size=%s expected_workspace_size=%s before_rect=%s target_rect=%s" % [
				str(is_instance_valid(input_blocker)),
				str(parent_is_desktop),
				str(workspace_size),
				str(expected_workspace_size),
				str(before_rect),
				str(target_rect),
			]
		)
		return

	var before_position: Vector2 = input_blocker.position
	var before_size: Vector2 = input_blocker.size
	input_blocker.position = Vector2.ZERO
	input_blocker.size = workspace_size

	var actual_rect: Rect2 = input_blocker.get_global_rect()
	if not _f53_rect_matches(actual_rect, target_rect):
		input_blocker.position = before_position
		input_blocker.size = before_size
		_f53_coverage_blocked = true
		_f53_log(
			"C0_COVERAGE_APPLY",
			"status=BLOCKED reason=actual_rect_mismatch before_rect=%s target_rect=%s actual_rect=%s restored_rect=%s" % [
				str(before_rect),
				str(target_rect),
				str(actual_rect),
				str(input_blocker.get_global_rect()),
			]
		)
		return

	_f53_coverage_applied = true
	_f53_log(
		"C0_COVERAGE_APPLY",
		"status=APPLIED input_blocker_parent=Desktop workspace_size=%s before_rect=%s target_rect=%s actual_rect=%s" % [
			str(workspace_size),
			str(before_rect),
			str(target_rect),
			str(actual_rect),
		]
	)


func _f53_rect_matches(left: Rect2, right: Rect2) -> bool:
	return left.position.is_equal_approx(right.position) and left.size.is_equal_approx(right.size)


func _f51_record_desktop_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if mouse_event.is_pressed():
		if not _f51_active_attempt.is_empty() or _f51_guard_failed:
			return
		if not _f51_shift_candidate(mouse_event):
			return
		var attempt_area: String = _f51_area_for_screen_position(mouse_event.position)
		if attempt_area != _f51_expected_area:
			_f51_log(
				"B10_INPUTBLOCKER_CAMERA_CLASSIFICATION",
				"attempt_id=none expected_area=%s actual_area=%s classification=EXPANDED_ROUTE_DIAGNOSTIC_INCONCLUSIVE reason=attempt_order_mismatch" % [
					_f51_expected_area,
					attempt_area,
				]
			)
			return
		_f51_start_attempt(mouse_event, attempt_area)
	elif not _f51_active_attempt.is_empty():
		_f51_active_attempt["mouse_released"] = true
		call_deferred("_f51_finalize_attempt")


func _f51_shift_candidate(event: InputEventMouseButton) -> bool:
	return (
		event.shift_pressed
		or Input.is_key_pressed(KEY_SHIFT)
		or Input.is_action_pressed("multi_select")
	)


func _f51_area_for_screen_position(screen_position: Vector2) -> String:
	var world_position: Vector2 = Utils.screen_to_world_pos(screen_position)
	if world_position.x > VANILLA_WORKSPACE_SIZE or world_position.y > VANILLA_WORKSPACE_SIZE:
		return "expanded"
	return "old_guard"


func _f51_start_attempt(event: InputEventMouseButton, attempt_area: String) -> void:
	_f51_attempt_id += 1
	var camera: Camera2D = get_node_or_null("../Camera2D") as Camera2D
	_f51_active_attempt = {
		"attempt_id": _f51_attempt_id,
		"attempt_area": attempt_area,
		"screen_position": event.position,
		"world_position": Utils.screen_to_world_pos(event.position),
		"camera_start_position": camera.position if is_instance_valid(camera) else Vector2.ZERO,
		"input_blocker_reached": false,
		"selection_panel_reached": false,
		"main2d_gui_reached": false,
		"main2d_unhandled_reached": false,
		"camera_reached": false,
		"camera_moved": false,
		"selection_panel_visible_seen": false,
		"mouse_released": false,
	}
	_f51_capture_control_state(event)
	if attempt_area == "old_guard":
		_f51_log("B1_OLD_AREA_GUARD_START", _f51_attempt_header())
		_f53_log("C1_OLD_AREA_GUARD_START", _f51_attempt_header() + " " + _f51_input_blocker_state())
	else:
		_f51_log("B3_EXPANDED_TARGET_START", _f51_attempt_header())
		_f53_log("C3_EXPANDED_TARGET_START", _f51_attempt_header() + " " + _f51_input_blocker_state())
		_f53_log("C4_EXPANDED_HIT_TEST", _f51_attempt_header() + " " + _f51_input_blocker_hit_test(event))
	_f51_log("B4_INPUT_STATE_AT_TARGET", _f51_attempt_header() + " " + _f51_input_state(event))
	_f51_log("B5_INPUTBLOCKER_STATE_AND_GEOMETRY", _f51_attempt_header() + " " + _f51_input_blocker_state())
	_f51_log("B6_INPUTBLOCKER_HIT_TEST", _f51_attempt_header() + " " + _f51_input_blocker_hit_test(event))


func _f51_record_input_blocker_gui(event: InputEvent) -> void:
	if not _f51_is_active_pointer_event(event):
		return
	_f51_active_attempt["input_blocker_reached"] = true
	_f51_active_attempt["selection_panel_reached"] = _f51_selection_panel_connection_exists()
	_f51_capture_control_state(event)


func _f51_record_main2d_route(route: String, event: InputEvent) -> void:
	if not _f51_is_active_pointer_event(event):
		return
	_f51_active_attempt["main2d_%s_reached" % route] = true
	_f51_capture_control_state(event)


func _f51_record_camera_route(event: InputEvent, before_position: Vector2, after_position: Vector2) -> void:
	if not _f51_is_active_pointer_event(event):
		return
	_f51_active_attempt["camera_reached"] = true
	if not before_position.is_equal_approx(after_position):
		_f51_active_attempt["camera_moved"] = true
	_f51_capture_control_state(event)


func _f51_is_active_pointer_event(event: InputEvent) -> bool:
	if _f51_active_attempt.is_empty() or bool(_f51_active_attempt.get("mouse_released", false)):
		return false
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventMouseMotion:
		return event.button_mask == MOUSE_BUTTON_LEFT
	return false


func _f51_capture_control_state(event: InputEvent) -> void:
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	if is_instance_valid(selection_panel) and selection_panel.visible:
		_f51_active_attempt["selection_panel_visible_seen"] = true



func _f51_finalize_attempt() -> void:
	if _f51_active_attempt.is_empty():
		return
	var attempt_area: String = str(_f51_active_attempt["attempt_area"])
	var camera: Camera2D = get_node_or_null("../Camera2D") as Camera2D
	if is_instance_valid(camera) and not camera.position.is_equal_approx(_f51_active_attempt["camera_start_position"]):
		_f51_active_attempt["camera_moved"] = true
	var rectangle_appeared: bool = bool(_f51_active_attempt["selection_panel_visible_seen"])
	var nodes_selected: bool = Globals.selections.size() > 0 or Globals.connector_selection.size() > 0
	var classification: String = _f51_classify_attempt()
	if attempt_area == "old_guard":
		var guard_passed: bool = rectangle_appeared and nodes_selected and not bool(_f51_active_attempt["camera_moved"])
		if not guard_passed:
			classification = "EXPANDED_ROUTE_OLD_AREA_GUARD_FAILED"
			_f51_guard_failed = true
			_f51_expected_area = "blocked"
		else:
			_f51_expected_area = "expanded"
		_f51_log(
			"B2_OLD_AREA_GUARD_RESULT",
			"%s rectangle_appeared=%s nodes_selected=%s camera_moved=%s guard_passed=%s classification=%s %s %s" % [
				_f51_attempt_header(),
				str(rectangle_appeared),
				str(nodes_selected),
				str(_f51_active_attempt["camera_moved"]),
				str(guard_passed),
				classification,
				_f51_main2d_route_summary(),
				_f51_camera_route_summary(),
			]
		)
		_f51_old_guard_snapshot = _f51_active_attempt.duplicate(true)
		_f53_log(
			"C2_OLD_AREA_GUARD_RESULT",
			"%s rectangle_appeared=%s nodes_selected=%s camera_moved=%s guard_passed=%s" % [
				_f51_attempt_header(),
				str(rectangle_appeared),
				str(nodes_selected),
				str(_f51_active_attempt["camera_moved"]),
				str(guard_passed),
			]
		)
		if not guard_passed:
			_f53_log("C7_FINAL_CLASSIFICATION", "classification=F53_INPUTBLOCKER_COVERAGE_OLD_GUARD_FAILED")
	else:
		_f51_log("B7_MAIN2D_ROUTE_SUMMARY", _f51_attempt_header() + " " + _f51_main2d_route_summary())
		_f51_log("B8_CAMERA_ROUTE_SUMMARY", _f51_attempt_header() + " " + _f51_camera_route_summary())
		_f51_log("B9_ROUTE_DIFF_OLD_VS_EXPANDED", _f51_route_difference_summary())
		_f53_log("C5_VANILLA_ROUTE", _f51_attempt_header() + " " + _f51_main2d_route_summary() + " " + _f51_camera_route_summary())
		_f53_log(
			"C6_EXPANDED_SELECTION_RESULT",
			"%s rectangle_appeared=%s nodes_selected=%s camera_moved=%s" % [
				_f51_attempt_header(),
				str(rectangle_appeared),
				str(nodes_selected),
				str(_f51_active_attempt["camera_moved"]),
			]
		)
		_f53_log(
			"C7_FINAL_CLASSIFICATION",
			"classification=%s" % _f53_classify_attempt(rectangle_appeared, nodes_selected)
		)
	_f51_log(
		"B10_INPUTBLOCKER_CAMERA_CLASSIFICATION",
		"%s classification=%s input_blocker_reached=%s selection_panel_reached=%s camera_reached=%s" % [
			_f51_attempt_header(),
			classification,
			str(_f51_active_attempt["input_blocker_reached"]),
			str(_f51_active_attempt["selection_panel_reached"]),
			str(_f51_active_attempt["camera_reached"]),
		]
	)
	_f51_active_attempt.clear()


func _f51_classify_attempt() -> String:
	if _f51_guard_failed:
		return "EXPANDED_ROUTE_OLD_AREA_GUARD_FAILED"
	if str(_f51_active_attempt.get("attempt_area", "")) != "expanded":
		return "EXPANDED_ROUTE_DIAGNOSTIC_INCONCLUSIVE"
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	if not is_instance_valid(input_blocker) or not input_blocker.visible:
		return "EXPANDED_ROUTE_INPUTBLOCKER_HIDDEN"
	var screen_position: Vector2 = _f51_active_attempt["screen_position"]
	var panel_mouse_position: Vector2 = _f51_panel_mouse_position(screen_position)
	if not input_blocker.get_global_rect().has_point(panel_mouse_position):
		return "EXPANDED_ROUTE_INPUTBLOCKER_OUT_OF_BOUNDS"
	if input_blocker.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return "EXPANDED_ROUTE_INPUTBLOCKER_MOUSE_FILTER_BLOCKED"
	if Globals.tool != Utils.tools.SELECT:
		return "EXPANDED_ROUTE_TOOL_NOT_SELECT"
	if bool(_f51_active_attempt["main2d_unhandled_reached"]) and bool(_f51_active_attempt["camera_reached"]):
		return "EXPANDED_ROUTE_MAIN2D_FORWARDS_TO_CAMERA"
	if bool(_f51_active_attempt["camera_reached"]) and not bool(_f51_active_attempt["input_blocker_reached"]):
		return "EXPANDED_ROUTE_CAMERA_HANDLES_WHEN_GUI_MISSES"
	return "EXPANDED_ROUTE_DIAGNOSTIC_INCONCLUSIVE"


func _f53_classify_attempt(rectangle_appeared: bool, nodes_selected: bool) -> String:
	if _f53_coverage_blocked or not _f53_coverage_applied:
		return "F53_INPUTBLOCKER_COVERAGE_APPLY_FAILED"
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	if not is_instance_valid(input_blocker):
		return "F53_INPUTBLOCKER_COVERAGE_APPLY_FAILED"
	var screen_position: Vector2 = _f51_active_attempt["screen_position"]
	var panel_mouse_position: Vector2 = _f51_panel_mouse_position(screen_position)
	if not input_blocker.get_global_rect().has_point(panel_mouse_position):
		return "F53_INPUTBLOCKER_COVERAGE_ROUTE_NOT_RESTORED"
	if not bool(_f51_active_attempt["input_blocker_reached"]) or not bool(_f51_active_attempt["selection_panel_reached"]):
		return "F53_INPUTBLOCKER_COVERAGE_ROUTE_NOT_RESTORED"
	if not rectangle_appeared or not nodes_selected or bool(_f51_active_attempt["camera_moved"]):
		return "F53_INPUTBLOCKER_COVERAGE_SELECTION_FAILED"
	return "F53_INPUTBLOCKER_COVERAGE_CANARY_PASS"


func _f51_attempt_header() -> String:
	return "attempt_id=%s attempt_area=%s" % [
		str(_f51_active_attempt.get("attempt_id", "none")),
		str(_f51_active_attempt.get("attempt_area", "unknown")),
	]


func _f51_input_state(event: InputEventMouseButton) -> String:
	return "raw_shift=%s multi_select=%s event_shift=%s globals_tool=%s select_value=%s tool_is_select=%s" % [
		str(Input.is_key_pressed(KEY_SHIFT)),
		str(Input.is_action_pressed("multi_select")),
		str(event.shift_pressed),
		str(Globals.tool),
		str(Utils.tools.SELECT),
		str(Globals.tool == Utils.tools.SELECT),
	]


func _f51_input_blocker_state() -> String:
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	if not is_instance_valid(input_blocker):
		return "input_blocker=MISSING"
	return "visible=%s mouse_filter=%s position=%s global_position=%s size=%s rect=%s global_rect=%s" % [
		str(input_blocker.visible),
		str(input_blocker.mouse_filter),
		str(input_blocker.position),
		str(input_blocker.global_position),
		str(input_blocker.size),
		str(input_blocker.get_rect()),
		str(input_blocker.get_global_rect()),
	]


func _f51_input_blocker_hit_test(event: InputEventMouseButton) -> String:
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var panel_mouse_position: Vector2 = _f51_panel_mouse_position(event.position)
	var world_position: Vector2 = Utils.screen_to_world_pos(event.position)
	if not is_instance_valid(input_blocker):
		return "screen=%s world=%s panel_mouse=%s input_blocker_local=UNKNOWN inside_input_blocker=UNKNOWN" % [
			str(event.position), str(world_position), str(panel_mouse_position)
		]
	return "screen=%s world=%s panel_mouse=%s input_blocker_local=%s inside_input_blocker=%s" % [
		str(event.position),
		str(world_position),
		str(panel_mouse_position),
		str(input_blocker.get_local_mouse_position()),
		str(input_blocker.get_global_rect().has_point(panel_mouse_position)),
	]


func _f51_panel_mouse_position(screen_position: Vector2) -> Vector2:
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	if is_instance_valid(selection_panel):
		return selection_panel.get_global_mouse_position()
	return Utils.screen_to_world_pos(screen_position)


func _f51_selection_panel_connection_exists() -> bool:
	var input_blocker: Control = get_node_or_null("InputBlocker") as Control
	var selection_panel: Control = get_node_or_null("SelectionPanel") as Control
	if not is_instance_valid(input_blocker) or not is_instance_valid(selection_panel):
		return false
	return input_blocker.gui_input.is_connected(
		Callable(selection_panel, "_on_input_blocker_gui_input")
	)


func _f51_main2d_route_summary() -> String:
	return "main2d_gui_reached=%s main2d_unhandled_reached=%s input_blocker_reached=%s selection_panel_reached=%s" % [
		str(_f51_active_attempt["main2d_gui_reached"]),
		str(_f51_active_attempt["main2d_unhandled_reached"]),
		str(_f51_active_attempt["input_blocker_reached"]),
		str(_f51_active_attempt["selection_panel_reached"]),
	]


func _f51_camera_route_summary() -> String:
	return "camera_reached=%s camera_moved=%s" % [
		str(_f51_active_attempt["camera_reached"]),
		str(_f51_active_attempt["camera_moved"]),
	]


func _f51_route_difference_summary() -> String:
	if _f51_old_guard_snapshot.is_empty():
		return "old_guard=UNAVAILABLE expanded=%s" % _f51_attempt_header()
	return "old_input_blocker_reached=%s expanded_input_blocker_reached=%s old_selection_panel_reached=%s expanded_selection_panel_reached=%s old_camera_reached=%s expanded_camera_reached=%s" % [
		str(_f51_old_guard_snapshot["input_blocker_reached"]),
		str(_f51_active_attempt["input_blocker_reached"]),
		str(_f51_old_guard_snapshot["selection_panel_reached"]),
		str(_f51_active_attempt["selection_panel_reached"]),
		str(_f51_old_guard_snapshot["camera_reached"]),
		str(_f51_active_attempt["camera_reached"]),
	]


func _f51_log(checkpoint: String, message: String) -> void:
	ModLoaderLog.info("[F51][%s] %s" % [checkpoint, message], MOD_LOG_NAME)


func _f53_log(checkpoint: String, message: String) -> void:
	ModLoaderLog.info("[F53][%s] %s" % [checkpoint, message], MOD_LOG_NAME)
