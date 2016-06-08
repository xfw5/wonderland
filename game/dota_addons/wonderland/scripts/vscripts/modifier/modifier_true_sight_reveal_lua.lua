modifier_true_sight_reveal_lua = class ({})

if IsServer()
	function modifier_true_sight_reveal_lua:IsHidden()
		return true
	end

	function modifier_true_sight_reveal_lua:IsDebuff()
		return true
	end

	function modifier_true_sight_reveal_lua:IsPurgable()
		return false
	end

	function modifier_true_sight_reveal_lua:GetAttributes()
		return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
	end

	function modifier_true_sight_reveal_lua:CheckState()
		local state = {
			[MODIFIER_STATE_INVISIBLE] = false
		}

		return state
	end
end