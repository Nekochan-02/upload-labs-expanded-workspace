extends "res://scripts/main_2d.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)

var _expanded_workspace_initialized: bool


func _ready() -> void:
	_apply_expanded_desktop_area()
	super._ready()
	_apply_visual_workspace_size()


func set_screen(screen: int) -> void:
	_apply_expanded_desktop_area()
	super.set_screen(screen)
	_apply_visual_workspace_size()


func _apply_expanded_desktop_area() -> void:
	if screen_size.size() > 0:
		screen_size[0] = WorkspaceAreaConfig.MODDED_WORKSPACE_SIZE

	if _expanded_workspace_initialized:
		return

	if screen_position.size() > 0 and screen_position[0].is_equal_approx(
		WorkspaceAreaConfig.VANILLA_WORKSPACE_CENTER
	):
		screen_position[0] = WorkspaceAreaConfig.MODDED_WORKSPACE_CENTER

	_expanded_workspace_initialized = true


func _apply_visual_workspace_size() -> void:
	var workspace_size: Vector2 = WorkspaceAreaConfig.get_workspace_size()

	var desktop: Control = get_node_or_null("Desktop")
	if desktop:
		desktop.custom_minimum_size = workspace_size
		desktop.size = workspace_size

	var background: ColorRect = get_node_or_null("Desktop/Background")
	if background:
		background.custom_minimum_size = workspace_size
		background.size = workspace_size

	var lines: Control = get_node_or_null("Desktop/Lines")
	if lines:
		lines.custom_minimum_size = workspace_size
		lines.size = workspace_size
		lines.clip_contents = false
