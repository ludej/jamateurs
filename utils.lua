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

return utils
