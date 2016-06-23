-- Wanderland core.
SURVIVE_TIME = 30.0

if WonderlandGM == nil then
	WonderlandGM = class({})
end

require("events_handler")
require("command_handler")

function WonderlandGM:InitGameMode()
	Utils:Wprint("Game mode loading ...")

	WonderlandGM = self

	WonderlandGM:LoadingKV()
	WonderlandGM:SetupGameRules()
	WonderlandGM:HookGameEvents()
	WonderlandGM:RegisterCommands()

	Utils:Wprint("Game mode loading done.");
end

function WonderlandGM:LoadingKV()
	Utils:Wprint('Loading config...')
	_G.GameConfig = LoadKeyValues("scripts/config/game.config")

	GameRules.AbilitiesKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
  	GameRules.UnitsKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")
  	GameRules.ItemsKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")

	Utils:Wprint('Config loading Done')
end

function WonderlandGM:SetupGameRules()
	Mode = GameRules:GetGameModeEntity();

	Mode:SetThink( "OnThink", self, 1 );

	Mode:SetTopBarTeamValuesOverride( true );
	Mode:SetTopBarTeamValuesVisible( false );
	Mode:SetLoseGoldOnDeath( false );
	Mode:SetFogOfWarDisabled( false );
	Mode:SetBuybackEnabled( false );

	GameRules:SetGoldPerTick( 0 );
	GameRules:SetHeroSelectionTime( 0.0 );
	GameRules:SetCustomGameEndDelay( 0 );
	GameRules:SetCustomVictoryMessageDuration( 10 );
	GameRules:SetHideKillMessageHeaders( false );
	GameRules:SetUseUniversalShopMode( false );
	GameRules:SetHeroRespawnEnabled( false );
	GameRules:SetPreGameTime( 30 );
	GameRules:SetTreeRegrowTime((SURVIVE_TIME + 10)*60);
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
end

function WonderlandGM:HookGameEvents()
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(WonderlandGM, 'OnGameRulesChange'), self)
	ListenToGameEvent('team_info', Dynamic_Wrap(WonderlandGM, 'OnTeamInfo'), self)

	ListenToGameEvent('player_spawn', Dynamic_Wrap(WonderlandGM, 'OnPlayerSpwan'), self)
	ListenToGameEvent('player_use', Dynamic_Wrap(WonderlandGM, 'OnplayerUse'), self)
	ListenToGameEvent('player_fullyjoined', Dynamic_Wrap(WonderlandGM, 'OnPlayerFullyJoined'), self)

	ListenToGameEvent('dota_player_kill', Dynamic_Wrap(WonderlandGM, 'OnDotaPlayerKill'), self)
	ListenToGameEvent('dota_player_killed', Dynamic_Wrap(WonderlandGM, 'OnDotaPlayerKilled'), self)
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(WonderlandGM, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(WonderlandGM, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(WonderlandGM, 'OnHeroPicked'), self)

	ListenToGameEvent('dota_chat_first_blood', Dynamic_Wrap(WonderlandGM, 'OnChatFirstBlood'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(WonderlandGM, 'OnEntityKilled'), self)
end

function WonderlandGM:RegisterCommands()
	Convars:RegisterCommand( "cmd_spawn_ent", Dynamic_Wrap(WonderlandGM, 'SpawnEnt'), "Spawn a ent at origin", 0 )
	Convars:RegisterCommand( "cmd_spawn_infernal", Dynamic_Wrap(WonderlandGM, 'SpawnInfernal'), "Spawn a infernal at origin", 0 )
end

function WonderlandGM:OnGameRulesChange( keys )
	local state = GameRules:State_Get()

	if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		WonderlandGM:OnGRVoting()

	elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
		WonderlandGM:OnGRPreGame()	
	
	elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		WonderlandGM:OnGRStart()
	end
end

function WonderlandGM:OnGRVoting()
	BuildingHelper:Init()
end

function WonderlandGM:OnGRPreGame()

	local player = PlayerResource:GetPlayer(0)
	local hero = Utils:CreateEntForPlayer(player);

	hero:SetAbilityPoints(0)
	Utils:SetupAllAbilitiesAsLevel(hero, 1)
	Utils:EquipItemsWithName(hero, Utils:GetEntBuildAbilityItem())
end

function WonderlandGM:OnGRStart()
	-- body
end

-- Evaluate the state of the game
function WonderlandGM:OnThink()
	--wprint('on Think')
	--print(debug.getinfo(1, "n").name);
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end