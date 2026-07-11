extends Node

# Mod: Nekochan-ExpandedWorkspace
# Phase 2A: Node count limit only (500 -> 1000)
# No canvas bounds expansion in this phase.

const MOD_ID: String = "Nekochan-ExpandedWorkspace"


func _init() -> void:
	# Register Script Extensions during the init phase (before _ready),
	# as required by Godot Mod Loader.
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scenes/window_dragger.gd"
	)
	ModLoaderMod.install_script_extension(
		"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/desktop.gd"
	)
	ModLoaderLog.info("Registered Script Extensions (Phase 2A: node limit x2)", MOD_ID)


func _ready() -> void:
	ModLoaderLog.info("ExpandedWorkspace v0.1.0 loaded. MAX node limit: 1000.", MOD_ID)
