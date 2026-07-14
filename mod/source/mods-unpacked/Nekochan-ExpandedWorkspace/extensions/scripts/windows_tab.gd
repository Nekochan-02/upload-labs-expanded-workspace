extends "res://scripts/windows_tab.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000
const F9_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F9"
const F9_SNAP_INTERVAL: float = 50.0
const F9_OPENING_SETTLE_DELAY_SECONDS: float = 0.5

var _f9_diagnostic_target_taken: bool = false


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
	var log_diagnostic: bool = not _f9_diagnostic_target_taken
	if log_diagnostic:
		_f9_diagnostic_target_taken = true
		_f9_log_target(instance, target_position)

	instance.global_position = target_position
	Signals.create_window.emit(instance)

	if is_instance_valid(instance):
		instance.global_position = target_position
		call_deferred(
			"_apply_expanded_click_local_alignment",
			instance,
			target_position,
			log_diagnostic
		)


func _should_use_vanilla_limit() -> bool:
	return Globals.max_window_count < Utils.MAX_WINDOW or Globals.max_window_count >= MODDED_MAX_WINDOW


func _restore_count_after_vanilla_call(before: int) -> void:
	var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
	Globals.max_window_count = before + added


func _get_expanded_click_target(window_size: Vector2) -> Vector2:
	var target: Vector2 = Globals.camera_center - (window_size / 2.0)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)


func _apply_expanded_click_local_alignment(
	window: WindowContainer,
	target_position: Vector2,
	log_diagnostic: bool
) -> void:
	if not is_instance_valid(window):
		return

	if log_diagnostic:
		_f9_log_window_checkpoint(
			"F9_BEFORE_LOCAL_CORRECTION",
			window,
			target_position
		)

	window.position = target_position
	window.moved.emit()

	if not log_diagnostic:
		return

	_f9_log_window_checkpoint("F9_AFTER_LOCAL_CORRECTION", window, target_position)
	call_deferred("_f9_log_next_deferred_stability", window, target_position)
	get_tree().create_timer(F9_OPENING_SETTLE_DELAY_SECONDS).timeout.connect(
		_f9_log_opening_settle.bind(window, target_position)
	)


func _f9_log_target(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	var snap_units: Vector2 = target_position / F9_SNAP_INTERVAL
	var snap_nearest_integer_delta: Vector2 = Vector2(
		snap_units.x - round(snap_units.x),
		snap_units.y - round(snap_units.y)
	)
	var target_snap_correct: bool = snap_nearest_integer_delta.is_zero_approx()
	var snap_classification: String = (
		"TARGET_SNAP_CORRECT" if target_snap_correct else "TARGET_SNAP_INCORRECT"
	)

	ModLoaderLog.info(
		"[F9][F9_TARGET] window=%s target=%s snap_interval=%s snap_units=%s snap_nearest_integer_delta=%s classification=%s" % [
			window.name,
			str(target_position),
			str(F9_SNAP_INTERVAL),
			str(snap_units),
			str(snap_nearest_integer_delta),
			snap_classification,
		],
		F9_LOG_NAME
	)


func _f9_log_next_deferred_stability(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	if not is_instance_valid(window):
		_f9_log_missing_checkpoint("F9_STABILITY_NEXT_DEFERRED", target_position)
		return

	_f9_log_window_checkpoint("F9_STABILITY_NEXT_DEFERRED", window, target_position)


func _f9_log_opening_settle(window: WindowContainer, target_position: Vector2) -> void:
	if not is_instance_valid(window):
		_f9_log_missing_checkpoint("F9_STABILITY_AFTER_OPENING_SETTLE", target_position)
		return

	_f9_log_window_checkpoint(
		"F9_STABILITY_AFTER_OPENING_SETTLE",
		window,
		target_position
	)


func _f9_log_missing_checkpoint(checkpoint: String, target_position: Vector2) -> void:
	ModLoaderLog.info(
		"[F9][%s] window=missing target=%s" % [
			checkpoint,
			str(target_position),
		],
		F9_LOG_NAME
	)


func _f9_log_window_checkpoint(
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
		"[F9][%s] window=%s local=%s global=%s parent=%s parent_global_origin=%s parent_transform_origin=%s target=%s local_to_target=%s global_to_target=%s global_local=%s" % [
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
		F9_LOG_NAME
	)
