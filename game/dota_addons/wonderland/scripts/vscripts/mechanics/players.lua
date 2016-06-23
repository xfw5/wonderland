if not Players then
    Players = class({})
end

function Players:Init( playerID, hero )

    -- Tables
    hero.units = {} -- This keeps the handle of all the units of the player army, to iterate for unlocking upgrades
    hero.structures = {} -- This keeps the handle of the constructed units, to iterate for unlocking upgrades
    hero.heroes = {} -- Owned hero units (not this assigned hero, which will be a fake)
    hero.altar_structures = {} -- Keeps altars linked

    hero.buildings = {} -- This keeps the name and quantity of each building
    hero.upgrades = {} -- This kees the name of all the upgrades researched, so each unit can check and upgrade itself on spawn

    hero.idle_builders = {} -- Keeps indexes of idle builders to send to the panorama UI
    hero.flags = {} -- Particle flags for each building currently selected
    
    -- Resource tracking
    hero.gold = 0
    hero.lumber = 0
end

---------------------------------------------------------------

function Players:GetUnits( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.units
end

function Players:GetStructures( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.structures
end

function Players:GetHeroes( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.heroes
end

function Players:GetAltars( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.altar_structures
end

function Players:GetUpgradeTable( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.upgrades
end

function Players:GetBuildingTable( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.buildings
end

function Players:GetIdleBuilders( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.idle_builders
end

-- Returns float with the percentage to reduce income
function Players:GetUpkeep( playerID )
    local food_used = Players:GetFoodUsed(playerID)
    if food_used > 80 then
        return 0.4 -- High Upkeep
    elseif food_used > 50 then
        return 0.7 -- Low Upkeep
    else
        return 1 -- No Upkeep
    end
end

-- Adjusts name inside tools
function Players:GetPlayerName( playerID )
    local playerName = PlayerResource:GetPlayerName(playerID)
    if playerName == "" then playerName = "Player "..playerID end
    return playerName
end

-- For particles
function Players:GetPlayerFlags( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.flags
end

function Players:ClearPlayerFlags( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local flags = Players:GetPlayerFlags( playerID )
    local selected = PlayerResource:GetSelectedEntities(playerID)

    if not flags then return end
    
    for entIndex,particleTable in pairs(flags) do
        local flagParticle = particleTable.flagParticle
        local lineParticle = particleTable.lineParticle

        if flagParticle then
            ParticleManager:DestroyParticle(flagParticle, true)
            flags[entIndex].flagParticle = nil
        end

        if lineParticle then
            ParticleManager:DestroyParticle(lineParticle, true)
            flags[entIndex].lineParticle = nil
        end
    end
end

function Players:GetGold( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero:GetGold()
end

function Players:GetLumber( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return hero.lumber
end

function Players:SetGold( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero:SetGold(value, false)
    hero.gold = value
    --CustomGameEventManager:Send_ServerToPlayer(player, "player_gold_changed", { gold = math.floor(hero.gold) })
end

function Players:SetLumber( playerID, value )
    local player = PlayerResource:GetPlayer(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    
    hero.lumber = value

    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(hero.lumber) })
end
---------------------------------------------------------------

-- Modifies the gold of this player, accepts negative values
function Players:ModifyGold( playerID, gold_value )
    PlayerResource:ModifyGold(playerID, gold_value, false, 0)
end

-- Modifies the lumber of this player, accepts negative values
function Players:ModifyLumber( playerID, lumber_value )
    if lumber_value == 0 then return end

    local current_lumber = Players:GetLumber( playerID )
    local new_lumber = current_lumber + lumber_value

    if lumber_value > 0 then
        Players:SetLumber( playerID, new_lumber )
    else
        if Players:HasEnoughLumber( playerID, math.abs(lumber_value) ) then
            Players:SetLumber( playerID, new_lumber )
        end
    end
end

-- Returns bool
function Players:HasEnoughGold( playerID, gold_cost )
    local gold = Players:GetGold( playerID )

    if not gold_cost or gold >= gold_cost then 
        return true
    else
        SendErrorMessage(playerID, "#error_not_enough_gold")
        return false
    end
end

-- Returns bool
function Players:HasEnoughLumber( playerID, lumber_cost )
    local lumber = Players:GetLumber(playerID)

    if not lumber_cost or lumber >= lumber_cost then 
        return true 
    else
        SendErrorMessage(playerID, "#error_not_enough_lumber")
        return false
    end
end

function Players:EnoughForDoMyPower( playerID, ability )
    local gold_cost = ability:GetGoldCost(ability:GetLevel()) or 0
    local lumber_cost = ability:GetSpecialValueFor("lumber_cost") or 0

    local current_gold = Players:GetGold(playerID)
    local current_lumber = Players:GetLumber(playerID)

    local bCanAffordGoldCost = current_gold >= gold_cost
    local bCanAffordLumberCost = current_lumber >= lumber_cost

    return bCanAffordGoldCost and bCanAffordLumberCost
end

---------------------------------------------------------------

function Players:AddUnit( playerID, unit )
    local playerUnits = Players:GetUnits(playerID)

    table.insert(playerUnits, unit)

    Scores:IncrementUnitsProduced(playerID, unit)
end

function Players:AddHero( playerID, hero )
    local playerHeroes = Players:GetHeroes(playerID)

    table.insert(playerHeroes, hero)

    Scores:AddHeroesUsed(playerID, hero:GetUnitName())
end

function Players:AddStructure( playerID, building )
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    local name = building:GetUnitName()
    buildingTable[name] = buildingTable[name] and (buildingTable[name] + 1) or 1

    table.insert(playerStructures, building)

    Scores:IncrementBuildingsProduced( playerID, unit )
end

function Players:RemoveUnit( playerID, unit )
    -- Attempt to remove from player units
    local playerUnits = Players:GetUnits(playerID)
    local unit_index = getIndexTable(playerUnits, unit)
    if unit_index then
        table.remove(playerUnits, unit_index)
    end
end

function Players:RemoveStructure( playerID, unit )
    local playerStructures = Players:GetStructures(playerID)
    local buildingTable = Players:GetBuildingTable(playerID)

    -- Substract 1 to the player building tracking table for that name
    local unitName = unit:GetUnitName()
    if buildingTable[unitName] then
        buildingTable[unitName] = buildingTable[unitName] - 1
    end

    -- Remove the handle from the player structures
    local playerStructures = Players:GetStructures( playerID )
    local structure_index = getIndexTable(playerStructures, unit)
    if structure_index then 
        table.remove(playerStructures, structure_index)
    end

    if IsAltar(unit) then
        -- Remove from altar structures
        local playerAltars = Players:GetAltars( playerID )
        local altar_index = getIndexTable(playerAltars, unit)
        if altar_index then 
            table.remove(playerAltars, altar_index)
        end
    end
end

-- Returns bool
function Players:HasResearch( playerID, research_name )
    local upgrades = Players:GetUpgradeTable(playerID)
    return upgrades[research_name]
end

-- Returns bool
function Players:HasRequirementForAbility( playerID, ability_name )
    local requirements = GameRules.Requirements
    local buildings = Players:GetBuildingTable(playerID)
    local upgrades = Players:GetUpgradeTable(playerID)
    local requirement_failed = false

    if requirements[ability_name] then

        -- Go through each requirement line and check if the player has that building on its list
        for k,v in pairs(requirements[ability_name]) do

            -- If it's an ability tied to a research, check the upgrades table
            if requirements[ability_name].research then
                if k ~= "research" and (not upgrades[k] or upgrades[k] == 0) then
                    --print("Failed the research requirements for "..ability_name..", no "..k.." found")
                    return false
                end
            else
                --print("Building Name","Need","Have")
                --print(k,v,buildings[k])

                -- If its a building, check every building requirement
                if not buildings[k] or buildings[k] == 0 then
                    --print("Failed one of the requirements for "..ability_name..", no "..k.." found")
                    return false
                end
            end
        end
    end

    return true
end

function Players:HasAltar( playerID )
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    return IsValidAlive(hero.altar) and hero.altar or false
end

---------------------------------------------------------------

-- Return ability handle or nil
function Players:FindAbilityOnStructures( playerID, ability_name )
    local structures = Players:GetStructures(playerID)

    for _,building in pairs(structures) do
        local ability_found = building:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end

-- Return ability handle or nil
function Players:FindAbilityOnUnits( playerID, ability_name )
    local units = Players:GetUnits(playerID)

    for _,unit in pairs(units) do
        local ability_found = unit:FindAbilityByName(ability_name)
        if ability_found then
            return ability_found
        end
    end
    return nil
end


-- Returns int, 0 if the player doesnt have the research
function Players:GetCurrentResearchRank( playerID, research_name )
    local upgrades = Players:GetUpgradeTable(playerID)
    local max_rank = MaxResearchRank(research_name)

    local current_rank = 0
    if max_rank > 0 then
        for i=1,max_rank do
            local ability_len = string.len(research_name)
            local this_research = string.sub(research_name, 1 , ability_len - 1)..i
            if Players:HasResearch(playerID, this_research) then
                current_rank = i
            end
        end
    end

    return current_rank
end

function Players:HeroCount( playerID )
    return #Players:GetHeroes(playerID)
end