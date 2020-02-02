-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local scene = composer.newScene()
local background

-- include Corona's "widget" library
local widget = require "widget"

--------------------------------------------

-- forward declarations and other locals
local playBtn
local imgNo = 1
local backgroundTimer
local backgroundMusicChannel

local function loadBackground()
	imgNo = imgNo % 45 + 1
	if imgNo < 10 then
		imgStr = "00" .. imgNo
	else
		imgStr = "0" .. imgNo
	end
	display.remove(background)
	background = display.newImageRect( "Images/Scene/menu/menu_bg_loop/menu_bg_loop_" .. imgStr .. ".png", display.actualContentWidth, display.actualContentHeight )
	background.anchorX = 0
	background.anchorY = 0
	background.x = 0 + display.screenOriginX
	background.y = 0 + display.screenOriginY
	background:toBack()
end

-- 'onRelease' event listener for playBtn
local function onPlayBtnRelease()
	timer.cancel( backgroundTimer )
	composer.gotoScene( "level4")
	return true	-- indicates successful touch
end

function scene:create( event )
	local sceneGroup = self.view

	-- playBtn = display.newImageRect( "Images/Scene/menu/play_button/play_btn_01.png", 300, 300 )
	playBtn = widget.newButton(
    {
        width = 2500,
        height = 1250,
        defaultFile = "Images/Scene/menu/play_button/play_btn_01.png",
        overFile = "Images/Scene/menu/play_button/play_btn_03.png",
        onRelease = onPlayBtnRelease})
	-- playBtn = widget.newButton{
	-- 	label="Play Now",
	-- 	labelColor = { default={255}, over={128} },
	-- 	default="button.png",
	-- 	over="button-over.png",
	-- 	width=154, height=40,
	-- 	onRelease = onPlayBtnRelease	-- event listener function
	-- }
	playBtn.x = display.contentCenterX + 100
	playBtn.y = display.contentHeight - 500

	-- all display objects must be inserted into group
	-- sceneGroup:insert( background )
	-- sceneGroup:insert( titleLogo )
	sceneGroup:insert( playBtn )
end

function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
        -- Code here runs when the scene is still off screen (but is about to come on screen)
		backgroundTimer = timer.performWithDelay( 80, loadBackground, 0 )
		local music = audio.loadStream( "music/liquidator_menu.wav" )
		backgroundMusicChannel = audio.play( music, { channel=1, loops=-1, fadein=1000 } )

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen

      local prevScene = composer.getSceneName("previous")  -- restart the game if going to the menu
      if(prevScene) then
        composer.removeScene(prevScene)
      end

    end
end

function scene:hide( event )
	local sceneGroup = self.view
	local phase = event.phase

	if event.phase == "will" then
		audio.stop( backgroundMusicChannel )
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end
end

function scene:destroy( event )
	local sceneGroup = self.view

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.

	if playBtn then
		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
