-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()


-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local leftPressed, rightPressed, upPressed
local crate, entrancePortal, exit, explodingThing
local playerInContactWith = nil
local gameLoopTimer
local explosionSound = audio.loadSound("sound/plop.wav")
local teleportSound = audio.loadSound("sound/teleport_01.wav")
local shootingSounds = {
    audio.loadSound("sound/shoot_01.wav"),
    audio.loadSound("sound/shoot_02.wav"),
    audio.loadSound("sound/shoot_03.wav")}


-- Shoot a gun
local function fire()
    local bullet = display.newImageRect("Images/Things/red-square.png", 10, 10)
    physics.addBody(bullet, "static", {isSensor=true})
    bullet.isBullet = true
    bullet.myName = "bullet"
    bullet.x = crate.x
    bullet.y = crate.y
    transition.to(bullet, {x=20000, time=5000, onComplete = function() display.remove(bullet) end})
    audio.play(shootingSounds[math.random(1, #shootingSounds)])
end


-- Called when a key event has been received
local function onKeyEvent( event )

    if event.keyName == "left" then
		if event.phase == "down" then
			leftPressed = true
		elseif event.phase == "up" then
			leftPressed = false
		end
	end

	if event.keyName == "right" then
		if event.phase == "down" then
			rightPressed = true
		elseif event.phase == "up" then
			rightPressed = false
		end
	end

	if event.keyName == "up" then
		if event.phase == "down" then
			crate:setLinearVelocity(0, -500)
		end
	end

	if event.keyName == "e" then
		if event.phase == "down" then
			if playerInContactWith then
				display.remove(playerInContactWith)
                audio.play(explosionSound)
			end
		end
	end

    if event.keyName == "space" then
		if event.phase == "down" then
			fire()
		end
	end


    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end


local function gameLoop()
    if leftPressed then
		crate.x = crate.x - 10
	end
	if rightPressed then
		crate.x = crate.x + 10
	end
end


local function onCollision( event )

    if ( event.phase == "began" ) then
        local obj1 = event.object1
        local obj2 = event.object2
		if ((obj1.myName == "player" and obj2.myName == "explodingThing") or
			(obj1.myName == "explodingThing" and obj2.myName == "player")) then
			playerInContactWith = explodingThing
		end
        if ((obj1.myName == "player" and obj2.myName == "exit") or
			(obj1.myName == "exit" and obj2.myName == "player")) then
            timer.cancel( gameLoopTimer )
            transition.to(crate, {x=exit.x})
            transition.to(
                crate, {time=1000, alpha=0, width=10, height=10,
                onComplete=function() display.remove(crate) end} )
        end
	elseif ( event.phase == "ended" ) then
		local obj1 = event.object1
        local obj2 = event.object2
		if ((obj1.myName == "player" and obj2.myName == "explodingThing") or
			(obj1.myName == "explodingThing" and obj2.myName == "player")) then
			playerInContactWith = nil
		end
    end
end


-- include Corona's "physics" library
local physics = require "physics"

--------------------------------------------

function scene:create( event )

	-- Called when the scene's view does not exist.
	--
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.

	local sceneGroup = self.view

	-- We need physics started to add bodies, but we don't want the simulaton
	-- running until the scene is on the screen.
	physics.start()
	physics.setGravity(0, 20)
	physics.pause()


	-- create a grey rectangle as the backdrop
	-- the physical screen will likely be a different shape than our defined content area
	-- since we are going to position the background from it's top, left corner, draw the
	-- background at the real top, left corner.
	local background = display.newRect( display.screenOriginX, display.screenOriginY, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( .5 )

    entrancePortal = display.newImageRect("Images/Things/portal.png", 150, 150)
    entrancePortal.x, entrancePortal.y = 160, 950
    entrancePortal.alpha = 0

    exit = display.newImageRect("Images/Things/exit.png", 150, 150)
    exit.x, exit.y = 1500, 950
    physics.addBody(exit, "static", { isSensor=true })
	exit.myName = "exit"

	-- make a crate (off-screen), position it, and rotate slightly
	crate = display.newImageRect( "crate.png", 10, 90 )
	crate.x, crate.y = 160, 950
    crate.alpha = 0
	crate.myName = "player"

	-- add physics to the crate
	physics.addBody( crate, { density=1.0, friction=0.3, bounce=0 } )

	-- create a grass object and add physics (with custom shape)
	local grass = display.newImageRect( "grass.png", screenW, 82 )
	grass.anchorX = 0
	grass.anchorY = 1
	--  draw the grass at the very bottom of the screen
	grass.x, grass.y = display.screenOriginX, display.actualContentHeight + display.screenOriginY

	explodingThing = display.newImageRect("Images/Things/red-square.png", 90, 90)
	explodingThing.x, explodingThing.y = 1000, 950
	physics.addBody(explodingThing, "static", { isSensor=true })
	explodingThing.myName = "explodingThing"

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local grassShape = { -halfW,-34, halfW,-34, halfW,34, -halfW,34 }
	physics.addBody( grass, "static", { friction=0.3, shape=grassShape } )

	-- all display objects must be inserted into group
	sceneGroup:insert( background )
    sceneGroup:insert( entrancePortal )
    sceneGroup:insert( exit )
	sceneGroup:insert( grass)
	sceneGroup:insert( crate )
	sceneGroup:insert( explodingThing )
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		local function teleportIn()
            timer.pause(gameLoopTimer)
            transition.fadeIn(entrancePortal, { time=300, delay=500, onComplete=function() audio.play(teleportSound) end} )
            transition.to(crate, { time=500, delay=800, alpha=1, width=90, onComplete=function() timer.resume(gameLoopTimer) end} )
            transition.fadeOut(entrancePortal, { time=300, delay=1400 } )
        end

		leftPressed = false
		rightPressed = false
		Runtime:addEventListener( "key", onKeyEvent )
		gameLoopTimer = timer.performWithDelay( 30, gameLoop, 0 )
		Runtime:addEventListener( "collision", onCollision )
        teleportIn()
        physics.start()
	end
end

function scene:hide( event )
	local sceneGroup = self.view

	local phase = event.phase

	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end

end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view

	package.loaded[physics] = nil
	physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
