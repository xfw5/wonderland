passvie_tower_lua = class ({})
LinkLuaModifier( "modifier_tower_lua", "modifier/modifier_tower_lua", LUA_MODIFIER_MOTION_NONE )

function passvie_tower_lua:GetIntrinsicModifierName()
	return "modifier_tower_lua"
end

function passvie_tower_lua:IsPassive()
	return true
end

function passvie_tower_lua:IsHidden()
	return true
end