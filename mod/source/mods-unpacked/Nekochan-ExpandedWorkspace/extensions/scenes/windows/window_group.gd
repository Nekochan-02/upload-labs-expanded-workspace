extends "res://scenes/windows/window_group.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const GroupResizeDiagnosticObserver = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/group_resize_diagnostic_observer.gd"
)
const F13_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F13"
const F13_OLD_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)

static var _f13_target_taken: bool = false

var _f13_sequence_active: bool = false
var _f13_first_resize_process_logged: bool = false
var _f13_observer: Node


func _process(delta: float) -> void:
	var first_resize_process: bool = (
		_f13_sequence_active
		and not _f13_first_resize_process_logged
		and _f13_is_resizing()
	)
	if first_resize_process:
		_f13_log_checkpoint("R3_FIRST_RESIZE_PROCESS", "before_super")

	super._process(delta)

	if first_resize_process:
		_f13_first_resize_process_logged = true
		_f13_log_checkpoint("R3_FIRST_RESIZE_PROCESS", "after_super")

	if not moving:
		return

	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var target_position: Vector2 = (drag_start_rect.position + (current_mouse - drag_start_mouse)).clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	).snappedf(50)
	move(target_position)


func _on_top_left_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_left_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_top_left_button_up() -> void:
	super._on_top_left_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_top_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_top_button_up() -> void:
	super._on_top_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_top_right_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_top_right_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_top_right_button_up() -> void:
	super._on_top_right_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_left_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_left_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_left_button_up() -> void:
	super._on_left_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_left_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_left_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_left_button_up() -> void:
	super._on_bottom_left_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_button_up() -> void:
	super._on_bottom_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_bottom_right_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_bottom_right_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_bottom_right_button_up() -> void:
	super._on_bottom_right_button_up()
	_f13_complete_edge_diagnostic_release()


func _on_right_button_down() -> void:
	var started: bool = _f13_begin_edge_diagnostic()
	super._on_right_button_down()
	_f13_complete_edge_diagnostic_start(started)


func _on_right_button_up() -> void:
	super._on_right_button_up()
	_f13_complete_edge_diagnostic_release()


func _f13_begin_edge_diagnostic() -> bool:
	if _f13_target_taken:
		return false

	_f13_target_taken = true
	_f13_sequence_active = true
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
