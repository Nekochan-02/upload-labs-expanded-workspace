extends "res://scripts/lines.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)


func _ready() -> void:
	_apply_render_scale()
	super._ready()


func update_lines() -> void:
	_apply_render_scale()
	super.update_lines()


func _apply_render_scale() -> void:
	scale = WorkspaceAreaConfig.RENDER_SCALE
