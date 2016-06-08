passive_construction_building_lua = class ({})
LinkLuaModifier("modifier_passive_construction_building_lua", "modifier/modifier_passive_construction_building_lua", LUA_MODIFIER_MOTION_NONE)

function passive_construction_building_lua:GetIntrinsicModifierName()
	return "modifier_passive_construction_building_lua"
end

function passive_construction_building_lua:IsPassive()
	return true
end

function passive_construction_building_lua:IsHidden()
	return true
end