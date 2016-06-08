modifier_passive_fly_vision_lua = class ({})

if IsServer() then 
	function modifier_passive_fly_vision_lua:CheckState( )
		local state = {
			[MODIFIER_STATE_FLYING] = true;
			[MODIFIER_STATE_ATTACK_IMMUNE] = true;
			[MODIFIER_STATE_INVISIBLE] = true;
			[MODIFIER_STATE_UNSELECTABLE] = true;
			[MODIFIER_STATE_INVULNERABLE] = true;
			[MODIFIER_STATE_ROOTED] = true;
			[MODIFIER_STATE_NO_HEALTH_BAR] = false;
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true;
			[MODIFIER_STATE_NO_TEAM_SELECT] = true;
			[MODIFIER_STATE_NOT_ON_MINIMAP] = true;
		}

		return state
	end
end