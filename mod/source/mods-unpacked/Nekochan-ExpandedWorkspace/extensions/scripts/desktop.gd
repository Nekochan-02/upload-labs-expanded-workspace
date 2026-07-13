extends "res://scripts/desktop.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F3_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F3"
const F3_MAX_TARGETS: int = 3
const F3_OLD_WORKSPACE_THRESHOLD: float = 10000.0

var _expanded_workspace_drag_start_positions: Dictionary = {}
var _f3_targets: Array = []
var _f3_targets_by_name: Dictionary = {}


func _enter_tree() -> void:
	_f3_capture_restoration_targets()

	var windows_node: Node = get_node_or_null("Windows")
	if (
		windows_node
		and not windows_node.child_entered_tree.is_connected(
			_on_f3_windows_child_entered_tree
		)
	):
		windows_node.child_entered_tree.connect(_on_f3_windows_child_entered_tree)

	super._enter_tree()

	_f3_log_after_super_enter_tree()
	if not _f3_targets.is_empty():
		call_deferred("_f3_log_deferred_final")


func _ready() -> void:
	super._ready()

	if not Signals.begin_drag.is_connected(_on_expanded_workspace_begin_drag):
		Signals.begin_drag.connect(_on_expanded_workspace_begin_drag)
	if not Signals.drag_selection.is_connected(_on_expanded_workspace_drag_selection):
		Signals.drag_selection.connect(_on_expanded_workspace_drag_selection)


func paste(data: Dictionary) -> void:
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


func _f3_capture_restoration_targets() -> void:
	_f3_targets.clear()
	_f3_targets_by_name.clear()

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

	var source_index: int = 0
	for window_data in desktop_data.windows:
		if _f3_targets.size() >= F3_MAX_TARGETS:
			break
		if not (window_data is Dictionary):
			source_index += 1
			continue
		if not window_data.has("position"):
			source_index += 1
			continue

		var saved_position = window_data.position
		if not (saved_position is Vector2):
			source_index += 1
			continue
		if not _f3_is_beyond_old_workspace(saved_position):
			source_index += 1
			continue

		var target: Dictionary = {
			"diagnostic_index": _f3_targets.size(),
			"source_index": source_index,
			"name": str(window_data.get("name", "")),
			"filename": str(window_data.get("filename", "")),
			"saved_position": saved_position,
			"saved_size": _f3_get_saved_size_text(window_data),
			"is_group": _f3_is_group_window_data(window_data),
		}
		_f3_targets.append(target)
		if not target["name"].is_empty():
			_f3_targets_by_name[target["name"]] = target

		ModLoaderLog.info(
			"[F3][window=%d][P2] source_index=%d name=%s filename=%s saved=%s saved_size=%s is_group=%s" % [
				target["diagnostic_index"],
				target["source_index"],
				target["name"],
				target["filename"],
				str(target["saved_position"]),
				target["saved_size"],
				str(target["is_group"]),
			],
			F3_LOG_NAME
		)
		source_index += 1

	if _f3_targets.is_empty():
		ModLoaderLog.info(
			"[F3] no saved windows beyond old workspace threshold; no position checkpoints selected",
			F3_LOG_NAME
		)


func _f3_is_beyond_old_workspace(position: Vector2) -> bool:
	return (
		position.x > F3_OLD_WORKSPACE_THRESHOLD
		or position.y > F3_OLD_WORKSPACE_THRESHOLD
	)


func _f3_get_saved_size_text(window_data: Dictionary) -> String:
	if window_data.has("size"):
		return str(window_data["size"])
	return "absent"


func _f3_is_group_window_data(window_data: Dictionary) -> bool:
	var filename: String = str(window_data.get("filename", ""))
	return filename == "window_group.tscn" or filename == "window_group"


func _on_f3_windows_child_entered_tree(child: Node) -> void:
	var target: Dictionary = _f3_get_target_for_child(child)
	if target.is_empty():
		return

	_f3_log_child_checkpoint("P3.5", "child_entered_tree", target, child)


func _f3_log_after_super_enter_tree() -> void:
	for target: Dictionary in _f3_targets:
		var child: Node = _f3_find_child_for_target(target)
		if child:
			_f3_log_child_checkpoint("P3.5", "after_super_enter_tree", target, child)
		else:
			ModLoaderLog.info(
				"[F3][window=%d][P3.5] after_super_enter_tree child=missing name=%s" % [
					target["diagnostic_index"],
					target["name"],
				],
				F3_LOG_NAME
			)

		ModLoaderLog.info(
			"[F3][window=%d][P3] after_load_direct=UNOBSERVED reason=no_vanilla_enter_tree_body_copy" % [
				target["diagnostic_index"],
			],
			F3_LOG_NAME
		)


func _f3_log_deferred_final() -> void:
	for target: Dictionary in _f3_targets:
		var child: Node = _f3_find_child_for_target(target)
		if child:
			_f3_log_child_checkpoint("P4", "deferred_final", target, child)
		else:
			ModLoaderLog.info(
				"[F3][window=%d][P4] deferred_final child=missing name=%s" % [
					target["diagnostic_index"],
					target["name"],
				],
				F3_LOG_NAME
			)


func _f3_get_target_for_child(child: Node) -> Dictionary:
	var child_name: String = str(child.name)
	if _f3_targets_by_name.has(child_name):
		return _f3_targets_by_name[child_name]
	return {}


func _f3_find_child_for_target(target: Dictionary) -> Node:
	if target["name"].is_empty():
		return null
	return get_node_or_null("Windows/" + target["name"])


func _f3_log_child_checkpoint(
	checkpoint: String,
	phase: String,
	target: Dictionary,
	child: Node
) -> void:
	var script_path: String = "none"
	var script: Script = child.get_script()
	if script:
		script_path = script.resource_path

	var size_text: String = "not_control"
	if child is Control:
		size_text = str((child as Control).size)

	ModLoaderLog.info(
		"[F3][window=%d][%s] %s name=%s filename=%s position=%s global=%s size=%s script=%s" % [
			target["diagnostic_index"],
			checkpoint,
			phase,
			target["name"],
			target["filename"],
			str(child.position),
			str(child.global_position),
			size_text,
			script_path,
		],
		F3_LOG_NAME
	)
