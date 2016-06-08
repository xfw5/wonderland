passive_building_lua = class ({})
LinkLuaModifier("modifier_passive_building_lua", "modifier/modifier_passive_building_lua", LUA_MODIFIER_MOTION_NONE)

function passive_building_lua:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:AddNewModifier(caster, slef, "modifier_passive_building_lua", nil)
end

function passive_building_lua:IsHidden()
	return true
end