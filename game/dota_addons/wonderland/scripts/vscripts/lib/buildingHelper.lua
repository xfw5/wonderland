if BuildingHelper == nil then
	BuildingHelper = class ({})
end

function BuildingHelper:CreateBuilding(owner, vLocation, onbuildingStart, onBuildingComplete, params)
	local playerID = owner:GetPlayerID()
	local hero = owner:GetAssignedHero()
	local team = owner:GetTeam()

	local building = CreateUnitByName(params['UNIT_NAME'], vLocation, false, hero, hero, team);
	building:SetControllableByPlayer(playerID, true);
	building:SetTeam(team);
	building:SetOwner(hero);

	BuildingHelper:PrepareBuidling(building, onbuildingStart, onBuildingComplete, params)
	return BuildingHelper:ConstructBuilding(hero, building)
end

function BuildingHelper:PrepareBuidling(building, onbuildingStart, onBuildingComplete, params)
	Utils:SetupAllAbilitiesAsLevel(building, 0)
	
	building:SetHealth(1);

	Utils:AddAbility(building, "passive_construction_building_lua"):SetLevel(1)

	building.buildProcess = 0
	building.buildingCompelted = false
	building.buildInterrupted = false
	building.buildTime = params['BUILD_TIME']
	building.buildSize = params['BUILD_SIZE']
	building.buildCost = params['BUILD_COST']
	building.particleName = params['BUILD_PARTICLE']

	if onbuildingStart ~= nil then
		onbuildingStart(building)
	end

	if onBuildingComplete ~= nil then
		building.onBuildingComplete = onBuildingComplete
	end
end

function BuildingHelper:ConstructBuilding(owner, building)
	Timers:CreateTimer(function() 
		return BuildingHelper:BuildingProcessor(owner, building)
	end)

	building.buildParticle = ParticleManager:CreateParticle(building.particleName, PATTACH_ABSORIGIN, owner)
	ParticleManager:SetParticleControl(building.buildParticle, 0, building:GetAbsOrigin())

	return building
end

function BuildingHelper:OnBuildingComplete(owner, building)
	if building.onBuildingComplete ~= nil then
		building.onBuildingComplete(building)
	end

	building:RemoveAbility("passive_construction_building_lua")

	Utils:SetupAllAbilitiesAsLevel(building, 1)

	if building.buildParticle ~= nil then
		ParticleManager:DestroyParticle(building.buildParticle, false)
		building.buildParticle = nil
	end

	building.buildingCompelted = true
end

function BuildingHelper:BuildingProcessor(owner, building)
	local processDelta = 0.1;

	building.buildProcess = building.buildProcess + processDelta;
	local percent = building.buildProcess / building.buildTime;
	local hp = math.ceil(percent * building:GetMaxHealth());
	building:ModifyHealth(hp, nil, true, 0);

	if percent >= 1 then
			BuildingHelper:OnBuildingComplete(owner, building);
	else
		if building.buildInterrupted then
	    	building.buildInterrupted = false;
	    else
	    	return processDelta;
	    end
	end  
end