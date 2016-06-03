infernal_chain_lightning_lua = class ({})
--LinkLuaModifier("modifier", "modifier/modifier_infernal_chain_lightning_tracker_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infernal_chain_lightning_caster_lua", "modifier/modifier_infernal_chain_lightning_caster_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infernal_chain_lightning_invisibility_lua", "modifier/modifier_infernal_chain_lightning_invisibility_lua", LUA_MODIFIER_MOTION_NONE)

function infernal_chain_lightning_lua:OnSpellStart()
	local caster = self:GetCaster()
	local targetPoint = self:GetCursorPosition()

	local land_mine = CreateUnitByName("npc_dota_techies_land_mine", targetPoint, false, nil, nil, caster:GetTeamNumber())
    land_mine:AddNewModifier(caster, self, "modifier_kill", {Duration = 10})
    land_mine:AddNewModifier(caster, self, "modifier_infernal_chain_lightning_caster_lua", nil)
    land_mine:AddNewModifier(caster, self, "modifier_infernal_chain_lightning_invisibility_lua", nil)
end