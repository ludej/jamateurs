-----------------------------------------------------------------------------------------
--
-- level4.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local utils = require("utils")

local scene = composer.newScene()

local arnold,player
local arnieDefaultCountdownTime = 8
local arnieCountdownTime
local countDownTimer
local gameLoopTimer

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local leftPressed, rightPressed
local crate, entrancePortal, exit, explodingThing, lever, winch
local playerInContactWith, arnoldInContactWith = nil
local canDoubleJump


local nw, nh
local scaleX,scaleY = 0.5,0.5


-- Character movement animation
local playerSheetData = {width = 185, height = 195, numFrames = 8, sheetContentWidth = 1480, sheetContentHeight= 195 }
local playerSheet1 = graphics.newImageSheet("/Images/Character/heroRun.png", playerSheetData)


local playerSequenceData = {
    {name="running", start=1, count=8, time=575, loopCount=0}
  }

-- Arnold movement animation
local arnoldSheetData = {width = 210, height = 210, numFrames = 6, sheetContentWidth = 1260, sheetContentHeight= 210 }
local arnoldSheet1 = graphics.newImageSheet("/Images/Character/arnieRun.png", arnoldSheetData)


local arnoldSequenceData = {
    {name="running", start=1, count=8, time=575, loopCount=0}
  }

local arnoldMovements = {
    {action = "sound", actionData = utils.sounds["hastaLaVista"]},
     {action = "jump", actionData = -600},
    {action = "move", actionData = 200},
    {action = "jump", actionData = -600},
    {action = "move", actionData = 550},
    {action = "shoot", actionData = 1},
    {action = "move", actionData = 350},
    {action = "jump", actionData = -600},
    {action = "move", actionData = 450},
  }

local function canArnieKillSomeone()
   --print( "Checking hits" )
  if(arnold==nill or arnold.x == nil) then
    return
  end

  local hits = physics.rayCast( arnold.x, arnold.y, arnold.x + 1000, arnold.y, "closest" )
  if ( hits ) then

    if (hits[1].object.myName == "player") then
      utils.fire(arnold)
    end
  end
end

local function arnoldMover(index)
  if(index > #arnoldMovements or arnold ==nill or arnold.x == nill) then
    return
  end

  if(arnoldMovements[index].action == "move") then
    transition.to(arnold, {time=1000, x=arnold.x + arnoldMovements[index].actionData, onComplete = function() arnoldMover(index+1) end })
    --transition.to(arnold, {delay = 2000, x=arnold.x + arnoldMovements[index].delta, time=2000})
    print("Arnold movement, type  move. Delta : ", arnoldMovements[index].actionData)
  elseif(arnoldMovements[index].action == "jump") then
      audio.play( utils.sounds["jump"] )
      arnold:setLinearVelocity( 0, arnoldMovements[index].actionData )
      print("Arnold movement, type  jump. actionData : ", arnoldMovements[index].actionData)
      arnoldMover(index+1)
  elseif(arnoldMovements[index].action == "shoot") then
      for i=1,arnoldMovements[index].actionData do

        utils.fire(arnold)
      end
      print("Arnold movement, type  shoot. actionData : ", arnoldMovements[index].actionData)
      arnoldMover(index+1)
    elseif(arnoldMovements[index].action == "sound") then
      print("Arnold movement, type  sound. actionData : ", arnoldMovements[index].actionData)
      audio.play(arnoldMovements[index].actionData)
      arnoldMover(index+1)
    end
  --ArnoldMovement(index+1)
  --transition.to(arnold, {x=20000, time=5000, onComplete = function() display.remove(bullet) end})
end

local function sensorCollide( self, event )
    -- Confirm that the colliding elements are the foot sensor and a ground object
    if ( event.selfElement == 2) then
        -- Foot sensor has entered (overlapped) a ground object
        if ( event.phase == "began" ) then
            self.sensorOverlaps = self.sensorOverlaps + 1
        -- Foot sensor has exited a ground object
        elseif ( event.phase == "ended" ) then
            self.sensorOverlaps = self.sensorOverlaps - 1
        end
    end
end


local function objectCollide(self, event)
    if ( event.phase == "began" ) then
        if event.other.myName == "player" then
            playerInContactWith = self
        elseif event.other.myName == "arnold" then
            arnoldInContactWith = self
        end
    elseif ( event.phase == "ended" ) then
        if event.other.myName == "player" then
            playerInContactWith = nil
        elseif event.other.myName == "arnold" then
            arnoldInContactWith = nil
        end
    end
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

	if ((event.keyName == "up") and (event.phase == "down")) then
        if crate.sensorOverlaps > 0 then
            -- crate:applyLinearImpulse( 0, -0.75, crate.x, crate.y )
            canDoubleJump = true
            crate:setLinearVelocity(0, -500)
        elseif canDoubleJump then
            canDoubleJump = false
            crate:setLinearVelocity(0, -500)
        end
	end

    if event.keyName == "e" then
		if event.phase == "down" then
			if playerInContactWith then
				display.remove(playerInContactWith)
                audio.play(utils.sounds["explosion"])
			end
		end
	end

    if event.keyName == "space" then
		if event.phase == "down" then
			utils.fire(crate)
		end
	end
    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end


local function gameLoop()
    if leftPressed then
        crate.xScale = -1
        crate.x = crate.x - 10
	end
	if rightPressed then
		crate.x = crate.x + 10
        crate.xScale = 1
	end

    if(leftPressed or rightPressed) then
        if(crate.isPlaying == false) then
            crate:play()
        else
            crate:pause()
        end
    end
    canArnieKillSomeone()
end


local function onCollision( event )

    if ( event.phase == "began" ) then
        local obj1 = event.object1
        local obj2 = event.object2
		if ((obj1.myName == "player" and obj2.myName == "explodingThing") or
			(obj1.myName == "explodingThing" and obj2.myName == "player")) then
			playerInContactWith = explodingThing
		end
        if ((obj1.myName == "arnold" and obj2.myName == "exit") or
			(obj1.myName == "exit" and obj2.myName == "arnold")) then
            -- timer.cancel( gameLoopTimer )
            transition.to(arnold, {x=exit.x})
            transition.to(
                arnold, {time=1000, alpha=0, width=10, height=10,
                onComplete=function() display.remove(arnold) end} )
        end
        if (obj1.myName == "bullet" or obj2.myName == "bullet") then
            local bullet, target
            if obj1.myName == "bullet" then
                bullet, target = obj1, obj2
            else
                bullet, target = obj2, obj1
            end
            if target.myName ~= "arnold" then
                display.remove(bullet)
                if target.myName == "player" then
                    timer.cancel( gameLoopTimer )
                    display.remove(target)
                end
            end
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

local function createPlatform (positionX, positionY, width)
  local platform = display.newImageRect( "Images/Scene/platform.png", width, 41)
	platform.anchorX = 0
	platform.anchorY = 0
	--  draw the grass at the very bottom of the screen
	platform.x, platform.y = positionX, positionY

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local platformShape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
	physics.addBody( platform, "static", { friction=0.3 } )
  end
-- include Corona's "physics" library
local physics = require "physics"

local function updateTime( event )
    arnieCountdownTime = arnieCountdownTime - 1
    countDownSecondsText.text = arnieCountdownTime

    if(arnieCountdownTime == 0) then
        sendArnie()
        arnieCountdownTime = arnieDefaultCountdownTime
        countDownTimer = timer.performWithDelay( 1000, updateTime, arnieCountdownTime )
    end
end

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
    physics.setDrawMode("hybrid") -- shows the physics box around the object

	-- create a grey rectangle as the backdrop
	-- the physical screen will likely be a different shape than our defined content area
	-- since we are going to position the background from it's top, left corner, draw the
	-- background at the real top, left corner.
	local background = display.newRect( display.screenOriginX, display.screenOriginY, screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	background:setFillColor( .5 )

  lever = display.newImageRect( "Images/Scene/lever.png", 50, 50)
  lever.anchorX = 0
  lever.anchorY = 1
  lever.x, lever.y = 0, 225
  lever.myName = "paka"
  physics.addBody( lever, "static", { isSensor=true } )
  lever.collision = objectCollide
  lever:addEventListener( "collision" )

  winch = display.newImageRect( "Images/Scene/winch.png", 50, 50)
  winch.anchorX = 0
  winch.anchorY = 1
  winch.x, winch.y = 750, 880
  physics.addBody( winch, "static", { isSensor=true } )
  winch.myName = "navijak"
  winch.collision = objectCollide
  winch:addEventListener( "collision" )


  crate = display.newSprite(playerSheet1, playerSequenceData)
  crate.x, crate.y = 1900, 950
  crate.myName = "player"
  crate:setSequence("running")

  entrancePortal = display.newImageRect("Images/Things/portal.png", 150, 300)
  entrancePortal.x, entrancePortal.y = 160, 781
  entrancePortal.alpha = 0

  exit = display.newImageRect("Images/Things/exit.png", 150, 150)
  exit.x, exit.y = 1845, 762
  physics.addBody(exit, "static", { isSensor=true })
  exit.myName = "exit"


	-- add physics to the crate
  crate:scale(scaleX,scaleY)

  nw, nh = crate.width*scaleX*1, crate.height*scaleY*0.8
	physics.addBody(
        crate, "dynamic",
        { density=1.0, friction=0.3, bounce=0, shape={-nw,-nh,nw,-nh,nw,nh,-nw,nh} },
        { box={ halfWidth=30, halfHeight=10, x=0, y=95 }, isSensor=true  }
        )
    crate.isFixedRotation = true
    crate.sensorOverlaps = 0
    crate.collision = sensorCollide
    crate:addEventListener( "collision" )




	-- create a grass object and add physics (with custom shape)
	local grass = display.newImageRect( "grass.png", screenW, 82)
	grass.anchorX = 0
	grass.anchorY = 0
	--  draw the grass at the very bottom of the screen
	grass.x, grass.y = display.screenOriginX, display.actualContentHeight + display.screenOriginY

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local grassShape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
	physics.addBody( grass, "static", { friction=0.3 } )


  --local ground1 = display.newImageRect( "Images/Scene/ground.png", 1200, 41)
	--ground1.anchorX = 0
	--ground1.anchorY = 1

	--ground1.x, ground1.y = display.screenOriginX, 938

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	--local ground1Shape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
	--physics.addBody( ground1, "static", { friction=0.3 } )

  local ground2 = display.newImageRect( "Images/Scene/ground.png", 535, 41)
	ground2.anchorX = 0
	ground2.anchorY = 1

	ground2.x, ground2.y = 1385, 880

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local ground2Shape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
	physics.addBody( ground2, "static", { friction=0.3 } )


  local platforms = {
      createPlatform (300, 639, 400),
      createPlatform (1200, 639, 400),
      createPlatform (700, 439, 400),
      createPlatform (0, 239, 200),
      createPlatform (400, 239, 300),
      createPlatform (1520, 239, 400),
    }

    --sendArnie()

	-- all display objects must be inserted into group
    sceneGroup:insert( background )
    sceneGroup:insert( entrancePortal )
    sceneGroup:insert( exit )
	sceneGroup:insert( grass)
	sceneGroup:insert( crate )
	--sceneGroup:insert( explodingThing )

  countDownText = display.newText(sceneGroup, "Arnie comes in: ", 0,0, "MadeinChina", 56)
          countDownText.x = display.contentWidth*0.5
          countDownText.y = 50
    countDownSecondsText = display.newText(sceneGroup,arnieDefaultCountdownTime , 0,0, "MadeinChina", 56)
          countDownSecondsText.x = countDownText.x + countDownText.width/2 + 25
          countDownSecondsText.y = 50
end

local function teleportIn()
  transition.fadeIn(entrancePortal, { time=300, delay=500, onComplete=function() audio.play(utils.sounds["teleport"]) end} )
  transition.fadeIn(arnold, {
    time=500, delay=800, onComplete=function()
    timer.resume(gameLoopTimer)
    arnold:setSequence("running")
    arnold:play()
    arnoldMover(1)
  end} )

  transition.fadeOut(entrancePortal, { time=300, delay=1400 } )
end

function sendArnie()

   if(arnold ~= nil) then
    display.remove(arnold)   
   end
   
   arnold = display.newSprite(arnoldSheet1, arnoldSequenceData)
  --arnold:scale(0.5,0.5)
  arnold.x, arnold.y = entrancePortal.x, entrancePortal.y
  arnold.alpha = 0
  arnold.myName = "arnold"

  physics.addBody( arnold, "dynamic", { density=1.0, friction=0.3, bounce=0, shape={-nw,-nh,nw,-nh,nw,nh,-nw,nh} } )
    arnold.isFixedRotation = true

  teleportIn()

end



function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
    leftPressed = false
		rightPressed = false
		Runtime:addEventListener( "key", onKeyEvent )
		gameLoopTimer = timer.performWithDelay( 30, gameLoop, 0 )
    arnieCountdownTime = arnieDefaultCountdownTime
    countDownTimer = timer.performWithDelay( 1000, updateTime, arnieCountdownTime )

    arnieCountdownTime = arnieDefaultCountdownTime
        Runtime:addEventListener( "collision", onCollision )
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
