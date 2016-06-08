modifier_tower_lua = class ({})

if IsServer() then 
	function modifier_tower_lua:CheckState( )
		local state = {
			[MODIFIER_STATE_ROOTED] = true
			[MODIFIER_STATE_STUNNED] = true
			[MODIFIER_STATE_UNSELECTABLE] = true
		}

		return state
	end

	function modifier_tower_lua:IsPurgable()
		return false
	end
end