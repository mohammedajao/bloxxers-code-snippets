local Unity = require(script.Parent.Parent)()

local module = { }

function module.Play(asset, volume, pitch)
	local sound = Unity:LoadClientAsset(asset)
	sound.Parent = getfenv(2).script.Parent
	sound.Volume = volume
	sound.Pitch = pitch
	
	sound.Ended:connect(function()
		sound:Destroy()
	end)
	
	sound:Play()
end

return module
