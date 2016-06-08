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

function Utils:EmitParticle(particleName, particleAttach, owningEntity, controls, location, lifeTime, destroyImmediately)
	local particle = ParticleManager:CreateParticle(particleName, particleAttach, owningEntity);

	local controls = controls or {0, 1, 2};
	for _,index in pairs(controls) do
		ParticleManager:SetParticleControl(particle, index, location);
	end
	
	if lifeTime ~= nil then
		Timers:CreateTimer({
			endTime = lifeTime,
			callback = function()
				ParticleManager:DestroyParticle(particle, destroyImmediately);
			end
		});
	end

	return particle;
end

LinkLuaModifier("modifier_passive_fly_vision_lua", "modifier/modifier_passive_fly_vision_lua", LUA_MODIFIER_MOTION_NONE)
function Utils:CreateFlyingDummy(vLocation, hPlayer, fDayVision, fNightVision, fDuration)
	local hero = hPlayer:GetAssignedHero()
	local unit = CreateUnitByName("npc_flying_dummy", vLocation, false, hero, hero, hPlayer:GetTeamNumber());

	unit:AddNewModifier(nil, nil, "modifier_passive_fly_vision_lua", nil)

	unit:SetDayTimeVisionRange(fDayVision);
	unit:SetNightTimeVisionRange(fNightVision);

	if duration ~= nil then
		Timers:CreateTimer({
		    endTime = duration,
		    callback = function()
		    	unit:ForceKill(false);
		    end
		 });
	end

	return unit;
end