extends "res://scripts/desktop.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F4_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F4"
const F4_MAX_LOG_TARGETS: int = 3
const F4_OLD_WORKSPACE_SIZE: float = 10000.0

var _expanded_workspace_drag_start_positions: Dictionary = {}
var _f4_saved_restore_positions: Dictionary = {}
var _f4_saved_restore_metadata: Dictionary = {}
var _f4_correlation_blocked: bool
var _f4_stability_checks: Array = []


func _enter_tree() -> void:
	_f4_capture_restoration_snapshots()

	super._enter_tree()

	if not _f4_correlation_blocked and not _f4_saved_restore_positions.is_empty():
		call_deferred("_f4_apply_restoration_corrections")


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


func _f4_capture_restoration_snapshots() -> void:
	_f4_saved_restore_positions.clear()
	_f4_saved_restore_metadata.clear()
	_f4_stability_checks.clear()
	_f4_correlation_blocked = false

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
			_f4_block_correlation(
				"empty saved window name at source_index=%d" % source_index
			)
			return
		if seen_names.has(window_name):
			_f4_block_correlation(
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
		_f4_saved_restore_positions[window_name] = saved_position
		_f4_saved_restore_metadata[window_name] = {
			"source_index": source_index,
			"filename": str(window_data.get("filename", "")),
			"is_group": _f4_is_group_window_data(window_data),
		}
		source_index += 1


func _f4_is_group_window_data(window_data: Dictionary) -> bool:
	var filename: String = str(window_data.get("filename", ""))
	return filename == "window_group.tscn" or filename == "window_group"


func _f4_block_correlation(reason: String) -> void:
	_f4_correlation_blocked = true
	_f4_saved_restore_positions.clear()
	_f4_saved_restore_metadata.clear()
	ModLoaderLog.warning(
		"[F4][STOP] restoration correction disabled: %s" % reason,
		F4_LOG_NAME
	)


func _f4_apply_restoration_corrections() -> void:
	var log_count: int = 0
	var correction_count: int = 0

	for window_name: String in _f4_saved_restore_positions:
		var window: WindowContainer = (
			get_node_or_null("Windows/" + window_name) as WindowContainer
		)
		if not is_instance_valid(window):
			continue

		var saved_position: Vector2 = _f4_saved_restore_positions[window_name]
		if saved_position.x < 0.0 or saved_position.y < 0.0:
			continue

		var vanilla_max_position: Vector2 = (
			Vector2.ONE * F4_OLD_WORKSPACE_SIZE
		) - window.size
		if not _f4_is_beyond_vanilla_bounds(saved_position, vanilla_max_position):
			continue

		var desired_position: Vector2 = saved_position.clamp(
			Vector2.ZERO,
			WorkspaceAreaConfig.get_max_position(window.size)
		).snappedf(50)
		var before_position: Vector2 = window.position
		var should_log: bool = log_count < F4_MAX_LOG_TARGETS
		var metadata: Dictionary = _f4_saved_restore_metadata.get(window_name, {})

		if should_log:
			_f4_log_saved_checkpoint(
				window_name,
				saved_position,
				desired_position,
				vanilla_max_position,
				metadata
			)
			_f4_log_runtime_checkpoint(
				window_name,
				"BEFORE_CORRECTION",
				window,
				saved_position,
				desired_position
			)

		window.move(desired_position)
		correction_count += 1

		if should_log:
			_f4_log_runtime_checkpoint(
				window_name,
				"AFTER_CORRECTION",
				window,
				saved_position,
				desired_position
			)
			_f4_stability_checks.append({
				"name": window_name,
				"saved_position": saved_position,
				"desired_position": desired_position,
				"before_position": before_position,
			})
			log_count += 1

	_f4_saved_restore_positions.clear()
	_f4_saved_restore_metadata.clear()

	if correction_count > 0:
		call_deferred("_f4_log_stability_check")
	else:
		ModLoaderLog.info(
			"[F4] no restored windows required expanded-area correction",
			F4_LOG_NAME
		)


func _f4_is_beyond_vanilla_bounds(
	saved_position: Vector2,
	vanilla_max_position: Vector2
) -> bool:
	return (
		saved_position.x > vanilla_max_position.x
		or saved_position.y > vanilla_max_position.y
	)


func _f4_log_stability_check() -> void:
	for check: Dictionary in _f4_stability_checks:
		var window_name: String = check["name"]
		var window: WindowContainer = (
			get_node_or_null("Windows/" + window_name) as WindowContainer
		)
		if is_instance_valid(window):
			_f4_log_runtime_checkpoint(
				window_name,
				"STABILITY_CHECK",
				window,
				check["saved_position"],
				check["desired_position"]
			)
		else:
			ModLoaderLog.info(
				"[F4][name=%s][STABILITY_CHECK] child=missing" % [
					window_name,
				],
				F4_LOG_NAME
			)

	_f4_stability_checks.clear()


func _f4_log_saved_checkpoint(
	window_name: String,
	saved_position: Vector2,
	desired_position: Vector2,
	vanilla_max_position: Vector2,
	metadata: Dictionary
) -> void:
	ModLoaderLog.info(
		"[F4][name=%s][SAVED] source_index=%s filename=%s is_group=%s saved=%s vanilla_max=%s desired=%s" % [
			window_name,
			str(metadata.get("source_index", "unknown")),
			str(metadata.get("filename", "")),
			str(metadata.get("is_group", false)),
			str(saved_position),
			str(vanilla_max_position),
			str(desired_position),
		],
		F4_LOG_NAME
	)


func _f4_log_runtime_checkpoint(
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
		"[F4][name=%s][%s] runtime=%s global=%s saved=%s desired=%s size=%s script=%s" % [
			window_name,
			checkpoint,
			str(window.position),
			str(window.global_position),
			str(saved_position),
			str(desired_position),
			str(window.size),
			script_path,
		],
		F4_LOG_NAME
	)
