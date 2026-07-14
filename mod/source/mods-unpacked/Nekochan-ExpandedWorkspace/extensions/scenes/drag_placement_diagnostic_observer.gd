extends Node

const F11_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F11"
const F11_OPENING_SETTLE_DELAY_SECONDS: float = 0.5


func begin(window: WindowContainer, target_position: Vector2) -> void:
	call_deferred("_log_next_deferred_stability", window, target_position)
	get_tree().create_timer(F11_OPENING_SETTLE_DELAY_SECONDS).timeout.connect(
		_log_opening_settle.bind(window, target_position)
	)


func _log_next_deferred_stability(
	window: WindowContainer,
	target_position: Vector2
) -> void:
	_log_checkpoint_or_missing("F11_NEXT_DEFERRED_STABILITY", window, target_position)


func _log_opening_settle(window: WindowContainer, target_position: Vector2) -> void:
	_log_checkpoint_or_missing("F11_OPENING_SETTLE_STABILITY", window, target_position)
	queue_free()


func _log_checkpoint_or_missing(
	checkpoint: String,
	window: WindowContainer,
	target_position: Vector2
) -> void:
	if not is_instance_valid(window):
		ModLoaderLog.info(
			"[F11][drag][%s] window=missing target=%s" % [
				checkpoint,
				str(target_position),
			],
			F11_LOG_NAME
		)
		return

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
		"[F11][drag][%s] window=%s local=%s global=%s parent=%s parent_global_origin=%s parent_transform_origin=%s target=%s local_to_target=%s global_to_target=%s global_local=%s" % [
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
		F11_LOG_NAME
	)
