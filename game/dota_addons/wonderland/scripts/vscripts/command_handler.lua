function WonderlandGM:SpawnEnt()

end

function WonderlandGM:SpawnInfernal( )
	local cmdPlayer = Convars:GetCommandClient()
	if cmdPlayer then
		local playerID = cmdPlayer:GetPlayerID()
		if playerID ~= nil and playerID ~= -1 then
			local hero = cmdPlayer:GetAssignedHero()
			local infernal = CreateUnitByName( "npc_dota_creature_infernal", Vector(0,0,0), true, hero, hero, cmdPlayer:GetTeamNumber() )
			infernal:SetOwner(hero)
			infernal:SetControllableByPlayer(playerID, true)
		end
	end
end