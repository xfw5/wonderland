modifier_out_of_game = class ( { })

if IsServer() then
	function modifier_out_of_game:CheckState( )
		local state = {
			-- out of game no working?
			[MODIFIER_STATE_OUT_OF_GAME] = true; 

			[MODIFIER_STATE_NO_HEALTH_BAR] = true;
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true;
			[MODIFIER_STATE_INVULNERABLE] = true;
			[MODIFIER_STATE_UNSELECTABLE] = true;
			[MODIFIER_STATE_DISARMED] = true;
		}

		return state
	end
end