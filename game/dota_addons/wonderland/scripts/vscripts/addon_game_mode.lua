
require("lib/timers")
require("lib/buildingHelper")
require("mechanics/Players")
require("utils/utils")
require("Wonderland")

function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	PrecacheResource( "particle_folder", "particles/units", context )
	
	PrecacheUnitByNameSync("npc_building_scout_tower", context);
end

-- Create the game mode when we activate
function Activate()
	GameRules.WonderlandGM = WonderlandGM()
	GameRules.WonderlandGM:InitGameMode()
end