modifier_no_unit_collision = class ({ })

if IsServer() then
	function modifier_no_unit_collision:CheckState()
		local state = {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true
		}

		return state
	end
end