modifier_infernal_stomp_stun_lua = class ({})

function modifier_infernal_stomp_stun_lua:IsHidden()
	return false
end

function modifier_infernal_stomp_stun_lua:IsStunDebuff()
	return true;
end

function modifier_infernal_stomp_stun_lua:IsDebuff()
	return true;
end

function modifier_infernal_stomp_stun_lua:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_infernal_stomp_stun_lua:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_infernal_stomp_stun_lua:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end