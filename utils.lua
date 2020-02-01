local utils = {}

 -- Bullet  animation
local bulletSheetData = {width = 210, height = 210, numFrames = 3, sheetContentWidth = 630, sheetContentHeight= 210 }
local bulletSheet = graphics.newImageSheet("/Images/Things/bulletAnim.png", bulletSheetData)


local bulletSequenceData = {
    {name="fly", start=1, count=3, time=575, loopCount=0}
  }

local sounds = {}
sounds["explosion"] = audio.loadSound("sound/plop.wav")
sounds["teleport"] = audio.loadSound("sound/teleport_01.wav")
sounds["shooting"] = {
    audio.loadSound("sound/shoot_01.wav"),
    audio.loadSound("sound/shoot_02.wav"),
    audio.loadSound("sound/shoot_03.wav")}
sounds["jump"] = audio.loadSound( "sound/jump.wav" )
sounds["hastaLaVista"] = audio.loadSound( "sound/hastaLaVista.wav" )
utils.sounds = sounds

-- Shoot a gun
local function fire(shooter)
    --local bullet = display.newSprite(bulletSheet, bulletSequenceData)
    local bullet = display.newImageRect("Images/Things/red-square.png", 10, 10)
    physics.addBody(bullet, "dynamic", {isSensor=true})
    bullet.isBullet = true
    bullet.myName = "bullet"
    bullet.x = shooter.x + 100
    bullet.y = shooter.y
    --bullet:setSequence("fly")
    --bullet:play()
    transition.to(bullet, {x=2000, time=5000, onComplete = function() display.remove(bullet) end})
    audio.play(utils.sounds["shooting"][math.random(1, #utils.sounds["shooting"])])
end
utils.fire = fire

return utils
