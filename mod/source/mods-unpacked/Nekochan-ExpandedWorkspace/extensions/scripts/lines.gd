extends "res://scripts/lines.gd"

const GRID_TILE_META: StringName = &"expanded_workspace_grid_tile"
const GRID_TILE_SIZE: Vector2 = Vector2(10000, 10000)
const GRID_TILE_OFFSETS: Array[Vector2] = [
	Vector2(10000, 0),
	Vector2(0, 10000),
	Vector2(10000, 10000),
]

var _grid_tiles_created: bool


func _ready() -> void:
	_apply_vanilla_scale()
	super._ready()
	if not _is_grid_tile():
		call_deferred("_create_grid_tiles")


func update_lines() -> void:
	_apply_vanilla_scale()
	super.update_lines()


func _apply_vanilla_scale() -> void:
	scale = Vector2.ONE


func _is_grid_tile() -> bool:
	return has_meta(GRID_TILE_META)


func _create_grid_tiles() -> void:
	if _grid_tiles_created or not is_inside_tree():
		return
	_grid_tiles_created = true
	var renderer_script: Script = get_script()
	for index: int in GRID_TILE_OFFSETS.size():
		var tile: Control = Control.new()
		tile.name = "ExpandedWorkspaceGridTile%d" % index
		tile.set_meta(GRID_TILE_META, true)
		tile.set_script(renderer_script)
		tile.position = GRID_TILE_OFFSETS[index]
		tile.custom_minimum_size = GRID_TILE_SIZE
		tile.size = GRID_TILE_SIZE
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tile)
