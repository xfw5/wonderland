passive_true_sight_lua = class ({})
LinkLuaModifier("modifier_true_sight_lua", "modifier/modifier_true_sight_lua", LUA_MODIFIER_MOTION_NONE)

function passive_true_sight_lua:GetIntrinsicModifierName()
	return "modifier_true_sight_lua"
end