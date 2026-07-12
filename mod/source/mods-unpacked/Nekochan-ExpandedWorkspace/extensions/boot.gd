extends "res://boot.gd"

const SpaceUpgradeLimitPatch = preload(
	"res://mods-unpacked/Nekochan-ExpandedWorkspace/extensions/scripts/space_upgrade_limit_patch.gd"
)


func _ready() -> void:
	SpaceUpgradeLimitPatch.apply()
	super._ready()
