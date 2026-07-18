extends "res://scripts/camera_2d.gd"


func handle_unhandled_input(event: InputEvent, from: Vector2) -> void:
	var desktop: Node = get_node_or_null("../Desktop")
	var before_position: Vector2 = position
	if is_instance_valid(desktop) and desktop.has_method("_f51_record_camera_route"):
		desktop._f51_record_camera_route(event, before_position, before_position)
	super.handle_unhandled_input(event, from)
	if is_instance_valid(desktop) and desktop.has_method("_f51_record_camera_route"):
		desktop._f51_record_camera_route(event, before_position, position)
