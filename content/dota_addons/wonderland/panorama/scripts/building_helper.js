'use strict';

var state = 'disabled';
var size = 0;
var overlay_size = 0;
var grid_alpha = 30;
var model_alpha = 100;
var pressedShift = false;
var modelParticle;
var gridParticles;
var builderIndex;

function OnBuildingStart( params )
{
	$.Msg("On Building Start...")
	
    if (params !== undefined)
    {
        state = params.state;
        size = params.size;
        builderIndex = params.builderIndex;
        var entindex = params.entindex;
        
        pressedShift = GameUI.IsShiftDown();

        var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );

        if (modelParticle !== undefined) {
            Particles.DestroyParticleEffect(modelParticle, true)
        }
        if (gridParticles !== undefined) {
            for (var i in gridParticles) {
                Particles.DestroyParticleEffect(gridParticles[i], true)
            }
        }

        // Grid squares
        gridParticles = [];
        for (var x=0; x < size*size; x++)
        {
            var particle = Particles.CreateParticle("particles/buildinghelper/square_sprite.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, 0)
            Particles.SetParticleControl(particle, 1, [32,0,0])
            Particles.SetParticleControl(particle, 3, [grid_alpha,0,0])
            gridParticles.push(particle)
        }  
    } 
    
    if (state == 'active')
    {   
        $.Schedule(1/60, OnBuildingStart);

        var mPos = GameUI.GetCursorPosition();
        var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);

        if ( GamePos !== null ) 
        {
            SnapToGrid(GamePos, size)

            var invalid
            var color = [0,255,0]
            var part = 0
            var halfSide = (size/2)*64
            var boundingRect = {}
            boundingRect["leftBorderX"] = GamePos[0]-halfSide
            boundingRect["rightBorderX"] = GamePos[0]+halfSide
            boundingRect["topBorderY"] = GamePos[1]+halfSide
            boundingRect["bottomBorderY"] = GamePos[1]-halfSide

            if (GamePos[0] > 10000000) return

            // Building Base Grid
            for (var x=boundingRect["leftBorderX"]+32; x <= boundingRect["rightBorderX"]-32; x+=64)
            {
                for (var y=boundingRect["topBorderY"]-32; y >= boundingRect["bottomBorderY"]+32; y-=64)
                {
                    var pos = [x,y,GamePos[2]]
                    if (part>size*size)
                        return

                    var gridParticle = gridParticles[part]
                    Particles.SetParticleControl(gridParticle, 0, pos)     
                    part++; 

                    // Grid color turns red when over invalid positions
                    // Until we get a good way perform clientside FindUnitsInRadius & Gridnav Check, the prevention will stay serverside
                    var screenX = Game.WorldToScreenX( pos[0], pos[1], pos[2] );
                    var screenY = Game.WorldToScreenY( pos[0], pos[1], pos[2] );
                    var mouseEntities = GameUI.FindScreenEntities( [screenX,screenY] );
     
                    if (mouseEntities.length > 0)
                    {
                        color = [255,0,0]
                    }
                    else
                    {
                        color = [0,255,0]
                    }

                    Particles.SetParticleControl(gridParticle, 2, color)            
                }
            }
        }

        if ( (!GameUI.IsShiftDown() && pressedShift) || !Entities.IsAlive( builderIndex ) )
        {
            EndBuildingHelper();
        }
    }
}

function OnBuildingEnd()
{
    state = 'disabled'
    if (modelParticle !== undefined){
         Particles.DestroyParticleEffect(modelParticle, true)
    }
    for (var i in gridParticles) {
        Particles.DestroyParticleEffect(gridParticles[i], true)
    }
}

function SendBuildCommand( params )
{
    pressedShift = GameUI.IsShiftDown();

    $.Msg("Send Build command. Queue: "+pressedShift)
    var mPos = GameUI.GetCursorPosition();
    var GamePos = Game.ScreenXYToWorld(mPos[0], mPos[1]);

    GameEvents.SendCustomGameEventToServer( "building_helper_build_command", { "X" : GamePos[0], "Y" : GamePos[1], "Z" : GamePos[2] , "Queue" : pressedShift } );

    // Cancel unless the player is holding shift
    if (!GameUI.IsShiftDown())
    {
        OnBuildingEnd(params);
        return true;
    }
    return true;
}

function SendCancelCommand( params )
{
    OnBuildingEnd();
    GameEvents.SendCustomGameEventToServer( "building_helper_cancel_command", {} );
}

(function () {
    GameEvents.Subscribe( "building_helper_enable", OnBuildingStart);
    GameEvents.Subscribe( "building_helper_end", OnBuildingEnd);
})();

//-----------------------------------

function SnapToGrid(vec, size) {
    // Buildings are centered differently when the size is odd.
    if (size % 2 != 0) 
    {
        vec[0] = SnapToGrid32(vec[0])
        vec[1] = SnapToGrid32(vec[1])
    } 
    else 
    {
        vec[0] = SnapToGrid64(vec[0])
        vec[1] = SnapToGrid64(vec[1])
    }
}

function SnapToGrid64(coord) {
    return 64*Math.floor(0.5+coord/64);
}

function SnapToGrid32(coord) {
    return 32+64*Math.floor(coord/64);
}