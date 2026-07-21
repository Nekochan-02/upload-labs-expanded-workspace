extends Node


func apply_deferred(window: WindowContainer, target_position: Vector2) -> void:
	call_deferred("_apply", window, target_position)


func _apply(window: WindowContainer, target_position: Vector2) -> void:
	if is_instance_valid(window):
		window.position = target_position
		window.moved.emit()
	queue_free()
