extends Node

const F13_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F13"

var _target: WeakRef
var _target_name: String = "unknown"


func begin(group: Node) -> void:
	_target = weakref(group)
	_target_name = group.name
	call_deferred("_log_after_first_frame")


func log_after_release_or_cancel() -> void:
	_log_checkpoint_or_missing("R5_AFTER_RELEASE_OR_CANCEL")
	queue_free()


func _log_after_first_frame() -> void:
	_log_checkpoint_or_missing("R4_AFTER_FIRST_FRAME")


func _log_checkpoint_or_missing(checkpoint: String) -> void:
	var group: Node = _target.get_ref() if _target else null
	if not is_instance_valid(group):
		ModLoaderLog.info(
			"[F13][%s] group=%s is_instance_valid=false classification=GROUP_NODE_QUEUE_FREED" % [
				checkpoint,
				_target_name,
			],
			F13_LOG_NAME
		)
		return
	group.call("_f13_log_from_observer", checkpoint)
