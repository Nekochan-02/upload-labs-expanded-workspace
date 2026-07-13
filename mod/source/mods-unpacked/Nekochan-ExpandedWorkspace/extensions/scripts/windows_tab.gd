extends "res://scripts/windows_tab.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F8_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F8"
const F8_SNAP_INTERVAL: float = 50.0

var _f8_diagnostic_target_taken: bool = false


func update_node_count() -> void:
	super.update_node_count()
	$WindowsContainer / TopContainer / Nodes / Label.text = "%d/%d" % [
		Globals.max_window_count,
		MODDED_MAX_WINDOW,
	]


func _on_add_pressed() -> void:
	if _should_use_vanilla_limit():
		super._on_add_pressed()
		return

	var before: int = Globals.max_window_count
	Globals.max_window_count = Utils.MAX_WINDOW - 1
	super._on_add_pressed()
	_restore_count_after_vanilla_call(before)


func _on_window_selected(window: String) -> void:
	if Data.is_mobile() or window.is_empty() or _should_use_vanilla_limit():
		super._on_window_selected(window)
		return

	var before: int = Globals.max_window_count
	Globals.max_window_count = Utils.MAX_WINDOW - 1
	super._on_window_selected(window)
	_restore_count_after_vanilla_call(before)


func add_window(window: String) -> void:
	var instance: WindowContainer = load(
		"res://scenes/windows/" + Data.windows[window].scene + ".tscn"
	).instantiate()
	instance.name = window

	var target_position: Vector2 = _get_expanded_click_target(instance.size)
	var log_diagnostic: bool = not _f8_diagnostic_target_taken
	if log_diagnostic:
		_f8_diagnostic_target_taken = true
		_f8_log_target_calculation(instance, target_position)

	instance.global_position = target_position
	if log_diagnostic:
		_f8_log_window_checkpoint("C4_PRE_CREATE", instance, target_position)
	Signals.create_window.emit(instance)
	if log_diagnostic and is_instance_valid(instance):
		_f8_log_window_checkpoint("C5_POST_CREATE", instance, target_position)

	if is_instance_valid(instance):
		instance.global_position = target_position
		if log_diagnostic:
			_f8_log_window_checkpoint(
				"C6_AFTER_REAPPLY_GLOBAL",
				instance,
				target_position
			)
			_f8_log_window_checkpoint(
				"C7_BEFORE_DEFERRED_MOVE",
				instance,
				target_position
			)
		instance.call_deferred("move", target_position)
		if log_diagnostic:
			call_deferred("_f8_log_after_deferred_move", instance, target_position)


func _should_use_vanilla_limit() -> bool:
	return Globals.max_window_count < Utils.MAX_WINDOW or Globals.max_window_count >= MODDED_MAX_WINDOW


func _restore_count_after_vanilla_call(before: int) -> void:
	var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
	Globals.max_window_count = before + added


func _get_expanded_click_target(window_size: Vector2) -> Vector2:
	var target: Vector2 = Globals.camera_center - (window_size / 2.0)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)


func _f8_log_target_calculation(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	var camera_center: Vector2 = Globals.camera_center
	var raw_target: Vector2 = camera_center - (window.size / 2.0)
	var max_position: Vector2 = WorkspaceAreaConfig.get_max_position(window.size)
	var clamped_target: Vector2 = raw_target.clamp(Vector2.ZERO, max_position)
	var recomputed_snapped_target: Vector2 = clamped_target.snappedf(F8_SNAP_INTERVAL)
	var target_recompute_delta: Vector2 = target_position - recomputed_snapped_target
	var snap_units: Vector2 = target_position / F8_SNAP_INTERVAL
	var snap_nearest_integer_delta: Vector2 = Vector2(
		snap_units.x - round(snap_units.x),
		snap_units.y - round(snap_units.y)
	)
	var target_snap_correct: bool = (
		target_recompute_delta.is_zero_approx()
		and snap_nearest_integer_delta.is_zero_approx()
	)
	var snap_classification: String = (
		"TARGET_SNAP_CORRECT" if target_snap_correct else "TARGET_SNAP_INCORRECT"
	)

	ModLoaderLog.info(
		"[F8][C1_CAMERA_CENTER] window=%s camera_center=%s window_size=%s" % [
			window.name,
			str(camera_center),
			str(window.size),
		],
		F8_LOG_NAME
	)
	ModLoaderLog.info(
		"[F8][C2_RAW_TARGET] window=%s raw_target=%s formula=camera_center-window_size/2" % [
			window.name,
			str(raw_target),
		],
		F8_LOG_NAME
	)
	ModLoaderLog.info(
		"[F8][C3_SNAPPED_TARGET] window=%s clamped_target=%s max_position=%s snapped_target=%s recomputed_target=%s target_recompute_delta=%s snap_interval=%s snap_units=%s snap_nearest_integer_delta=%s classification=%s" % [
			window.name,
			str(clamped_target),
			str(max_position),
			str(target_position),
			str(recomputed_snapped_target),
			str(target_recompute_delta),
			str(F8_SNAP_INTERVAL),
			str(snap_units),
			str(snap_nearest_integer_delta),
			snap_classification,
		],
		F8_LOG_NAME
	)


func _f8_log_after_deferred_move(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	if not is_instance_valid(window):
		_f8_log_missing_checkpoint("C8_AFTER_DEFERRED_MOVE", target_position)
		return

	_f8_log_window_checkpoint("C8_AFTER_DEFERRED_MOVE", window, target_position)
	call_deferred("_f8_log_stability", window, target_position)


func _f8_log_stability(window: WindowContainer, target_position: Vector2) -> void:
	if not is_instance_valid(window):
		_f8_log_missing_checkpoint("C9_STABILITY", target_position)
		return

	_f8_log_window_checkpoint("C9_STABILITY", window, target_position)


func _f8_log_missing_checkpoint(checkpoint: String, target_position: Vector2) -> void:
	ModLoaderLog.info(
		"[F8][%s] window=missing target=%s" % [
			checkpoint,
			str(target_position),
		],
		F8_LOG_NAME
	)


func _f8_log_window_checkpoint(
	checkpoint: String,
	window: WindowContainer,
	target_position: Vector2
) -> void:
	var parent: Node = window.get_parent()
	var parent_name: String = "none"
	var parent_global_origin: String = "none"
	var parent_transform_origin: String = "none"
	if parent:
		parent_name = str(parent.get_path())
		var parent_canvas: CanvasItem = parent as CanvasItem
		if parent_canvas:
			parent_global_origin = str(parent_canvas.global_transform.origin)
			parent_transform_origin = str(parent_canvas.get_global_transform().origin)

	var local_position: Vector2 = window.position
	var global_position: Vector2 = window.global_position
	ModLoaderLog.info(
		"[F8][%s] window=%s local=%s global=%s parent=%s parent_global_origin=%s parent_transform_origin=%s target=%s local_to_target=%s global_to_target=%s global_local=%s" % [
			checkpoint,
			window.name,
			str(local_position),
			str(global_position),
			parent_name,
			parent_global_origin,
			parent_transform_origin,
			str(target_position),
			str(local_position - target_position),
			str(global_position - target_position),
			str(global_position - local_position),
		],
		F8_LOG_NAME
	)
