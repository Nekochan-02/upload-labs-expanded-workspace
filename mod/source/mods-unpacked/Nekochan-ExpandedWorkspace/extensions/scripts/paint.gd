extends "res://scripts/paint.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)


func _draw() -> void:
	var half_size: float = WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE / 2.0
	draw_rect(
		Rect2(
			Vector2(-half_size, -half_size),
			WorkspaceAreaConfig.get_workspace_size()
		),
		Color.WHITE
	)
