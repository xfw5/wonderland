function BuildingScoutTower( keys )
	local point = keys.target_points[1];
	local owner = keys.caster:GetPlayerOwner();
	local hero = owner:GetAssignedHero()
	local playerID = keys.caster:GetPlayerOwnerID();
	local team = owner:GetTeamNumber()

	local building = CreateUnitByName(keys.UnitName, point, false, hero, hero, team)
	building:SetControllableByPlayer(playerID, true);
	building:SetTeam(team);
	building:SetOwner(hero);
	building:SetHealth(1);
end