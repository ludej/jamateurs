-----------------------------------------------------------------------------------------
--
-- level4.lua
--
-----------------------------------------------------------------------------------------
--require("mobdebug").start()
local composer = require( "composer" )
local utils = require("utils")
local physics = require ("physics")

local scene = composer.newScene()
local sceneGroup


local flames
local arnold

local arnieDefaultCountdownTime = 8
local arnieCountdownTime
local countDownTimer
local gameLoopTimer
local shootLoopTimer
local gameEnded = false
local angryArnold = false

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX
local leftPressed, rightPressed
local player, entrancePortal, exit, exitIsOpen, explodingThing, lever, winch

local playerInContactWith, arnoldInContactWith = nil
local canDoubleJump
local platforms = {}
local platformCount = 0
local enemies = {}
local enemiesCount = 0
local gameOverScreen, gameoverBackground


local nw, nh
local scaleX,scaleY = 0.5,0.5


-- Character movement animation
local playerSheetData = {width = 210, height = 210, numFrames = 10, sheetContentWidth = 2100, sheetContentHeight= 210 }
local playerSheet1 = graphics.newImageSheet("/Images/Character/heroAnim.png", playerSheetData)


local playerSequenceData = {
    {name="idle", start=1, count=4, time=800, loopCount=0},
    {name="running", start=5, count=6, time=800, loopCount=0}
  }

-- Arnold movement animation
local arnoldSheetData = {width = 210, height = 210, numFrames = 6, sheetContentWidth = 1260, sheetContentHeight= 210 }
local arnoldSheet1 = graphics.newImageSheet("/Images/Character/arnieRun.png", arnoldSheetData)

local arnoldSequenceData = {
    {name="running", start=1, count=6, time=575, loopCount=0}
  }


local flamesSheetData = {width = 200, height = 300, numFrames = 17, sheetContentWidth = 3400, sheetContentHeight= 300 }
local flamesSheet1 = graphics.newImageSheet("/Images/Things/flamesAnim.png", flamesSheetData)

local flamesSequenceData = {
    {name="burning", start=1, count=17, time=1500, loopCount=0}
  }

local entrancePortalSheetData = {width = 300, height = 300, numFrames = 12, sheetContentWidth = 3600, sheetContentHeight= 300 }
local entrancePortalSheet1 = graphics.newImageSheet("/Images/Things/portalAnim.png", entrancePortalSheetData)

local entrancePortalSequenceData = {
    {name="beaming", start=1, count=12, time=1300, loopCount=0}
  }
  
  -- Enemy idle animation
local enemyIdleSheetData = {width = 210, height = 210, numFrames = 7, sheetContentWidth = 1470, sheetContentHeight= 210 }
local enemyIdleSheet = graphics.newImageSheet("/Images/Character/enemyIdle.png", enemyIdleSheetData)


local enemyIdleSequenceData = {
    {name="idle", start=1, count=7, time=575, loopCount=0}
  }

local arnoldMovements = {
    {action = "sound", actionData = utils.sounds["hastaLaVista"]},
    {action = "move", actionData = 350},
    {action = "move", actionData = 350},
    {action = "move", actionData = 250},
    {action = "jump", actionData = -600},
    {action = "move", actionData = 650},
    {action = "jump", actionData = -500},
    {action = "move", actionData = -390},
  }

local function canArnieKillSomeone()
   --print( "Checking hits" )
  if(arnold==nil or arnold.x == nil) then
    return
  end

  local hits = physics.rayCast( arnold.x, arnold.y, arnold.x + 1000, arnold.y, "closest" )
  if ( hits ) then

    if (hits[1].object.myName == "player" or hits[1].object.myName == "enemy") then
    utils.fire(arnold)
    end
  end
end

local function arnoldMover(index)
  if(index > #arnoldMovements or arnold ==nil or arnold.x == nil or gameEnded== true) then
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


local function createExit(imageLocation)
    exit = display.newImageRect(imageLocation, 150, 150)
    exit.x, exit.y = 1845, 670
    physics.addBody(exit, "static", { isSensor=true })
    exit.myName = "exit"
end

local function toggleExit()
    display.remove(exit)
    if exitIsOpen then
        exitIsOpen = false
        createExit("Images/Things/gate-closed.png")
    else
        exitIsOpen = true
        createExit("Images/Things/gate-open.png")
    end
end


local function objectCollide(self, event)
    if ( event.phase == "began" ) then
        if event.other.myName == "player" then
            playerInContactWith = self
        elseif event.other.myName == "arnold" then
            arnoldInContactWith = self
            if self.myName == "switch" then
                toggleExit()
            end
        end
    elseif ( event.phase == "ended" ) then
        if event.other.myName == "player" then
            playerInContactWith = nil
        elseif event.other.myName == "arnold" then
            arnoldInContactWith = nil
        end
    end
end


local function gameLoop()
    if leftPressed then
        player.xScale = -1
        player.x = player.x - 10
	end
	if rightPressed then
		player.x = player.x + 10
        player.xScale = 1
	end

    if(leftPressed or rightPressed) then
        if player.sequence ~= "running" then
            player:setSequence("running")
            player:play()
        end
    elseif player.sequence ~= "idle" then
        player:setSequence("idle")
        player:play()
    end
end

local function shootLoop()
  if(angryArnold) then
    utils.fireAtPlayer(arnold,player)
  end

  canArnieKillSomeone()
end

function createEnemy(xPosition, yPosition, type, index)
  if(index<0) then
    enemiesCount = enemiesCount +1
    index = enemiesCount
  end
  if(type == "enemy") then
    enemies[index]= display.newSprite(enemyIdleSheet, enemyIdleSequenceData)
    enemies[index]:setSequence("idle")
    enemies[index]:play()
    timer.performWithDelay(1, function() physics.addBody( enemies[index], "dynamic", { density=1.0, friction=0.3, bounce=0, shape ={-90,-90 , 90,-90 , 90,100 , -90,100} } ) end, 1)
  elseif(type == "deadEnemy") then
     enemies[index]= display.newImageRect( "Images/Character/enemyDead.png", 200, 200)
     timer.performWithDelay(1, function() physics.addBody( enemies[index], "static", { isSensor = true } ) end, 1)
     enemies[index].collision = objectCollide
     enemies[index]:addEventListener( "collision" )
  end
  enemies[index].myName=type
  enemies[index].enemyIndex=enemiesCount
  enemies[index].x = xPosition
  enemies[index].y = yPosition
  enemies[index].isFixedRotation = true
  sceneGroup:insert( enemies[index] )

  end

local function enemyHit(enemy)
  local x,y = enemy.x,enemy.y
  display.remove(enemy)
  createEnemy(x,y,"deadEnemy", enemy.enemyIndex)
end

local function resurrectEnemy(enemy)
  local x,y = enemy.x,enemy.y
  display.remove(enemy)
  createEnemy(x,y,"enemy", enemy.enemyIndex)
end

function leaveGame()


  for i=1,#platforms do
          display.remove(platforms[i])
        end

  for i=1,#enemies do
    if(enemies[i].isPlaying == true) then
       enemies[i]:pause()
       display.remove(enemies[i])
    end
  end

  display.remove(player)
  display.remove(arnold)
  display.remove(exit)
  display.remove(lever)
  display.remove(winch)
  display.remove(flames)

  display.remove(gameOverScreen)
  display.remove(gameoverBackground)
  composer.gotoScene("menu", "slideRight")
end

function gameOver()
  gameEnded = true
  gameoverBackground = display.newRect( 0, 0 , display.contentWidth* 1.25, display.contentHeight * 1.25)
      gameoverBackground.x =display.contentWidth*0.5
      gameoverBackground.y = display.contentHeight*0.5
      gameoverBackground:setFillColor(0)
      gameoverBackground.alpha = 0.7
  gameOverScreen = display.newImageRect( "Images/Scene/UI/hasta/hasta_001.png",1920, 1080)
  gameOverScreen.x = display.contentWidth*0.5
  gameOverScreen.y = display.contentHeight*0.5

  timer.cancel(gameLoopTimer)
  timer.cancel(shootLoopTimer)
  timer.cancel(countDownTimer)

  Runtime:removeEventListener("key", onKeyEvent)
  Runtime:removeEventListener("collision", onCollision)

  countDownTimer = timer.performWithDelay( 2000, leaveGame, 1 )
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
            if exitIsOpen then
                transition.to(arnold, {x=exit.x})
                transition.to(
                    arnold, {time=1000, alpha=0, width=10, height=10,
                    onComplete=function() display.remove(arnold) end} )
            end
        end
        if (obj1.myName == "bullet" or obj2.myName == "bullet") then
            local bullet, target
            if obj1.myName == "bullet" then
                bullet, target = obj1, obj2
            else
                bullet, target = obj2, obj1
            end
            if target.myName ~= "arnold" then
                --bullet:pause()
                display.remove(bullet)
                if target.myName == "player" then
                    timer.cancel( gameLoopTimer )
                    target:pause()
                    display.remove(target)
                    gameOver()
                elseif(target.myName == "enemy") then
                  enemyHit(target)
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


-- Called when a key event has been received
local function onKeyEvent( event )
    if(gameEnded) then return end
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
        if player.sensorOverlaps > 0 then
            -- player:applyLinearImpulse( 0, -0.75, player.x, player.y )
            canDoubleJump = true
            player:setLinearVelocity(0, -500)
        elseif canDoubleJump then
            canDoubleJump = false
            player:setLinearVelocity(0, -500)
        end
	end

    if event.keyName == "e" then
		if event.phase == "down" then
            if playerInContactWith then
    			if playerInContactWith.myName == "lever" then
    				toggleExit()
                    audio.play(utils.sounds["explosion"])
    			end
                if playerInContactWith.myName == "deadEnemy" then
                    print("In contact with enemy for resurrection")
                    resurrectEnemy(playerInContactWith)
                end
            end
		end
	end
    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end



local function createPlatform (positionX, positionY, typePlatform)
  local platform
  platformCount = platformCount + 1
   if (typePlatform == "A") then

     platform = display.newImageRect("Images/Scene/background/platform_A.png", 206, 92 )
     local nwA, nhA = platform.width*scaleX*0.9, platform.height*scaleY*0.5
     physics.addBody( platform, "static", { friction=0.3, shape ={-nwA,-nhA,nwA,-nhA,nwA,nhA,-nwA,nhA} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   elseif (typePlatform == "B") then
     platform = display.newImageRect( "Images/Scene/background/platform_B.png", 350, 62)
     local nwB, nhB = platform.width*scaleX*0.9, platform.height*scaleY*0.7
     physics.addBody( platform, "static", { friction=0.3, shape ={-nwB,-nhB,nwB,-nhB,nwB,nhB,-nwB,nhB} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   elseif (typePlatform == "C") then
     platform = display.newImageRect( "Images/Scene/background/platform_C.png", 503, 82)
     local nwC, nhC = platform.width*scaleX*0.95, platform.height*scaleY*0.6
     physics.addBody( platform, "static", { friction=0.3, shape ={-nwC,-nhC,nwC,-nhC,nwC,nhC,-nwC,nhC} })
     platform.anchorX = 0.5
     platform.anchorY = 0.45

   elseif (typePlatform == "D") then
     platform = display.newImageRect( "Images/Scene/background/platform_D.png", 845, 70)
     local nwD, nhD = platform.width*scaleX*0.97, platform.height*scaleY*0.7
     physics.addBody( platform, "static", { friction=0.3, shape ={-nwD,-nhD,nwD,-nhD,nwD,nhD,-nwD,nhD} })
     platform.anchorX = 0.49
     platform.anchorY = 0.5

   elseif (typePlatform == "AP") then
     platform = display.newImageRect( "Images/Scene/background/platform_plant_A.png", 232, 199)
     physics.addBody( platform, "static", { friction=0.3, shape ={-80,35, 90,35, 90,75, -80,75} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   elseif (typePlatform == "BP") then
     platform = display.newImageRect( "Images/Scene/background/platform_plant_B.png", 348, 128)
     physics.addBody( platform, "static", { friction=0.3, shape ={-165,5 , 160,5 , 160,50  , -165,50} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   elseif (typePlatform == "CP") then
     platform = display.newImageRect( "Images/Scene/background/platform_plant_C.png", 505, 195)
     physics.addBody( platform, "static", { friction=0.3, shape ={-233,32 , 235,32 , 235,72 , -235,70} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   elseif (typePlatform == "DP") then
     platform = display.newImageRect( "Images/Scene/background/platform_plant_D.png", 841, 197)
     physics.addBody( platform, "static", { friction=0.3, shape ={-420.5,45 , 400,45 , 400,85 , -420,85} })
     platform.anchorX = 0.5
     platform.anchorY = 0.5

   end
   platform.x, platform.y = positionX, positionY
  platforms[platformCount]= platform
	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	--local platformShape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
 end


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
	--physics.pause()

  --physics.setDrawMode("hybrid") -- shows the physics box around the object



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
    lever.myName = "lever"
	physics.addBody( lever, "static", { isSensor=true } )
    lever.collision = objectCollide
    lever:addEventListener( "collision" )

    winch = display.newImageRect( "Images/Scene/winch.png", 50, 50)
    winch.anchorX = 0
    winch.anchorY = 1
    winch.x, winch.y = 750, 880
    physics.addBody( winch, "static", { isSensor=true } )
    winch.myName = "winch"
    winch.collision = objectCollide
    winch:addEventListener( "collision" )



  flames = display.newSprite(flamesSheet1, flamesSequenceData)
  flames.x, flames.y = 960, 940
  flames.myName = "flames"
  flames:setSequence("burning")
  flames:play()
  physics.addBody( flames, "static", { friction=0.3, shape ={-70,-90 , 70,-90 , 70,150 , -70,150} })
  player = display.newSprite(playerSheet1, playerSequenceData)
  player.x, player.y = 1900, 950
  player.myName = "player"
  player:setSequence("idle")
  player:play()

  entrancePortal = display.newSprite(entrancePortalSheet1,entrancePortalSequenceData)
  entrancePortal.x, entrancePortal.y = 160, 781
  entrancePortal.alpha = 0
  entrancePortal.myName = "portal"
  entrancePortal:setSequence("beaming")
  entrancePortal:play()
  

  createExit("Images/Things/gate-closed.png")

	-- add physics to the player
  --player:scale(scaleX,scaleY)

  nw, nh = player.width*scaleX*1, player.height*scaleY*0.8
	physics.addBody(
        player, "dynamic",
        { density=1.0, friction=0.3, bounce=0, shape={-75,-50 , 75,-50 , 75,85 , -75,85} },
        { box={ halfWidth=30, halfHeight=10, x=0, y=95 }, isSensor=true  }
        )
    player.isFixedRotation = true
    player.sensorOverlaps = 0
    player.collision = sensorCollide
    player:addEventListener( "collision" )




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

  --local ground2 = display.newImageRect( "Images/Scene/ground.png", 535, 41)
	--ground2.anchorX = 0
	--ground2.anchorY = 1

	--ground2.x, ground2.y = 1385, 880

	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	--local ground2Shape = {-halfW,-34, halfW,-34, halfW,34, -halfW,34,  }
	--physics.addBody( ground2, "static", { friction=0.3 } )





    --sendArnie()

	-- all display objects must be inserted into group
    sceneGroup:insert( background )
    sceneGroup:insert( entrancePortal )
    sceneGroup:insert( exit )
	sceneGroup:insert( grass)
	sceneGroup:insert( player )
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
    angryArnold = false
    for i=1,#enemies do
    if(enemies[i] and enemies[i].myName=="deadEnemy") then
       angryArnold = true
       print("Arnold is ANGRY///////")
    end
  end
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
	sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
    local platforms = {
      createPlatform (450, 1010, "D"),
      createPlatform (1480, 950, "DP"),
      createPlatform (890, 724, "BP"),
      createPlatform (1800, 764, "A"),
      createPlatform (300, 460, "CP"),
      createPlatform (1450, 540, "C"),
      createPlatform (110, 180, "AP"),
      createPlatform (1050, 300, "BP"),
      createPlatform (1700, 210, "B"),

    }

    leftPressed = false
	rightPressed = false
    exitIsOpen = false
	Runtime:addEventListener( "key", onKeyEvent )
	gameLoopTimer = timer.performWithDelay( 30, gameLoop, 0 )
    shootLoopTimer = timer.performWithDelay( 1000, shootLoop, 0 )
    arnieCountdownTime = arnieDefaultCountdownTime
    countDownTimer = timer.performWithDelay( 1000, updateTime, arnieCountdownTime )

    arnieCountdownTime = arnieDefaultCountdownTime
        Runtime:addEventListener( "collision", onCollision )

    physics.start() 
    createEnemy(1400,900,"enemy", -1)
      
    
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
