infernal_stomp_lua = class ({})
LinkLuaModifier("modifier_infernal_stomp_stun_lua", "modifier/modifier_infernal_stomp_stun_lua", LUA_MODIFIER_MOTION_NONE)

function infernal_stomp_lua:OnSpellStart()
	self.stomp_radius = self:GetSpecialValueFor("stomp_radius")
	self.stomp_damage = self:GetLevelSpecialValueFor("stomp_damage", self:GetLevel() - 1)
	self.stomp_stun_duration = self:GetLevelSpecialValueFor("stomp_stun_duration", self:GetLevel() - 1)

	local caster = self:GetCaster()
	local center = caster:GetOrigin()

	SetTeamCustomHealthbarColor(caster:GetTeamNumber(), 0x21,0x66,0xec)
	SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 0x21,0x66,0xec)

	fxId = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_warstomp.vpcf", PATTACH_POINT, caster)
	ParticleManager:ReleaseParticleIndex(fxId)

	local units = FindUnitsInRadius(caster:GetTeamNumber(), center, nil, self.stomp_radius, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		if unit ~= nil then
			local damage = {
				victim = unit,
				attacker = caster,
				ability = self,
				damage = self.stomp_damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			}

			ApplyDamage(damage)
			unit:AddNewModifier( caster, self, "modifier_infernal_stomp_stun_lua", {duration = self.stomp_stun_duration} )
		end
	end
end