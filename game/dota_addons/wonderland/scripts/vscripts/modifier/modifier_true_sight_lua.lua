modifier_true_sight_lua = class ({})
LinkLuaModifier("modifier_true_sight_reveal_lua", "modifier/modifier_true_sight_reveal_lua", LUA_MODIFIER_MOTION_NONE)

if IsServer() then 
	function modifier_true_sight_lua:OnCreated(table)
		self.reveal_interval = 0.03
		self:StartIntervalThink(self.reveal_interval)
	end

	function modifier_true_sight_lua:OnIntervalThink()
		local caster = self:GetCaster()
		local teamID = caster:GetTeamNumber()
		local radius = caster:GetDayTimeVisionRange()
		local enemies = FindUnitsInRadius(teamID, self:GetParent():GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

		if #enemies > 0 then
			for _, enemy in pairs(enemies) do
				if enemy ~= nil then
					enemy:AddNewModifier(caster, nil, "modifier_true_sight_reveal_lua", {Duration = self.reveal_interval})
				end
			end
		end
	end
end