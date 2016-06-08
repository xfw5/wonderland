LinkLuaModifier("modifier_passive_building_lua", "modifier/modifier_passive_building_lua", LUA_MODIFIER_MOTION_NONE)

function BuildingScoutTower( keys )
	local location = keys.target_points[1]
	local owner = keys.caster:GetPlayerOwner()

	local params = {
		UNIT_NAME = keys.UnitName,
		BUILD_TIME = 10,
		BUILD_SIZE = 32,
		BUILD_COST = 20,
		BUILD_PARTICLE = "particles/econ/events/league_teleport_2014/teleport_start_league_silver.vpcf"
	}

	BuildingHelper:CreateBuilding(owner, location, OnScoutTowerBuildingComplete, params)
end

function OnScoutTowerBuildingComplete(unit)
	Utils:Wprint("building complete...")
	unit:AddNewModifier(units, nil, "modifier_passive_building_lua", nil)
end