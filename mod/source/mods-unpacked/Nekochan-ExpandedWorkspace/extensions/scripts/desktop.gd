extends "res://scripts/desktop.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MODDED_MAX_WINDOW: int = 1000

var _expanded_workspace_drag_start_positions: Dictionary = {}


func _ready() -> void:
	super._ready()

	if not Signals.begin_drag.is_connected(_on_expanded_workspace_begin_drag):
		Signals.begin_drag.connect(_on_expanded_workspace_begin_drag)
	if not Signals.drag_selection.is_connected(_on_expanded_workspace_drag_selection):
		Signals.drag_selection.connect(_on_expanded_workspace_drag_selection)


func paste(data: Dictionary) -> void:
	var required: int = _count_required_windows(data)
	if required <= 0 or Globals.max_window_count + required <= Utils.MAX_WINDOW:
		super.paste(data)
		return

	if Globals.max_window_count + required > MODDED_MAX_WINDOW:
		Signals.notify.emit("exclamation", "build_limit_reached")
		Sound.play("error")
		return

	var before: int = Globals.max_window_count
	var temporary_count: int = Utils.MAX_WINDOW - required
	Globals.max_window_count = temporary_count
	super.paste(data)

	var added: int = max(0, Globals.max_window_count - temporary_count)
	Globals.max_window_count = before + added


func _count_required_windows(data: Dictionary) -> int:
	if not data.has("windows") or not (data["windows"] is Array):
		return 0
	return data.windows.size()


func _on_expanded_workspace_begin_drag() -> void:
	_expanded_workspace_drag_start_positions.clear()

	for window: WindowContainer in Globals.selections:
		if not is_instance_valid(window):
			continue
		_expanded_workspace_drag_start_positions[window] = window.global_position


func _on_expanded_workspace_drag_selection(from: Vector2, to: Vector2) -> void:
	if _expanded_workspace_drag_start_positions.is_empty():
		return

	call_deferred("_apply_expanded_workspace_drag_selection", to - from)


func _apply_expanded_workspace_drag_selection(delta: Vector2) -> void:
	for window: WindowContainer in _expanded_workspace_drag_start_positions:
		if not is_instance_valid(window):
			continue

		var start_position: Vector2 = _expanded_workspace_drag_start_positions[window]
		var target_position: Vector2 = (start_position + delta).clamp(
			Vector2.ZERO,
			WorkspaceAreaConfig.get_max_position(window.size)
		).snappedf(50)
		window.move(target_position)
