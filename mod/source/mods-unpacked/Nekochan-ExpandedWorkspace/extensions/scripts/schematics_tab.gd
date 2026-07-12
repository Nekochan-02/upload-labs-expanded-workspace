extends "res://scripts/schematics_tab.gd"

const MODDED_MAX_WINDOW: int = 1000


func update_node_count() -> void:
	super.update_node_count()
	if cur_schematic.is_empty():
		return

	var remaining: int = max(0, MODDED_MAX_WINDOW - Globals.max_window_count)
	$SchematicPanel / RequirementContainer / Requirement.text = "%d/%d" % [
		required,
		remaining,
	]

	requirement_met = Globals.max_window_count + required <= MODDED_MAX_WINDOW
	var color: Color = Color("a0c6cf") if requirement_met else Color.RED
	$SchematicPanel / RequirementContainer / Requirement.add_theme_color_override(
		"font_color",
		color
	)
	$SchematicPanel / OptionsContainer / Add.disabled = not requirement_met
