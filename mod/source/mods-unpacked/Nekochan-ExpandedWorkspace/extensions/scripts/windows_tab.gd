extends "res://scripts/windows_tab.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000


func update_node_count() -> void:
	super.update_node_count()
	$WindowsContainer / TopContainer / Nodes / Label.text = "%d/%d" % [
		Globals.max_window_count,
		MODDED_MAX_WINDOW,
	]


func _on_add_pressed() -> void:
	if _should_use_vanilla_limit():
		super._on_add_pressed()
		return

	var before: int = Globals.max_window_count
	Globals.max_window_count = Utils.MAX_WINDOW - 1
	super._on_add_pressed()
	_restore_count_after_vanilla_call(before)


func _on_window_selected(window: String) -> void:
	if Data.is_mobile() or window.is_empty() or _should_use_vanilla_limit():
		super._on_window_selected(window)
		return

	var before: int = Globals.max_window_count
	Globals.max_window_count = Utils.MAX_WINDOW - 1
	super._on_window_selected(window)
	_restore_count_after_vanilla_call(before)


func add_window(window: String) -> void:
	var instance: WindowContainer = load(
		"res://scenes/windows/" + Data.windows[window].scene + ".tscn"
	).instantiate()
	instance.name = window

	var target_position: Vector2 = _get_expanded_click_target(instance.size)
	instance.global_position = target_position
	Signals.create_window.emit(instance)

	if is_instance_valid(instance):
		instance.global_position = target_position
		instance.call_deferred("move", target_position)


func _should_use_vanilla_limit() -> bool:
	return Globals.max_window_count < Utils.MAX_WINDOW or Globals.max_window_count >= MODDED_MAX_WINDOW


func _restore_count_after_vanilla_call(before: int) -> void:
	var added: int = max(0, Globals.max_window_count - (Utils.MAX_WINDOW - 1))
	Globals.max_window_count = before + added


func _get_expanded_click_target(window_size: Vector2) -> Vector2:
	var target: Vector2 = Globals.camera_center - (window_size / 2.0)
	return target.clamp(Vector2.ZERO, WorkspaceAreaConfig.get_max_position(window_size)).snappedf(50)
