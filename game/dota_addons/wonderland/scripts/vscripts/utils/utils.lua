if Utils == nil then 
	Utils = class ({})
end

require("utils/utils_item")
require("utils/utils_ability")

function Utils:Wprint(msg)
	print("[Wonderland]" .. msg)
end

function Utils:GetInfernalModel(pszName)
	for k, v in pairs(_G.GameConfig.infernal_hero_model) do
		if pszName == k then
			return v
		end
	end
end

function Utils:GetEntModel(pszName)
	return _G.GameConfig.ent_hero_model[pszName];
end

function Utils:GetEntBuildAbilityItem()
	return _G.GameConfig.ent_spawn_items;
end

function Utils:CreateEntForPlayer(hPlayer)
	return CreateHeroForPlayer(Utils:GetEntModel('Normal'), hPlayer)
end

function Utils:ReplaceEntHeroWithPlayer(hPlayer)
	Utils:ReplaceHeroWithPlayer(player:GetPlayerID(), Utils:GetEntModel('Normal'))
end

function Utils:ReplaceEntJailHeroWithPlayer(hPlayer)
	Utils:ReplaceHeroWithPlayer(player:GetPlayerID(), Utils:GetEntModel('Jail'))
end

function Utils:ReplaceHeroWithPlayer(hPlayer, pszHeroClass)
	local playerID = hPlayer:GetPlayerID()
	local hero = hPlayer:GetAssignedHero()
	local gold = hPlayer:GetGold(playerID)
	local xp = hero:GetCurrentXP()

	player:ReplaceHeroWith(playerID, pszHeroClass, gold, xp)
end

function Utils:DestroyTreesAroundPoint(vPosition, flRadius, bFullCollision)
	GridNav:DestroyTreesAroundPoint(vPosition, flRadius, bFullCollision)
end

function Utils:GetChannelTimeFlow(ability)
	return GameRules:GetGameTime() - ability:GetChannelStartTime()
end