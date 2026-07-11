extends "res://scenes/window_dragger.gd"

# Mod: Nekochan-ExpandedWorkspace  Phase 2A
# Overrides place() to replace the Utils.MAX_WINDOW (500) global limit
# check with the modded limit (1000). All other logic is inherited unchanged.

const MODDED_MAX_WINDOW: int = 1000


func place() -> void:
	if Globals.max_window_count >= MODDED_MAX_WINDOW:
		Signals.notify.emit("exclamation", "build_limit_reached")
		Sound.play("error")
	elif Utils.can_add_window(window):
		var instance: WindowContainer = load(
			"res://scenes/windows/" + Data.windows[window].scene + ".tscn"
		).instantiate()
		instance.name = window
		var instance_pos: Vector2 = Utils.screen_to_world_pos(global_position + size / 2)
		instance.global_position = (instance_pos - Vector2(175, instance.size.y / 2)).snappedf(50)
		Signals.create_window.emit(instance)

	Globals.dragging = false
	Signals.dragging_set.emit()

	queue_free()
