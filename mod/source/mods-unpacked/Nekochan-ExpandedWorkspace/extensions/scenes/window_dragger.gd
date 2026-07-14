extends "res://scenes/window_dragger.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const DragPlacementDiagnosticObserver = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/drag_placement_diagnostic_observer.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F11_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F11"
const F11_SNAP_INTERVAL: float = 50.0

var _f11_diagnostic_target_taken: bool = false


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

	var log_diagnostic: bool = not _f11_diagnostic_target_taken
	if log_diagnostic:
		_f11_diagnostic_target_taken = true
		_f11_log_target(instance, target_position)

	var before: int = Globals.max_window_count
	var lifted_count_for_vanilla_create: bool = Globals.max_window_count >= Utils.MAX_WINDOW
	if lifted_count_for_vanilla_create:
		Globals.max_window_count = Utils.MAX_WINDOW - 1

	instance.global_position = target_position
	Signals.create_window.emit(instance)

	if lifted_count_for_vanilla_create:
		var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
		Globals.max_window_count = before + added

	if is_instance_valid(instance):
		instance.global_position = target_position
		_f11_start_local_alignment_observer(instance, target_position, log_diagnostic)

	_finish_drag()


func _get_expanded_drag_target(window_size: Vector2) -> Vector2:
	var instance_pos: Vector2 = Utils.screen_to_world_pos(global_position + size / 2)
	var target: Vector2 = instance_pos - Vector2(175, window_size.y / 2)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)


func _f11_log_target(window: WindowContainer, target_position: Vector2) -> void:
	var snap_units: Vector2 = target_position / F11_SNAP_INTERVAL
	var snap_nearest_integer_delta: Vector2 = Vector2(
		snap_units.x - round(snap_units.x),
		snap_units.y - round(snap_units.y)
	)
	var target_snap_correct: bool = snap_nearest_integer_delta.is_zero_approx()
	var snap_classification: String = (
		"TARGET_SNAP_CORRECT" if target_snap_correct else "TARGET_SNAP_INCORRECT"
	)

	ModLoaderLog.info(
		"[F11][drag][F11_TARGET] window=%s target=%s snap_interval=%s snap_units=%s snap_nearest_integer_delta=%s classification=%s" % [
			window.name,
			str(target_position),
			str(F11_SNAP_INTERVAL),
			str(snap_units),
			str(snap_nearest_integer_delta),
			snap_classification,
		],
		F11_LOG_NAME
	)


func _f11_start_local_alignment_observer(
	window: WindowContainer,
	target_position: Vector2,
	log_diagnostic: bool
) -> void:
	var observer = DragPlacementDiagnosticObserver.new()
	get_tree().root.add_child(observer)
	observer.begin(window, target_position, log_diagnostic)


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
