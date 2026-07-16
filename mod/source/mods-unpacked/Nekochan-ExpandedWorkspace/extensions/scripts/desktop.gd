extends "res://scripts/desktop.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F6_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F6"
const F6_MAX_LOG_TARGETS: int = 3
const F6_OLD_WORKSPACE_SIZE: float = 10000.0
const F12_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F12"
const F12_MAX_CHILDREN: int = 2
const F12_OPENING_SETTLE_DELAY_SECONDS: float = 0.5
const F21_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F21"
const F21_OLD_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)
const F21_MAX_WINDOW_RECORDS: int = 2
const F25_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F25"
const F25_OLD_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)
const F25_MAX_LOG_RECORDS: int = 20

var _expanded_workspace_drag_start_positions: Dictionary = {}
var _f6_saved_restore_positions: Dictionary = {}
var _f6_saved_restore_metadata: Dictionary = {}
var _f6_correlation_blocked: bool
var _f6_stability_checks: Array = []
var _f12_group_diagnostic: Dictionary = {}
var _f21_sequence_consumed: bool
var _f21_pending: Dictionary = {}
var _f25_sequence_consumed: bool
var _f25_pending: Dictionary = {}


func _enter_tree() -> void:
	_f6_capture_restoration_snapshots()

	super._enter_tree()

	if not _f6_correlation_blocked and not _f6_saved_restore_positions.is_empty():
		call_deferred("_f6_apply_restoration_corrections")


func _ready() -> void:
	super._ready()

	if not Signals.begin_drag.is_connected(_on_expanded_workspace_begin_drag):
		Signals.begin_drag.connect(_on_expanded_workspace_begin_drag)
	if not Signals.drag_selection.is_connected(_on_expanded_workspace_drag_selection):
		Signals.drag_selection.connect(_on_expanded_workspace_drag_selection)


func paste(data: Dictionary) -> void:
	var f25_started: bool = _f25_begin_template_connector_ownership_canary(data)
	_paste_with_expanded_node_limit(data)

	if f25_started:
		_f25_evaluate_and_apply_correction()


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


func _f21_begin_template_preplacement_diagnostic(data: Dictionary) -> bool:
	if _f21_sequence_consumed:
		return false

	_f21_sequence_consumed = true
	var rect_value = data.get("rect", Rect2())
	var template_rect: Rect2 = rect_value if rect_value is Rect2 else Rect2()
	var camera_center: Vector2 = Globals.camera_center
	var raw_target: Vector2 = camera_center - (template_rect.size / 2.0)
	var old_max: Vector2 = (F21_OLD_WORKSPACE_SIZE - template_rect.size).max(Vector2.ZERO)
	var old_clamped: Vector2 = raw_target.clamp(Vector2.ZERO, old_max)
	var expanded_max: Vector2 = WorkspaceAreaConfig.get_max_position(template_rect.size)
	var expanded_clamped: Vector2 = raw_target.clamp(Vector2.ZERO, expanded_max)
	var camera: Camera2D = get_viewport().get_camera_2d()
	var camera_global: Vector2 = Vector2.ZERO
	var camera_zoom: Vector2 = Vector2.ZERO
	if camera:
		camera_global = camera.global_position
		camera_zoom = camera.zoom

	_f21_pending = {
		"before_window_ids": _f21_capture_window_ids(),
		"camera_center": camera_center,
		"raw_target": raw_target,
		"old_clamped": old_clamped,
		"expanded_clamped": expanded_clamped,
		"immediate_instance_id": -1,
	}

	ModLoaderLog.info(
		"[F21][T1_CAMERA_STATE] camera_center=%s camera_global=%s camera_zoom=%s viewport_rect=%s" % [
			str(camera_center),
			str(camera_global),
			str(camera_zoom),
			str(get_viewport().get_visible_rect()),
		],
		F21_LOG_NAME
	)
	ModLoaderLog.info(
		"[F21][T2_TEMPLATE_DATA_BOUNDS] template_name=unavailable_at_paste window_count=%d group_window_count=%d rect_position=%s rect_size=%s" % [
			_f21_template_window_count(data),
			_f21_template_group_count(data),
			str(template_rect.position),
			str(template_rect.size),
		],
		F21_LOG_NAME
	)
	ModLoaderLog.info(
		"[F21][T3_PREPLACEMENT_TARGET_RAW] camera_center=%s raw_target=%s template_anchor=%s" % [
			str(camera_center),
			str(raw_target),
			str(template_rect.position),
		],
		F21_LOG_NAME
	)
	ModLoaderLog.info(
		"[F21][T4_PREPLACEMENT_TARGET_CLAMPED_OLD] old_max=%s old_clamped=%s old_bound_clamp_detected=%s" % [
			str(old_max),
			str(old_clamped),
			str(not raw_target.is_equal_approx(old_clamped)),
		],
		F21_LOG_NAME
	)
	ModLoaderLog.info(
		"[F21][T5_PREPLACEMENT_TARGET_CLAMPED_EXPANDED] expanded_max=%s expanded_clamped=%s differs_from_old_candidate=%s" % [
			str(expanded_max),
			str(expanded_clamped),
			str(not old_clamped.is_equal_approx(expanded_clamped)),
		],
		F21_LOG_NAME
	)
	return true


func _f21_template_window_count(data: Dictionary) -> int:
	var windows = data.get("windows", [])
	return windows.size() if windows is Array else 0


func _f21_template_group_count(data: Dictionary) -> int:
	var groups: int = 0
	var windows = data.get("windows", [])
	if not (windows is Array):
		return groups
	for window_data in windows:
		if window_data is Dictionary and str(window_data.get("filename", "")) == "window_group.tscn":
			groups += 1
	return groups


func _f21_capture_window_ids() -> Dictionary:
	var ids: Dictionary = {}
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return ids
	for child in windows_node.get_children():
		if child is WindowContainer:
			ids[child.get_instance_id()] = true
	return ids


func _f21_collect_new_window_records() -> Array:
	var records: Array = []
	var before_ids: Dictionary = _f21_pending.get("before_window_ids", {})
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return records
	for child in windows_node.get_children():
		if not (child is WindowContainer):
			continue
		if before_ids.has(child.get_instance_id()):
			continue
		records.append({
			"instance_id": child.get_instance_id(),
			"name": child.name,
			"local": child.position,
			"global": child.global_position,
			"size": child.size,
		})
		if records.size() >= F21_MAX_WINDOW_RECORDS:
			break
	return records


func _f21_log_template_runtime_checkpoint(checkpoint: String, phase: String) -> void:
	if _f21_pending.is_empty():
		return
	var records: Array = _f21_collect_new_window_records()
	var first_record: Dictionary = records[0] if not records.is_empty() else {}
	if checkpoint == "T6_PREVIEW_INSTANCE_POSITION" and not first_record.is_empty():
		_f21_pending["immediate_instance_id"] = first_record["instance_id"]
	ModLoaderLog.info(
		"[F21][%s] phase=%s separate_preview_observed=false new_window_count=%d records=%s" % [
			checkpoint,
			phase,
			records.size(),
			str(records),
		],
		F21_LOG_NAME
	)
	_f21_log_offset_from_camera(checkpoint, phase, first_record)


func _f21_log_template_final_checkpoint() -> void:
	_f21_log_template_runtime_checkpoint(
		"T7_FINAL_PLACEMENT_POSITION",
		"one_deferred_after_super_paste"
	)
	_f21_pending.clear()


func _f21_log_offset_from_camera(
	checkpoint: String,
	phase: String,
	first_record: Dictionary
) -> void:
	var camera_center: Vector2 = _f21_pending.get("camera_center", Vector2.ZERO)
	var raw_target: Vector2 = _f21_pending.get("raw_target", Vector2.ZERO)
	var old_clamped: Vector2 = _f21_pending.get("old_clamped", Vector2.ZERO)
	var expanded_clamped: Vector2 = _f21_pending.get("expanded_clamped", Vector2.ZERO)
	var observed_local = first_record.get("local", Vector2.ZERO)
	var observed_global = first_record.get("global", Vector2.ZERO)
	ModLoaderLog.info(
		"[F21][T8_OFFSET_FROM_CAMERA] source_checkpoint=%s phase=%s camera_center=%s raw_delta=%s old_candidate_delta=%s expanded_candidate_delta=%s observed_local=%s observed_local_delta=%s observed_global=%s observed_global_delta=%s" % [
			checkpoint,
			phase,
			str(camera_center),
			str(raw_target - camera_center),
			str(old_clamped - camera_center),
			str(expanded_clamped - camera_center),
			str(observed_local),
			str(observed_local - camera_center),
			str(observed_global),
			str(observed_global - camera_center),
		],
		F21_LOG_NAME
	)


func _f25_begin_template_connector_ownership_canary(data: Dictionary) -> bool:
	if _f25_sequence_consumed:
		return false

	_f25_sequence_consumed = true
	var rect_value = data.get("rect", Rect2())
	var rect_valid: bool = rect_value is Rect2
	var template_rect: Rect2 = rect_value if rect_valid else Rect2()
	var camera_center: Vector2 = Globals.camera_center
	var raw_target: Vector2 = camera_center - (template_rect.size / 2.0)
	var old_max: Vector2 = (F25_OLD_WORKSPACE_SIZE - template_rect.size).max(Vector2.ZERO)
	var old_candidate: Vector2 = raw_target.clamp(Vector2.ZERO, old_max)
	var expanded_max: Vector2 = WorkspaceAreaConfig.get_max_position(template_rect.size)
	var expanded_candidate: Vector2 = raw_target.clamp(Vector2.ZERO, expanded_max)
	var correction_delta: Vector2 = expanded_candidate - old_candidate

	_f25_pending = {
		"before_window_ids": _f25_capture_window_ids(),
		"before_connector_ids": _f25_capture_connector_ids(),
		"before_window_state": _f25_capture_window_state(),
		"before_connector_state": _f25_capture_connector_state(),
		"expected_window_count": _f25_expected_window_count(data),
		"expected_connector_count": _f25_expected_connector_count(data),
		"rect_valid": rect_valid,
		"template_rect": template_rect,
		"camera_center": camera_center,
		"raw_target": raw_target,
		"old_candidate": old_candidate,
		"expanded_candidate": expanded_candidate,
		"old_bound_clamp": not raw_target.is_equal_approx(old_candidate),
		"expanded_differs": not old_candidate.is_equal_approx(expanded_candidate),
		"correction_delta": correction_delta,
		"correction_applied": false,
	}
	return true


func _f25_evaluate_and_apply_correction() -> void:
	if _f25_pending.is_empty():
		return

	var new_windows: Array[WindowContainer] = _f25_collect_new_windows()
	var new_connectors: Array[Connector] = _f25_collect_new_connectors()
	var selection_matches: bool = _f25_selection_matches(new_windows)
	var windows_valid: bool = _f25_windows_are_valid(new_windows)
	var connectors_valid: bool = _f25_connectors_are_valid(new_connectors)
	var resource_owners: Dictionary = _f25_collect_pasted_resource_owners(new_windows)
	var pasted_resource_map: Dictionary = resource_owners.get("owners", {})
	var classifications: Array = _f25_classify_new_connectors(
		new_connectors,
		pasted_resource_map
	)
	var before_records: Array = _f25_window_records(new_windows)
	var before_relative: Array = _f25_relative_offsets(new_windows)

	_f25_log(
		"F25_CONNECTOR_GUARD_SOURCE",
		"camera_center=%s raw_target=%s old_candidate=%s expanded_candidate=%s correction_delta=%s expected_window_count=%d actual_new_window_count=%d expected_connector_count=%d actual_new_connector_count=%d selection_matches=%s windows_valid=%s connectors_valid=%s pasted_resource_set_valid=%s pasted_resource_count=%d pasted_resources=%s" % [
			str(_f25_pending["camera_center"]),
			str(_f25_pending["raw_target"]),
			str(_f25_pending["old_candidate"]),
			str(_f25_pending["expanded_candidate"]),
			str(_f25_pending["correction_delta"]),
			_f25_pending["expected_window_count"],
			new_windows.size(),
			_f25_pending["expected_connector_count"],
			new_connectors.size(),
			str(selection_matches),
			str(windows_valid),
			str(connectors_valid),
			str(resource_owners.get("valid", false)),
			pasted_resource_map.size(),
			str(resource_owners.get("records", [])),
		]
	)
	_f25_log(
		"F25_CONNECTOR_ENDPOINT_OWNERSHIP",
		"records=%s" % [str(classifications)]
	)
	_f25_log(
		"F25_CONNECTOR_CLASSIFICATION",
		"summary=%s" % [str(_f25_classification_summary(classifications))]
	)

	var decision_reason: String = _f25_get_correction_stop_reason(
		new_windows,
		selection_matches,
		windows_valid,
		connectors_valid,
		resource_owners,
		classifications
	)
	if not decision_reason.is_empty():
		_f25_pending["expected_positions"] = _f25_position_map(new_windows)
		_f25_log(
			"F25_CORRECTION_DECISION",
			"applied=false reason=%s correction_delta=%s" % [
				decision_reason,
				str(_f25_pending["correction_delta"]),
			]
		)
		_f25_log(
			"F25_WINDOW_CORRECTION",
			"applied=false before=%s after=%s" % [str(before_records), str(before_records)]
		)
		_f25_log(
			"F25_CONNECTOR_CORRECTION",
			"applied=false records=%s" % [str(_f25_connector_records(new_connectors))]
		)
		_f25_log(
			"F25_RELATIVE_LAYOUT_CHECK",
			"applied=false preserved=true before=%s after=%s" % [
				str(before_relative),
				str(before_relative),
			]
		)
		_f25_log(
			"F25_SELECTION_CHECK",
			"selection_matches=%s selection_ids=%s" % [
				str(selection_matches),
				str(_f25_selection_ids()),
			]
		)
		call_deferred("_f25_log_final_stability")
		return

	var correction_delta: Vector2 = _f25_pending["correction_delta"]
	for window: WindowContainer in new_windows:
		window.position += correction_delta
		window.moved.emit()
	var connector_corrections: Array = _f25_translate_internal_connectors(
		new_connectors,
		classifications,
		correction_delta
	)

	var after_records: Array = _f25_window_records(new_windows)
	var after_relative: Array = _f25_relative_offsets(new_windows)
	var relative_layout_preserved: bool = _f25_relative_layout_matches(before_relative, after_relative)
	var selection_preserved: bool = _f25_selection_matches(new_windows)
	_f25_pending["correction_applied"] = true
	_f25_pending["expected_positions"] = _f25_position_map(new_windows)
	_f25_log(
		"F25_CORRECTION_DECISION",
		"applied=true reason=all_guards_passed correction_delta=%s" % [str(correction_delta)]
	)
	_f25_log(
		"F25_WINDOW_CORRECTION",
		"applied=true before=%s after=%s" % [str(before_records), str(after_records)]
	)
	_f25_log(
		"F25_CONNECTOR_CORRECTION",
		"applied=true records=%s" % [str(connector_corrections)]
	)
	_f25_log(
		"F25_RELATIVE_LAYOUT_CHECK",
		"applied=true preserved=%s before=%s after=%s" % [
			str(relative_layout_preserved),
			str(before_relative),
			str(after_relative),
		]
	)
	_f25_log(
		"F25_SELECTION_CHECK",
		"selection_matches=%s selection_ids=%s" % [
			str(selection_preserved),
			str(_f25_selection_ids()),
		]
	)
	call_deferred("_f25_log_final_stability")


func _f25_get_correction_stop_reason(
	new_windows: Array[WindowContainer],
	selection_matches: bool,
	windows_valid: bool,
	connectors_valid: bool,
	resource_owners: Dictionary,
	classifications: Array
) -> String:
	if not _f25_pending["rect_valid"]:
		return "STOP_INVALID_TEMPLATE_RECT"
	if not _f25_pending["old_bound_clamp"]:
		return "SKIP_NO_OLD_BOUND_CLAMP"
	if not _f25_pending["expanded_differs"]:
		return "SKIP_EXPANDED_CANDIDATE_MATCHES_OLD"
	var correction_delta: Vector2 = _f25_pending["correction_delta"]
	if not is_finite(correction_delta.x) or not is_finite(correction_delta.y):
		return "STOP_NONFINITE_CORRECTION_DELTA"
	if correction_delta.is_zero_approx():
		return "SKIP_ZERO_CORRECTION_DELTA"
	if new_windows.size() != _f25_pending["expected_window_count"]:
		return "STOP_NEW_WINDOW_COUNT_MISMATCH"
	if not windows_valid:
		return "STOP_INVALID_NEW_WINDOW"
	if not connectors_valid:
		return "STOP_INVALID_NEW_CONNECTOR"
	if not selection_matches:
		return "STOP_SELECTION_SET_MISMATCH"
	if not resource_owners.get("valid", false):
		return "STOP_PASTED_RESOURCE_SET_AMBIGUOUS"
	for record: Dictionary in classifications:
		var classification: String = str(record.get("classification", "AMBIGUOUS_CONNECTOR"))
		if classification != "INTERNAL_PASTED_CONNECTOR":
			return "STOP_" + classification
	return ""


func _f25_expected_window_count(data: Dictionary) -> int:
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


func _f25_expected_connector_count(data: Dictionary) -> int:
	var connector_data = data.get("connectors", {})
	return connector_data.size() if connector_data is Dictionary else 0


func _f25_capture_window_ids() -> Dictionary:
	var ids: Dictionary = {}
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return ids
	for child in windows_node.get_children():
		if child is WindowContainer:
			ids[child.get_instance_id()] = true
	return ids


func _f25_capture_connector_ids() -> Dictionary:
	var ids: Dictionary = {}
	var connectors_node: Node = get_node_or_null("Connectors")
	if not connectors_node:
		return ids
	for child in connectors_node.get_children():
		if child is Connector:
			ids[child.get_instance_id()] = true
	return ids


func _f25_collect_new_windows() -> Array[WindowContainer]:
	var new_windows: Array[WindowContainer] = []
	var before_ids: Dictionary = _f25_pending.get("before_window_ids", {})
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return new_windows
	for child in windows_node.get_children():
		if child is WindowContainer and not before_ids.has(child.get_instance_id()):
			new_windows.append(child)
	return new_windows


func _f25_collect_new_connectors() -> Array[Connector]:
	var new_connectors: Array[Connector] = []
	var before_ids: Dictionary = _f25_pending.get("before_connector_ids", {})
	var connectors_node: Node = get_node_or_null("Connectors")
	if not connectors_node:
		return new_connectors
	for child in connectors_node.get_children():
		if child is Connector and not before_ids.has(child.get_instance_id()):
			new_connectors.append(child)
	return new_connectors


func _f25_windows_are_valid(windows_to_check: Array[WindowContainer]) -> bool:
	for window: WindowContainer in windows_to_check:
		if not is_instance_valid(window) or window.get_parent() != get_node_or_null("Windows"):
			return false
	return true


func _f25_connectors_are_valid(connectors_to_check: Array[Connector]) -> bool:
	for connector: Connector in connectors_to_check:
		if not is_instance_valid(connector) or connector.get_parent() != get_node_or_null("Connectors"):
			return false
	return true


func _f25_selection_matches(new_windows: Array[WindowContainer]) -> bool:
	if Globals.selections.size() != new_windows.size():
		return false
	for selected: WindowContainer in Globals.selections:
		if not new_windows.has(selected):
			return false
	return true


func _f25_window_records(windows_to_log: Array[WindowContainer]) -> Array:
	var records: Array = []
	for window: WindowContainer in windows_to_log:
		if records.size() >= F25_MAX_LOG_RECORDS:
			break
		records.append({
			"instance_id": window.get_instance_id(),
			"name": window.name,
			"path": str(window.get_path()),
			"local": window.position,
			"size": window.size,
		})
	return records


func _f25_connector_records(connectors_to_log: Array[Connector]) -> Array:
	var records: Array = []
	for connector: Connector in connectors_to_log:
		if records.size() >= F25_MAX_LOG_RECORDS:
			break
		records.append({
			"instance_id": connector.get_instance_id(),
			"name": connector.name,
			"path": str(connector.get_path()),
			"parent_path": str(connector.get_parent().get_path()),
			"output_id": connector.output_id,
			"input_id": connector.input_id,
			"custom_point_count": connector.custom_points.size(),
			"custom_points": connector.custom_points,
		})
	return records


func _f25_capture_window_state() -> Dictionary:
	var state: Dictionary = {}
	var windows_node: Node = get_node_or_null("Windows")
	if not windows_node:
		return state
	for child in windows_node.get_children():
		if child is WindowContainer:
			state[child.get_instance_id()] = {
				"node": child,
				"position": child.position,
			}
	return state


func _f25_capture_connector_state() -> Dictionary:
	var state: Dictionary = {}
	var connectors_node: Node = get_node_or_null("Connectors")
	if not connectors_node:
		return state
	for child in connectors_node.get_children():
		if child is Connector:
			state[child.get_instance_id()] = {
				"node": child,
				"custom_points": child.custom_points.duplicate(true),
			}
	return state


func _f25_collect_pasted_resource_owners(
	windows_to_check: Array[WindowContainer]
) -> Dictionary:
	var owners: Dictionary = {}
	var records: Array = []
	for window: WindowContainer in windows_to_check:
		if not is_instance_valid(window):
			return {"valid": false, "owners": owners, "records": records}
		for resource: ResourceContainer in window.containers:
			if not is_instance_valid(resource) or not window.is_ancestor_of(resource):
				return {"valid": false, "owners": owners, "records": records}
			var resource_id: String = str(resource.id)
			if resource_id.is_empty() or owners.has(resource_id):
				return {"valid": false, "owners": owners, "records": records}
			owners[resource_id] = {
				"window_instance_id": window.get_instance_id(),
				"window_path": str(window.get_path()),
				"resource_path": str(resource.get_path()),
			}
			if records.size() < F25_MAX_LOG_RECORDS:
				records.append({
					"resource_id": resource_id,
					"window_instance_id": window.get_instance_id(),
					"window_path": str(window.get_path()),
					"resource_path": str(resource.get_path()),
				})
	return {"valid": true, "owners": owners, "records": records}


func _f25_classify_new_connectors(
	connectors_to_classify: Array[Connector],
	resource_owners: Dictionary
) -> Array:
	var records: Array = []
	for connector: Connector in connectors_to_classify:
		records.append(_f25_classify_connector(connector, resource_owners))
	return records


func _f25_classify_connector(connector: Connector, resource_owners: Dictionary) -> Dictionary:
	var record: Dictionary = {
		"instance_id": connector.get_instance_id() if is_instance_valid(connector) else -1,
		"path": str(connector.get_path()) if is_instance_valid(connector) else "invalid",
		"parent_path": str(connector.get_parent().get_path()) if is_instance_valid(connector) and connector.get_parent() else "missing",
		"classification": "AMBIGUOUS_CONNECTOR",
		"custom_point_count": connector.custom_points.size() if is_instance_valid(connector) else -1,
	}
	if not is_instance_valid(connector):
		return record

	var output_id: String = connector.output_id
	var input_id: String = connector.input_id
	record["output_id"] = output_id
	record["input_id"] = input_id
	if output_id.is_empty() or input_id.is_empty():
		record["classification"] = "UNOWNED_CONNECTOR"
		return record
	if not is_instance_valid(connector.output) or not is_instance_valid(connector.input):
		return record
	if str(connector.output.id) != output_id or str(connector.input.id) != input_id:
		return record

	var output_owned: bool = resource_owners.has(output_id)
	var input_owned: bool = resource_owners.has(input_id)
	record["output_owned_by_pasted_set"] = output_owned
	record["input_owned_by_pasted_set"] = input_owned
	record["output_owner"] = resource_owners.get(output_id, {})
	record["input_owner"] = resource_owners.get(input_id, {})
	if output_owned and input_owned:
		record["classification"] = "INTERNAL_PASTED_CONNECTOR"
	else:
		record["classification"] = "EXTERNAL_CONNECTOR"
	return record


func _f25_classification_summary(classifications: Array) -> Dictionary:
	var summary: Dictionary = {
		"INTERNAL_PASTED_CONNECTOR": 0,
		"EXTERNAL_CONNECTOR": 0,
		"AMBIGUOUS_CONNECTOR": 0,
		"UNOWNED_CONNECTOR": 0,
	}
	for record: Dictionary in classifications:
		var classification: String = str(record.get("classification", "AMBIGUOUS_CONNECTOR"))
		summary[classification] = int(summary.get(classification, 0)) + 1
	return summary


func _f25_translate_internal_connectors(
	new_connectors: Array[Connector],
	classifications: Array,
	correction_delta: Vector2
) -> Array:
	var classification_by_id: Dictionary = {}
	for record: Dictionary in classifications:
		classification_by_id[record.get("instance_id", -1)] = record.get("classification", "")

	var corrections: Array = []
	for connector: Connector in new_connectors:
		if classification_by_id.get(connector.get_instance_id(), "") != "INTERNAL_PASTED_CONNECTOR":
			continue
		var before_points: Array = connector.custom_points.duplicate(true)
		for point_index: int in connector.custom_points.size():
			connector.custom_points[point_index] = connector.custom_points[point_index] + correction_delta
		connector.update_points()
		corrections.append({
			"instance_id": connector.get_instance_id(),
			"path": str(connector.get_path()),
			"custom_points_before": before_points,
			"custom_points_after": connector.custom_points,
			"translated": true,
			"update_points_called": true,
		})
	return corrections


func _f25_existing_windows_untouched() -> bool:
	var before_state: Dictionary = _f25_pending.get("before_window_state", {})
	for entry: Dictionary in before_state.values():
		var window = entry.get("node")
		if not is_instance_valid(window) or not window.position.is_equal_approx(entry.get("position", Vector2.ZERO)):
			return false
	return true


func _f25_existing_connectors_untouched() -> bool:
	var before_state: Dictionary = _f25_pending.get("before_connector_state", {})
	for entry: Dictionary in before_state.values():
		var connector = entry.get("node")
		if not is_instance_valid(connector) or connector.custom_points != entry.get("custom_points", []):
			return false
	return true


func _f25_relative_offsets(windows_to_check: Array[WindowContainer]) -> Array:
	var offsets: Array = []
	if windows_to_check.is_empty():
		return offsets
	var anchor: Vector2 = windows_to_check[0].position
	for window: WindowContainer in windows_to_check:
		if offsets.size() >= F25_MAX_LOG_RECORDS:
			break
		offsets.append({
			"instance_id": window.get_instance_id(),
			"offset": window.position - anchor,
		})
	return offsets


func _f25_relative_layout_matches(before: Array, after: Array) -> bool:
	if before.size() != after.size():
		return false
	for index: int in before.size():
		if before[index].get("instance_id", -1) != after[index].get("instance_id", -1):
			return false
		var before_offset: Vector2 = before[index].get("offset", Vector2.ZERO)
		var after_offset: Vector2 = after[index].get("offset", Vector2.ZERO)
		if not before_offset.is_equal_approx(after_offset):
			return false
	return true


func _f25_position_map(windows_to_capture: Array[WindowContainer]) -> Dictionary:
	var positions: Dictionary = {}
	for window: WindowContainer in windows_to_capture:
		positions[window.get_instance_id()] = window.position
	return positions


func _f25_selection_ids() -> Array:
	var ids: Array = []
	for selected: WindowContainer in Globals.selections:
		ids.append(selected.get_instance_id())
	return ids


func _f25_log_final_stability() -> void:
	if _f25_pending.is_empty():
		return
	var new_windows: Array[WindowContainer] = _f25_collect_new_windows()
	var expected_positions: Dictionary = _f25_pending.get("expected_positions", {})
	var stable: bool = new_windows.size() == expected_positions.size()
	for window: WindowContainer in new_windows:
		if not expected_positions.has(window.get_instance_id()):
			stable = false
			continue
		var expected_position: Vector2 = expected_positions[window.get_instance_id()]
		if not window.position.is_equal_approx(expected_position):
			stable = false
	var unrelated_windows_untouched: bool = _f25_existing_windows_untouched()
	var unrelated_connectors_untouched: bool = _f25_existing_connectors_untouched()
	_f25_log(
		"F25_FINAL_STABILITY",
		"correction_applied=%s stable=%s unrelated_windows_untouched=%s unrelated_connectors_untouched=%s final_window_records=%s" % [
			str(_f25_pending.get("correction_applied", false)),
			str(stable),
			str(unrelated_windows_untouched),
			str(unrelated_connectors_untouched),
			str(_f25_window_records(new_windows)),
		]
	)
	_f25_pending.clear()


func _f25_log(label: String, details: String) -> void:
	ModLoaderLog.info("[F25][%s] %s" % [label, details], F25_LOG_NAME)


func _count_required_windows(data: Dictionary) -> int:
	if not data.has("windows") or not (data["windows"] is Array):
		return 0
	return data.windows.size()


func _on_expanded_workspace_begin_drag() -> void:
	_expanded_workspace_drag_start_positions.clear()

	for window: WindowContainer in Globals.selections:
		if not is_instance_valid(window):
			continue
		_expanded_workspace_drag_start_positions[window] = window.global_position


func _on_expanded_workspace_drag_selection(from: Vector2, to: Vector2) -> void:
	if _expanded_workspace_drag_start_positions.is_empty():
		return

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


func _f6_capture_restoration_snapshots() -> void:
	_f6_saved_restore_positions.clear()
	_f6_saved_restore_metadata.clear()
	_f6_stability_checks.clear()
	_f6_correlation_blocked = false
	_f12_group_diagnostic.clear()

	if not Globals.tutorial_done:
		return
	if Data.loading.is_empty():
		return
	if not Data.loading.has("desktop_data"):
		return

	var desktop_data = Data.loading.desktop_data
	if not (desktop_data is Dictionary):
		return
	if not desktop_data.has("windows"):
		return
	if not (desktop_data.windows is Array):
		return

	var seen_names: Dictionary = {}
	var source_index: int = 0
	for window_data in desktop_data.windows:
		if not (window_data is Dictionary):
			source_index += 1
			continue

		var window_name: String = str(window_data.get("name", ""))
		if window_name.is_empty():
			_f6_block_correlation(
				"empty saved window name at source_index=%d" % source_index
			)
			return
		if seen_names.has(window_name):
			_f6_block_correlation(
				"duplicate saved window name=%s source_index=%d" % [
					window_name,
					source_index,
				]
			)
			return

		seen_names[window_name] = true
		if not window_data.has("position"):
			source_index += 1
			continue

		var saved_position = window_data.position
		if not (saved_position is Vector2):
			source_index += 1
			continue
		_f6_saved_restore_positions[window_name] = saved_position
		var saved_size: Vector2 = Vector2.ZERO
		if window_data.has("size") and window_data.size is Vector2:
			saved_size = window_data.size
		_f6_saved_restore_metadata[window_name] = {
			"source_index": source_index,
			"filename": str(window_data.get("filename", "")),
			"is_group": _f6_is_group_window_data(window_data),
			"saved_size": saved_size,
		}
		source_index += 1


func _f6_is_group_window_data(window_data: Dictionary) -> bool:
	var filename: String = str(window_data.get("filename", ""))
	return filename == "window_group.tscn" or filename == "window_group"


func _f6_block_correlation(reason: String) -> void:
	_f6_correlation_blocked = true
	_f6_saved_restore_positions.clear()
	_f6_saved_restore_metadata.clear()
	ModLoaderLog.warning(
		"[F6][STOP] restoration correction disabled: %s" % reason,
		F6_LOG_NAME
	)


func _f6_apply_restoration_corrections() -> void:
	var log_count: int = 0
	var correction_count: int = 0
	_f12_prepare_group_diagnostic()

	for window_name: String in _f6_saved_restore_positions:
		var window: WindowContainer = (
			get_node_or_null("Windows/" + window_name) as WindowContainer
		)
		if not is_instance_valid(window):
			continue

		var saved_position: Vector2 = _f6_saved_restore_positions[window_name]
		if saved_position.x < 0.0 or saved_position.y < 0.0:
			continue

		var vanilla_max_position: Vector2 = (
			Vector2.ONE * F6_OLD_WORKSPACE_SIZE
		) - window.size
		if not _f6_is_beyond_vanilla_bounds(saved_position, vanilla_max_position):
			continue

		var desired_position: Vector2 = saved_position.clamp(
			Vector2.ZERO,
			WorkspaceAreaConfig.get_max_position(window.size)
		)
		var clamp_delta: Vector2 = desired_position - saved_position
		var should_log: bool = log_count < F6_MAX_LOG_TARGETS
		var metadata: Dictionary = _f6_saved_restore_metadata.get(window_name, {})

		if should_log:
			_f6_log_saved_checkpoint(
				window_name,
				saved_position,
				desired_position,
				clamp_delta,
				vanilla_max_position,
				metadata
			)
			_f6_log_runtime_checkpoint(
				window_name,
				"BEFORE_CORRECTION",
				window,
				saved_position,
				desired_position
			)

		window.position = desired_position
		window.moved.emit()
		correction_count += 1

		if should_log:
			_f6_log_runtime_checkpoint(
				window_name,
				"AFTER_CORRECTION",
				window,
				saved_position,
				desired_position
			)
			_f6_stability_checks.append({
				"name": window_name,
				"saved_position": saved_position,
				"desired_position": desired_position,
			})
			log_count += 1

	_f6_saved_restore_positions.clear()
	_f6_saved_restore_metadata.clear()
	_f12_log_after_restore()

	if correction_count > 0:
		call_deferred("_f6_log_stability_check")
	else:
		ModLoaderLog.info(
			"[F6] no restored windows required expanded-area correction",
			F6_LOG_NAME
		)

	_f12_schedule_stability_checks()


func _f6_is_beyond_vanilla_bounds(
	saved_position: Vector2,
	vanilla_max_position: Vector2
) -> bool:
	return (
		saved_position.x > vanilla_max_position.x
		or saved_position.y > vanilla_max_position.y
	)


func _f6_log_stability_check() -> void:
	for check: Dictionary in _f6_stability_checks:
		var window_name: String = check["name"]
		var window: WindowContainer = (
			get_node_or_null("Windows/" + window_name) as WindowContainer
		)
		if is_instance_valid(window):
			_f6_log_runtime_checkpoint(
				window_name,
				"STABILITY_CHECK",
				window,
				check["saved_position"],
				check["desired_position"]
			)
		else:
			ModLoaderLog.info(
				"[F6][name=%s][STABILITY_CHECK] child=missing" % [
					window_name,
				],
				F6_LOG_NAME
			)

	_f6_stability_checks.clear()


func _f6_log_saved_checkpoint(
	window_name: String,
	saved_position: Vector2,
	desired_position: Vector2,
	clamp_delta: Vector2,
	vanilla_max_position: Vector2,
	metadata: Dictionary
) -> void:
	ModLoaderLog.info(
		"[F6][name=%s][SAVED_LOCAL] source_index=%s filename=%s is_group=%s saved_local=%s vanilla_max=%s desired_local=%s clamp_delta=%s" % [
			window_name,
			str(metadata.get("source_index", "unknown")),
			str(metadata.get("filename", "")),
			str(metadata.get("is_group", false)),
			str(saved_position),
			str(vanilla_max_position),
			str(desired_position),
			str(clamp_delta),
		],
		F6_LOG_NAME
	)


func _f6_log_runtime_checkpoint(
	window_name: String,
	checkpoint: String,
	window: WindowContainer,
	saved_position: Vector2,
	desired_position: Vector2
) -> void:
	var script_path: String = "none"
	var script: Script = window.get_script()
	if script:
		script_path = script.resource_path

	ModLoaderLog.info(
		"[F6][name=%s][%s] local=%s global=%s saved_local=%s desired_local=%s exact_local=%s size=%s script=%s" % [
			window_name,
			checkpoint,
			str(window.position),
			str(window.global_position),
			str(saved_position),
			str(desired_position),
			str(window.position.is_equal_approx(desired_position)),
			str(window.size),
			script_path,
		],
		F6_LOG_NAME
	)


func _f12_prepare_group_diagnostic() -> void:
	_f12_group_diagnostic.clear()
	var candidates: Array = []

	for group_name: String in _f6_saved_restore_positions:
		var metadata: Dictionary = _f6_saved_restore_metadata.get(group_name, {})
		if not metadata.get("is_group", false):
			continue

		var group_window: WindowContainer = (
			get_node_or_null("Windows/" + group_name) as WindowContainer
		)
		if not is_instance_valid(group_window):
			continue

		var saved_group_position: Vector2 = _f6_saved_restore_positions[group_name]
		var saved_group_size_value = metadata.get("saved_size", Vector2.ZERO)
		if not (saved_group_size_value is Vector2):
			continue
		var saved_group_size: Vector2 = saved_group_size_value
		if saved_group_size.x <= 0.0 or saved_group_size.y <= 0.0:
			continue
		if not _f12_is_expanded_saved_target(saved_group_position, group_window.size):
			continue

		var saved_group_rect: Rect2 = Rect2(saved_group_position, saved_group_size).grow(20.0)
		var children: Array = []
		for child_name: String in _f6_saved_restore_positions:
			if child_name == group_name:
				continue
			var child_metadata: Dictionary = _f6_saved_restore_metadata.get(child_name, {})
			if child_metadata.get("is_group", false):
				continue

			var child_window: WindowContainer = (
				get_node_or_null("Windows/" + child_name) as WindowContainer
			)
			if not is_instance_valid(child_window):
				continue

			var saved_child_position: Vector2 = _f6_saved_restore_positions[child_name]
			if not _f12_is_expanded_saved_target(saved_child_position, child_window.size):
				continue
			if not saved_group_rect.encloses(Rect2(saved_child_position, child_window.size)):
				continue

			children.append({
				"name": child_name,
				"saved_position": saved_child_position,
				"saved_relative": saved_child_position - saved_group_position,
			})

		if children.is_empty() or children.size() > F12_MAX_CHILDREN:
			continue
		candidates.append({
			"frame_name": group_name,
			"frame_saved_position": saved_group_position,
			"frame_saved_size": saved_group_size,
			"children": children,
		})

	if candidates.size() != 1:
		ModLoaderLog.info(
			"[F12][STOP] group diagnostic skipped: eligible_group_candidates=%d" % candidates.size(),
			F12_LOG_NAME
		)
		return

	_f12_group_diagnostic = candidates[0]
	_f12_log_saved_group_data()
	_f12_log_runtime_group_checkpoint(
		"G4_BEFORE_RESTORE_CORRECTION_FRAME",
		"G5_BEFORE_RESTORE_CORRECTION_CHILDREN"
	)


func _f12_is_expanded_saved_target(saved_position: Vector2, window_size: Vector2) -> bool:
	if saved_position.x < 0.0 or saved_position.y < 0.0:
		return false
	var vanilla_max_position: Vector2 = (Vector2.ONE * F6_OLD_WORKSPACE_SIZE) - window_size
	return _f6_is_beyond_vanilla_bounds(saved_position, vanilla_max_position)


func _f12_log_saved_group_data() -> void:
	var frame_name: String = _f12_group_diagnostic["frame_name"]
	var frame_position: Vector2 = _f12_group_diagnostic["frame_saved_position"]
	var frame_size: Vector2 = _f12_group_diagnostic["frame_saved_size"]
	var children: Array = _f12_group_diagnostic["children"]
	var child_names: Array[String] = []

	ModLoaderLog.info(
		"[F12][G1_SAVED_GROUP_FRAME_LOCAL] frame=%s saved_local=%s saved_size=%s" % [
			frame_name,
			str(frame_position),
			str(frame_size),
		],
		F12_LOG_NAME
	)
	for child: Dictionary in children:
		child_names.append(str(child["name"]))
		ModLoaderLog.info(
			"[F12][G2_SAVED_CHILD_LOCAL_POSITIONS] frame=%s child=%s saved_local=%s saved_relative=%s" % [
				frame_name,
				str(child["name"]),
				str(child["saved_position"]),
				str(child["saved_relative"]),
			],
			F12_LOG_NAME
		)
	ModLoaderLog.info(
		"[F12][G3_SAVED_GROUP_MEMBERSHIP] frame=%s expected_children=%s count=%d" % [
			frame_name,
			str(child_names),
			child_names.size(),
		],
		F12_LOG_NAME
	)


func _f12_log_after_restore() -> void:
	_f12_log_runtime_group_checkpoint(
		"G6_AFTER_RESTORE_CORRECTION_FRAME",
		"G7_AFTER_RESTORE_CORRECTION_CHILDREN"
	)


func _f12_schedule_stability_checks() -> void:
	if _f12_group_diagnostic.is_empty():
		return
	call_deferred("_f12_log_next_deferred")
	get_tree().create_timer(F12_OPENING_SETTLE_DELAY_SECONDS).timeout.connect(
		_f12_log_opening_settle
	)


func _f12_log_next_deferred() -> void:
	_f12_log_runtime_group_checkpoint(
		"G8_NEXT_DEFERRED_FRAME",
		"G9_NEXT_DEFERRED_CHILDREN"
	)


func _f12_log_opening_settle() -> void:
	_f12_log_runtime_group_checkpoint(
		"G10_OPENING_SETTLE_FRAME",
		"G11_OPENING_SETTLE_CHILDREN"
	)
	_f12_group_diagnostic.clear()


func _f12_log_runtime_group_checkpoint(
	frame_checkpoint: String,
	child_checkpoint: String
) -> void:
	if _f12_group_diagnostic.is_empty():
		return

	var frame_name: String = _f12_group_diagnostic["frame_name"]
	var frame: WindowContainer = get_node_or_null("Windows/" + frame_name) as WindowContainer
	if not is_instance_valid(frame):
		ModLoaderLog.info(
			"[F12][STOP] frame missing at %s frame=%s" % [frame_checkpoint, frame_name],
			F12_LOG_NAME
		)
		return

	var frame_saved_position: Vector2 = _f12_group_diagnostic["frame_saved_position"]
	var frame_rect: Rect2 = Rect2(frame.position, frame.size).grow(20.0)
	var children: Array = _f12_group_diagnostic["children"]
	var membership_preserved: bool = true
	var connector_count: int = $Connectors.get_child_count()

	for child: Dictionary in children:
		var child_window: WindowContainer = (
			get_node_or_null("Windows/" + str(child["name"])) as WindowContainer
		)
		if not is_instance_valid(child_window):
			membership_preserved = false
			continue
		if not frame_rect.encloses(Rect2(child_window.position, child_window.size)):
			membership_preserved = false

	ModLoaderLog.info(
		"[F12][%s] frame=%s local=%s global=%s saved_local=%s exact_local=%s membership_preserved=%s connector_count=%d" % [
			frame_checkpoint,
			frame_name,
			str(frame.position),
			str(frame.global_position),
			str(frame_saved_position),
			str(frame.position.is_equal_approx(frame_saved_position)),
			str(membership_preserved),
			connector_count,
		],
		F12_LOG_NAME
	)

	for child: Dictionary in children:
		_f12_log_runtime_child_checkpoint(child_checkpoint, frame, child, frame_rect)


func _f12_log_runtime_child_checkpoint(
	checkpoint: String,
	frame: WindowContainer,
	child: Dictionary,
	frame_rect: Rect2
) -> void:
	var child_name: String = str(child["name"])
	var child_window: WindowContainer = get_node_or_null("Windows/" + child_name) as WindowContainer
	if not is_instance_valid(child_window):
		ModLoaderLog.info(
			"[F12][%s] frame=%s child=%s status=missing" % [checkpoint, frame.name, child_name],
			F12_LOG_NAME
		)
		return

	var saved_position: Vector2 = child["saved_position"]
	var saved_relative: Vector2 = child["saved_relative"]
	var runtime_relative: Vector2 = child_window.position - frame.position
	var relative_delta: Vector2 = runtime_relative - saved_relative
	var script_path: String = "none"
	var script: Script = child_window.get_script()
	if script:
		script_path = script.resource_path

	ModLoaderLog.info(
		"[F12][%s] frame=%s child=%s local=%s global=%s saved_local=%s exact_local=%s saved_relative=%s runtime_relative=%s relative_delta=%s membership_preserved=%s inside_tree=%s visible=%s script=%s" % [
			checkpoint,
			frame.name,
			child_name,
			str(child_window.position),
			str(child_window.global_position),
			str(saved_position),
			str(child_window.position.is_equal_approx(saved_position)),
			str(saved_relative),
			str(runtime_relative),
			str(relative_delta),
			str(frame_rect.encloses(Rect2(child_window.position, child_window.size))),
			str(child_window.is_inside_tree()),
			str(child_window.visible),
			script_path,
		],
		F12_LOG_NAME
	)
