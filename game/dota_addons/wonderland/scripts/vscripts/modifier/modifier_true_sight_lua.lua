modifier_true_sight_lua = class ({})

if IsServer() then 
	function modifier_true_sight_lua:OnCreated(table)
		self:StartIntervalThink(0.03)
	end

	function modifier_true_sight_lua:OnIntervalThink()
		local ability = self:GetAbility()
		local caster = self:GetCaster()
		local teamID = ability:GetAbilityTargetTeam()
		local enemies = FindUnitsInRadius(teamID, self:GetParent():GetAbsOrigin(), nil, ability.true_sight_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				if enemy ~= nil then
					enemy:AddNewModifier(ability:GetCaster(), ability, "modifier_true_sight_reveal_lua", { Duration = ability.true_sight_duration, IsDebuff = true, IsPurgable = false})
				end
			end
		end
	end
end