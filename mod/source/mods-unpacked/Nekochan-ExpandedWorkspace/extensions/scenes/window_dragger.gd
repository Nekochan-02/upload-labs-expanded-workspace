extends "res://scenes/window_dragger.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000


func place() -> void:
	if Globals.max_window_count >= MODDED_MAX_WINDOW:
		super.place()
		return

	if not Utils.can_add_window(window):
		_finish_drag()
		return

	var instance: WindowContainer = load(
		"res://scenes/windows/" + Data.windows[window].scene + ".tscn"
	).instantiate()
	instance.name = window
	var target_position: Vector2 = _get_expanded_drag_target(instance.size)
	var should_use_vanilla_path: bool = (
		Globals.max_window_count < Utils.MAX_WINDOW
		and _is_inside_vanilla_area(target_position, instance.size)
	)

	if should_use_vanilla_path:
		instance.free()
		super.place()
		return

	var before: int = Globals.max_window_count
	var lifted_count_for_vanilla_create: bool = Globals.max_window_count >= Utils.MAX_WINDOW
	if lifted_count_for_vanilla_create:
		Globals.max_window_count = Utils.MAX_WINDOW - 1

	instance.global_position = target_position
	Signals.create_window.emit(instance)

	if lifted_count_for_vanilla_create:
		var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
		Globals.max_window_count = before + added

	if is_instance_valid(instance):
		instance.global_position = target_position
		instance.call_deferred("move", target_position)

	_finish_drag()


func _get_expanded_drag_target(window_size: Vector2) -> Vector2:
	var instance_pos: Vector2 = Utils.screen_to_world_pos(global_position + size / 2)
	var target: Vector2 = instance_pos - Vector2(175, window_size.y / 2)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)


func _is_inside_vanilla_area(target_position: Vector2, window_size: Vector2) -> bool:
	var vanilla_size: Vector2 = Vector2(
		WorkspaceAreaConfig.VANILLA_WORKSPACE_SIZE,
		WorkspaceAreaConfig.VANILLA_WORKSPACE_SIZE
	)
	var vanilla_max_position: Vector2 = (vanilla_size - window_size).max(Vector2.ZERO)
	return target_position == target_position.clamp(Vector2.ZERO, vanilla_max_position)


func _finish_drag() -> void:
	Globals.dragging = false
	Signals.dragging_set.emit()

	queue_free()
