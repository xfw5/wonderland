function ProviderFoWWithTrueSight(keys)
	local ability = keys.ability;
	local teamNum = keys.caster:GetTeamNumber()
	local view_range = ability:GetSpecialValueFor("view_range")
	local view_duration = ability:GetSpecialValueFor("view_duration")
	
	AddFOWViewer(keys.caster:GetTeamNumber(), ability:GetCursorPosition(), view_range, view_duration, false)

	keys.caster:AddNewModifier(keys.caster, ability, "modifier_true_sight_lua", {Duration = view_duration})
end