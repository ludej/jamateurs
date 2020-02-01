local utils = {}

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
    local bullet = display.newImageRect("Images/Things/red-square.png", 10, 10)
    physics.addBody(bullet, "dynamic", {isSensor=true})
    bullet.isBullet = true
    bullet.myName = "bullet"
    bullet.x = shooter.x + 100
    bullet.y = shooter.y
    transition.to(bullet, {x=20000, time=5000, onComplete = function() display.remove(bullet) end})
    audio.play(utils.sounds["shooting"][math.random(1, #utils.sounds["shooting"])])
end
utils.fire = fire

return utils
