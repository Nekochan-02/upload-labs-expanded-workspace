extends "res://scenes/windows/window_group.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)


func _process(delta: float) -> void:
	super._process(delta)

	if not moving:
		return

	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var target_position: Vector2 = (drag_start_rect.position + (current_mouse - drag_start_mouse)).clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	).snappedf(50)
	move(target_position)
