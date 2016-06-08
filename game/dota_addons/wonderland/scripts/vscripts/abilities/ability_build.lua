function OnBuildingAction( keys )
	local location = keys.target_points[1]
	local owner = keys.caster:GetPlayerOwner()

	local params = {
		UNIT_NAME = keys.UnitName,
		BUILD_TIME = 10,
		BUILD_SIZE = 32,
		BUILD_COST = 20,
		BUILD_PARTICLE = "particles/econ/events/league_teleport_2014/teleport_start_league_silver.vpcf"
	}

	BuildingHelper:CreateBuilding(owner, location, keys.onBuildingStart, keys.onBuildingComplete, params)
end

LinkLuaModifier("modifier_passive_building_lua", "modifier/modifier_passive_building_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_true_sight_lua", "modifier/modifier_true_sight_lua", LUA_MODIFIER_MOTION_NONE)
function OnBuildingScoutTower( keys )
	keys.onBuildingStart = function (building)
		local location = keys.target_points[1]
		local owner = keys.caster:GetPlayerOwner()
		local dayVision = building:GetDayTimeVisionRange()
		local nightVision = building:GetNightTimeVisionRange()

		keys.fly_vision_creature = Utils:CreateFlyingDummy(location, owner, dayVision, nightVision)
	end

	keys.onBuildingComplete = function (building)
		building:AddNewModifier(building, nil, "modifier_passive_building_lua", nil)
		keys.fly_vision_creature:AddNewModifier(building, nil, "modifier_true_sight_lua", nil)
	end

	OnBuildingAction(keys)
end