modifier_infernal_chain_lightning_caster_lua = class ({})

function modifier_infernal_chain_lightning_caster_lua:IsHidden()
	return false;
end

function modifier_infernal_chain_lightning_caster_lua:OnCreated(table)
	if IsServer() then
		self.detected_radius = 500
		self:StartIntervalThink(1)

		self.fx_id = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_WORLDORIGIN, self:GetParent())
	end
end

function modifier_infernal_chain_lightning_caster_lua:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.fx_id, false)
	end
end

function modifier_infernal_chain_lightning_caster_lua:OnIntervalThink()
	local caster = self:GetCaster()
    local center = self:GetParent():GetOrigin()

	local units = FindUnitsInRadius(caster:GetTeamNumber(), center, nil, self.detected_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		if unit ~= nil and unit ~= self.caster then
			local damage = {
				victim = unit,
				attacker = caster,
				ability = self:GetAbility(),
				damage = 300,
				damage_type = DAMAGE_TYPE_MAGICAL,
			}

			print('--' .. unit:GetUnitName())
			ApplyDamage(damage)
			return
		end
	end
end