extends "res://scripts/lines.gd"

const WorkspaceAreaConfig = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/workspace_area_config.gd"
)
const F7_LOG_NAME: String = "Nekochan-ExpandedWorkspace:F7"
const F7_TILE_META: StringName = &"expanded_workspace_f7_grid_tile"
const F7_TILE_SIZE: Vector2 = Vector2(10000, 10000)
const F7_TILE_OFFSETS: Array[Vector2] = [
	Vector2(10000, 0),
	Vector2(0, 10000),
	Vector2(10000, 10000),
]

var _f7_tiles_created: bool


func _ready() -> void:
	_apply_vanilla_scale()
	super._ready()

	if not _is_f7_grid_tile():
		call_deferred("_f7_create_grid_tiles")


func update_lines() -> void:
	_apply_vanilla_scale()
	super.update_lines()


func _apply_vanilla_scale() -> void:
	scale = Vector2.ONE


func _is_f7_grid_tile() -> bool:
	return has_meta(F7_TILE_META)


func _f7_create_grid_tiles() -> void:
	if _f7_tiles_created or not is_inside_tree():
		return
	_f7_tiles_created = true

	var renderer_script: Script = get_script()
	for index: int in F7_TILE_OFFSETS.size():
		var tile: Control = Control.new()
		tile.name = "F7GridTile%d" % index
		tile.set_meta(F7_TILE_META, true)
		tile.set_script(renderer_script)
		tile.position = F7_TILE_OFFSETS[index]
		tile.custom_minimum_size = F7_TILE_SIZE
		tile.size = F7_TILE_SIZE
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tile)

	_f7_log_grid()


func _f7_log_grid() -> void:
	var line_type: int = Data.lines_type
	var per_tile_instances: int = _f7_instances_for_line_type(line_type)
	ModLoaderLog.info(
		"[F7][GRID] workspace_size=%s renderer_scale=%s geometry=%s origin=%s coverage=%s tile_count=%d per_tile_instance_count=%d instance_count=%d lines_type=%d" % [
			str(WorkspaceAreaConfig.get_workspace_size()),
			str(scale),
			_f7_geometry_for_line_type(line_type),
			str(Vector2.ZERO),
			str(WorkspaceAreaConfig.get_workspace_size()),
			F7_TILE_OFFSETS.size() + 1,
			per_tile_instances,
			per_tile_instances * (F7_TILE_OFFSETS.size() + 1),
			line_type,
		],
		F7_LOG_NAME
	)


func _f7_geometry_for_line_type(line_type: int) -> String:
	match line_type:
		0:
			return "lines_minor=50_major=500"
		1:
			return "circles_interval=50"
		2:
			return "diagonal_offset=50"
		3:
			return "crosses_interval=50"
		4:
			return "hexagons_x=43.30127_y=37.5"
		5:
			return "starfield_seed=1"
		_:
			return "unknown"


func _f7_instances_for_line_type(line_type: int) -> int:
	match line_type:
		0:
			return 400
		1:
			return 40401
		2:
			return 820
		3:
			return 40000
		4:
			return 62176
		5:
			return 5000
		_:
			return 0
