extends Node

# Mod: Nekochan-ExpandedWorkspace
# Clean RC integration of verified workspace, capacity, persistence, resize, and
# guarded template placement corrections.
# Do not register connector, window container, or window base/indexed area patches here.

const MOD_ID: String = "Nekochan-ExpandedWorkspace"
const SpaceUpgradeLimitPatch = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd"
)


func _init() -> void:
	_apply_space_upgrade_limit("mod_init")
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/boot.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/windows_tab.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/windows/window_group.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/schematics_tab.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/main_2d.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/lines.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/paint.gd"
	)


func _ready() -> void:
	_apply_space_upgrade_limit("mod_ready")
	ModLoaderLog.info("ExpandedWorkspace v0.2.28 loaded.", MOD_ID)


func _apply_space_upgrade_limit(phase: String) -> void:
	var result: Dictionary = SpaceUpgradeLimitPatch.apply()
	if result["applied"]:
		ModLoaderLog.info(
			"Applied R4 space upgrade limit patch (%d -> %d) during %s." % [
				result["old_limit"],
				result["new_limit"],
				phase,
			],
			MOD_ID
		)
	elif result["old_limit"] == result["new_limit"]:
		ModLoaderLog.info(
			"R4 space upgrade limit already set to %d during %s." % [
				result["new_limit"],
				phase,
			],
			MOD_ID
		)
	else:
		ModLoaderLog.warning(
			"Could not apply R4 space upgrade limit patch during %s: %s." % [
				phase,
				result["reason"],
			],
			MOD_ID
		)
