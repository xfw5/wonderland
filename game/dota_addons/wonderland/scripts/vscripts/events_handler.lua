-- events handler

function WonderlandGM:OnTeamInfo( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnPlayerSpwan( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnPlayerUse( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnPlayerFullyJoined( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnDotaPlayerKill( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnDotaPlayerKilled( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnPlayerLevelUp( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnPlayerLearnedAbility( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnHeroPicked( keys )
	DeepPrintTable(keys)

	Players:Init(keys.player, EntIndexToHScript(keys.heroindex))
end

function WonderlandGM:OnChatFirstBlood( keys )
	DeepPrintTable(keys)
end

function WonderlandGM:OnEntityKilled( keys )
	DeepPrintTable(keys)
end

