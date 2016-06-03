infernal_shockwave_lua = class ({})

function infernal_shockwave_lua:OnSpellStart()
	self.shock_speed = self:GetSpecialValueFor("shockwave_speed")
	self.shock_width = self:GetSpecialValueFor("shockwave_width")
	self.shock_distance = self:GetLevelSpecialValueFor("shockwave_distance", self:GetLevel() - 1)

	local caster = self:GetCaster()
	local vDirection = self:GetCursorPosition() - caster:GetOrigin()
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()

	-- Launch projectile
	local info = {
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		Ability = self,
		vSpawnOrigin		= caster:GetOrigin(),
		fDistance			= self.shock_distance,
		fStartRadius		= self.shock_width,
		fEndRadius			= self.shock_width,
		vVelocity			= vDirection * self.shock_speed,
		Source				= caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

	ProjectileManager:CreateLinearProjectile( info )

	caster:EmitSound("Hero_Magnataur.ShockWave.Cast")
end


function infernal_shockwave_lua:OnProjectileHit(hTarget, vLocation)
	if hTarget == nil or hTarget == self:GetCaster() then
		return false
	end

	local ability_level = self:GetLevel() - 1

	-- Parameters
	local shock_speed = self:GetSpecialValueFor("shockwave_speed")
	local shock_width = self:GetSpecialValueFor("shockwave_width")
	local shock_distance = self:GetLevelSpecialValueFor("shockwave_distance", ability_level)
	local shock_damage = self:GetLevelSpecialValueFor("shockwave_damage", ability_level)

	-- Play impact particle
	local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_magnataur/magnataur_shockwave_hit.vpcf", PATTACH_ABSORIGIN, hTarget)
	ParticleManager:SetParticleControl(hit_pfx, 0, hTarget:GetAbsOrigin())

	-- Play impact sound
	hTarget:EmitSound("hero/hero_magnus.lua")

	-- Deal damage
	ApplyDamage({attacker = self:GetCaster(), victim = hTarget, ability = self, damage = shock_damage, damage_type = DAMAGE_TYPE_MAGICAL})

	return false
end