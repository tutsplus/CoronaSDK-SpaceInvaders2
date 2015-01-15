local composer = require("composer")
local scene = composer.newScene()

local starFieldGenerator = require("starfieldgenerator")
local pulsatingText = require("pulsatingtext")
local physics = require("physics")
local gameData = require( "gamedata" )
physics.start()
local backgroundRect
local starGenerator
local player
local playerHeight = 125
local playerWidth = 94
local invaderSize = 32 -- The width and height of the invader image
local changeDirection = false
local leftBounds = 30
local rightBounds = display.contentWidth - 30
local invaderHalfWidth = 16
local invaders = {} -- Table that holds all the invaders
local invaderSpeed = 5
local playerBullets = {} -- Table that holds the players Bullets
local canFireBullet = true
local invadersWhoCanFire = {} -- Table that holds the invaders that are able to fire bullets
local invaderBullets = {}
local numberOfLives = 3
local playerIsInvincible = false
local rowOfInvadersWhoCanFire = 5
local invaderTimer
local gameIsOver = false;
local drawDebugButtons = {}  --Temporary buttons to move player in simulator
local enableBulletFireTimer

function scene:create( event )
        local group = self.view
    	 starGenerator =  starFieldGenerator.new(100,group,5)
     	 setupPlayer()     	 setupInvaders()
     	 drawDebugButtons()
end

function scene:show( event )
	local phase = event.phase
	  local previousScene = composer.getSceneName( "previous" )
      composer.removeScene(previousScene)
	   local group = self.view
	   if ( phase == "did" ) then	    Runtime:addEventListener("enterFrame", gameLoop)
     	Runtime:addEventListener("enterFrame", starGenerator)		 Runtime:addEventListener("tap", firePlayerBullet)		 Runtime:addEventListener( "collision", onCollision )
	   end
end

function scene:hide( event )
	local phase = event.phase
    local group = self.view
    if ( phase == "will" ) then
       	Runtime:removeEventListener("enterFrame", starGenerator)       	Runtime:removeEventListener("tap", firePlayerBullet)       	Runtime:removeEventListener("enterFrame", gameLoop)       	Runtime:removeEventListener( "collision", onCollision )
    end
end
function setupPlayer()
	local options = { width = playerWidth,height = playerHeight,numFrames = 2}
	local playerSheet = graphics.newImageSheet( "player.png", options )
	local sequenceData = {
  	 {  start=1, count=2, time=300,   loopCount=0 }
	}
	player = display.newSprite( playerSheet, sequenceData )
	player.name = "player"
	player.x=display.contentCenterX- playerWidth /2 
	player.y = display.contentHeight - playerHeight - 10
	player:play()
	scene.view:insert(player)
	local physicsData = (require "shapedefs").physicsData(1.0)
	physics.addBody( player, physicsData:get("ship"))
	player.gravityScale = 0
end

function drawDebugButtons()
	local function movePlayer(event)
		if(event.target.name == "left") then
			  player.x = player.x - 5
		elseif(event.target.name == "right") then
			player.x = player.x+5
		end
	end
	local left = display.newRect(60,700,50,50)
	left.name = "left"

    scene.view:insert(left)
	local right = display.newRect(display.contentWidth-60,700,50,50)
	right.name = "right"
	scene.view:insert(right)
     left:addEventListener("tap", movePlayer)
    right:addEventListener("tap", movePlayer)

end
function firePlayerBullet()
	if(canFireBullet == true)then
		local tempBullet = display.newImage("laser.png", player.x, player.y - playerHeight/ 2)
		tempBullet.name = "playerBullet"
		scene.view:insert(tempBullet)
		physics.addBody(tempBullet, "dynamic" )
    	tempBullet.gravityScale = 0
    	tempBullet.isBullet = true
    	tempBullet.isSensor = true
   	 tempBullet:setLinearVelocity( 0,-400)
		table.insert(playerBullets,tempBullet)
		local laserSound = audio.loadSound( "laser.mp3" )
		local laserChannel = audio.play( laserSound )
		audio.dispose(laserChannel)
		canFireBullet = false

	else
		return
	end
	local function enableBulletFire()
		canFireBullet = true
	end
	timer.performWithDelay(750,enableBulletFire,1)
endfunction checkPlayerBulletsOutOfBounds()
	if(#playerBullets > 0)then
		for i=#playerBullets,1,-1 do
 			if(playerBullets[i].y < 0) then
 				playerBullets[i]:removeSelf()
 				playerBullets[i] = nil
 				table.remove(playerBullets,i)
 			end
 		end
	end
endfunction gameLoop()
	checkPlayerBulletsOutOfBounds()	moveInvaders()
endfunction setupInvaders()
	local xPositionStart =display.contentCenterX - invaderHalfWidth - (gameData.invaderNum *(invaderSize + 10))
	local numberOfInvaders = gameData.invaderNum *2+1 
	for i = 1, gameData.rowsOfInvaders do
		for j = 1, numberOfInvaders do
			local tempInvader = display.newImage("invader1.png",xPositionStart + ((invaderSize+10)*(j-1)), i * 46 )
			tempInvader.name = "invader"
			if(i== gameData.rowsOfInvaders)then
				table.insert(invadersWhoCanFire,tempInvader)
			end
			
		physics.addBody(tempInvader, "dynamic" )
   		tempInvader.gravityScale = 0
		tempInvader.isSensor = true
		scene.view:insert(tempInvader)
		table.insert(invaders,tempInvader)
		end
	end
endfunction moveInvaders()
    local changeDirection = false
	for i=1, #invaders do
      	invaders[i].x = invaders[i].x + invaderSpeed
     	if(invaders[i].x > rightBounds - invaderHalfWidth or invaders[i].x < leftBounds + invaderHalfWidth) then
          	changeDirection = true;
     	end
	 end
    if(changeDirection == true)then
        invaderSpeed = invaderSpeed*-1
        for j = 1, #invaders do
            invaders[j].y = invaders[j].y+ 46
        end
        changeDirection = false;
    end 
endfunction onCollision( event )
	local function removeInvaderAndPlayerBullet(event)
    local params = event.source.params	local invaderIndex = table.indexOf(invaders,params.theInvader)
	 local invadersPerRow = gameData.invaderNum *2+1
    if(invaderIndex > invadersPerRow) then
		 table.insert(invadersWhoCanFire, invaders[invaderIndex - invadersPerRow])
   end
	 params.theInvader.isVisible = false
     physics.removeBody(  params.theInvader )
      table.remove(invadersWhoCanFire,table.indexOf(invadersWhoCanFire,params.theInvader))
	if(table.indexOf(playerBullets,params.thePlayerBullet)~=nil)then
		physics.removeBody(params.thePlayerBullet)
	  table.remove(playerBullets,table.indexOf(playerBullets,params.thePlayerBullet))
	  display.remove(params.thePlayerBullet)
	  params.thePlayerBullet = nil
	  end
	end
	  if ( event.phase == "began" ) then
			if(event.object1.name == "invader" and event.object2.name == "playerBullet")then
				local tm = timer.performWithDelay(10, removeInvaderAndPlayerBullet,1)
				tm.params = {theInvader = event.object1 , thePlayerBullet = event.object2}
			end
   	  if(event.object1.name == "playerBullet" and event.object2.name == "invader") then
			local tm = timer.performWithDelay(10, removeInvaderAndPlayerBullet,1)
			tm.params = {theInvader = event.object2 , thePlayerBullet = event.object1}
   	  end
  	end
end	
local function onAccelerate( event )

	player.x = display.contentCenterX + (display.contentCenterX * (event.xGravity*2))
end

system.setAccelerometerInterval( 60 )

Runtime:addEventListener ("accelerometer", onAccelerate)

scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )



return scene