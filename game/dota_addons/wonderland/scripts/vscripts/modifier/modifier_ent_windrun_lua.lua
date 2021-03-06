modifier_ent_windrun_lua = class ({})

if IsServer() then
	function modifier_ent_windrun_lua:DeclareFunctions()
		local funcs = {
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_MAX,
		}

		return funcs
	end

	function modifier_ent_windrun_lua:IsHidden()
		return false
	end

	function modifier_ent_windrun_lua:OnCreated(kv)
		self.nFXIndexStart = ParticleManager:CreateParticle("particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
		self.bonus_speed_percentage = self:GetAbility():GetSpecialValueFor("windrun_bonus_speed_percentage")
	end

	function modifier_ent_windrun_lua:OnDestroy()
			ParticleManager:DestroyParticle(self.nFXIndexStart, false)
	end

	function modifier_ent_windrun_lua:GetModifierMoveSpeedBonus_Constant()
		return self.bonus_speed_percentage;
	end

	function modifier_ent_windrun_lua:GetModifierMoveSpeed_Max()
		return 1000
	end
end

