extends "res://scenes/window_dragger.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const DragPlacementDiagnosticObserver = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_diagnostic_observer.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F10_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F10"
const F10_SNAP_INTERVAL: float = 50.0

var _f10_diagnostic_target_taken: bool = false


func place() -> void:
	if Globals.max_window_count >= MODDED_MAX_WINDOW:
		super.place()
		return

	if not Utils.can_add_window(window):
		_finish_drag()
		return

	var instance: WindowContainer = load(
		"res://scenes/windows/" + Data.windows[window].scene + ".tscn"
	).instantiate()
	instance.name = window
	var target_position: Vector2 = _get_expanded_drag_target(instance.size)
	var should_use_vanilla_path: bool = (
		Globals.max_window_count < Utils.MAX_WINDOW
		and _is_inside_vanilla_area(target_position, instance.size)
	)

	if should_use_vanilla_path:
		instance.free()
		super.place()
		return

	var log_diagnostic: bool = not _f10_diagnostic_target_taken
	if log_diagnostic:
		_f10_diagnostic_target_taken = true
		_f10_log_drag_target(instance, target_position)

	var before: int = Globals.max_window_count
	var lifted_count_for_vanilla_create: bool = Globals.max_window_count >= Utils.MAX_WINDOW
	if lifted_count_for_vanilla_create:
		Globals.max_window_count = Utils.MAX_WINDOW - 1

	instance.global_position = target_position
	if log_diagnostic:
		_f10_log_window_checkpoint("D5_PRE_CREATE", instance, target_position)
	Signals.create_window.emit(instance)
	if log_diagnostic and is_instance_valid(instance):
		_f10_log_window_checkpoint("D6_POST_CREATE", instance, target_position)

	if lifted_count_for_vanilla_create:
		var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
		Globals.max_window_count = before + added

	if is_instance_valid(instance):
		instance.global_position = target_position
		if log_diagnostic:
			_f10_log_window_checkpoint(
				"D7_AFTER_REAPPLY_GLOBAL",
				instance,
				target_position
			)
			_f10_log_window_checkpoint(
				"D8_BEFORE_DEFERRED_MOVE",
				instance,
				target_position
			)
		instance.call_deferred("move", target_position)
		if log_diagnostic:
			_f10_start_lifecycle_observer(instance, target_position)

	_finish_drag()


func _get_expanded_drag_target(window_size: Vector2) -> Vector2:
	var instance_pos: Vector2 = Utils.screen_to_world_pos(global_position + size / 2)
	var target: Vector2 = instance_pos - Vector2(175, window_size.y / 2)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)


func _f10_log_drag_target(window: WindowContainer, target_position: Vector2) -> void:
	var screen_input_point: Vector2 = global_position + size / 2.0
	var instance_pos: Vector2 = Utils.screen_to_world_pos(screen_input_point)
	var raw_target: Vector2 = instance_pos - Vector2(175.0, window.size.y / 2.0)
	var max_position: Vector2 = WorkspaceAreaConfig.get_max_position(window.size)
	var clamped_target: Vector2 = raw_target.clamp(Vector2.ZERO, max_position)
	var recomputed_snapped_target: Vector2 = clamped_target.snappedf(F10_SNAP_INTERVAL)
	var target_recompute_delta: Vector2 = target_position - recomputed_snapped_target
	var snap_units: Vector2 = target_position / F10_SNAP_INTERVAL
	var snap_nearest_integer_delta: Vector2 = Vector2(
		snap_units.x - round(snap_units.x),
		snap_units.y - round(snap_units.y)
	)
	var target_snap_correct: bool = (
		target_recompute_delta.is_zero_approx()
		and snap_nearest_integer_delta.is_zero_approx()
	)
	var snap_classification: String = (
		"DRAG_TARGET_SNAP_CORRECT" if target_snap_correct else "DRAG_TARGET_SNAP_INCORRECT"
	)

	ModLoaderLog.info(
		"[F10][drag][D1_DRAGGER_STATE] dragger_global=%s dragger_size=%s screen_input_point=%s" % [
			str(global_position),
			str(size),
			str(screen_input_point),
		],
		F10_LOG_NAME
	)
	ModLoaderLog.info(
		"[F10][drag][D2_SCREEN_TO_WORLD] instance_pos=%s" % [
			str(instance_pos),
		],
		F10_LOG_NAME
	)
	ModLoaderLog.info(
		"[F10][drag][D3_RAW_TARGET] raw_target=%s offset=%s" % [
			str(raw_target),
			str(Vector2(175.0, window.size.y / 2.0)),
		],
		F10_LOG_NAME
	)
	ModLoaderLog.info(
		"[F10][drag][D4_SNAPPED_TARGET] window=%s clamped_target=%s max_position=%s snapped_target=%s recomputed_target=%s target_recompute_delta=%s snap_interval=%s snap_units=%s snap_nearest_integer_delta=%s classification=%s" % [
			window.name,
			str(clamped_target),
			str(max_position),
			str(target_position),
			str(recomputed_snapped_target),
			str(target_recompute_delta),
			str(F10_SNAP_INTERVAL),
			str(snap_units),
			str(snap_nearest_integer_delta),
			snap_classification,
		],
		F10_LOG_NAME
	)


func _f10_start_lifecycle_observer(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	var observer = DragPlacementDiagnosticObserver.new()
	get_tree().root.add_child(observer)
	observer.begin(window, target_position)


func _f10_log_window_checkpoint(
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
		"[F10][drag][%s] window=%s local=%s global=%s parent=%s parent_global_origin=%s parent_transform_origin=%s target=%s local_to_target=%s global_to_target=%s global_local=%s" % [
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
		F10_LOG_NAME
	)


func _is_inside_vanilla_area(target_position: Vector2, window_size: Vector2) -> bool:
	var vanilla_size: Vector2 = Vector2(
		WorkspaceAreaConfig.VANILLA_WORKSPACE_SIZE,
		WorkspaceAreaConfig.VANILLA_WORKSPACE_SIZE
	)
	var vanilla_max_position: Vector2 = (vanilla_size - window_size).max(Vector2.ZERO)
	return target_position == target_position.clamp(Vector2.ZERO, vanilla_max_position)


func _finish_drag() -> void:
	Globals.dragging = false
	Signals.dragging_set.emit()

	queue_free()
