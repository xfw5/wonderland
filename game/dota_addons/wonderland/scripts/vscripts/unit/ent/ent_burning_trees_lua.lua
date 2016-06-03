ent_destroy_trees_lua = class({})

function ent_destroy_trees_lua:OnSpellStart()
	self.destroy_range = self:GetSpecialValueFor("burning_trees_aoe")
	self.destroy_location = self:GetCursorPosition()

	self.fx_rayIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_light_strike_array_ray_team.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl( self.fx_rayIndex, 0, self.destroy_location )
	ParticleManager:SetParticleControl( self.fx_rayIndex, 1, Vector( 0, 1, 1 ) )
end

function ent_destroy_trees_lua:OnChannelThink(flInterval)
	local percentage = Utils:GetChannelTimeFlow(self) / self:GetChannelTime()
	local aoe = percentage * self.destroy_range;

	ParticleManager:SetParticleControl( self.fx_rayIndex, 1, Vector( aoe + 500, 1, 1 ) )
	Utils:DestroyTreesAroundPoint(self.destroy_location, aoe, true)
end

function ent_destroy_trees_lua:GetAOERadius()
	return self:GetSpecialValueFor("burning_trees_aoe")
end