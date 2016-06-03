ent_windrun_lua = class ({})
LinkLuaModifier( "modifier_ent_windrun_lua", "modifier/modifier_ent_windrun_lua", LUA_MODIFIER_MOTION_NONE )

function ent_windrun_lua:OnSpellStart()
	local duration = self:GetSpecialValueFor("windrun_duration")
	local caster = self:GetCaster()

	caster:AddNewModifier( caster, self, "modifier_ent_windrun_lua", {duration = duration} )
end