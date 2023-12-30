local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Network = require("Network")
local DealDamage = {}
--// https://github.com/digiholic/universalSmashSystem/blob/master/engine/subactions/behavior/dealDamage.py

function DealDamage.new(_damage)
	local object = {damage = _damage}
	setmetatable(object, {__index = DealDamage})
	return object
end
function DealDamage:execute(_entity)
	--// Deal damage if _actor has owner
	--// Might need to use Network
end

return DealDamage