if not BuildingHelper then
	BuildingHelper = class ({})
	BuildingAbilities = class({})
end

-- Build-in grid size base on hammer.
GRID_SIZE = 64
GRID_TILE = 1
BUILDING_DEBUG = 1
GHOST_MODEL_ALPHA = 0.02*255
GHOST_MODEL_COLOR = Vector(0,255,0)
OUT_OF_WROLD_LOCATION = Vector(100000, 0, 0)

function BuildingHelper:Init()
	BuildingHelper.buildingsKV = { }
	BuildingHelper.previewBuildings = { }
	BuildingHelper.ghostBuildings = { }

	BuildingHelper:FilterBuildingsKV(GameRules.AbilitiesKV, BuildingHelper.buildingsKV)
	BuildingHelper:FilterBuildingsKV(GameRules.ItemsKV, BuildingHelper.buildingsKV)

	BuildingHelper:InitGrids()

	LinkLuaModifier("modifier_out_of_game", "modifier/modifier_out_of_game", LUA_MODIFIER_MOTION_NONE)

	CustomGameEventManager:RegisterListener( "building_helper_build_command", Dynamic_Wrap(BuildingHelper, "OnBuildCommand"))
	CustomGameEventManager:RegisterListener( "building_helper_cancel_command", Dynamic_Wrap(BuildingHelper, "OnCancelCommand"))
end

function BuildingHelper:ActiveWithPreviewBuilding( keys , abilityKV)
	-- Callbacks
    callbacks = BuildingHelper:SetCallbacks(keys)
    local builder = keys.caster
    local ability = keys.ability
    local abilName = ability:GetAbilityName()

    -- Prepare the builder, if it hasn't already been done
    if not builder.buildingQueue then  
        BuildingHelper:InitializeBuilder(builder)
    end

    local size = abilityKV.BuildGridSize
    local unitName = abilityKV.UnitName

    -- Set the active variables and callbacks
    local playerID = builder:GetMainControllingPlayer()
    local player = PlayerResource:GetPlayer(playerID)
    player.activeBuilder = builder
    player.activeBuildingName = unitName
    player.activeBuildingKV = abilityKV
    player.activeCallbacks = callbacks

    player.activePreviewBuilding = BuildingHelper:GetOrCreatePreviewModel(unitName)

    local event = { state = "active", size = size, scale = 1.0, ghostEntIndex = player.activePreviewBuilding:GetEntityIndex(), builderIndex = builder:GetEntityIndex() }
    CustomGameEventManager:Send_ServerToPlayer(player, "building_helper_enable", event)
end

function BuildingHelper:OnCancelCommand(args)
    local playerID = args['PlayerID']
    local player = PlayerResource:GetPlayer(playerID)
    player.activeBuilding = nil

    print(player.activeBuilder)
    if not player.activeBuilder or not IsValidEntity(player.activeBuilder) then
        return
    end
    BuildingHelper:ClearQueue(player.activeBuilder)
end

-- Detects a Left Click with a builder through Panorama
function BuildingHelper:OnBuildCommand(args)
	local x = args['X']
    local y = args['Y']
    local z = args['Z']
    local location = Vector(x, y, z)

    local player = PlayerResource:GetPlayer(args['PlayerID'])
    local queue = Utils:ToBool(args['Queue'])
    local builder = player.activeBuilder

    Utils:BTPrint("On build command, queue: ".. tostring(queue))

    -- Cancel current repair
    if builder:HasModifier("modifier_builder_repairing") and not queue then
        local repair_ability = builder:FindAbilityByName("repair")
        local event = {}
        event.caster = builder
        event.ability = repair_ability
        BuilderStopRepairing(event)
    end

    BuildingHelper:QueueBuilding(player, builder, location, queue)
end

function BuildingHelper:QueueBuilding(player, builder, vLocation, bQueued )
    local buildingName = player.activeBuildingName
    local buildingKV = player.activeBuildingKV
    local size = 1--activeBuildingKV.BuildGridSize
    local callbacks = player.activeCallbacks

    BuildingHelper:SnapToGrid(size, vLocation)
  	if BuildingHelper:IsAreaBlocked(vLocation, size) then
  		if callbacks.onConstructionFailed then
  			callbacks.onConstructionFailed()
  		end
  	end

    if callbacks.onPreConstruction then
        local result = callbacks.onPreConstruction(vLocation)
        if result == false then
            return
        end
    end

    -- Position chosen is initially valid, send callback to spend gold
    callbacks.onBuildingPosChosen(vLocation)

    -- If the ability wasn't queued, override the building queue
    if not bQueued then
        BuildingHelper:ClearQueue(builder)
    end

	local ghostBuilding = BuildingHelper:CreateGhost(buildingName, vLocation)
    local work = 
    {
        location = vLocation,
      	unitName = buildingName,
      	ghostBuilding = ghostBuilding,
      	ghostPariticelIndex = modelParticle,
      	buildingKV = buildingKV,
      	callbacks = callbacks
  	}
    table.insert(builder.buildingQueue, work)

    -- If the builder doesn't have a current work, start the queue
    -- Extra check for builder-inside behaviour, those abilities are always queued
    if builder.work == nil then
    	Utils:BTPrint("Builder doesn't have work to do, start right away")
        builder.work = builder.buildingQueue[1]
        BuildingHelper:ProcessQueue(builder)
    else
        Utils:BTPrint("Work was queued, builder already has work to do")
        BuildingHelper:PrintQueue(builder)
    end
end

function BuildingHelper:ProcessQueue(builder)
	if (builder.move_to_build_timer) then 
		Timers:RemoveTimer(builder.move_to_build_timer) 
	end

	if builder.buildingQueue and #builder.buildingQueue > 0 then
        BuildingHelper:PrintQueue(builder)

        local work = builder.buildingQueue[1]
        table.remove(builder.buildingQueue, 1) --Pop

        local buildingKV = work.buildingKV
        local castRange = buildingKV.AbilityCastRange
        local callbacks = work.callbacks
        local location = work.location
        builder.work = work

        builder.move_to_build_timer = Timers:CreateTimer(0.03, function()
            builder:MoveToPosition(location)
            if not IsValidEntity(builder) or not builder:IsAlive() then return end
            builder.state = "moving_to_build"

            local distance = (location - builder:GetAbsOrigin()):Length2D()
            if distance > castRange then
                return 0.03
            else
                builder:Stop()
                
                -- Self placement goes directly to the OnConstructionStarted callback
                if work.unitName == builder:GetUnitName() then
                    local callbacks = work.callbacks
                    if callbacks.onConstructionStarted then
                        callbacks.onConstructionStarted(builder)
                    end

                else
                    BuildingHelper:StartBuilding(builder)
                end
                return
            end
        end)    
    
    else
        -- Set the builder work to nil to accept next work directly
        Utils:BTPrint("Builder "..builder:GetUnitName().." "..builder:GetEntityIndex().." finished its building Queue")
        builder.state = "idle"
        builder.work = nil
    end
end

function BuildingHelper:StartBuilding(builder)
    local playerID = builder:GetMainControllingPlayer()
    local work = builder.work
    local callbacks = work.callbacks
    local unitName = work.unitName
    local location = work.location
    local player = PlayerResource:GetPlayer(playerID)
    local playerHero = PlayerResource:GetSelectedHeroEntity(playerID)
    local buildingKV = work.buildingKV
    local gridSize = buildingKV.BuildGridSize
    local buildTime = buildingKV.BuildTime

    BuildingHelper:RemoveGhost(work)

	if BuildingHelper:IsAreaBlocked(location, gridSize) then
  		if callbacks.onConstructionFailed then
  			callbacks.onConstructionFailed()
  		end

        -- Remove the model particle and Advance Queue
        BuildingHelper:ProcessQueue(builder)
        BuildingHelper:ClearWorkParticles(work)

        -- Building canceled, refund resources
        work.refund = true
        callbacks.onConstructionCancelled(work)
        return
    end

    Utils:BTPrint("Initializing Building Entity: "..unitName.." at "..Utils:VectorToString(location))

    -- Mark this work in progress, skip refund if cancelled as the building is already placed
    work.inProgress = true

    local building = CreateUnitByName(unitName, location, false, playerHero, palyer, player:GetTeamNumber())
    local regen = building:GetBaseHealthRegen()
    building:SetBaseHealthRegen(0)

    -- Start construction
    if callbacks.onConstructionStarted then
        callbacks.onConstructionStarted(building)
    end

    building.buildingProgress = 0
    building.buildingProgressTimer = Timers:CreateTimer(function()
    	local progressDelta = 0.1
    	if IsValidEntity(building) and building:IsAlive() then
			building.buildingProgress = building.buildingProgress + progressDelta;
			local percent = building.buildingProgress / buildTime;
			local currentHP = math.ceil(percent * building:GetMaxHealth());
			building:ModifyHealth(currentHP, nil, true, 0);

			if percent >= 1 and callbacks.onConstructionCompleted then
				building:SetBaseHealthRegen(regen)
				callbacks.onConstructionCompleted(building)
			else
				if building.buildInterrupted then
			    	building.buildInterrupted = false;
			    else
			    	return progressDelta;
			    end
			end
		end
	end)

    building.fireEffect = GameRules.UnitsKV[unitName]["FireEffect"]
    building.fireEffectAttachPoint = GameRules.UnitsKV[unitName]["FireEffectAttachPoint"]
    building.onBelowHalfHealthProc = false
    building.healthChecker = Timers:CreateTimer(.2, function()
        if IsValidEntity(building) and building:IsAlive() then
            local health_percentage = building:GetHealthPercent() * 0.01
            local belowThreshold = health_percentage < 0.5
            if belowThreshold and not building.onBelowHalfHealthProc and building.state == "complete" then
                if building.fireEffect then
                    if building.fireEffectAttachPoint then
                        building.fireEffectParticle = ParticleManager:CreateParticle(building.fireEffect, PATTACH_CUSTOMORIGIN_FOLLOW, building)
                        ParticleManager:SetParticleControlEnt(building.fireEffectParticle, 0, building, PATTACH_POINT_FOLLOW, building.fireEffectAttachPoint, building:GetAbsOrigin(), true)
                    else
                        building.fireEffectParticle = ParticleManager:CreateParticle(building.fireEffect, PATTACH_ABSORIGIN_FOLLOW, building)
                    end
                end
            
                callbacks.onBelowHalfHealth(building)
                building.onBelowHalfHealthProc = true
            elseif not belowThreshold and building.onBelowHalfHealthProc and building.state == "complete" then
                if building.fireEffect then
                    ParticleManager:DestroyParticle(building.fireEffectParticle, false)
                end

                callbacks.onAboveHalfHealth(building)
                building.onBelowHalfHealthProc = false
            end
        else
            return nil
        end
        return .2
    end)

    BuildingHelper:ProcessQueue(builder)

    if work.particleIndex then 
    	ParticleManager:DestroyParticle(work.particleIndex, true)
    end
end

function BuildingHelper:CreateBuilding(owner, vLocation, onbuildingStart, onBuildingComplete, params)
	local playerID = owner:GetPlayerID()
	local hero = owner:GetAssignedHero()
	local team = owner:GetTeam()

	BuildingHelper:SnapToGrid(GRID_TILE, vLocation)
	BuildingHelper:BlockArea(vLocation, params['BUILD_SIZE'], BUILDING_DEBUG)

	local building = CreateUnitByName(params['UNIT_NAME'], vLocation, false, hero, hero, team);
	building:SetControllableByPlayer(playerID, true);
	building:SetTeam(team);
	building:SetOwner(hero);
	building:SetHullRadius(params['BUILD_SIZE'] * GRID_SIZE * 0.5)

	BuildingHelper:PrepareBuidling(building, onbuildingStart, onBuildingComplete, params)
	Utils:PushAwayUnits(owner:GetTeamNumber(), vLocation, BuildingHelper:GetRadiusWithGridSize(params['BUILD_SIZE']))
	return BuildingHelper:ConstructBuilding(hero, building)
end

function BuildingHelper:PrepareBuidling(building, onbuildingStart, onBuildingComplete, params)
	Utils:SetupAllAbilitiesAsLevel(building, 0)
	
	building:SetHealth(1);

	building:AddNewModifier(building, nil, "modifier_passive_construction_building_lua", {Duration = params['BUILD_TIME']})

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
	local currentHP = math.ceil(percent * building:GetMaxHealth());
	building:ModifyHealth(currentHP, nil, true, 0);

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

function BuildingHelper:ClearQueue(builder)

    local work = builder.work
    builder.work = nil
    builder.state = "idle"

    -- Skip if there's nothing to clear
    if not builder.buildingQueue or (not work and #builder.buildingQueue == 0) then
        return
    end

    Utils:BTPrint("ClearQueue "..builder:GetUnitName().." "..builder:GetEntityIndex())

    -- Main work  
    if work and work.particleIndex then
        ParticleManager:DestroyParticle(work.particleIndex, true)

        -- Only refund work that hasn't been placed yet
        if not work.inProgress then
            work.refund = true
        end

        if work.ghostBuilding then
        	UTIL_Remove(work.ghostBuilding)
        end

        if work.callbacks.onConstructionCancelled ~= nil then
            work.callbacks.onConstructionCancelled(work)
        end
    end

    -- Queued work
    while #builder.buildingQueue > 0 do
        work = builder.buildingQueue[1]
        work.refund = true --Refund this
        if work.particleIndex then 
          ParticleManager:DestroyParticle(work.particleIndex, true)
        end
        
        table.remove(builder.buildingQueue, 1)

        if work.ghostBuilding then
        	UTIL_Remove(work.ghostBuilding)
        end

        if work.callbacks.onConstructionCancelled ~= nil then
            work.callbacks.onConstructionCancelled(work)
        end
    end
end

function BuildingHelper:PrintQueue(builder)
    Utils:BTPrint("Builder Queue of "..builder:GetUnitName().. " "..builder:GetEntityIndex())
    local buildingQueue = builder.buildingQueue
    for i,v in pairs(buildingQueue) do
        Utils:BTPrint(" #"..i..": "..buildingQueue[i]["unitName"].." at "..Utils:VectorToString(buildingQueue[i]["location"]))
    end
end

function BuildingHelper:FilterBuildingsKV(kv, result)
	for name,info in pairs(kv) do
        if type(info) == "table" then
            local isBuilding = info["BuildGridSize"]
            if isBuilding then
                if result[name] then
                    Utils:BTPrint("Error: There's more than 2 entries for "..name)
                else
                    result[name] = info
                end
            end
        end
    end
end

function BuildingHelper:InitGrids()
	self.gridsBlocked = {}

	local worldMin = Vector(GetWorldMinX(), GetWorldMinY(), 0)
    local worldMax = Vector(GetWorldMaxX(), GetWorldMaxY(), 0)

    local boundX1 = GridNav:WorldToGridPosX(worldMin.x)
    local boundX2 = GridNav:WorldToGridPosX(worldMax.x)
    local boundY1 = GridNav:WorldToGridPosY(worldMin.y)
    local boundY2 = GridNav:WorldToGridPosY(worldMax.y)

	for x=boundX1, boundX2 do
		for y=boundY1, boundY2 do

			local gridX = GridNav:GridPosToWorldCenterX(x);
			local gridY = GridNav:GridPosToWorldCenterX(y);
			local gridPos = Vector(gridX, gridY, 0);

			if GridNav:IsTraversable(gridPos) == false or 
				GridNav:IsNearbyTree(gridPos, GRID_SIZE, false) or 
				GridNav:IsBlocked(gridPos) then
				BuildingHelper:BlockGrid(x, y);
			end
		end
	end
end

function BuildingHelper:GetOrCreatePreviewModel(unitName)
	if BuildingHelper.previewBuildings[unitName] then
        return BuildingHelper.previewBuildings[unitName]
    else
        Utils:BTPrint("Add preview building "..unitName)
        local preview = CreateUnitByName(unitName, OUT_OF_WROLD_LOCATION, false, nil, nil, 0)
        preview:SetAbsOrigin(OUT_OF_WROLD_LOCATION)
        preview:AddEffects(EF_NODRAW)
        preview:AddNewModifier(preview, nil, "modifier_out_of_game", {})
        BuildingHelper.previewBuildings[unitName] = preview
        return preview
    end
end

function BuildingHelper:CreateGhost(unitName, vLocation)
	local ghost = CreateUnitByName(unitName, vLocation, false, nil, nil, 0)
    ghost:AddNewModifier(ghost, nil, "modifier_out_of_game", {})
    
    local modelParticle = ParticleManager:CreateParticleForPlayer("particles/buildinghelper/ghost_model.vpcf", PATTACH_ABSORIGIN, ghost, player)
    ParticleManager:SetParticleControlEnt(modelParticle, 1, ghost, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", ghost:GetAbsOrigin(), true) -- Model attach          
    ParticleManager:SetParticleControl(modelParticle, 2, GHOST_MODEL_COLOR) 
    ParticleManager:SetParticleControl(modelParticle, 3, Vector(GHOST_MODEL_ALPHA,0,0)) -- Alpha
    ParticleManager:SetParticleControl(modelParticle, 4, Vector(1,0,0)) -- Scale

    ghost.modelParticle = modelParticle
    ghost:NoHealthBar()
    ghost:SetDayTimeVisionRange(0)
    ghost:SetNightTimeVisionRange(0)

    return ghost
end

function BuildingHelper:RemoveGhost(work)
	if work.ghostBuilding then
		UTIL_Remove(work.ghostBuilding)
	end
end

function BuildingHelper:InitializeBuilder(builder)
    Utils:BTPrint("InitializeBuilder "..builder:GetUnitName().." "..builder:GetEntityIndex())

    if not builder.buildingQueue then
        builder.buildingQueue = {}
    end

    -- Store the builder entity indexes on a net table
    --CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = true })
end

function BuildingHelper:RemoveBuilder(builder)
    -- Store the builder entity indexes on a net table
    CustomNetTables:SetTableValue("builders", tostring(builder:GetEntityIndex()), { IsBuilder = false })
end

function BuildingHelper:BlockGrid(x, y, bDebug)
	if self.gridsBlocked[x] == nil then
		self.gridsBlocked[x] = {};
	end

	self.gridsBlocked[x][y] = true;

	if bDebug then
		local pos = Vector(GridNav:GridPosToWorldCenterX(x), GridNav:GridPosToWorldCenterY(y), 0)
		local height = GetGroundHeight(pos, nil)
		BuildingHelper:DrawGrid(Vector(pos.x, pos.y, height), Vector(255, 0, 0), 2, 9999)
	end
end

function BuildingHelper:BlockArea(vLocation, nSize, bDebug)
	local grids = BuildingHelper:GetGridsInRange(vLocation, nSize)

	for _,grid in pairs(grids) do
		BuildingHelper:BlockGrid(grid.x, grid.y, bDebug)
	end
end

function BuildingHelper:IsGridBlocked( x, y)
	if self.gridsBlocked[x] == nil then
		return false
	end

	if self.gridsBlocked[x][y] == nil then
		return false
	end

	return true
end

function BuildingHelper:IsAreaBlocked(vLocation, nSize)
    local grids = BuildingHelper:GetGridsInRange(vLocation, nSize)

	for _,grid in pairs(grids) do
		if BuildingHelper:IsGridBlocked(grid.x, grid.y) then
			return true;
		end
	end

	return false;
end

function BuildingHelper:GetGridsInRange(vLocation, nSize)
	local grids = {};

	local originX = GridNav:WorldToGridPosX(vLocation.x)
    local originY = GridNav:WorldToGridPosY(vLocation.y)
    local halfSize = math.floor(nSize/2)
    local boundX1 = originX + halfSize
    local boundX2 = originX - halfSize
    local boundY1 = originY + halfSize
    local boundY2 = originY - halfSize

    local lowerBoundX = math.min(boundX1, boundX2)
    local upperBoundX = math.max(boundX1, boundX2)
    local lowerBoundY = math.min(boundY1, boundY2)
    local upperBoundY = math.max(boundY1, boundY2)

    if (nSize % 2) == 0 then
        upperBoundX = upperBoundX-1
        upperBoundY = upperBoundY-1
    end
	
	for y = lowerBoundY, upperBoundY do
        for x = lowerBoundX, upperBoundX do
        	table.insert(grids, Vector(x,y,vLocation.z))
        end
    end

    return grids
end

function BuildingHelper:GetRadiusWithGridSize(nSize)
	return nSize * GRID_SIZE;
end

function BuildingHelper:SnapToGrid64(coord)
    return 64*math.floor(0.5+coord/64)
end

function BuildingHelper:SnapToGrid32(coord)
    return 32+64*math.floor(coord/64)
end

function BuildingHelper:SnapToGrid(nTile, location)
    if nTile % 2 ~= 0 then
        location.x = BuildingHelper:SnapToGrid32(location.x)
        location.y = BuildingHelper:SnapToGrid32(location.y)
    else
        location.x = BuildingHelper:SnapToGrid64(location.x)
        location.y = BuildingHelper:SnapToGrid64(location.y)
    end
end

function BuildingHelper:SetCallbacks(keys)
    local callbacks = {}

    function keys:OnPreConstruction(callback)
        callbacks.onPreConstruction = callback -- Return false to abort the build
    end

     function keys:OnBuildingPosChosen(callback)
        callbacks.onBuildingPosChosen = callback -- Spend resources here
    end

    function keys:OnConstructionFailed(callback) -- Called if there is a mechanical issue with the building (cant be placed)
        callbacks.onConstructionFailed = callback
    end

    function keys:OnConstructionCancelled(callback) -- Called when player right clicks to cancel a queue
        callbacks.onConstructionCancelled = callback
    end

    function keys:OnConstructionStarted(callback)
        callbacks.onConstructionStarted = callback
    end

    function keys:OnConstructionCompleted(callback)
        callbacks.onConstructionCompleted = callback
    end

    function keys:OnBelowHalfHealth(callback)
        callbacks.onBelowHalfHealth = callback
    end

    function keys:OnAboveHalfHealth(callback)
        callbacks.onAboveHalfHealth = callback
    end

    return callbacks
end

function BuildingHelper:DrawGrid(vPos, vRGB, fHeightOffset, fDuration)
	vRGB = vRGB or Vector(255, 0, 0);
	fDuration = fDuration or 5;
	fHeightOffset = fHeightOffset or 0;

	vPos.z = vPos.z + fHeightOffset
	local HALF_GRID = GRID_SIZE / 2;

	BuildingHelper:SnapToGrid(GRID_TILE, vPos)

	DebugDrawLine(Vector(vPos.x-HALF_GRID,vPos.y+HALF_GRID,vPos.z), Vector(vPos.x+HALF_GRID,vPos.y+HALF_GRID,vPos.z), vRGB.x, vRGB.y, vRGB.z, false, fDuration);
	DebugDrawLine(Vector(vPos.x-HALF_GRID,vPos.y+HALF_GRID,vPos.z), Vector(vPos.x-HALF_GRID,vPos.y-HALF_GRID,vPos.z), vRGB.x, vRGB.y, vRGB.z, false, fDuration);
	DebugDrawLine(Vector(vPos.x-HALF_GRID,vPos.y-HALF_GRID,vPos.z), Vector(vPos.x+HALF_GRID,vPos.y-HALF_GRID,vPos.z), vRGB.x, vRGB.y, vRGB.z, false, fDuration);
	DebugDrawLine(Vector(vPos.x+HALF_GRID,vPos.y-HALF_GRID,vPos.z), Vector(vPos.x+HALF_GRID,vPos.y+HALF_GRID,vPos.z), vRGB.x, vRGB.y, vRGB.z, false, fDuration);
end

function BuildingHelper:DebugGrids(vPos, nSize)
	local grids = BuildingHelper:GetGridsInRange(vPos, nSize)

	local color = Vector(255,0,0)
	for _,grid in pairs(grids) do
		if BuildingHelper:IsGridBlocked(grid.x, grid.y) then
			color = Vector(255,0,0)
		else
			color = Vector(0,255,0)
		end

		local pos = Vector(GridNav:GridPosToWorldCenterX(grid.x), GridNav:GridPosToWorldCenterY(grid.y), 0)
		local height = GetGroundHeight(pos, nil)
		pos = Vector(pos.x, pos.y, height)	

		BuildingHelper:DrawGrid(pos, color, 2, 9999)
	end
end