ent_blink_lua = class ({})

function ent_blink_lua:OnSpellStart()
	local caster = self:GetCaster()

	FindClearSpaceForUnit(caster, self.blink_location, false)
	ProjectileManager:ProjectileDodge(caster)
	
	EmitSoundOn("Hero_Antimage.Blink_in", caster)
	ParticleManager:CreateParticle("particles/units/ent/ent_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
end

function ent_blink_lua:OnAbilityPhaseStart()
	self.blink_location = self:GetCursorPosition()
	local caster = self:GetCaster()
	local casterPos = caster:GetOrigin()

	local diff = self.blink_location - casterPos

	local range = self:GetSpecialValueFor("blink_range")

	local lenght = diff:Length2D();
	if lenght > range then
		self.blink_location = casterPos + (self.blink_location - casterPos):Normalized() * range;
	end

	EmitSoundOnLocationWithCaster(self.blink_location, "Hero_Antimage.Blink_out", caster)

	local blinkEndIndex = ParticleManager:CreateParticle("particles/units/ent/ent_blink_end.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(blinkEndIndex,0, self.blink_location)

	return true;
end

function ent_blink_lua:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("blink_range")
end

function ent_blink_lua:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_DIRECTIONAL + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
end

function ent_blink_lua:GetAbilityTargetType()
	return DOTA_UNIT_TARGET_NONE
end

function ent_blink_lua:CastFilterResultLocation(vLocation)
	return UF_SUCCESS
end