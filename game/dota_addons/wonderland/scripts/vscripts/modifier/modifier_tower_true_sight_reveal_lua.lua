modifier_tower_true_sight_reveal_lua = class ({})

function modifier_tower_true_sight_reveal_lua:IsHidden()
	return true
end

function modifier_tower_true_sight_reveal_lua:IsDebuff()
	return true
end

function modifier_tower_true_sight_reveal_lua:IsPurgable()
	return false
end

if IsServer()
	function modifier_tower_true_sight_reveal_lua:CheckState()
		local state = {
			[MODIFIER_STATE_INVISIBLE] = false
		}

		return state
	end
end