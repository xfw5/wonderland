modifier_infernal_chain_lightning_invisibility_lua = class ({})

function modifier_infernal_chain_lightning_invisibility_lua:IsHidden()
	return false;
end

function modifier_infernal_chain_lightning_invisibility_lua:IsPurgable()
	return false;
end

function modifier_infernal_chain_lightning_invisibility_lua:checkState()
	local state = {
		[MODIFIER_STATE_INVISIBLE] = true,
	}

	return state
end