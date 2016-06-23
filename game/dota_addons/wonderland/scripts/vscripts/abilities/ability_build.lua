LinkLuaModifier("modifier_passive_construction_building_lua", "modifier/modifier_passive_construction_building_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_passive_building_lua", "modifier/modifier_passive_building_lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_true_sight_lua", "modifier/modifier_true_sight_lua", LUA_MODIFIER_MOTION_NONE)

function OnBuildingAction( keys )
	local location = keys.target_points[1]
	local owner = keys.caster:GetPlayerOwner()
	local playerID = owner:GetPlayerID()

	local params = {
		UNIT_NAME = keys.UnitName,
		BUILD_TIME = keys.BuildTime,
		BUILD_COST = keys.BuildCost,
		BUILD_SIZE = keys.BuildGridSize,
		BUILD_PARTICLE = keys.BuildParticle,
	}

	if BuildingHelper:IsAreaBlocked(location, keys.BuildGridSize) then
		local gold = PlayerResource:GetGold(playerID);
		PlayerResource:SetGold(playerID, gold + keys.BuildCost, false);
	else
		BuildingHelper:CreateBuilding(owner, location, keys.onBuildingStart, keys.onBuildingComplete, params)
	end
end

function OnBuildingScoutTower( keys )
	keys.onBuildingStart = function (building)
		local location = keys.target_points[1]
		local owner = keys.caster:GetPlayerOwner()
		local dayVision = building:GetDayTimeVisionRange()
		local nightVision = building:GetNightTimeVisionRange()

		keys.fly_vision_creature = Utils:CreateFlyingDummy(location, owner, dayVision, nightVision)
	end

	keys.onBuildingComplete = function (building)
		building:AddNewModifier(building, nil, "modifier_passive_building_lua", nil)
		keys.fly_vision_creature:AddNewModifier(building, nil, "modifier_true_sight_lua", nil)

		ParticleManager:CreateParticle("particles/neutral_fx/roshan_spawn.vpcf", PATTACH_ABSORIGIN, building)
		ParticleManager:SetParticleControl(building.buildParticle, 0, building:GetAbsOrigin())
	end

	OnBuildingAction(keys)
end

function DebugBuildingGrid(keys)
	pos = keys.target_points[1]
	--[[local print(pos)
	local gridX = GridNav:WorldToGridPosX(pos.x);
	local gridY = GridNav:WorldToGridPosY(pos.y);
	local cell = BuildingHelper:VectorToTile( Vector(pos.x, pos.y, Z_HEIGHT) );

	BuildingHelper:DrawCell( pos, Vector(50, 50, 50), 0, 9999 );
--]]
	BuildingHelper:DebugGrids(pos, 5);
end

passive_building_lua = class ({})
LinkLuaModifier("modifier_passive_building_lua", "modifier/modifier_passive_building_lua", LUA_MODIFIER_MOTION_NONE)

function passive_building_lua:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	caster:AddNewModifier(caster, slef, "modifier_passive_building_lua", nil)
end

function passive_building_lua:IsHidden()
	return true
end

function Build( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_name = ability:GetAbilityName()
	local abilitykv = BuildingHelper.BuildingsKV[ability_name]

    -- Hold needs an Interrupt
	if caster.bHold then
		caster.bHold = false
		caster:Interrupt()
	end

	building_name = abilitykv.UnitName --Building Helper value

	-- Checks if there is enough custom resources to start the building, else stop.
	local unit_table = GameRules.UnitsKV[building_name]
	local build_time = abilitykv.BuildTime
	local gold_cost = abilitykv.BuildCost
	local lumber_cost = abilitykv.LumberCost
	local buildGridSize = abilitykv.BuildGridSize
	local buildSize = buildGridSize * 64

	local hero = caster:GetPlayerOwner():GetAssignedHero()
	local playerID = hero:GetPlayerID()
	local player = PlayerResource:GetPlayer(playerID)	
	local teamNumber = hero:GetTeamNumber()

	-- If the ability has an AbilityGoldCost, it's impossible to not have enough gold the first time it's cast
	-- Always refund the gold here, as the building hasn't been placed yet
	hero:ModifyGold(gold_cost, false, 0)

	if not Players:HasEnoughLumber( playerID, lumber_cost ) then
		return
	end

    -- Makes a building dummy and starts panorama ghosting
	BuildingHelper:AddBuilding(keys, abilitykv)

	-- Additional checks to confirm a valid building position can be performed here
	keys:OnPreConstruction(function(vPos)
       	-- If not enough resources to queue, stop
		if not Players:HasEnoughGold( playerID, gold_cost ) then
       		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_not_enough_gold")
			return false
		end

       	if not Players:HasEnoughLumber( playerID, lumber_cost ) then
       		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_not_enough_lumber")
			return false
		end

		return true
    end)

	-- Position for a building was confirmed and valid
    keys:OnBuildingPosChosen(function(vPos)
		
    	-- Spend resources
    	hero:ModifyGold(-gold_cost, false, 0)
    	Players:ModifyLumber( playerID, -lumber_cost)

    	-- Play a sound
    	EmitSoundOnClient("DOTA_Item.ObserverWard.Activate", player)

    	-- Move the units away from the building place
		local units = FindUnitsInRadius(teamNumber, vPos, nil, buildSize, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, FIND_ANY_ORDER, false)
	end)

    -- The construction failed and was never confirmed due to the gridnav being blocked in the attempted area
	keys:OnConstructionFailed(function()
		local name = player.activeBuilding
		Utils:BTPrint("Failed placement of " .. name)
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
	end)

	-- Cancelled due to ClearQueue
	keys:OnConstructionCancelled(function(work)
		local name = work.name
		Utils:BTPrint("Cancelled construction of " .. name)

		-- Refund resources for this cancelled work
		if work.refund then
			hero:ModifyGold(gold_cost, false, 0)
    		Players:ModifyLumber( playerID, lumber_cost)
    	end
	end)

	-- A building unit was created
	keys:OnConstructionStarted(function(unit)
		Utils:BTPrint("Started construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
		-- Play construction sound

		-- Store the Build Time, Gold Cost and secondary resource the building 
	    -- This is necessary for repair to know what was the cost of the building and use resources periodically
	    unit.GoldCost = gold_cost
	    unit.LumberCost = lumber_cost
	    unit.BuildTime = build_time

	    -- Units can't attack while building
	    unit.original_attack = unit:GetAttackCapability()
		unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)

		-- Give item to cancel
		--local item = CreateItem("item_building_cancel", playersHero, playersHero)
		--unit:AddItem(item)

		-- FindClearSpace for the builder
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
		--caster:AddNewModifier(caster, nil, "modifier_phased", {duration=0.03})

    	-- Remove invulnerability on npc_dota_building baseclass
    	--unit:RemoveModifierByName("modifier_invulnerable")

    	-- Particle effect
    	--ApplyModifier(unit, "modifier_construction")

    	-- Check the abilities of this building, disabling those that don't meet the requirements
    	--CheckAbilityRequirements( unit, player )

		-- Add the building handle to the list of structures
		table.insert(player.structures, unit)
	end)

	-- A building finished construction
	keys:OnConstructionCompleted(function(unit)
		Utils:BTPrint("Completed construction of " .. unit:GetUnitName() .. " " .. unit:GetEntityIndex())
		
		-- Play construction complete sound

		-- Give the unit their original attack capability
		unit:SetAttackCapability(unit.original_attack)

		-- Let the building cast abilities
		--unit:RemoveModifierByName("modifier_construction")

		-- Remove item_building_cancel
        --[[for i=0,5 do
            local item = unit:GetItemInSlot(i)
            if item then
            	if item:GetAbilityName() == "item_building_cancel" then
            		item:RemoveSelf()
                end
            end
        end--]]

		local building_name = unit:GetUnitName()
		local builders = {}
		if unit.builder then
			table.insert(builders, unit.builder)
		elseif unit.units_repairing then
			builders = unit.units_repairing
		end

		-- Add 1 to the player building tracking table for that name
		if not player.buildings[building_name] then
			player.buildings[building_name] = 1
		else
			player.buildings[building_name] = player.buildings[building_name] + 1
		end

		-- Update the abilities of the builders and buildings
    	--[[for k,units in pairs(player.units) do
    		CheckAbilityRequirements( units, player )
    	end

    	for k,structure in pairs(player.structures) do
    		CheckAbilityRequirements( structure, player )
    	end--]]

	end)

	-- These callbacks will only fire when the state between below half health/above half health changes.
	-- i.e. it won't fire multiple times unnecessarily.
	keys:OnBelowHalfHealth(function(unit)
		Utils:BTPrint("[BH] " .. unit:GetUnitName() .. " is below half health.")
				
		local item = CreateItem("item_apply_modifiers", nil, nil)
    	item:ApplyDataDrivenModifier(unit, unit, "modifier_onfire", {})
    	item = nil

	end)

	keys:OnAboveHalfHealth(function(unit)
		Utils:BTPrint("[BH] " ..unit:GetUnitName().. " is above half health.")

		unit:RemoveModifierByName("modifier_onfire")
		
	end)
end
