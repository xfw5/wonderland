function Utils:SetupAllAbilitiesAsLevel(hero, level)
	for i = 0, hero:GetAbilityCount() -1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability ~= nil then 
			ability:SetLevel(level)
		end
	end
end

function Utils:AddAbility(unit, pAbilityName)
	local ability = unit:FindAbilityByName(pAbilityName)
	if ability == nil then
		ability = unit:AddAbility(pAbilityName)
	end

	return ability
end