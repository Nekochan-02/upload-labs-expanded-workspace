extends "res://scenes/windows/window_group.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const MINIMUM_GROUP_SIZE: Vector2 = Vector2(200, 100)
const VANILLA_WORKSPACE_SIZE: Vector2 = Vector2(10000, 10000)


func _process(delta: float) -> void:
	var correct_size_collapse: bool = resizing_right or resizing_bottom
	var resize_geometry: Dictionary = {}
	if correct_size_collapse:
		resize_geometry = _derive_resize_geometry(get_global_mouse_position().snappedf(50))

	super._process(delta)

	if correct_size_collapse:
		_correct_old_bound_size_collapse(resize_geometry)

	if not moving:
		return
	var current_mouse: Vector2 = get_global_mouse_position().snappedf(50)
	var target_position: Vector2 = (drag_start_rect.position + (current_mouse - drag_start_mouse)).clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	).snappedf(50)
	move(target_position)


func move_snapped(to: Vector2) -> void:
	if not _is_expanded_workspace_resize_active():
		super.move_snapped(to)
		return
	var clamped_target: Vector2 = to.clamp(
		Vector2.ZERO,
		WorkspaceAreaConfig.get_max_position(size)
	)
	move(clamped_target.snappedf(50))


func _is_expanded_workspace_resize_active() -> bool:
	return resizing_left or resizing_right or resizing_top or resizing_bottom


func _correct_old_bound_size_collapse(geometry: Dictionary) -> void:
	var old_rect: Rect2 = geometry["old_rect"]
	var expanded_rect: Rect2 = geometry["expanded_rect"]
	var expanded_valid: bool = (
		expanded_rect.size.x >= MINIMUM_GROUP_SIZE.x
		and expanded_rect.size.y >= MINIMUM_GROUP_SIZE.y
		and not bool(geometry["expanded_minimum_violation"])
	)
	if not expanded_valid:
		return

	var old_width_invalid: bool = old_rect.size.x < MINIMUM_GROUP_SIZE.x or old_rect.size.x <= 0.0
	var old_height_invalid: bool = old_rect.size.y < MINIMUM_GROUP_SIZE.y or old_rect.size.y <= 0.0
	var actual_width_collapsed: bool = size.x < MINIMUM_GROUP_SIZE.x or custom_minimum_size.x < 0.0
	var actual_height_collapsed: bool = size.y < MINIMUM_GROUP_SIZE.y or custom_minimum_size.y < 0.0
	var correct_width: bool = resizing_right and old_width_invalid and actual_width_collapsed
	var correct_height: bool = resizing_bottom and old_height_invalid and actual_height_collapsed
	if not correct_width and not correct_height:
		return

	var corrected_size: Vector2 = size
	var corrected_minimum: Vector2 = custom_minimum_size
	if correct_width:
		corrected_size.x = expanded_rect.size.x
		corrected_minimum.x = expanded_rect.size.x
	if correct_height:
		corrected_size.y = expanded_rect.size.y
		corrected_minimum.y = expanded_rect.size.y
	custom_minimum_size = corrected_minimum
	size = corrected_size

	var expanded_position: Vector2 = geometry["expanded_snapped_position"]
	if not position.is_equal_approx(expanded_position):
		move(expanded_position)


func _derive_resize_geometry(current_mouse: Vector2) -> Dictionary:
	var mouse_delta: Vector2 = current_mouse - drag_start_mouse
	var old_candidate: Dictionary = _derive_rect_candidate(VANILLA_WORKSPACE_SIZE, mouse_delta)
	var expanded_candidate: Dictionary = _derive_rect_candidate(
		WorkspaceAreaConfig.get_workspace_size(),
		mouse_delta
	)
	return {
		"old_rect": old_candidate["rect"],
		"expanded_rect": expanded_candidate["rect"],
		"expanded_snapped_position": expanded_candidate["snapped_position"],
		"expanded_minimum_violation": expanded_candidate["minimum_violation"],
	}


func _derive_rect_candidate(bounds: Vector2, mouse_delta: Vector2) -> Dictionary:
	var horizontal: Dictionary = _derive_axis_candidate(
		drag_start_rect.position.x,
		drag_start_rect.size.x,
		mouse_delta.x,
		resizing_left,
		resizing_right,
		MINIMUM_GROUP_SIZE.x,
		bounds.x
	)
	var vertical: Dictionary = _derive_axis_candidate(
		drag_start_rect.position.y,
		drag_start_rect.size.y,
		mouse_delta.y,
		resizing_top,
		resizing_bottom,
		MINIMUM_GROUP_SIZE.y,
		bounds.y
	)
	var rect: Rect2 = Rect2(
		Vector2(float(horizontal["position"]), float(vertical["position"])),
		Vector2(float(horizontal["size"]), float(vertical["size"]))
	)
	return {
		"rect": rect,
		"snapped_position": rect.position.clamp(Vector2.ZERO, bounds - rect.size).snappedf(50),
		"minimum_violation": rect.size.x < MINIMUM_GROUP_SIZE.x or rect.size.y < MINIMUM_GROUP_SIZE.y,
	}


func _derive_axis_candidate(
	start_position: float,
	start_size: float,
	delta: float,
	leading_edge: bool,
	trailing_edge: bool,
	minimum_size: float,
	bound: float
) -> Dictionary:
	if leading_edge:
		var anchor: float = start_position + start_size
		var candidate_position: float = clampf(start_position + delta, 0.0, anchor - minimum_size)
		return {"position": candidate_position, "size": anchor - candidate_position}
	if trailing_edge:
		var candidate_size: float = maxf(start_size + delta, minimum_size)
		if start_position + candidate_size > bound:
			candidate_size = bound - start_position
		return {"position": start_position, "size": candidate_size}
	return {"position": start_position, "size": start_size}
