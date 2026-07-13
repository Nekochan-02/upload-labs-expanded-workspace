extends RefCounted

const VANILLA_WORKSPACE_SIZE: int = 10000
const MODDED_WORKSPACE_SIZE: int = 20000
const VANILLA_WORKSPACE_CENTER: Vector2 = Vector2(5000, 5000)
const MODDED_WORKSPACE_CENTER: Vector2 = Vector2(10000, 10000)
static func get_workspace_size() -> Vector2:
	return Vector2(MODDED_WORKSPACE_SIZE, MODDED_WORKSPACE_SIZE)


static func get_max_position(size: Vector2) -> Vector2:
	return (get_workspace_size() - size).max(Vector2.ZERO)
