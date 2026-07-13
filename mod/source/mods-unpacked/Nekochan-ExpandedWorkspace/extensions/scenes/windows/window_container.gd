extends "res://scenes/windows/window_container.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)


func get_position_snapped(to: Vector2) -> Vector2:
	return to.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(size)).snappedf(50)
