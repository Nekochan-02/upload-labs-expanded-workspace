extends RefCounted

const SPACE_UPGRADE_ID: String = "space"
const MODDED_SPACE_UPGRADE_LIMIT: int = 200


static func apply() -> Dictionary:
	var result: Dictionary = {
		"applied": false,
		"old_limit": -1,
		"new_limit": MODDED_SPACE_UPGRADE_LIMIT,
		"reason": "",
	}

	if not Data.upgrades.has(SPACE_UPGRADE_ID):
		result["reason"] = "missing_space_upgrade"
		return result

	var upgrade_data: Dictionary = Data.upgrades[SPACE_UPGRADE_ID]
	result["old_limit"] = int(upgrade_data.get("limit", -1))

	if result["old_limit"] == MODDED_SPACE_UPGRADE_LIMIT:
		return result

	upgrade_data["limit"] = MODDED_SPACE_UPGRADE_LIMIT
	Data.upgrades[SPACE_UPGRADE_ID] = upgrade_data
	result["applied"] = true
	return result
