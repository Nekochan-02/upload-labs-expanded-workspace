extends "res://scenes/windows/window_group.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const GroupResizeDiagnosticObserver = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/group_resize_diagnostic_observer.gd"
)
const F13_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F13"
const F13_OLD_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)
const F14_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F14"
const F15_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F15"
const F15_OLD_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)
const F15_MINIMUM_GROUP_SIZE: Vector2 = Vector2(200, 100)
const F16_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F16"

static var _f13_target_taken: bool = false
static var _f15_target_taken: bool = false
static var _f15_ineligible_target_reported: bool = false
static var _f16_target_taken: bool = false

var _f13_sequence_active: bool = false
var _f13_first_resize_process_logged: bool = false
var _f13_observer: Node
var _f14_first_move_snapped_logged: bool = false
var _f14_after_resize_frame_logged: bool = false
var _f14_after_release_logged: bool = false
var _f15_sequence_active: bool = false
var _f15_first_resize_process_logged: bool = false
var _f15_release_logged: bool = false
var _f15_edge_path: String = "unknown"
var _f15_children: Array[WindowContainer] = []
var _f16_sequence_active: bool = false
var _f16_first_resize_logged: bool = false
var _f16_release_logged: bool = false
var _f16_edge_path: String = "unknown"
var _f16_last_geometry: Dictionary = {}
var _f16_correction_applied: bool = false


func _process(delta: float) -> void:
	var first_resize_process: bool = (
		_f13_sequence_active
		and not _f13_first_resize_process_logged
		and _f13_is_resizing()
	)
	var f15_first_resize_process: bool = (
		_f15_sequence_active
		and not _f15_first_resize_process_logged
		and _f13_is_resizing()
	)
	var f16_resize_active: bool = _f16_sequence_active and _f13_is_resizing()
	var f16_geometry: Dictionary = {}
	if f16_resize_active:
		f16_geometry = _f15_derive_geometry(get_global_mouse_position().snappedf(50))
		_f16_last_geometry = f16_geometry
	if first_resize_process:
		_f13_log_checkpoint("R3_FIRST_RESIZE_PROCESS", "before_super")
	if f15_first_resize_process:
		_f15_log_checkpoint("S3_FIRST_SIZE_CALCULATION", "before_super")

	super._process(delta)

	if first_resize_process:
		_f13_first_resize_process_logged = true
		_f13_log_checkpoint("R3_FIRST_RESIZE_PROCESS", "after_super")
	if f15_first_resize_process:
		_f15_first_resize_process_logged = true
		_f15_log_checkpoint("S4_AFTER_FIRST_RESIZE_PROCESS", "after_super")
	if f16_resize_active:
		_f16_correct_old_bound_size_collapse(f16_geometry)

	if not moving:
		return

	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var target_position: Vector2 = (drag_start_rect.position + (current_mouse - drag_start_mouse)).clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	).snappedf(50)
	move(target_position)


func move_snapped(to: Vector2) -> void:
	if not _is_expanded_workspace_resize_active():
		super.move_snapped(to)
		return

	var position_before: Vector2 = position
	var clamped_target: Vector2 = to.clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	)
	var snapped_target: Vector2 = clamped_target.snappedf(50)
	if _f13_sequence_active and not _f14_first_move_snapped_logged:
		_f14_log_resize_move_snapped_input(
			to,
			clamped_target,
			snapped_target,
			position_before
		)

	move(snapped_target)

	if _f13_sequence_active and not _f14_first_move_snapped_logged:
		_f14_first_move_snapped_logged = true
		_f14_log_resize_move_snapped_output(
			to,
			clamped_target,
			snapped_target,
			position_before
		)
		call_deferred("_f14_log_after_resize_first_frame")


func _on_top_left_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("top-left")
	_f16_begin_resize_fix_canary("top-left", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_left_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_top_left_button_up() -> void:
	super._on_top_left_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_top_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("top")
	_f16_begin_resize_fix_canary("top", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_top_button_up() -> void:
	super._on_top_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_top_right_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("top-right")
	_f16_begin_resize_fix_canary("top-right", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_right_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_top_right_button_up() -> void:
	super._on_top_right_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_left_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("left")
	_f16_begin_resize_fix_canary("left", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_left_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_left_button_up() -> void:
	super._on_left_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_left_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("bottom-left")
	_f16_begin_resize_fix_canary("bottom-left", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_left_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_left_button_up() -> void:
	super._on_bottom_left_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("bottom")
	_f16_begin_resize_fix_canary("bottom", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_button_up() -> void:
	super._on_bottom_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_right_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("bottom-right")
	_f16_begin_resize_fix_canary("bottom-right", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_right_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_right_button_up() -> void:
	super._on_bottom_right_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _on_right_button_down() -> void:
	var f15_started: bool = _f15_begin_populated_resize_diagnostic("right")
	_f16_begin_resize_fix_canary("right", f15_started)
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_right_button_down()
	_f15_complete_resize_start(f15_started)
	_f13_complete_edge_diagnostic_start(started)


func _on_right_button_up() -> void:
	super._on_right_button_up()
	_f16_complete_resize_release()
	_f15_complete_resize_release()
	_f13_complete_edge_diagnostic_release()


func _f16_begin_resize_fix_canary(edge_path: String, f15_started: bool) -> void:
	if not f15_started or _f16_target_taken:
		return
	_f16_target_taken = true
	_f16_sequence_active = true
	_f16_first_resize_logged = false
	_f16_release_logged = false
	_f16_edge_path = edge_path
	_f16_last_geometry = {}
	_f16_correction_applied = false


func _f16_correct_old_bound_size_collapse(geometry: Dictionary) -> void:
	var decision: Dictionary = _f16_get_correction_decision(geometry)
	var first_resize: bool = not _f16_first_resize_logged
	if first_resize:
		_f16_log_checkpoint("F16_BEFORE_CORRECTION", geometry, decision, false)

	var correction_applied: bool = bool(decision["apply"])
	if correction_applied:
		_f16_apply_expanded_candidate(decision)
		_f16_correction_applied = true

	if first_resize:
		_f16_log_checkpoint("F16_CORRECTION_DECISION", geometry, decision, correction_applied)
		_f16_log_checkpoint("F16_AFTER_CORRECTION", geometry, decision, correction_applied)
		_f16_first_resize_logged = true


func _f16_get_correction_decision(geometry: Dictionary) -> Dictionary:
	var old_rect: Rect2 = geometry["old_rect"]
	var expanded_rect: Rect2 = geometry["expanded_rect"]
	var expanded_position: Vector2 = geometry["expanded_snapped_position"]
	var expanded_valid: bool = (
		expanded_rect.size.x >= F15_MINIMUM_GROUP_SIZE.x
		and expanded_rect.size.y >= F15_MINIMUM_GROUP_SIZE.y
		and not bool(geometry["expanded_minimum_violation"])
	)
	var width_guard: bool = (
		resizing_right
		and old_rect.size.x < F15_MINIMUM_GROUP_SIZE.x
		and expanded_valid
		and (size.x < F15_MINIMUM_GROUP_SIZE.x or custom_minimum_size.x < F15_MINIMUM_GROUP_SIZE.x)
	)
	var height_guard: bool = (
		resizing_bottom
		and old_rect.size.y < F15_MINIMUM_GROUP_SIZE.y
		and expanded_valid
		and (size.y < F15_MINIMUM_GROUP_SIZE.y or custom_minimum_size.y < F15_MINIMUM_GROUP_SIZE.y)
	)
	return {
		"apply": width_guard or height_guard,
		"width_guard": width_guard,
		"height_guard": height_guard,
		"expanded_rect": expanded_rect,
		"expanded_position": expanded_position,
	}


func _f16_apply_expanded_candidate(decision: Dictionary) -> void:
	var expanded_rect: Rect2 = decision["expanded_rect"]
	var corrected_size: Vector2 = size
	var corrected_minimum: Vector2 = custom_minimum_size
	if bool(decision["width_guard"]):
		corrected_size.x = expanded_rect.size.x
		corrected_minimum.x = expanded_rect.size.x
	if bool(decision["height_guard"]):
		corrected_size.y = expanded_rect.size.y
		corrected_minimum.y = expanded_rect.size.y

	# Control property setters preserve the vanilla resize signal/update path.
	custom_minimum_size = corrected_minimum
	size = corrected_size
	var expanded_position: Vector2 = decision["expanded_position"]
	if not position.is_equal_approx(expanded_position):
		move(expanded_position)


func _f16_complete_resize_release() -> void:
	if not _f16_sequence_active or _f16_release_logged:
		return
	_f16_release_logged = true
	_f16_log_checkpoint(
		"F16_AFTER_RELEASE",
		_f16_last_geometry,
		{},
		_f16_correction_applied
	)
	_f16_sequence_active = false
	call_deferred("_f16_log_one_frame_after_release")


func _f16_log_one_frame_after_release() -> void:
	if not _f16_release_logged:
		return
	_f16_log_checkpoint(
		"F16_ONE_FRAME_AFTER_RELEASE",
		_f16_last_geometry,
		{},
		_f16_correction_applied
	)


func _f16_log_checkpoint(
	checkpoint: String,
	geometry: Dictionary,
	decision: Dictionary,
	correction_applied: bool
) -> void:
	var child_geometry: Dictionary = _f15_collect_child_geometry()
	var old_rect: Variant = geometry.get("old_rect", "unavailable")
	var expanded_rect: Variant = geometry.get("expanded_rect", "unavailable")
	var width_guard: Variant = decision.get("width_guard", "unavailable")
	var height_guard: Variant = decision.get("height_guard", "unavailable")
	ModLoaderLog.info(
		"[F16][%s] group=%s edge=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s old_candidate_rect=%s expanded_candidate_rect=%s actual_position=%s actual_size=%s actual_custom_minimum_size=%s width_guard=%s height_guard=%s correction_applied=%s child_count=%d child_bounding_box=%s child_relative_bounds=%s contained_connector_count=%d connection_presence=%s" % [
			checkpoint,
			name,
			_f16_edge_path,
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(old_rect),
			str(expanded_rect),
			str(position),
			str(size),
			str(custom_minimum_size),
			str(width_guard),
			str(height_guard),
			str(correction_applied),
			int(child_geometry["valid_count"]),
			str(child_geometry["bounding_box"]),
			str(child_geometry["relative_bounds"]),
			int(child_geometry["connector_count"]),
			str(int(child_geometry["connector_count"]) > 0),
		],
		F16_LOG_NAME
	)


func _f15_begin_populated_resize_diagnostic(edge_path: String) -> bool:
	if _f15_target_taken:
		return false

	var contained_children: Array[WindowContainer] = _f15_collect_contained_windows()
	if contained_children.size() != 2:
		if not _f15_ineligible_target_reported:
			_f15_ineligible_target_reported = true
			ModLoaderLog.info(
				"[F15][STOP] group=%s edge=%s contained_window_count=%d required_window_count=2 reason=TARGET_NOT_ELIGIBLE" % [
					name,
					edge_path,
					contained_children.size(),
				],
				F15_LOG_NAME
			)
		return false

	_f15_target_taken = true
	_f15_sequence_active = true
	_f15_first_resize_process_logged = false
	_f15_release_logged = false
	_f15_edge_path = edge_path
	_f15_children = contained_children
	_f15_log_checkpoint("S1_BEFORE_POPULATED_RESIZE", "before_resize_flag")
	return true


func _f15_complete_resize_start(started: bool) -> void:
	if not started:
		return
	_f15_log_checkpoint("S2_RESIZE_START", "after_resize_flag")


func _f15_complete_resize_release() -> void:
	if not _f15_sequence_active or _f15_release_logged:
		return

	_f15_release_logged = true
	_f15_log_checkpoint("S5_AFTER_RELEASE", "after_resize_clear")
	_f15_sequence_active = false
	call_deferred("_f15_log_one_frame_after_release")


func _f15_log_one_frame_after_release() -> void:
	if not _f15_release_logged:
		return
	_f15_log_checkpoint("S6_ONE_FRAME_AFTER_RELEASE", "deferred_after_release")


func _f15_collect_contained_windows() -> Array[WindowContainer]:
	var contained: Array[WindowContainer] = []
	var frame_rect: Rect2 = get_rect().grow(20)
	for candidate_node: Node in get_tree().get_nodes_in_group("selectable"):
		var candidate: WindowContainer = candidate_node as WindowContainer
		if candidate and candidate != self and frame_rect.encloses(candidate.get_rect()):
			contained.append(candidate)
	return contained


func _f15_log_checkpoint(checkpoint: String, phase: String) -> void:
	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var geometry: Dictionary = _f15_derive_geometry(current_mouse)
	var child_geometry: Dictionary = _f15_collect_child_geometry()
	var parent: Node = get_parent()
	var parent_path: String = str(parent.get_path()) if parent else "none"
	ModLoaderLog.info(
		"[F15][%s] phase=%s group=%s edge=%s is_instance_valid=true is_inside_tree=%s visible=%s position=%s global_position=%s size=%s custom_minimum_size=%s scale=%s parent=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s drag_start_rect=%s drag_start_mouse=%s current_mouse_global_snapped=%s mouse_delta=%s old_bound_rect=%s old_bound_snapped_position=%s old_bound_minimum_violation=%s expanded_bound_rect=%s expanded_bound_snapped_position=%s expanded_bound_minimum_violation=%s child_count_initial=%d child_count_valid=%d child_records=%s child_bounding_box=%s child_to_frame_relative_bounds=%s contained_connector_count=%d connection_presence=%s diagnostics_pure=true classification=UNRESOLVED" % [
			checkpoint,
			phase,
			name,
			_f15_edge_path,
			str(is_inside_tree()),
			str(visible),
			str(position),
			str(global_position),
			str(size),
			str(custom_minimum_size),
			str(scale),
			parent_path,
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(drag_start_rect),
			str(drag_start_mouse),
			str(current_mouse),
			str(geometry["mouse_delta"]),
			str(geometry["old_rect"]),
			str(geometry["old_snapped_position"]),
			str(geometry["old_minimum_violation"]),
			str(geometry["expanded_rect"]),
			str(geometry["expanded_snapped_position"]),
			str(geometry["expanded_minimum_violation"]),
			_f15_children.size(),
			int(child_geometry["valid_count"]),
			str(child_geometry["records"]),
			str(child_geometry["bounding_box"]),
			str(child_geometry["relative_bounds"]),
			int(child_geometry["connector_count"]),
			str(int(child_geometry["connector_count"]) > 0),
		],
		F15_LOG_NAME
	)


func _f15_derive_geometry(current_mouse: Vector2) -> Dictionary:
	var mouse_delta: Vector2 = current_mouse - drag_start_mouse
	var old_candidate: Dictionary = _f15_derive_rect_candidate(
		F15_OLD_WORKSPACE_SIZE,
		mouse_delta
	)
	var expanded_candidate: Dictionary = _f15_derive_rect_candidate(
		WorkspaceAreaConfig.get_workspace_size(),
		mouse_delta
	)
	return {
		"mouse_delta": mouse_delta,
		"old_rect": old_candidate["rect"],
		"old_snapped_position": old_candidate["snapped_position"],
		"old_minimum_violation": old_candidate["minimum_violation"],
		"expanded_rect": expanded_candidate["rect"],
		"expanded_snapped_position": expanded_candidate["snapped_position"],
		"expanded_minimum_violation": expanded_candidate["minimum_violation"],
	}


# Pure diagnostic geometry only; this does not replace or mutate vanilla resize state.
func _f15_derive_rect_candidate(bounds: Vector2, mouse_delta: Vector2) -> Dictionary:
	var horizontal: Dictionary = _f15_derive_axis_candidate(
		drag_start_rect.position.x,
		drag_start_rect.size.x,
		mouse_delta.x,
		resizing_left,
		resizing_right,
		F15_MINIMUM_GROUP_SIZE.x,
		bounds.x
	)
	var vertical: Dictionary = _f15_derive_axis_candidate(
		drag_start_rect.position.y,
		drag_start_rect.size.y,
		mouse_delta.y,
		resizing_top,
		resizing_bottom,
		F15_MINIMUM_GROUP_SIZE.y,
		bounds.y
	)
	var rect: Rect2 = Rect2(
		Vector2(float(horizontal["position"]), float(vertical["position"])),
		Vector2(float(horizontal["size"]), float(vertical["size"]))
	)
	return {
		"rect": rect,
		"snapped_position": rect.position.clamp(Vector2.ZERO, bounds - rect.size).snappedf(50),
		"minimum_violation": rect.size.x < F15_MINIMUM_GROUP_SIZE.x or rect.size.y < F15_MINIMUM_GROUP_SIZE.y,
	}


func _f15_derive_axis_candidate(
	start_position: float,
	start_size: float,
	delta: float,
	leading_edge: bool,
	trailing_edge: bool,
	minimum_size: float,
	bound: float
) -> Dictionary:
	if leading_edge:
		var anchor: float = start_position + start_size
		var candidate_position: float = clampf(start_position + delta, 0.0, anchor - minimum_size)
		return {"position": candidate_position, "size": anchor - candidate_position}
	if trailing_edge:
		var candidate_size: float = maxf(start_size + delta, minimum_size)
		if start_position + candidate_size > bound:
			candidate_size = bound - start_position
		return {"position": start_position, "size": candidate_size}
	return {"position": start_position, "size": start_size}


func _f15_collect_child_geometry() -> Dictionary:
	var records: Array[String] = []
	var valid_count: int = 0
	var has_bounds: bool = false
	var bounding_box: Rect2 = Rect2()
	var has_relative_bounds: bool = false
	var relative_bounds: Rect2 = Rect2()
	for child: WindowContainer in _f15_children:
		if not is_instance_valid(child):
			records.append("invalid")
			continue
		var child_rect: Rect2 = Rect2(child.position, child.size)
		var relative_position: Vector2 = child.position - position
		var relative_rect: Rect2 = Rect2(relative_position, child.size)
		if not has_bounds:
			bounding_box = child_rect
			has_bounds = true
		else:
			bounding_box = bounding_box.merge(child_rect)
		if not has_relative_bounds:
			relative_bounds = relative_rect
			has_relative_bounds = true
		else:
			relative_bounds = relative_bounds.merge(relative_rect)
		valid_count += 1
		records.append("%s{inside_tree=%s,position=%s,global_position=%s,size=%s,relative_position=%s}" % [
			child.name,
			str(child.is_inside_tree()),
			str(child.position),
			str(child.global_position),
			str(child.size),
			str(relative_position),
		])
	return {
		"valid_count": valid_count,
		"records": records,
		"bounding_box": bounding_box if has_bounds else "none",
		"relative_bounds": relative_bounds if has_relative_bounds else "none",
		"connector_count": _f15_count_contained_connectors(),
	}


func _f15_count_contained_connectors() -> int:
	var count: int = 0
	var frame_rect: Rect2 = get_rect().grow(20)
	for connector_node: Node in get_tree().get_nodes_in_group("connector_point"):
		var connector: Control = connector_node as Control
		if connector and frame_rect.encloses(connector.get_rect()):
			count += 1
	return count


func _f13_begin_edge_diagnostic() -> bool:
	if _f13_target_taken:
		return false

	_f13_target_taken = true
	_f13_sequence_active = true
	_f14_first_move_snapped_logged = false
	_f14_after_resize_frame_logged = false
	_f14_after_release_logged = false
	_f13_connect_lifecycle_signals()
	_f13_log_checkpoint("R1_BEFORE_EDGE_DRAG", "before_resize_flag")
	return true


func _f13_complete_edge_diagnostic_start(started: bool) -> void:
	if not started:
		return

	_f13_log_checkpoint("R2_EDGE_DRAG_START", "after_resize_flag")
	_f13_observer = GroupResizeDiagnosticObserver.new()
	get_tree().root.add_child(_f13_observer)
	_f13_observer.begin(self)


func _f13_complete_edge_diagnostic_release() -> void:
	if not _f13_sequence_active:
		return

	_f13_log_checkpoint("R5_AFTER_RELEASE_OR_CANCEL", "after_resize_clear")
	_f14_log_after_release_or_cancel()
	if is_instance_valid(_f13_observer):
		_f13_observer.log_after_release_or_cancel()
	_f13_sequence_active = false


func _f13_connect_lifecycle_signals() -> void:
	tree_exiting.connect(_f13_on_tree_exiting, CONNECT_ONE_SHOT)
	visibility_changed.connect(_f13_on_visibility_changed, CONNECT_ONE_SHOT)
	resized.connect(_f13_on_resized, CONNECT_ONE_SHOT)


func _f13_on_tree_exiting() -> void:
	_f13_log_checkpoint("EVENT_TREE_EXITING", "signal")


func _f13_on_visibility_changed() -> void:
	_f13_log_checkpoint("EVENT_VISIBILITY_CHANGED", "signal")


func _f13_on_resized() -> void:
	_f13_log_checkpoint("EVENT_RESIZED", "signal")


func _f13_log_from_observer(checkpoint: String) -> void:
	if not is_instance_valid(self):
		return
	_f13_log_checkpoint(checkpoint, "observer")


func _f13_is_resizing() -> bool:
	return resizing_left or resizing_right or resizing_top or resizing_bottom


func _is_expanded_workspace_resize_active() -> bool:
	return resizing_left or resizing_right or resizing_top or resizing_bottom


func _f14_log_resize_move_snapped_input(
	input_to: Vector2,
	clamped_target: Vector2,
	snapped_target: Vector2,
	position_before: Vector2
) -> void:
	ModLoaderLog.info(
		"[F14][F14_RESIZE_MOVE_SNAPPED_INPUT] group=%s input_to=%s clamped_target=%s snapped_target=%s position_before=%s size=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s is_inside_tree=%s visible=%s" % [
			name,
			str(input_to),
			str(clamped_target),
			str(snapped_target),
			str(position_before),
			str(size),
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(is_inside_tree()),
			str(visible),
		],
		F14_LOG_NAME
	)


func _f14_log_resize_move_snapped_output(
	input_to: Vector2,
	clamped_target: Vector2,
	snapped_target: Vector2,
	position_before: Vector2
) -> void:
	ModLoaderLog.info(
		"[F14][F14_RESIZE_MOVE_SNAPPED_OUTPUT] group=%s input_to=%s clamped_target=%s snapped_target=%s position_before=%s position_after=%s size=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s is_inside_tree=%s visible=%s" % [
			name,
			str(input_to),
			str(clamped_target),
			str(snapped_target),
			str(position_before),
			str(position),
			str(size),
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(is_inside_tree()),
			str(visible),
		],
		F14_LOG_NAME
	)


func _f14_log_after_resize_first_frame() -> void:
	if _f14_after_resize_frame_logged or not _f14_first_move_snapped_logged:
		return

	_f14_after_resize_frame_logged = true
	ModLoaderLog.info(
		"[F14][F14_AFTER_RESIZE_FIRST_FRAME] group=%s position=%s size=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s is_inside_tree=%s visible=%s" % [
			name,
			str(position),
			str(size),
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(is_inside_tree()),
			str(visible),
		],
		F14_LOG_NAME
	)


func _f14_log_after_release_or_cancel() -> void:
	if _f14_after_release_logged:
		return

	_f14_after_release_logged = true
	ModLoaderLog.info(
		"[F14][F14_AFTER_RELEASE_OR_CANCEL] group=%s resize_branch_used=%s position=%s size=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s is_inside_tree=%s visible=%s" % [
			name,
			str(_f14_first_move_snapped_logged),
			str(position),
			str(size),
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(is_inside_tree()),
			str(visible),
		],
		F14_LOG_NAME
	)


func _f13_log_checkpoint(checkpoint: String, phase: String) -> void:
	var parent: Node = get_parent()
	var parent_path: String = "none"
	var parent_position: String = "none"
	var parent_global_position: String = "none"
	var parent_clip_contents: String = "unavailable"
	if parent:
		parent_path = str(parent.get_path())
		var parent_canvas: CanvasItem = parent as CanvasItem
		if parent_canvas:
			parent_position = str(parent_canvas.position)
			parent_global_position = str(parent_canvas.global_position)
		var parent_control: Control = parent as Control
		if parent_control:
			parent_clip_contents = str(parent_control.clip_contents)

	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var mouse_delta: Vector2 = current_mouse - drag_start_mouse
	var old_bound_max_size_from_anchor: Vector2 = F13_OLD_WORKSPACE_SIZE - drag_start_rect.position
	var expanded_bound_max_size_from_anchor: Vector2 = (
		WorkspaceAreaConfig.get_workspace_size() - drag_start_rect.position
	)
	ModLoaderLog.info(
		"[F13][%s] phase=%s group=%s is_instance_valid=true is_inside_tree=%s queued_for_deletion=%s visible=%s modulate_alpha=%s scale=%s position=%s global_position=%s size=%s custom_minimum_size=%s pivot_offset=%s parent=%s parent_position=%s parent_global_position=%s parent_clip_contents=%s child_count=%d moving=%s resizing_left=%s resizing_right=%s resizing_top=%s resizing_bottom=%s drag_start_rect=%s drag_start_mouse=%s current_mouse_global_snapped=%s mouse_delta=%s old_bound_max_size_from_anchor=%s expanded_bound_max_size_from_anchor=%s computed_rect=not_reimplemented classification=%s" % [
			checkpoint,
			phase,
			name,
			str(is_inside_tree()),
			str(is_queued_for_deletion()),
			str(visible),
			str(modulate.a),
			str(scale),
			str(position),
			str(global_position),
			str(size),
			str(custom_minimum_size),
			str(pivot_offset),
			parent_path,
			parent_position,
			parent_global_position,
			parent_clip_contents,
			get_child_count(),
			str(moving),
			str(resizing_left),
			str(resizing_right),
			str(resizing_top),
			str(resizing_bottom),
			str(drag_start_rect),
			str(drag_start_mouse),
			str(current_mouse),
			str(mouse_delta),
			str(old_bound_max_size_from_anchor),
			str(expanded_bound_max_size_from_anchor),
			_f13_classify_state(parent),
		],
		F13_LOG_NAME
	)


func _f13_classify_state(parent: Node) -> String:
	if is_queued_for_deletion():
		return "GROUP_NODE_QUEUE_FREED"
	if size.x <= 0.0 or size.y <= 0.0:
		return "GROUP_NODE_SIZE_COLLAPSED"
	if custom_minimum_size.x < 0.0 or custom_minimum_size.y < 0.0:
		return "GROUP_NODE_INVALID_RECT"
	if not visible or modulate.a <= 0.0:
		return "GROUP_NODE_HIDDEN"
	if not parent:
		return "GROUP_NODE_LOST_MEMBERSHIP_OR_REPARENTED"
	if position.x < 0.0 or position.y < 0.0 or position.x > WorkspaceAreaConfig.get_workspace_size().x or position.y > WorkspaceAreaConfig.get_workspace_size().y:
		return "GROUP_NODE_MOVED_OUT_OF_BOUNDS"
	return "UNRESOLVED"
