local Unity = require(game.ReplicatedStorage:WaitForChild("Unity.Api"))()
local Log = require("Log")
local Network = require("Network")

local BrawlerPhysics = require("BrawlerPhysics")
local module = {}

Network.BindEvent(
	"DealDamage",
	Enum.Receiver.Server,
	function(player, amount, target, base_knockback, knockback_growth, trajectory)
		print(target)
		local enemyChar = Network.Invoke("GetBrawlerCharacter", Enum.Receiver.Self, game.Players[tostring(target)])
		Log.Write(Enum.LogLevel.Normal, Enum.LogSystem.ActionSystem, "Dealing damage to: ", target.Name, " - Damage: ",  amount, "TD: ", enemyChar.damage)
		BrawlerPhysics:ApplyScaledKnockback(enemyChar, amount, base_knockback, knockback_growth, trajectory)
	end
)

Network.BindEvent(
	"SetState",
	Enum.Receiver.Server,
	function(target, state)
		Network.Fire("ClientSetState", Enum.Receiver.Client, target.player, state)
	end
)

return module
