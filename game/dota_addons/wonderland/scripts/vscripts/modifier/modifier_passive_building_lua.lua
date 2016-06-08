modifier_passive_building_lua = class ({})

if IsServer() then
	function modifier_passive_building_lua:IsPurgable()
		return false
	end

	function modifier_passive_building_lua:IsPassive()
		return true
	end

	function modifier_passive_building_lua:IsHidden()
		return false
	end

	function modifier_passive_building_lua:CheckState()
		local state = {
			[MODIFIER_STATE_STUNNED] = true;
			[MODIFIER_STATE_ROOTED] = true;
			[MODIFIER_STATE_FROZEN] = true;
		}

		return state
	end
end