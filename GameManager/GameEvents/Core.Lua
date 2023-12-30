--[[
	Top-level singleton
--]]
local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Log = require("Log")
local Network = require("Network")
local GameManager = {}

local Players = {}

function GameManager:Init()
	for i,module in pairs (script:GetChildren()) do
		if module.ClassName == "ModuleScript" then
			self[module.Name] = require(module)
		end
	end
end

function GameManager:Run()

end

game.Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		Players[player.Name] = Instance.new("BrawlerCharacter", player)
	end)
end)

game.Players.PlayerRemoving:connect(function(player)
	Players[player.Name] = nil
end)


Network.BindFunction(
	"GetBrawlerCharacter",
	Enum.Receiver.Self,
	function(player)
		return Players[player.Name]
	end
)

Network.BindEvent(
	"DealDamage",
	Enum.Receiver.Server,
	function(client, amount, player)
		Players[player.Name].damage = Players[player.Name].damage + amount
		Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.ActionSystem, player.Name, "took", amount, "damage", Players[player.Name].damage)
	end
)

return GameManager